#!/bin/bash

# --- Obsługa flagi --debug ---
DEBUG_MODE=false
# Tutaj trzymamy Twoje stare argumenty, plus ewentualny --debug
if [ "$1" == "--debug" ]; then
    DEBUG_MODE=true
    EXTRA_ARGS="--debug"
    echo -e "\033[1;33mTryb debugowania włączony. Logowanie RAM aktywne.\033[0m"
else
    EXTRA_ARGS=""
fi

# Przejdź do katalogu skryptu
cd "$(dirname "$(readlink -f "$0")")"
CURRENT_DIR=$(pwd)

# =================================================================================
#  KONFIGURACJA ŚCIEŻEK (Twoje nazwy)
# =================================================================================
CACHE_DIR="/dev/shm/conky-automail-suite"
LOCK_FILE="/dev/shm/conky-automail-suite/loop_script.lock"
CONKY_CONF="conkyrc_mail"
PYTHON_SCRIPT="./py/python_mail_conky_lua.py"
MAIL_CACHE="/dev/shm/conky-automail-suite/mail_cache.json"
MAX_WAIT=60

# --- Ścieżka do mapy avatarów ---
AVATAR_MAP_FILE="./config/avatar_map.json"

# --- Twoje argumenty dla Pythona ---
PYTHON_ARGS="\
  --config ./config/config.json \
  --cache /dev/shm/conky-automail-suite/mail_cache.json \
  --count-file ./config/mail_count_python.conf \
  --preview-lines-file ./config/mail_preview_lines.conf \
  --polling-interval 5 \
  --diag-file ./log/mail_diag.json \
  --no-diag-log \
  $EXTRA_ARGS \
"

# --- Pliki PID dla watchdogów ---
CONKY_PID_FILE="$CACHE_DIR/conky.pid"
RESPAWN_PID_FILE="$CACHE_DIR/respawn_conky.pid"
RAM_PID_FILE="$CACHE_DIR/ram_watchdog.pid"

# Utwórz katalog w pamięci RAM, jeśli nie istnieje
mkdir -p "$CACHE_DIR"

# =================================================================================
#  BLOKADA I ZARZĄDZANIE PROCESAMI
# =================================================================================
exec 200>"$LOCK_FILE"
flock -n 200 || {
    notify-send "ℹ️ Już działa" "Skrypt jest już uruchomiony w tle. Druga instancja nie wystartuje."
    if command -v zenity >/dev/null 2>&1; then
        zenity --question \
            --title="Conky Mail – już działa!" \
            --text="<big><big><b>Conky Mail</b> już działa w tle!</big></big>\n\nCzy chcesz wyłączyć widget i zamknąć WSZYSTKIE powiązane z nim procesy?\n\nWyłączony zostanie proces <b>conky</b>, skrypt <b>python_mail_conky_lua.py</b> oraz usunięty cache."
        if [ $? -eq 0 ]; then
            # 1. Zabijamy watchdogi (żeby nie podniosły Conky za chwilę)
            if [ -f "$RESPAWN_PID_FILE" ]; then kill -9 $(cat "$RESPAWN_PID_FILE") 2>/dev/null; rm -f "$RESPAWN_PID_FILE"; fi
            if [ -f "$RAM_PID_FILE" ]; then kill -9 $(cat "$RAM_PID_FILE") 2>/dev/null; rm -f "$RAM_PID_FILE"; fi
            
            # 2. Conky: ATOMOWE UDERZENIE (-9). 
            pkill -9 -u "$USER" -f "conky.*-c $CONKY_CONF"
            
            # 3. Python: GRZECZNE ZAMKNIĘCIE (SIGTERM).
            PY_PIDS=$(pgrep -f "python3.*${PYTHON_SCRIPT}")
            if [ -n "$PY_PIDS" ]; then
                kill $PY_PIDS 2>/dev/null
                
                # Czekamy aktywnie, aż Python się zamknie (max 5 sekund)
                for i in {1..50}; do
                    if ! kill -0 $PY_PIDS 2>/dev/null; then
                        break
                    fi
                    sleep 0.1
                done
                
                # Jeśli po 5 sekundach dalej wisi -> dobijamy
                kill -9 $PY_PIDS 2>/dev/null
            fi
            
            # 4. Bezpieczne usunięcie cache
            rm -rf "$CACHE_DIR"

            notify-send "✅ Wyłączono" "Procesy zakończone poprawnie."
            
            if zenity --question --title="Restart Conky Mail" --text="Czy chcesz ponownie uruchomić skrypt?"; then
                notify-send "🔁 Restartuję!" "Ponownie uruchamiam..."
                exec "$0" "$@"
            else
                notify-send "🛑 Zakończono" "Nie uruchamiam ponownie. Wszystko zamknięte."
                exit 0
            fi
        fi
    fi
    exit 1
}

# Sprawdzenie istnienia pliku python
if [ ! -f "$PYTHON_SCRIPT" ]; then
    notify-send "❗ Brak pliku" "Nie znaleziono pliku $PYTHON_SCRIPT. Kończę działanie."
    exit 1
fi

