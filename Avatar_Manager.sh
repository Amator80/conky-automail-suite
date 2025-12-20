#!/bin/bash

# =============================================================================
# INTELIGENTNE WYKRYWANIE KATALOGU PROJEKTU
# =============================================================================
BASE_DIR="$(dirname "$(readlink -f "$0")")"
CHECK_FILE="lua/e-mail.lua"

if [ ! -f "$BASE_DIR/$CHECK_FILE" ]; then
    FOUND_PATH=$(find "$HOME" -maxdepth 5 -type f -path "*/$CHECK_FILE" -print -quit 2>/dev/null)
    if [ -n "$FOUND_PATH" ]; then
        BASE_DIR="$(dirname "$(dirname "$FOUND_PATH")")"
    else
        if command -v yad >/dev/null; then
            yad --error --title="Błąd krytyczny" --center \
                --text="Nie mogę znaleźć folderu projektu!\nSzukano pliku: lua/e-mail.lua" --button="OK":1
        fi
        exit 1
    fi
fi

# =============================================================================
# KONFIGURACJA ŚCIEŻEK
# =============================================================================
CONFIG_DIR="$BASE_DIR/config"
LUA_FILE="$BASE_DIR/$CHECK_FILE"
JSON_FILE="$CONFIG_DIR/avatar_map.json"

# --- STRUKTURA KATALOGÓW AVATARÓW ---
AVATAR_ROOT="$BASE_DIR/avatar"
DIR_DEFAULT="$AVATAR_ROOT/DEFAULT"
DIR_ZNAJOMI="$AVATAR_ROOT/znajomi"
DIR_SKLEPY="$AVATAR_ROOT/inne-sklepy"
DEFAULT_ICON="$DIR_DEFAULT/user_default.png"

# PLIKI TYMCZASOWE
YAD_OUT_FILE="/tmp/conky_automail_multi.out"

# =============================================================================
# ŚCIEŻKI RAM
# =============================================================================
RAM_JSON="/dev/shm/conky-automail-suite/avatar_map.json"
RAM_TRIGGER="/dev/shm/conky-automail-suite/avatar_trigger"

# =============================================================================
# INICJALIZACJA I AUTONAPRAWA ŚCIEŻEK
# =============================================================================
mkdir -p "$CONFIG_DIR" "$DIR_DEFAULT" "$DIR_ZNAJOMI" "$DIR_SKLEPY"
if [ ! -f "$JSON_FILE" ]; then echo "{}" > "$JSON_FILE"; fi

# --- FUNKCJA: AUTOMATYCZNA NAPRAWA ŚCIEŻEK W JSON ---
auto_fix_paths() {
    local tmp=$(mktemp)
    jq --arg base "$BASE_DIR" '
      map_values(
        if (. | contains("/avatar/")) then
          (. | split("|") | 
           (.[0] | sub(".*\\/avatar\\/"; $base + "/avatar/")) + "|" + .[1])
        else
          .
        end
      )
    ' "$JSON_FILE" > "$tmp" && mv "$tmp" "$JSON_FILE"
}
auto_fix_paths

CURRENT_VIEW="Znajomi"
SEARCH_QUERY=""

# =============================================================================
# FUNKCJE POMOCNICZE
# =============================================================================

update_conky_ram() {
    mkdir -p "$(dirname "$RAM_JSON")"
    cp "$JSON_FILE" "$RAM_JSON"
    date +%s > "$RAM_TRIGGER"
}

