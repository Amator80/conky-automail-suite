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

# === FUNKCJA AKTUALIZUJĄCA ===
update_config() {
    local var_name="$1"
    local new_val="$2"

    local current_line=$(grep -m1 "^${var_name}\s*=" "$LUA_FILE")
    local comment_part=$(echo "$current_line" | grep -oE "[[:blank:]]*--.*" || true)

    if [ -n "$comment_part" ]; then
        sed -i "s~^\(${var_name}\s*=\s*\).*$~\1${new_val}${comment_part}~" "$LUA_FILE"
    else
        sed -i "s~^${var_name}\s*=.*~${var_name} = ${new_val}~" "$LUA_FILE"
    fi
}

# === POZOSTAŁE FUNKCJE POMOCNICZE ===

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
    update_config "$var_name" "$lua_val"
}

get_lua_color() {
    local var_name=$1
    local type_var="${var_name%_CUSTOM}_TYPE"
    local type_val=$(grep -oP "${type_var}\s*=\s*\"\K[^\"]+" "$LUA_FILE")
    
    if [ "$type_val" == "white" ]; then echo "#FFFFFF"; return; fi
    if [ "$type_val" == "black" ]; then echo "#000000"; return; fi

    local val_str=$(grep -oP "${var_name}\s*=\s*\{\K[^}]+" "$LUA_FILE")
    echo "$val_str" | awk -F, '{
        r=$1; g=$2; b=$3;
        gsub(/[ \t]+/, "", r); gsub(/[ \t]+/, "", g); gsub(/[ \t]+/, "", b);
        if(r<=1 && r!=0) r=r*255; else if(r>1) r=r;
        if(g<=1 && g!=0) g=g*255; else if(g>1) g=g;
        if(b<=1 && b!=0) b=b*255; else if(b>1) b=b;
        printf("#%02x%02x%02x\n", r, g, b)
    }'
}

