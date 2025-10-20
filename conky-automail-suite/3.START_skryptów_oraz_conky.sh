#!/bin/bash

# Przejdź do folderu skryptu (ważne dla ścieżek względnych!)
cd "$(dirname "$(readlink -f "$0")")"

CACHE_DIR="/tmp/conky-automail-suite"
CACHE_MAIL="/tmp/conky-automail-suite/mail_cache.json"
CACHE_GEOIP="/tmp/conky-automail-suite/mail_geoip.cache.json"
LOCK_FILE="/tmp/conky-automail-suite/loop_script.lock"
LAST_SEEN_MAILS_FILE="/tmp/conky-automail-suite/last_seen_mails.json"
CONKY_CONF="conkyrc_mail"
PYTHON_SCRIPT="./py/python_mail_conky_lua.py"
WATCHDOG_SCRIPT="./py/mail_conky_watchdog.py"
PYTHON_ARGS="\
  --config ./config/config.json \
  --cache /tmp/conky-automail-suite/mail_cache.json \
  --count-file ./config/mail_count_python.conf \
  --preview-lines-file ./config/mail_preview_lines.conf \
  --polling-interval 3 \
  --diag-file ./log/mail_diag.json \
"
# Utwórz katalog, jeśli nie istnieje
mkdir -p "$CACHE_DIR"

exec 200>"$LOCK_FILE"
flock -n 200 || {
    notify-send "ℹ️ Już działa" "Skrypt jest już uruchomiony w tle. Druga instancja nie wystartuje."
    if command -v zenity >/dev/null 2>&1; then
        zenity --question \
            --title="Conky Mail – już działa!" \
            --text="Skrypt już działa w tle!\n\nCzy chcesz wyczyścić blokadę i zamknąć WSZYSTKIE powiązane procesy?\n\n(Ubity zostanie widget conky, watchdog, python_mail_conky_lua.py, mail_conky_watchdog.py, cache - mail_geoip.cache.json oraz usunięta blokada.)"
        if [ $? -eq 0 ]; then
            CONKY_CONF_ABS="$(readlink -f "$CONKY_CONF")"
            # Najpierw ubij watchdoga
            WATCHDOG_PID=$(pgrep -f "python3.*mail_conky_watchdog.py")
            if [ -n "$WATCHDOG_PID" ]; then
                kill $WATCHDOG_PID 2>/dev/null
                for i in {1..6}; do
                    sleep 0.2
                    if ! ps -p $WATCHDOG_PID > /dev/null; then break; fi
                done
            fi
            # Ubij conky (tylko ten widget)
            CONKY_PID=$(pgrep -f "conky.*-c $CONKY_CONF_ABS")
            if [ -n "$CONKY_PID" ]; then
                kill $CONKY_PID 2>/dev/null
                sleep 0.2
            fi
            # Usuń plik blokady
            rm -f "$LOCK_FILE"
            rm -f "$CACHE_GEOIP"
			rm -f "$LAST_SEEN_MAILS_FILE"
			rm -f "$CACHE_MAIL"
            # Ubij powiązane pythony
            for script in "$PYTHON_SCRIPT" "$WATCHDOG_SCRIPT"; do
                PIDS=$(pgrep -f "python3.*${script}")
                if [ -n "$PIDS" ]; then
                    kill $PIDS 2>/dev/null
                fi
            done
            notify-send "✅ Wszystko wyłączone" "Procesy conky/mail/py zostały zakończone i blokada usunięta."

            # Zapytaj o restart skryptu
            zenity --question \
                --title="Restart Conky Mail" \
                --text="Czy chcesz ponownie uruchomić skrypt 3.START_skryptów_oraz_conky.sh?"
            if [ $? -eq 0 ]; then
                notify-send "🔁 Restartuję!" "Ponownie uruchamiam 3.START_skryptów_oraz_conky.sh"
                exec "$0"
            else
                notify-send "🛑 Zakończono" "Nie uruchamiam ponownie. Wszystko zamknięte."
                exit 0
            fi
        fi
    fi
    exit 1
}

# Utwórz katalog CACHE_DIR, jeśli nie istnieje
mkdir -p "$CACHE_DIR"

# ----------- Sprawdź oba pliki! -----------
if [ ! -f "$PYTHON_SCRIPT" ]; then
    notify-send "❗ Brak pliku" "Nie znaleziono pliku $PYTHON_SCRIPT. Skrypt zostaje zakończony."
    echo "Nie znaleziono pliku $PYTHON_SCRIPT. Kończę działanie."
    exit 1
fi

if [ ! -f "$WATCHDOG_SCRIPT" ]; then
    notify-send "❗ Brak pliku" "Nie znaleziono pliku $WATCHDOG_SCRIPT. Skrypt zostaje zakończony."
    echo "Nie znaleziono pliku $WATCHDOG_SCRIPT. Kończę działanie."
    exit 1
fi

# ----------- Uruchom watchdog i mail jako tło (z pomiarem czasu startu) -----------
echo "Startuję mail_conky_watchdog.py..."
WATCHDOG_START=$(date +%s)
python3 "$WATCHDOG_SCRIPT" &
WATCHDOG_PID=$!
sleep 0.2
WATCHDOG_END=$(date +%s)
WATCHDOG_TIME=$((WATCHDOG_END - WATCHDOG_START))

echo "Startuję python_mail_conky_lua.py..."
MAIL_START=$(date +%s)
python3 $PYTHON_SCRIPT $PYTHON_ARGS &
MAIL_PID=$!
sleep 0.2
MAIL_END=$(date +%s)
MAIL_TIME=$((MAIL_END - MAIL_START))

# ----------- Weryfikacja działania obu procesów i notyfikacje -----------
ALL_OK=true

if ps -p $WATCHDOG_PID > /dev/null; then
    notify-send "✅ Watchdog uruchomiony" "mail_conky_watchdog.py (PID: $WATCHDOG_PID) – czas uruchamiania: ${WATCHDOG_TIME}s"
    echo "Watchdog uruchomiony (PID: $WATCHDOG_PID, czas: ${WATCHDOG_TIME}s)"
else
    notify-send "❌ Błąd!" "mail_conky_watchdog.py nie wystartował!"
    echo "mail_conky_watchdog.py nie wystartował!"
    ALL_OK=false
fi

if ps -p $MAIL_PID > /dev/null; then
    notify-send "✅ Mail Loop uruchomiony" "python_mail_conky_lua.py (PID: $MAIL_PID) – czas uruchamiania: ${MAIL_TIME}s"
    echo "Mail Loop uruchomiony (PID: $MAIL_PID, czas: ${MAIL_TIME}s)"
else
    notify-send "❌ Błąd!" "python_mail_conky_lua.py nie wystartował!"
    echo "python_mail_conky_lua.py nie wystartował!"
    ALL_OK=false
fi

if [ "$ALL_OK" != "true" ]; then
    notify-send "❗ Skrypt Conky Mail" "Nie udało się uruchomić jednego z procesów – zamykam wszystko."
    # Sprzątaj po sobie:
    [ -n "$WATCHDOG_PID" ] && kill $WATCHDOG_PID 2>/dev/null
    [ -n "$MAIL_PID" ] && kill $MAIL_PID 2>/dev/null
    rm -f "$LOCK_FILE"
    exit 1
fi

# ----------- Wyjście z basha (skrypty w tle) -----------
exit 0