# =================================================================================
#  AUTONAPRAWA ŚCIEŻEK AVATARÓW (Wklejona logika z Avatar_Manager)
# =================================================================================
# Ta sekcja uruchamia się zawsze przed startem Conky.
# Sprawdza config/avatar_map.json i aktualizuje ścieżki do folderu bieżącego.
if [ -f "$AVATAR_MAP_FILE" ] && command -v jq >/dev/null; then
    # echo "Weryfikacja ścieżek avatarów..."
    tmp_json=$(mktemp)
    
    # Magia jq: podmienia prefiks ścieżki na aktualny folder ($CURRENT_DIR)
    jq --arg base "$CURRENT_DIR" '
      map_values(
        if (. | contains("/avatar/")) then
          (. | split("|") | 
           (.[0] | sub(".*\\/avatar\\/"; $base + "/avatar/")) + "|" + .[1])
        else
          .
        end
      )
    ' "$AVATAR_MAP_FILE" > "$tmp_json" && mv "$tmp_json" "$AVATAR_MAP_FILE"
    
    # Kopiujemy od razu naprawiony plik do RAM-u, żeby Conky miał świeże dane
    mkdir -p "$(dirname "$CACHE_DIR/avatar_map.json")"
    cp "$AVATAR_MAP_FILE" "$CACHE_DIR/avatar_map.json"
fi

MEM_LIMIT_MB=299

# =================================================================================
#  WATCHDOGI (Utrzymywanie Conky przy życiu)
# =================================================================================

# --- Watchdog 1: Natychmiastowy respawn Conky ---
while true; do
    if ! pgrep -u "$USER" -f "conky.*-c $CONKY_CONF" >/dev/null; then
        conky -c "$CONKY_CONF" &
        CONKY_PID=$!
        echo $CONKY_PID > "$CONKY_PID_FILE"
    fi
    sleep 0.15
done &
RESPAWN_PID=$!
disown $RESPAWN_PID
echo $RESPAWN_PID > "$RESPAWN_PID_FILE"

# --- Watchdog 2: Monitorowanie RAM ---
while true; do
    CONKY_PIDS=$(pgrep -u "$USER" -f "conky.*-c $CONKY_CONF")
    for PID in $CONKY_PIDS; do
        MEM_KB=$(ps -o rss= -p "$PID" | awk '{print $1}')
        MEM_MB=$((MEM_KB / 1024))
        
        if [ "$DEBUG_MODE" = true ]; then
            echo "$(date) PID:$PID RAM:${MEM_MB}MB" >> "$CACHE_DIR/conky_ram_watchdog.log"
        fi
        
        if (( MEM_MB > MEM_LIMIT_MB )); then
            notify-send "⚠️ Restart Conky" "Proces PID $PID przekroczył ${MEM_MB} MB RAM. Restartuję..."
            kill "$PID"
        fi
    done
    sleep 5
done &
RAM_PID=$!
disown $RAM_PID
echo $RAM_PID > "$RAM_PID_FILE"

# =================================================================================
#  URUCHAMIANIE PYTHON (Bez VENV, standardowy systemowy Python)
# =================================================================================
echo "Uruchamiam skrypt Python..."
notify-send "▶️ Start" "Uruchamiam python_mail_conky_lua.py..."

python3 "$PYTHON_SCRIPT" $PYTHON_ARGS &
PY_PID=$!

# =================================================================================
#  OCZEKIWANIE NA CACHE (Weryfikacja startu)
# =================================================================================
notify-send "⏳ Oczekiwanie" "Czekam na utworzenie cache przez Pythona..."
success=0
START_WAIT=$(date +%s)

for ((i=1; i<=MAX_WAIT; i++)); do
    if [ -f "$MAIL_CACHE" ]; then
        success=1
        END_WAIT=$(date +%s)
        ELAPSED=$((END_WAIT - START_WAIT))
        break
    fi
    # Sprawdź czy proces pythona w ogóle żyje
    if ! kill -0 $PY_PID 2>/dev/null; then
        break
    fi
    if [ $i -eq 30 ]; then
        notify-send "⏳ Nadal czekam" "To może potrwać dłużej przy dużej ilości maili..."
    fi
    sleep 1
done

if [ $success -eq 1 ]; then
    notify-send "✅ Sukces" "Utworzono cache w ${ELAPSED}sek. Widget działa."
else
    notify-send "❌ Błąd uruchamiania!" "Nie utworzono pliku cache w czasie $MAX_WAIT sek."
    zenity --error --text="❌ Błąd uruchamiania!\n\nNie utworzono pliku cache ($MAIL_CACHE).\nSkrypt Pythona prawdopodobnie zakończył się błędem.\n\nUruchom skrypt w terminalu z flagą --debug, aby zobaczyć szczegóły."
    
    # Sprzątanie po błędzie
    [ -f "$RESPAWN_PID_FILE" ] && kill $(cat "$RESPAWN_PID_FILE") 2>/dev/null && rm -f "$RESPAWN_PID_FILE"
    [ -f "$RAM_PID_FILE" ] && kill $(cat "$RAM_PID_FILE") 2>/dev/null && rm -f "$RAM_PID_FILE"
    pkill -f "conky.*-c $CONKY_CONF"
    kill $PY_PID 2>/dev/null
    rm -f "$LOCK_FILE"
    exit 1
fi

# Czekaj na proces pythona (główna pętla skryptu wisi tutaj)
wait $PY_PID

# Po zakończeniu pythona (np. manualnym ubiciu) sprzątaj resztę
[ -f "$RESPAWN_PID_FILE" ] && kill $(cat "$RESPAWN_PID_FILE") 2>/dev/null && rm -f "$RESPAWN_PID_FILE"
[ -f "$RAM_PID_FILE" ] && kill $(cat "$RAM_PID_FILE") 2>/dev/null && rm -f "$RAM_PID_FILE"
pkill -f "conky.*-c $CONKY_CONF"
rm -f "$LOCK_FILE"

exit 0
