#!/bin/bash
cd "$(dirname "$(readlink -f "$0")")"
CACHE_DIR="/dev/shm/conky-automail-suite"

# Utwórz katalog, jeśli nie istnieje
mkdir -p "$CACHE_DIR"

# Zapewnij, że tylko jedna instancja skryptu działa w danym momencie
exec 200>/dev/shm/conky-automail-suite/.myconkyluadir.lock
if ! flock -n 200; then
    echo "Inna instancja skryptu już działa!"
    if command -v wmctrl &> /dev/null; then
        wmctrl -a "Konfiguracja Widgetu Mail"
    fi
    exit 1
fi

trap 'rm -f /dev/shm/conky-automail-suite/.myconkyluadir.lock' EXIT

# === Ścieżki do plików ===
LUA_FILE="lua/e-mail.lua"
CONKY_FILE="conkyrc_mail"

# === FUNKCJE POMOCNICZE ===

get_lua_bool() {
    local var_name=$1
    local val=$(grep -oP "${var_name}\s*=\s*\K(true|false)" "$LUA_FILE")
    if [ "$val" == "true" ]; then echo "TRUE"; else echo "FALSE"; fi
}

save_lua_bool() {
    local var_name=$1
    local yad_val=$2
    local lua_val="false"
    if [ "$yad_val" == "TRUE" ]; then lua_val="true"; fi
    sed -i "s|^${var_name}\s*=.*|${var_name} = ${lua_val}|" "$LUA_FILE"
}