hex_to_lua_color() {
    local hex=$1; local alpha=$2; hex=${hex#\#}
    local r_hex=${hex:0:2}; local g_hex=${hex:2:2}; local b_hex=${hex:4:2}
    if [ ${#hex} -eq 12 ]; then r_hex=${hex:0:2}; g_hex=${hex:4:2}; b_hex=${hex:8:2}; fi
    local r_dec=$((16#$r_hex)); local g_dec=$((16#$g_hex)); local b_dec=$((16#$b_hex))
    local r_lua=$(LC_NUMERIC=C awk "BEGIN {printf \"%.3g\", $r_dec/255}")
    local g_lua=$(LC_NUMERIC=C awk "BEGIN {printf \"%.3g\", $g_dec/255}")
    local b_lua=$(LC_NUMERIC=C awk "BEGIN {printf \"%.3g\", $b_dec/255}")
    local a_lua=$(LC_NUMERIC=C awk "BEGIN { val = $alpha / 100; if (val == 1) printf \"1.0\"; else printf \"%.2f\", val }")
    echo "{$r_lua, $g_lua, $b_lua, $a_lua}"
}

get_lua_status() {
    if grep -q "^SHOW_AVATARS = true" "$LUA_FILE"; then echo "ON"; else echo "OFF"; fi
}

toggle_lua_status() {
    local current=$(get_lua_status)
    if [ "$current" == "ON" ]; then
        sed -i 's/^SHOW_AVATARS = true/SHOW_AVATARS = false/' "$LUA_FILE"
    else
        local check_size=$(grep "^AVATAR_SIZE" "$LUA_FILE" | sed 's/.*= *//' | awk '{print $1}' | tr -d '",')
        [[ ! "$check_size" =~ ^[0-9]+$ ]] && check_size=0
        if [ "$check_size" -eq 0 ]; then
            yad --error --title="Błąd" --text="Nie można włączyć! Rozmiar awatara to 0 px." --center --button="OK":0
        else
            sed -i 's/^SHOW_AVATARS = false/SHOW_AVATARS = true/' "$LUA_FILE"
            update_conky_ram
        fi
    fi
}

trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

if [ "$(get_lua_status)" == "ON" ]; then
    update_conky_ram
fi

# =============================================================================
# PĘTLA PROGRAMU
# =============================================================================
while true; do
    echo "" > "$YAD_OUT_FILE"
    
    # 1. Konfiguracja widoku
    if [ "$CURRENT_VIEW" == "Znajomi" ]; then
        JQ_FILTER='select(.key != "DEFAULT_PROFILE") | select( (.value | split("|")[1] // "Znajomi") == "Znajomi" )'
        WINDOW_TITLE="Menedżer Awatarów - ZNAJOMI"
        BTN_SWITCH_LABEL="Przełącz na: INNE/SKLEPY"
        BTN_SWITCH_CODE=12
        BTN_ICON="gtk-jump-to"
        # DODANA IKONA CHŁOPKÓW
        HEADER_TEXT="<span size='large' weight='bold'>👥 Lista Znajomych</span>"
    else
        JQ_FILTER='select(.key != "DEFAULT_PROFILE") | select( (.value | split("|")[1]) == "Inne/Sklepy" )'
        WINDOW_TITLE="Menedżer Awatarów - SKLEPY / INNE"
        BTN_SWITCH_LABEL="Przełącz na: ZNAJOMI"
        BTN_SWITCH_CODE=11
        BTN_ICON="gtk-home"
        # DODANA IKONA KOSZYKA
        HEADER_TEXT="<span size='large' weight='bold'>🛒 Lista Sklepów i Innych</span>"
    fi

    # 2. Logika szukania
    if [ -n "$SEARCH_QUERY" ]; then
        JQ_FILTER+=" | select(.key | test(\"$SEARCH_QUERY\"; \"i\"))"
        HEADER_TEXT="$HEADER_TEXT\n<span color='orange'>🔍 WYNIKI DLA FRAZY: <b>$SEARCH_QUERY</b></span>"
        BTN_SEARCH_LABEL="WYCZYŚĆ FILTR"
        BTN_SEARCH_ICON="gtk-clear"
        BTN_SEARCH_TOOLTIP="Kliknij, aby pokazać wszystkie wpisy"
    else
        HEADER_TEXT="$HEADER_TEXT\n<span color='gray' size='small'>Wszystkie wpisy w kategorii</span>"
        BTN_SEARCH_LABEL="FILTRUJ / SZUKAJ..."
        BTN_SEARCH_ICON="gtk-find"
        BTN_SEARCH_TOOLTIP="Kliknij, aby wpisać frazę do wyszukania"
    fi

    # Wyświetlanie listy
    LIST_DATA=$(jq -r "to_entries[] | $JQ_FILTER | (.value | split(\"|\")) as \$vals | \"\(.key)\n\(\$vals[1] // \"Znajomi\")\n\(\$vals[0])\"" "$JSON_FILE")
    
    STATUS=$(get_lua_status)
    if [ "$STATUS" == "ON" ]; then STATUS_LABEL="Awatary: WŁĄCZONE"; STATUS_ICON="gtk-yes"; else STATUS_LABEL="Awatary: WYŁĄCZONE"; STATUS_ICON="gtk-no"; fi

    echo -e "$LIST_DATA" | yad --list \
        --width=950 --height=600 --center --title="$WINDOW_TITLE" \
        --text="$HEADER_TEXT" \
        --column="Adres E-mail":TEXT --column="Kategoria":TEXT --column="Plik Awatara":TEXT \
        --search-column=1 --separator="|" --multiple --print-column=1 \
        --button="$BTN_SEARCH_LABEL!$BTN_SEARCH_ICON!$BTN_SEARCH_TOOLTIP":8 \
        --button="$BTN_SWITCH_LABEL!$BTN_ICON":$BTN_SWITCH_CODE \
        --button="Ustawienia Wyglądu!gtk-color-picker":6 \
        --button="Zmień Domyślny!gtk-preferences":5 \
        --button="$STATUS_LABEL!$STATUS_ICON":2 \
        --button="DODAJ NOWY!gtk-add":4 \
        --button="ZARZĄDZAJ ZAZNACZONYMI!gtk-execute":0 \
        --button="Zamknij!gtk-close":1 > "$YAD_OUT_FILE"

    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 1 ] || [ $EXIT_CODE -eq 252 ]; then break; fi

    case $EXIT_CODE in
        11) 
            CURRENT_VIEW="Znajomi"
            SEARCH_QUERY="" 
            ;;
        12) 
            CURRENT_VIEW="Inne/Sklepy"
            SEARCH_QUERY="" 
            ;;
        
        8)  # OBSŁUGA SZUKANIA
            if [ -n "$SEARCH_QUERY" ]; then
                SEARCH_QUERY=""
            else
                NEW_QUERY=$(yad --entry --title="Wyszukiwanie" \
                    --text="Wpisz szukaną frazę:" \
                    --center --width=300 \
                    --button="Szukaj!gtk-find":0 --button="Anuluj!gtk-cancel":1)
                
                if [ $? -eq 0 ] && [ -n "$NEW_QUERY" ]; then
                    SEARCH_QUERY="$NEW_QUERY"
                fi
            fi
            ;;

        2)  toggle_lua_status ;;
        
        0)  # ZARZĄDZANIE (USUŃ / EDYTUJ)
            RAW_CONTENT=$(cat "$YAD_OUT_FILE")
            CLEAN_LIST=$(echo "$RAW_CONTENT" | tr '|' '\n' | grep -v "^$")
            if [ -z "$CLEAN_LIST" ]; then
                yad --info --text="Nie zaznaczono wpisu." --center --button="OK":0
            else
                yad --question --title="Zarządzaj" --text="Co zrobić?" \
                    --button="ANULUJ!gtk-cancel":1 --button="USUŃ!gtk-delete":33 --button="EDYTUJ!gtk-edit":44 --center
                ACT=$?
                if [ "$ACT" -eq 33 ]; then
                    tmp=$(mktemp)
                    JQ_DEL="del("
                    while IFS= read -r e; do e=$(trim "$e"); [ -n "$e" ] && JQ_DEL+=".[\"$e\"],"; done <<< "$CLEAN_LIST"
                    JQ_DEL="${JQ_DEL%,})"
                    jq "$JQ_DEL" "$JSON_FILE" > "$tmp" && mv "$tmp" "$JSON_FILE"
                    [ "$(get_lua_status)" == "ON" ] && update_conky_ram
                    yad --info --text="Usunięto pomyślnie." --center --button="OK":0
                elif [ "$ACT" -eq 44 ]; then
                    # --- LICZNIK DO EDYCJI ---
                    TOTAL_ITEMS=$(echo "$CLEAN_LIST" | grep -c .)
                    CURRENT_ITEM=1
                    
                    while IFS= read -r SE; do
                        SE=$(trim "$SE"); [ -z "$SE" ] && continue
                        JD=$(jq -r --arg e "$SE" '.[$e]' "$JSON_FILE")
                        if [ "$JD" == "null" ]; then continue; fi
                        RF=$(echo "$JD" | cut -d'|' -f1); RC=$(echo "$JD" | cut -d'|' -f2)
                        CMB="Znajomi!Inne/Sklepy"; [[ "$RC" == *"Inne"* ]] && CMB="Inne/Sklepy!Znajomi"
                        
                        TITLE_STR="Edycja ($CURRENT_ITEM z $TOTAL_ITEMS)"
                        
                        ED=$(yad --form --title="$TITLE_STR" --width=650 --center --field="E-mail":TEXT "$SE" --field="Kategoria":CB "$CMB" --field="Plik":FL "$RF")
                        
                        if [ -n "$ED" ]; then
                            IFS='|' read -r NE NC NF _ <<< "$ED"
                            NE=$(trim "$NE"); [ -n "$NE" ] && {
                                tmp=$(mktemp)
                                jq --arg o "$SE" --arg n "$NE" --arg v "$(trim "$NF")|$(trim "$NC")" 'del(.[$o]) | .[$n] = $v' "$JSON_FILE" > "$tmp" && mv "$tmp" "$JSON_FILE"
                                [ "$(get_lua_status)" == "ON" ] && update_conky_ram
                            }
                        fi
                        ((CURRENT_ITEM++))
                    done <<< "$CLEAN_LIST"
                fi
            fi
            ;;
        4)  # DODAJ NOWY
            NEW=$(yad --form --title="Dodaj" --width=600 --center --field="E-mail":TEXT "" --field="Kategoria":CB "Znajomi!Inne/Sklepy" --field="Plik":FL "")
            if [ -n "$NEW" ]; then
                IFS='|' read -r NE NC NF _ <<< "$NEW"
                NE=$(trim "$NE"); NF=$(trim "$NF"); NC=$(trim "$NC")
                
                if [ -n "$NE" ] && [ -f "$NF" ]; then
                    
                    # --- SPRAWDZANIE DUPLIKATÓW (NOWOŚĆ) ---
                    if jq -e --arg e "$NE" 'has($e)' "$JSON_FILE" >/dev/null; then
                        yad --question --title="Uwaga: Duplikat" \
                            --text="Adres e-mail <b>$NE</b> już istnieje w bazie.\nCzy chcesz nadpisać wpis?" \
                            --button="ANULUJ":1 --button="NADPISZ":0 --center
                        if [ $? -ne 0 ]; then continue; fi
                    fi
                    # ---------------------------------------

                    # --- INTELIGENTNE KOPIOWANIE ---
                    if [[ "$NF" != *"$BASE_DIR"* ]]; then
                        TARGET_DIR="$DIR_ZNAJOMI"
                        if [ "$NC" == "Inne/Sklepy" ]; then TARGET_DIR="$DIR_SKLEPY"; fi
                        
                        FNAME=$(basename "$NF")
                        TARGET_PATH="$TARGET_DIR/$FNAME"
                        
                        if [ -f "$TARGET_PATH" ]; then
                             NF="$TARGET_PATH"
                        else
                             yad --question --title="Import pliku" --text="Plik znajduje się poza folderem projektu.\nCzy skopiować go do:\n<b>$TARGET_PATH</b>?\n\n(Zalecane dla przenośności)" \
                                --button="NIE (Użyj oryginału)":1 --button="TAK (Kopiuj)":0 --center
                             if [ $? -eq 0 ]; then
                                cp "$NF" "$TARGET_PATH"
                                NF="$TARGET_PATH"
                                # --- CZEKA NA OK ---
                                yad --info --title="Sukces" --text="Skopiowano plik do projektu." --center --button="OK":0
                             fi
                        fi
                    fi
                    # -------------------------------

                    tmp=$(mktemp)
                    jq --arg e "$NE" --arg v "$NF|$NC" '.[$e] = $v' "$JSON_FILE" > "$tmp" && mv "$tmp" "$JSON_FILE"
                    [ "$(get_lua_status)" == "ON" ] && update_conky_ram
                    # --- CZEKA NA OK ---
                    yad --info --text="Dodano pomyślnie." --center --button="OK":0
                else
                     yad --error --text="Błędne dane lub brak pliku." --center --button="OK":0
                fi
            fi
            ;;
        5)  # ZMIEŃ DOMYŚLNY
            ND=$(yad --file --title="Domyślny" --filename="$DIR_DEFAULT/" --file-filter="Obrazy | *.png *.jpg" --center)
            if [ -n "$ND" ]; then
                if [[ "$ND" != *"$BASE_DIR"* ]]; then
                     yad --question --title="Import" --text="Skopiować ten plik do folderu DEFAULT?" --button="Nie":1 --button="Tak":0 --center
                     if [ $? -eq 0 ]; then
                        FNAME=$(basename "$ND")
                        cp "$ND" "$DIR_DEFAULT/$FNAME"
                        ND="$DIR_DEFAULT/$FNAME"
                     fi
                fi
                
                tmp=$(mktemp)
                jq --arg v "$ND|Default" '."DEFAULT_PROFILE" = $v' "$JSON_FILE" > "$tmp" && mv "$tmp" "$JSON_FILE"
                [ "$(get_lua_status)" == "ON" ] && update_conky_ram
                # --- CZEKA NA OK ---
                yad --info --text="Zaktualizowano." --center --button="OK":0
            fi
            ;;
        6)  # USTAWIENIA (POPRAWIONE + PRZEŹROCZYSTOŚĆ CO 1%)
            while true; do
                # 1. WCZYTYWANIE DANYCH Z PLIKU LUA
                CB="FALSE"; grep -q "^DRAW_AVATAR_BORDER = true" "$LUA_FILE" && CB="TRUE"
                
                CW=$(grep "^AVATAR_BORDER_WIDTH" "$LUA_FILE" | sed 's/.*= *//;s/[",]//g'); [ -z "$CW" ] && CW="2.0"
                CS=$(LC_NUMERIC=C awk -v v="$CW" 'BEGIN{printf "%.0f", v*10}')
                
                CC=$(grep "^AVATAR_BORDER_COLOR" "$LUA_FILE" | grep -oE "\{.*\}" | tr -d '{}' | tr ',' ' ' | LC_NUMERIC=C awk '{printf "#%02X%02X%02X",int($1*255),int($2*255),int($3*255)}'); [ -z "$CC" ] && CC="#FFFFFF"
                
                CA=$(grep "^AVATAR_BORDER_COLOR" "$LUA_FILE" | awk -F, '{print $4}' | tr -d '}'); [ -z "$CA" ] && CA="0.8"
                CP=$(LC_NUMERIC=C awk -v v="$CA" 'BEGIN{printf "%.0f", v*100}')
                
                SZ=$(grep "^AVATAR_SIZE" "$LUA_FILE" | sed 's/.*= *//;s/[",]//g'); [ -z "$SZ" ] && SZ="65"
                MG=$(grep "^AVATAR_MARGIN_RIGHT" "$LUA_FILE" | sed 's/.*= *//;s/[",]//g'); [ -z "$MG" ] && MG="15"
                
                # --- NOWE: CZYTANIE PRZEŹROCZYSTOŚCI AWATARA ---
                AA=$(grep "^AVATAR_ALPHA" "$LUA_FILE" | sed 's/.*= *//;s/[",]//g'); [ -z "$AA" ] && AA="1.0"
                # Konwersja 1.0 -> 100 do suwaka
                AP=$(LC_NUMERIC=C awk -v v="$AA" 'BEGIN{printf "%.0f", v*100}')
                # -----------------------------------------------

                # PAMIĘĆ KSZTAŁTU
                SH="Koło"
                grep "^AVATAR_SHAPE" "$LUA_FILE" | grep -q "square" && SH="Kwadrat"
                grep "^AVATAR_SHAPE" "$LUA_FILE" | grep -q "rounded" && SH="Zaokrąglony Kwadrat"
                
                OPTS="Koło!Kwadrat!Zaokrąglony Kwadrat"; 
                [ "$SH" == "Kwadrat" ] && OPTS="Kwadrat!Koło!Zaokrąglony Kwadrat"; 
                [ "$SH" == "Zaokrąglony Kwadrat" ] && OPTS="Zaokrąglony Kwadrat!Koło!Kwadrat"

                # 2. OKNO KONFIGURACJI (DODANO POLE PRZEŹROCZYSTOŚĆ)
                SET=$(yad --form --title="Wygląd Awatarów" --center --width=450 --height=550 \
                    --field="Kształt":CB "$OPTS" \
                    --field="Rozmiar (px)":SCL "$SZ!0..150!1" \
                    --field="Margines (px)":SCL "$MG!0..100!1" \
                    --field="Przeźroczystość (%)":SCL "$AP!0..100!1" \
                    --field="Rysuj Ramkę":CHK "$CB" \
                    --field="Grubość Ramki":SCL "$CS!5..100!5" \
                    --field="Kolor Ramki":CLR "$CC" \
                    --field="Alpha Ramki (%)":SCL "$CP" \
                    --button="Wróć":1 --button="Zastosuj":0)
                
                [ $? -ne 0 ] && break
                
                # 3. ZAPISYWANIE DANYCH (ODCZYT Z FORMULARZA W ODPOWIEDNIEJ KOLEJNOŚCI)
                IFS='|' read -r S_SH S_SZ S_MG S_AP S_BO S_WI S_CO S_AL _ <<< "$SET"
                
                # Zapis Kształtu
                L_SH="circle"; [ "$S_SH" == "Kwadrat" ] && L_SH="square"; [ "$S_SH" == "Zaokrąglony Kwadrat" ] && L_SH="rounded"
                sed -i "s/^AVATAR_SHAPE = .*/AVATAR_SHAPE = \"$L_SH\"/" "$LUA_FILE"
                
                # Zapis Rozmiaru
                if [[ "$S_SZ" =~ ^[0-9]+$ ]]; then
                    sed -i "s/^AVATAR_SIZE = .*/AVATAR_SIZE = $S_SZ/" "$LUA_FILE"
                    if [ "$S_SZ" -eq 0 ]; then
                        sed -i 's/^SHOW_AVATARS = true/SHOW_AVATARS = false/' "$LUA_FILE"
                    fi
                    if [ "$S_SZ" -eq 0 ] && [ "$SZ" -gt 0 ]; then
                        yad --info --title="Info" --text="Ustawiono rozmiar 0 px.\nAwatary zostały automatycznie WYŁĄCZONE." --center --button="OK":0
                    elif [ "$S_SZ" -gt 0 ] && [ "$SZ" -eq 0 ]; then
                        yad --info --title="Pamiętaj!" --text="Zmieniono rozmiar na $S_SZ px.\nJeśli chcesz widzieć awatary, WŁĄCZ je przyciskiem w menu głównym." --center --button="OK":0
                    fi
                fi
                
                # Zapis Marginesu
                [[ "$S_MG" =~ ^[0-9]+$ ]] && sed -i "s/^AVATAR_MARGIN_RIGHT = .*/AVATAR_MARGIN_RIGHT = $S_MG/" "$LUA_FILE"
                
                # --- NOWE: ZAPIS PRZEŹROCZYSTOŚCI AWATARA (PRECYZJA 2 MIEJSCA) ---
                # Konwersja 100 -> 1.00, 53 -> 0.53, 5 -> 0.05
                L_AA=$(LC_NUMERIC=C awk -v v="$S_AP" 'BEGIN{printf "%.2f", v/100}')
                sed -i "s/^AVATAR_ALPHA = .*/AVATAR_ALPHA = $L_AA/" "$LUA_FILE"
                # --------------------------------------------

                # Zapis Ramki (Włącz/Wyłącz)
                L_BO="false"; [ "$S_BO" == "TRUE" ] && L_BO="true"
                sed -i "s/^DRAW_AVATAR_BORDER = .*/DRAW_AVATAR_BORDER = $L_BO/" "$LUA_FILE"
                
                # Zapis Grubości Ramki
                L_WI=$(LC_NUMERIC=C awk -v v="$S_WI" 'BEGIN{printf "%.1f", v/10}')
                sed -i "s/^AVATAR_BORDER_WIDTH = .*/AVATAR_BORDER_WIDTH = $L_WI/" "$LUA_FILE"
                
                # Zapis Koloru Ramki
                L_COL=$(hex_to_lua_color "$S_CO" "$S_AL")
                sed -i "s/^AVATAR_BORDER_COLOR = .*/AVATAR_BORDER_COLOR = $L_COL/" "$LUA_FILE"
            done
            ;;
    esac
done