save_lua_color() {
    local var_name=$1
    local hex_val=$2
    
    if [[ $hex_val =~ ^#[0-9A-Fa-f]{6}$ ]]; then
        local r=$((16#${hex_val:1:2}))
        local g=$((16#${hex_val:3:2}))
        local b=$((16#${hex_val:5:2}))
        
        update_config "$var_name" "\{${r}, ${g}, ${b}\}"

        local type_var="${var_name%_CUSTOM}_TYPE"
        if grep -q "$type_var" "$LUA_FILE"; then
            update_config "$type_var" "\"custom\""
        fi
    fi
}

# === GŁÓWNA PĘTLA APLIKACJI ===
while true; do

    # 1. ODCZYT DANYCH Z PLIKU LUA
    CURRENT_SCALE_FACTOR=$(grep -oP 'GLOBAL_SCALE_FACTOR = \K[0-9.]+' "$LUA_FILE")
    CURRENT_LAYOUT=$(grep -oP 'LAYOUT_MODE = "\K[^"]+' "$LUA_FILE")
    CURRENT_MAX_MAILS=$(grep -oP 'MAX_MAILS = \K[0-9]+' "$LUA_FILE")
    CURRENT_WIDTH=$(grep -oP 'GLOBAL_WIDTH_MODIFIER = \K[0-9]+' "$LUA_FILE")
    
    # Odczyt tekstu nagłówka
    CURRENT_HEADER_TEXT=$(grep -oP 'CUSTOM_TEXT_VALUE = "\K[^"]+' "$LUA_FILE")

    # Kolory
    CLR_FROM=$(get_lua_color "FROM_COLOR_CUSTOM")
    CLR_SUBJECT=$(get_lua_color "SUBJECT_COLOR_CUSTOM")
    CLR_PREVIEW=$(get_lua_color "PREVIEW_COLOR_CUSTOM")
    CLR_SEPARATOR=$(get_lua_color "SEPARATOR_COLOR_CUSTOM")
    CLR_HEADER=$(get_lua_color "CUSTOM_TEXT_COLOR_CUSTOM")
    CLR_META_TEXT=$(get_lua_color "META_COLOR_IP")
    CLR_META_SEP=$(get_lua_color "META_COLOR_SEPARATOR")

    # Wartości domyślne
    if [ -z "$CURRENT_MAX_MAILS" ]; then CURRENT_MAX_MAILS=5; fi
    if [ -z "$CURRENT_WIDTH" ]; then CURRENT_WIDTH=1275; fi
    if [ -z "$CURRENT_SCALE_FACTOR" ]; then CURRENT_SCALE_FACTOR=1.0; fi
    CURRENT_SCALE_PERCENT=$(LC_NUMERIC=C awk -v val="$CURRENT_SCALE_FACTOR" 'BEGIN { printf "%.0f", val * 100 }')

    # --- ODCZYT BOOLEANÓW ---
    CHK_PREVIEW=$(get_lua_bool "SHOW_MAIL_PREVIEW")
    CHK_META=$(get_lua_bool "META_LINE_ENABLE")
    STATE_HEADER=$(get_lua_bool "CUSTOM_TEXT_ENABLE")
    STATE_SEPARATOR=$(get_lua_bool "SEPARATOR_ENABLE")

    BASE_LAYOUT_LIST="down_left: dolny lewy róg, blok maili w górę|down: okno na dole, blok maili w górę|up: okno na górze, blok maili w dół|down_right: dolny prawy róg, blok maili w górę|up_right: górny prawy róg, blok maili w dół|up_left: górny lewy róg, blok maili w dół"
    YAD_LAYOUT_OPTIONS=$(echo "$BASE_LAYOUT_LIST" | tr '|' '\n' | sed "s/^$CURRENT_LAYOUT:/\^&/" | tr '\n' '!')
    YAD_LAYOUT_OPTIONS=${YAD_LAYOUT_OPTIONS%?}

    # 2. BUDOWANIE OKNA
    
    # Etykieta sekcji kolorów
    if [ "$STATE_HEADER" == "TRUE" ]; then
        LABEL_COLORS="<b>Własny Nagłówek i Kolory:</b>"
    else
        LABEL_COLORS="<b>Kolory Podstawowe:</b>"
    fi

    # Treść nagłówka informacyjnego (sformatowana w Pango Markup)
    INFO_HEADER="<span size='x-large' weight='bold' color='#3498db'>PODSTAWOWY KONFIGURATOR</span>\n\nTo narzędzie zawiera jedynie <b>niezbędne minimum</b> opcji.\nPełna, zaawansowana konfiguracja wyglądu i zachowania (czcionki, animacje, marginesy)\nznajduje się w głównym pliku: <span font_family='monospace'>lua/e-mail.lua</span>\n\n<b>----------------------------------------------------------------------------------------------------------------</b>"

    YAD_ARGS=(
        --form --center 
        --title="Konfiguracja Widgetu Mail" 
        --width=900 
        --text-align=center
        --text="$INFO_HEADER"
        
        # --- SEKCJA 1: PARAMETRY (Indeksy 1-4) ---
        --field="Układ:CB" "$YAD_LAYOUT_OPTIONS"
        --field="Liczba maili:NUM" "$CURRENT_MAX_MAILS!1..200!1!0"
        --field="Skalowanie (0–150%):NUM" "$CURRENT_SCALE_PERCENT!0..150!1!0"
        --field="Szerokość widgetu (px):NUM" "$CURRENT_WIDTH!875..3820!1!0"
        
        # --- SEKCJA 2: OPCJE WYŚWIETLANIA (Indeksy 5-7) ---
        --field="<b>Opcje Wyświetlania:</b>:LBL" ""
        --field="Pokaż treść (Preview):CHK" "$CHK_PREVIEW"
        --field="Pokaż stopkę (Meta):CHK" "$CHK_META"
        
        # --- SEKCJA 3: KOLORY I NAGŁÓWEK (Indeks 8) ---
        --field="$LABEL_COLORS:LBL" ""
    )

    # --- WARUNKOWE DODAWANIE PÓL (Odtwarzanie kolejności) ---

    # A) Nagłówek
    if [ "$STATE_HEADER" == "TRUE" ]; then
        YAD_ARGS+=( --field="Treść nagłówka:ENTRY" "$CURRENT_HEADER_TEXT" )
        YAD_ARGS+=( --field="Kolor nagłówka:CLR" "$CLR_HEADER" )
    fi

    # B) Podstawowe Kolory
    YAD_ARGS+=( --field="Nadawca (From):CLR" "$CLR_FROM" )
    YAD_ARGS+=( --field="Temat (Subject):CLR" "$CLR_SUBJECT" )

    # C) Preview
    if [ "$CHK_PREVIEW" == "TRUE" ]; then
        YAD_ARGS+=( --field="Treść (Preview):CLR" "$CLR_PREVIEW" )
    fi

    # D) Meta
    if [ "$CHK_META" == "TRUE" ]; then
        YAD_ARGS+=( --field="Meta Dane (Tekst):CLR" "$CLR_META_TEXT" )
        YAD_ARGS+=( --field="Meta Separator (|):CLR" "$CLR_META_SEP" )
    fi

    # E) Separator
    if [ "$STATE_SEPARATOR" == "TRUE" ]; then
        YAD_ARGS+=( --field="Linia Nagłówka:CLR" "$CLR_SEPARATOR" )
    fi


    # Przyciski
    YAD_ARGS+=(
        --button="Zastosuj:0"
        --button="Przywróć Domyślne:2"
        --button="Zamknij:1"
    )

    # WYŚWIETLENIE OKNA
    FORM_OUTPUT=$(yad "${YAD_ARGS[@]}")
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 1 ] || [ $EXIT_CODE -eq 252 ]; then
        break
    fi

    # === RESET DOMYŚLNY ===
    if [ $EXIT_CODE -eq 2 ]; then
        yad --center --width=400 --title="Reset" --image="dialog-question" \
            --text="Przywrócić ustawienia domyślne?" \
            --button="Tak:0" --button="Anuluj:1"
        
        if [ $? -ne 0 ]; then continue; fi

        NEW_MAX_MAILS=5
        SCALE_INTEGER=100
        NEW_WIDTH=1275
        NEW_HEADER_TEXT="Mail@Desk Twój osobisty asystent poczty"
        
        # Kolory domyślne
        NEW_CLR_HEADER="#FF3C00" 
        NEW_CLR_FROM="#FA2532"
        NEW_CLR_SUBJECT="#FFFFFF"
        NEW_CLR_PREVIEW="#16D9C5"
        NEW_CLR_META_TEXT="#90B6EE"
        NEW_CLR_META_SEP="#86FF00"
        NEW_CLR_SEP="#FFFFFF"

        # Checkboxy GUI - resetujemy
        save_lua_bool "SHOW_MAIL_PREVIEW" "TRUE"
        save_lua_bool "META_LINE_ENABLE"  "TRUE"
        
        INTEGER_PART=1
        FRACTIONAL_PART=00
        FORMATTED_SCALE="$INTEGER_PART.$FRACTIONAL_PART"

        update_config "LAYOUT_MODE" "\"down_left\""
        update_config "GLOBAL_SCALE_FACTOR" "$FORMATTED_SCALE"
        update_config "MAX_MAILS" "$NEW_MAX_MAILS"
        update_config "GLOBAL_WIDTH_MODIFIER" "$NEW_WIDTH"
        update_config "CUSTOM_TEXT_VALUE" "\"$NEW_HEADER_TEXT\""
        
        save_lua_color "CUSTOM_TEXT_COLOR_CUSTOM" "$NEW_CLR_HEADER"
        save_lua_color "FROM_COLOR_CUSTOM"        "$NEW_CLR_FROM"
        save_lua_color "SUBJECT_COLOR_CUSTOM"     "$NEW_CLR_SUBJECT"
        save_lua_color "PREVIEW_COLOR_CUSTOM"     "$NEW_CLR_PREVIEW"
        save_lua_color "SEPARATOR_COLOR_CUSTOM"   "$NEW_CLR_SEP"
        save_lua_color "META_COLOR_SEPARATOR"     "$NEW_CLR_META_SEP"
        
        META_TEXT_VARS=("META_COLOR_IP" "META_COLOR_CITY" "META_COLOR_ISP" "META_COLOR_AGE" "META_COLOR_DATETIME" "META_COLOR_AGENT" "META_COLOR_COUNTRY" "META_COLOR_MOBILE")
        for meta_var in "${META_TEXT_VARS[@]}"; do
            save_lua_color "$meta_var" "$NEW_CLR_META_TEXT"
        done

        pkill -u "$USER" -f "conky.*$CONKY_FILE"
        notify-send "Mail Widget" "Przywrócono domyślne!"
        sleep 0.5
        continue
    fi

    # 3. PARSOWANIE WYNIKU (Pola Stałe)
    SELECTED_LAYOUT_FULL=$(echo "$FORM_OUTPUT" | cut -d'|' -f1)
    NEW_MAX_MAILS=$(echo "$FORM_OUTPUT" | cut -d'|' -f2)
    SCALE_VALUE=$(echo "$FORM_OUTPUT" | cut -d'|' -f3)
    NEW_WIDTH=$(echo "$FORM_OUTPUT" | cut -d'|' -f4)
    # Pole 5: Etykieta
    NEW_PREVIEW=$(echo "$FORM_OUTPUT" | cut -d'|' -f6)
    NEW_META=$(echo "$FORM_OUTPUT" | cut -d'|' -f7)
    # Pole 8: Etykieta - KONIEC STAŁYCH

    NEXT_INDEX=9

    # --- A) Nagłówek ---
    if [ "$STATE_HEADER" == "TRUE" ]; then
        NEW_HEADER_TEXT=$(echo "$FORM_OUTPUT" | cut -d'|' -f$NEXT_INDEX)
        NEXT_INDEX=$((NEXT_INDEX + 1))
        NEW_CLR_HEADER=$(echo "$FORM_OUTPUT" | cut -d'|' -f$NEXT_INDEX)
        NEXT_INDEX=$((NEXT_INDEX + 1))
    else
        NEW_HEADER_TEXT="$CURRENT_HEADER_TEXT"
        NEW_CLR_HEADER="$CLR_HEADER"
    fi

    # --- B) Podstawowe Kolory ---
    NEW_CLR_FROM=$(echo "$FORM_OUTPUT" | cut -d'|' -f$NEXT_INDEX)
    NEXT_INDEX=$((NEXT_INDEX + 1))
    NEW_CLR_SUBJECT=$(echo "$FORM_OUTPUT" | cut -d'|' -f$NEXT_INDEX)
    NEXT_INDEX=$((NEXT_INDEX + 1))

    # --- C) Preview ---
    if [ "$CHK_PREVIEW" == "TRUE" ]; then
        NEW_CLR_PREVIEW=$(echo "$FORM_OUTPUT" | cut -d'|' -f$NEXT_INDEX)
        NEXT_INDEX=$((NEXT_INDEX + 1))
    else
        NEW_CLR_PREVIEW="$CLR_PREVIEW"
    fi

    # --- D) Meta ---
    if [ "$CHK_META" == "TRUE" ]; then
        NEW_CLR_META_TEXT=$(echo "$FORM_OUTPUT" | cut -d'|' -f$NEXT_INDEX)
        NEXT_INDEX=$((NEXT_INDEX + 1))
        NEW_CLR_META_SEP=$(echo "$FORM_OUTPUT" | cut -d'|' -f$NEXT_INDEX)
        NEXT_INDEX=$((NEXT_INDEX + 1))
    else
        NEW_CLR_META_TEXT="$CLR_META_TEXT"
        NEW_CLR_META_SEP="$CLR_META_SEP"
    fi

    # --- E) Separator ---
    if [ "$STATE_SEPARATOR" == "TRUE" ]; then
        NEW_CLR_SEP=$(echo "$FORM_OUTPUT" | cut -d'|' -f$NEXT_INDEX)
        NEXT_INDEX=$((NEXT_INDEX + 1))
    else
        NEW_CLR_SEP="$CLR_SEPARATOR"
    fi


    # === ZAPIS ===
    SELECTED_LAYOUT="${SELECTED_LAYOUT_FULL%%:*}"
    SCALE_INTEGER="${SCALE_VALUE%.*}"
    
    if [ -z "$SELECTED_LAYOUT" ]; then continue; fi

    INTEGER_PART=$((SCALE_INTEGER / 100))
    FRACTIONAL_PART=$(printf "%02d" $((SCALE_INTEGER % 100)))
    FORMATTED_SCALE_FACTOR="${INTEGER_PART}.${FRACTIONAL_PART}"

    update_config "LAYOUT_MODE" "\"$SELECTED_LAYOUT\""
    update_config "GLOBAL_SCALE_FACTOR" "$FORMATTED_SCALE_FACTOR"
    update_config "MAX_MAILS" "$NEW_MAX_MAILS"
    update_config "GLOBAL_WIDTH_MODIFIER" "$NEW_WIDTH"
    
    save_lua_bool "SHOW_MAIL_PREVIEW"  "$NEW_PREVIEW"
    save_lua_bool "META_LINE_ENABLE"   "$NEW_META"
    
    update_config "CUSTOM_TEXT_VALUE" "\"$NEW_HEADER_TEXT\""

    save_lua_color "CUSTOM_TEXT_COLOR_CUSTOM" "$NEW_CLR_HEADER"
    save_lua_color "FROM_COLOR_CUSTOM"        "$NEW_CLR_FROM"
    save_lua_color "SUBJECT_COLOR_CUSTOM"     "$NEW_CLR_SUBJECT"
    save_lua_color "PREVIEW_COLOR_CUSTOM"     "$NEW_CLR_PREVIEW"
    save_lua_color "SEPARATOR_COLOR_CUSTOM"   "$NEW_CLR_SEP"
    save_lua_color "META_COLOR_SEPARATOR"     "$NEW_CLR_META_SEP"

    META_TEXT_VARS=("META_COLOR_IP" "META_COLOR_CITY" "META_COLOR_ISP" "META_COLOR_AGE" "META_COLOR_DATETIME" "META_COLOR_AGENT" "META_COLOR_COUNTRY" "META_COLOR_MOBILE")
    for meta_var in "${META_TEXT_VARS[@]}"; do
        save_lua_color "$meta_var" "$NEW_CLR_META_TEXT"
    done

    pkill -u "$USER" -f "conky.*$CONKY_FILE"
    notify-send "Mail Widget" "Zastosowano zmiany."
    sleep 0.5

done

notify-send "Mail Widget" "Konfigurator zamknięty."
echo "Konfigurator zamknięty."