# === GŁÓWNA PĘTLA APLIKACJI ===
while true; do

    # 1. Odczyt parametrów z LUA
    CURRENT_SCALE_FACTOR=$(grep -oP 'GLOBAL_SCALE_FACTOR = \K[0-9.]+' "$LUA_FILE")
    CURRENT_LAYOUT=$(grep -oP 'LAYOUT_MODE = "\K[^"]+' "$LUA_FILE")
    CURRENT_MAX_MAILS=$(grep -oP 'MAX_MAILS = \K[0-9]+' "$LUA_FILE")
    CURRENT_WIDTH=$(grep -oP 'GLOBAL_WIDTH_MODIFIER = \K[0-9]+' "$LUA_FILE")

    # Wartości domyślne (zabezpieczenie)
    if [ -z "$CURRENT_MAX_MAILS" ]; then CURRENT_MAX_MAILS=5; fi
    if [ -z "$CURRENT_WIDTH" ]; then CURRENT_WIDTH=1275; fi
    if [ -z "$CURRENT_SCALE_FACTOR" ]; then CURRENT_SCALE_FACTOR=1.0; fi

    # Oblicz procenty (LC_NUMERIC=C zapewnia poprawność kropki dziesiętnej)
    CURRENT_SCALE_PERCENT=$(LC_NUMERIC=C awk -v val="$CURRENT_SCALE_FACTOR" 'BEGIN { printf "%.0f", val * 100 }')

    # Odczyt checkboxów
    CHK_PREVIEW=$(get_lua_bool "SHOW_MAIL_PREVIEW")
    CHK_META=$(get_lua_bool "META_LINE_ENABLE")

    BASE_LAYOUT_LIST="down_left: dolny lewy róg, blok maili w górę|down: okno na dole, blok maili w górę|up: okno na górze, blok maili w dół|down_right: dolny prawy róg, blok maili w górę|up_right: górny prawy róg, blok maili w dół|up_left: górny lewy róg, blok maili w dół"
    YAD_LAYOUT_OPTIONS=$(echo "$BASE_LAYOUT_LIST" | tr '|' '\n' | sed "s/^$CURRENT_LAYOUT:/\^&/" | tr '\n' '!')
    YAD_LAYOUT_OPTIONS=${YAD_LAYOUT_OPTIONS%?}

    # 2. Wyświetlenie okna
    # ZMIANA: Usunięto $ASCII_PREVIEWS z parametru --text
    FORM_OUTPUT=$(yad --form --center \
        --title="Konfiguracja Widgetu Mail" \
        --width=800 \
        --text-align=left \
        --text="<b>Skonfiguruj parametry widgetu:</b>" \
        \
        --field="Układ:CB" \
            "$YAD_LAYOUT_OPTIONS" \
        --field="Liczba maili:NUM" \
            "$CURRENT_MAX_MAILS!1..200!1!0" \
        --field="Skalowanie (0–150%):NUM" \
            "$CURRENT_SCALE_PERCENT!0..150!1!0" \
        --field="Szerokość widgetu (px):NUM" \
            "$CURRENT_WIDTH!875..3820!1!0" \
        \
        --field="<b>Dodatkowe wiersze informacji:</b>:LBL" "" \
        --field="Pokaż podgląd treści wiadomości (tekst maila):CHK" \
            "$CHK_PREVIEW" \
        --field="Pokaż stopkę techniczną (Data, IP, Operator):CHK" \
            "$CHK_META" \
        \
        --button="Zastosuj:0" \
        --button="Przywróć Domyślne:2" \
        --button="Zamknij:1"
    )
    EXIT_CODE=$?

    # Obsługa wyjścia (Anuluj, Zamknij okno)
    if [ $EXIT_CODE -eq 1 ] || [ $EXIT_CODE -eq 252 ]; then
        break
    fi

    # Rozbicie danych z formularza na zmienne
    IFS='|' read -r SELECTED_LAYOUT_FULL NEW_MAX_MAILS SCALE_VALUE NEW_WIDTH _LBL NEW_PREVIEW NEW_META _ <<< "$FORM_OUTPUT"
    
    SELECTED_LAYOUT="${SELECTED_LAYOUT_FULL%%:*}"
    SCALE_INTEGER="${SCALE_VALUE%.*}" 

    # === LOGIKA PRZYCISKU "PRZYWRÓĆ DOMYŚLNE" (KOD 2) ===
    if [ $EXIT_CODE -eq 2 ]; then
        
        # 1. Sprawdzenie czy plik już ma wartości domyślne (porównanie ze stanem sprzed otwarcia okna)
        IS_DEFAULT="FALSE"
        if [ "$CURRENT_MAX_MAILS" == "5" ] && [ "$CURRENT_SCALE_PERCENT" == "100" ] && [ "$CURRENT_WIDTH" == "1275" ]; then
            IS_DEFAULT="TRUE"
        fi

        if [ "$IS_DEFAULT" == "TRUE" ]; then
             yad --center --width=300 \
                --title="Informacja" \
                --image="dialog-information" \
                --text="<b>Widget jest już ustawiony na wartości domyślne.</b>\n\n(5 maili, 100% skali, 1275px szerokości)" \
                --button="OK:0"
             # Wracamy do początku pętli, nic nie zmieniamy
             continue
        fi

        # 2. Pytanie o potwierdzenie
        yad --center --width=400 \
            --title="Potwierdzenie resetu" \
            --image="dialog-question" \
            --text="Czy na pewno chcesz przywrócić ustawienia domyślne?\n\n<b>Ustawi to:</b>\n- Liczba maili: 5\n- Skalowanie: 100%\n- Szerokość: 1275px" \
            --button="Tak, przywróć:0" \
            --button="Anuluj:1"
        
        CONFIRM_RESET=$?

        if [ $CONFIRM_RESET -ne 0 ]; then
            # Jeśli anulowano reset, wracamy do pętli (nie zapisujemy)
            continue
        fi

        # 3. NADPISANIE ZMIENNYCH
        # Zamiast zapisywać tu od razu, ustawiamy zmienne na sztywno.
        NEW_MAX_MAILS=5
        SCALE_INTEGER=100
        NEW_WIDTH=1275
        
        # Komunikat dla użytkownika
        notify-send "Mail Widget" "Przywracanie ustawień domyślnych..."
    fi

    # === WSPÓLNA SEKCJA ZAPISU (DLA ZASTOSUJ I PRZYWRÓĆ) ===
    
    # Walidacja
    if [ -z "$SELECTED_LAYOUT" ] || [ -z "$SCALE_INTEGER" ] || [ -z "$NEW_MAX_MAILS" ] || [ -z "$NEW_WIDTH" ]; then
        notify-send "Mail Widget - Błąd" "Nieprawidłowe dane. Spróbuj ponownie."
        continue
    fi

    # Formatowanie skali (np. 105 -> 1.05)
    INTEGER_PART=$((SCALE_INTEGER / 100))
    FRACTIONAL_PART=$(printf "%02d" $((SCALE_INTEGER % 100)))
    FORMATTED_SCALE_FACTOR="${INTEGER_PART}.${FRACTIONAL_PART}"

    # Edycja pliku LUA
    sed -i "s|^LAYOUT_MODE = \".*\"|LAYOUT_MODE = \"$SELECTED_LAYOUT\"|" "$LUA_FILE"
    sed -i "s|^GLOBAL_SCALE_FACTOR = .*|GLOBAL_SCALE_FACTOR = $FORMATTED_SCALE_FACTOR|" "$LUA_FILE"
    sed -i "s|^MAX_MAILS = [0-9]*|MAX_MAILS = $NEW_MAX_MAILS|" "$LUA_FILE"
    sed -i "s|^GLOBAL_WIDTH_MODIFIER = [0-9]*|GLOBAL_WIDTH_MODIFIER = $NEW_WIDTH|" "$LUA_FILE"

    # Zapis opcji dodatkowych
    save_lua_bool "SHOW_MAIL_PREVIEW" "$NEW_PREVIEW"
    save_lua_bool "META_LINE_ENABLE"  "$NEW_META"

    # Restart Conky
    pkill -u "$USER" -f "conky.*$CONKY_FILE"

    # Powiadomienie
    INFO_MSG="Zastosowano zmiany:
Układ: $SELECTED_LAYOUT
Liczba maili: $NEW_MAX_MAILS
Szerokość: ${NEW_WIDTH}px
Skala: ${SCALE_INTEGER}%"
    
    notify-send "Mail Widget" "$INFO_MSG"
    sleep 0.5

done

notify-send "Mail Widget" "Konfigurator został zamknięty."
echo "Konfigurator zamknięty."
