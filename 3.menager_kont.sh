#!/bin/bash
# ===================================================================================
# UNIWERSALNY KONFIGURATOR I SELEKTOR KONT E-MAIL (WERSJA FINALNA ROZSZERZONA)
# - Obsługa wielokrotnego usuwania
# - Możliwość zmiany kolejności kont
# - W pełni spolszczony interfejs YAD
# ===================================================================================
# Skrypt służący do zarządzania kontami e-mail i wybierania, które z nich mają być
# aktywne do celów wyświetlania (np. w Conky). Wykorzystuje YAD do interfejsu
# graficznego i jq do manipulacji plikiem konfiguracyjnym w formacie JSON.
# ===================================================================================

# --- ŚCIEŻKI KONFIGURACYJNE ---
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
CONFIG_PATH="$SCRIPT_DIR/config/config.json"
SELECTOR_FILE="$SCRIPT_DIR/config/active_account_selector"

# --- SPRAWDZENIE ZALEŻNOŚCI ---
if ! command -v jq &> /dev/null || \
   ! command -v yad &> /dev/null || \
   ! command -v xrandr &> /dev/null || \
   ! command -v notify-send &> /dev/null; then
    yad --center --fixed --error \
        --text="<b>Błąd: Brakujące zależności!</b>\n\nUpewnij się, że zainstalowane są pakiety:\n'jq', 'yad', 'x11-xserver-utils' (dla xrandr) oraz 'libnotify-bin' (dla notify-send).\n\n<b>sudo apt install jq yad x11-xserver-utils libnotify-bin</b>" \
        --width=800
    exit 1
fi

# --- SPRAWDZENIE PLIKU KONFIGURACYJNEGO ---
if [ ! -f "$CONFIG_PATH" ]; then
    yad --center --fixed --error \
        --text="<b>Błąd:</b> Nie znaleziono pliku konfiguracyjnego!\n\nOczekiwana ścieżka:\n$CONFIG_PATH" \
        --width=700
    exit 1
fi

# --- POBRANIE ROZDZIELCZOŚCI EKRANU ---
SCREEN_GEOMETRY=$(xrandr | grep '*' | head -n 1 | awk '{print $1}')
SCREEN_WIDTH=$(echo "$SCREEN_GEOMETRY" | cut -d'x' -f1)
SCREEN_HEIGHT=$(echo "$SCREEN_GEOMETRY" | cut -d'x' -f2)

# ===================================================================================
# FUNKCJA: select_view()
# ===================================================================================
select_view() {
    mkdir -p "$(dirname "$SELECTOR_FILE")"
    local ENABLED_LOGINS=()
    while IFS= read -r login; do
        if [[ -n "$login" ]]; then
            ENABLED_LOGINS+=("$login")
        fi
    done < <(jq -r '.accounts[] | select(.enabled == true and .login != null and .login != "") | .login' "$CONFIG_PATH")

    local ACCOUNT_COUNT=${#ENABLED_LOGINS[@]}

    if (( ACCOUNT_COUNT == 0 )); then
        yad --center --fixed --info --text="<b>Informacja:</b> Nie znaleziono żadnych aktywnych kont z ustawionym loginem." --width=600
        return
    elif (( ACCOUNT_COUNT == 1 )); then
        echo "${ENABLED_LOGINS[0]}" > "$SELECTOR_FILE"
        yad --center --fixed --info --title="Automatyczny wybór" --text="Wykryto jedno aktywne konto:\n\n<b>${ENABLED_LOGINS[0]}</b>" --width=700
        return
    fi

    local MODE_CHOICE_RAW MODE_CHOICE
    MODE_CHOICE_RAW=$(yad --list --radiolist --center --title="Wybierz tryb wyświetlania" \
        --text="W jaki sposób chcesz wyświetlać konta?" \
        --width=600 --height=200 \
        --column="Wybór:RD" --column="Opcja" \
        --button="Wybierz:0" --button="Anuluj:1" \
        TRUE "Podsumowanie wszystkich aktywnych kont" \
        FALSE "Wybiorę konkretne konta") || return

    MODE_CHOICE=$(echo "$MODE_CHOICE_RAW" | cut -d'|' -f2)

    if [[ "$MODE_CHOICE" == "Podsumowanie wszystkich aktywnych kont" ]]; then
        echo "0" > "$SELECTOR_FILE"
        notify-send "Przełączono widok poczty" "Wyświetlane: <b>Wszystkie konta</b>"
        return
    fi

    local YAD_ROWS=()
    for login in "${ENABLED_LOGINS[@]}"; do
        YAD_ROWS+=("FALSE" "$login")
    done

    local CHOICE
    CHOICE=$(yad --list --checklist --center --title="Wybierz konta do wyświetlenia" \
        --text="Zaznacz konta (loginy), które mają być widoczne w Conky." \
        --width=640 --height=480 \
        --column="Wybierz:CHK" --column="Login / Nazwa:TEXT" \
        --multiple --print-column=2 --separator=$'\n' \
        --button="Zatwierdź:0" --button="Anuluj:1" \
        "${YAD_ROWS[@]}") || return

    local SELECTED_LOGINS=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && SELECTED_LOGINS+=("$line")
    done <<< "$CHOICE"

    (( ${#SELECTED_LOGINS[@]} == 0 )) && yad --center --fixed --warning --text="Nie wybrano żadnego konta. Operacja anulowana." --width=500 && return

    if (( ${#SELECTED_LOGINS[@]} == ACCOUNT_COUNT )); then
        echo "0" > "$SELECTOR_FILE"
        notify-send "Przełączono widok poczty" "Wyświetlane: <b>Wszystkie konta (automatycznie)</b>"
        return
    fi

    printf '%s\n' "${SELECTED_LOGINS[@]}" > "$SELECTOR_FILE"
    local LOGINS_STR
    LOGINS_STR=$(printf '%s, ' "${SELECTED_LOGINS[@]}")
    LOGINS_STR="${LOGINS_STR%, }"
    notify-send "Przełączono widok poczty" "Wybrane konta: <b>$LOGINS_STR</b>"
}

# ===================================================================================
# FUNKCJA: edit_account()
# ===================================================================================
edit_account() {
    local choice_string="$1"
    if [[ $(echo "$choice_string" | wc -l) -gt 1 ]]; then
        yad --center --fixed --warning --text="Można edytować tylko jedno konto na raz." --width=500
        return
    fi

    local SLOT_NUM
    SLOT_NUM=$(echo "$choice_string" | grep -o -E '[0-9]+')
    [[ -z "$SLOT_NUM" ]] && return
    local INDEX=$((SLOT_NUM - 1))

    local values
    mapfile -t values < <(jq -r --argjson index "$INDEX" '.accounts[$index] | [ .enabled, .name, .host, .port, .login, .password, .encryption, (.color // [255, 255, 255, 255] | .[0]), (.color // [255, 255, 255, 255] | .[1]), (.color // [255, 255, 255, 255] | .[2]), (.color // [255, 255, 255, 255] | .[3]) ] | .[]' "$CONFIG_PATH")

    local ENABLED=${values[0]}
    local NAME=$([ "${values[1]}" == "null" ] && echo "" || echo "${values[1]}")
    local HOST=$([ "${values[2]}" == "null" ] && echo "" || echo "${values[2]}")
    local PORT=$([ "${values[3]}" == "null" ] && echo "" || echo "${values[3]}")
    local LOGIN=$([ "${values[4]}" == "null" ] && echo "" || echo "${values[4]}")
    local PASSWORD=$([ "${values[5]}" == "null" ] && echo "" || echo "${values[5]}")
    local ENCRYPTION=$([ "${values[6]}" == "null" ] && echo "SSL" || echo "${values[6]}")
    local ALPHA=${values[7]}
    local RED=${values[8]}
    local GREEN=${values[9]}
    local BLUE=${values[10]}
    
    local COLOR_HEX
    COLOR_HEX=$(printf "#%02x%02x%02x" "$RED" "$GREEN" "$BLUE")
    local ALPHA_WITH_RANGE="$ALPHA!0..255..1"
    local CHECKED_STATE=$([ "$ENABLED" == "true" ] && echo "TRUE" || echo "FALSE")
    
    local ENCRYPTION_OPTIONS
    if [[ "$ENCRYPTION" == "STARTTLS" ]]; then
        ENCRYPTION_OPTIONS="^STARTTLS!SSL";
    else
        ENCRYPTION_OPTIONS="^SSL!STARTTLS";
    fi

    local EDIT_WIN_WIDTH=650
    local EDIT_WIN_HEIGHT=400
    local EDIT_POS_X=$(((SCREEN_WIDTH - EDIT_WIN_WIDTH) / 2))
    local EDIT_POS_Y=$(((SCREEN_HEIGHT - EDIT_WIN_HEIGHT) / 2))

    local EDIT_DATA
    EDIT_DATA=$(yad --form --title="Edycja konta #$SLOT_NUM" \
        --width="$EDIT_WIN_WIDTH" --height="$EDIT_WIN_HEIGHT" --geometry="+$EDIT_POS_X+$EDIT_POS_Y" \
        --field="Aktywne:CHK" \
        --field="Nazwa konta (opis):" \
        --field="Host IMAP:" \
        --field="Port:" \
        --field="Szyfrowanie:CB" \
        --field="Login (e-mail):" \
        --field="Hasło:VER" \
        --field="Kolor nazwy:CLR" \
        --field="Przezroczystość (0-255):NUM" \
        --button="Zapisz:0" --button="Anuluj:1" \
        "$CHECKED_STATE" "$NAME" "$HOST" "$PORT" "$ENCRYPTION_OPTIONS" "$LOGIN" "$PASSWORD" "$COLOR_HEX" "$ALPHA_WITH_RANGE")
    
    local EDIT_EXIT_STATUS=$?
    if [ $EDIT_EXIT_STATUS -eq 0 ]; then
        local new_enabled new_name new_host new_port new_encryption new_login new_password new_color_hex new_alpha
        IFS='|' read -r new_enabled new_name new_host new_port new_encryption new_login new_password new_color_hex new_alpha <<< "$EDIT_DATA"

        local hex_clean=${new_color_hex#\#}
        local r=$((16#${hex_clean:0:2}))
        local g=$((16#${hex_clean:2:2}))
        local b=$((16#${hex_clean:4:2}))
        local alpha=$(printf "%.0f" "$new_alpha")
        local new_enabled_json=$([ "$new_enabled" == "TRUE" ] && echo "true" || echo "false")

        jq --argjson index "$INDEX" --argjson enabled "$new_enabled_json" --arg name "$new_name" \
           --argjson a "$alpha" --argjson r "$r" --argjson g "$g" --argjson b "$b" \
           --arg host "$new_host" --arg port "$new_port" --arg encryption "$new_encryption" \
           --arg login "$new_login" --arg password "$new_password" \
           '.accounts[$index].enabled = $enabled |
            .accounts[$index].name = (if $name == "" then null else $name end) |
            .accounts[$index].host = (if $host == "" then null else $host end) |
            .accounts[$index].port = (if $port == "" then null else ($port | tonumber) end) |
            .accounts[$index].encryption = (if $encryption == "" then "SSL" else $encryption end) |
            .accounts[$index].login = (if $login == "" then null else $login end) |
            .accounts[$index].password = (if $password == "" then null else $password end) |
            .accounts[$index].color = [$a, $r, $g, $b]' \
            "$CONFIG_PATH" > "$CONFIG_PATH.tmp" && mv "$CONFIG_PATH.tmp" "$CONFIG_PATH"
        
        yad --center --fixed --info --button="OK:0" --width=600 --text="Zmiany dla konta #$SLOT_NUM zostały zapisane!"
    fi
}

# ===================================================================================
# FUNKCJA: add_account()
# ===================================================================================
add_account() {
    local ADD_WIN_WIDTH=650
    local ADD_WIN_HEIGHT=400
    local ADD_POS_X=$(((SCREEN_WIDTH - ADD_WIN_WIDTH) / 2))
    local ADD_POS_Y=$(((SCREEN_HEIGHT - ADD_WIN_HEIGHT) / 2))

    local ADD_DATA
    ADD_DATA=$(yad --form --title="Dodaj nowe konto" \
        --width="$ADD_WIN_WIDTH" --height="$ADD_WIN_HEIGHT" --geometry="+$ADD_POS_X+$ADD_POS_Y" \
        --field="Aktywne:CHK" \
        --field="Nazwa konta (opis):" \
        --field="Host IMAP:" \
        --field="Port:" \
        --field="Szyfrowanie:CB" \
        --field="Login (e-mail):" \
        --field="Hasło:VER" \
        --field="Kolor nazwy:CLR" \
        --field="Przezroczystość (0-255):NUM" \
        --button="Dodaj:0" --button="Anuluj:1" \
        "FALSE" "" "" "" "^SSL!STARTTLS" "" "" "#ffffff" "255!0..255..1")
    
    local ADD_EXIT_STATUS=$?
    if [ $ADD_EXIT_STATUS -eq 0 ]; then
        local new_enabled new_name new_host new_port new_encryption new_login new_password new_color_hex new_alpha
        IFS='|' read -r new_enabled new_name new_host new_port new_encryption new_login new_password new_color_hex new_alpha <<< "$ADD_DATA"

        local hex_clean=${new_color_hex#\#}
        local r=$((16#${hex_clean:0:2}))
        local g=$((16#${hex_clean:2:2}))
        local b=$((16#${hex_clean:4:2}))
        local alpha=$(printf "%.0f" "$new_alpha")
        local new_enabled_json=$([ "$new_enabled" == "TRUE" ] && echo "true" || echo "false")

        jq --argjson enabled "$new_enabled_json" --arg name "$new_name" \
           --argjson a "$alpha" --argjson r "$r" --argjson g "$g" --argjson b "$b" \
           --arg host "$new_host" --arg port "$new_port" --arg encryption "$new_encryption" \
           --arg login "$new_login" --arg password "$new_password" \
           '.accounts += [{"enabled": $enabled, "name": (if $name == "" then null else $name end), "host": (if $host == "" then null else $host end), "port": (if $port == "" then null else ($port | tonumber) end), "login": (if $login == "" then null else $login end), "password": (if $password == "" then null else $password end), "encryption": $encryption, "color": [$a, $r, $g, $b]}]' \
           "$CONFIG_PATH" > "$CONFIG_PATH.tmp" && mv "$CONFIG_PATH.tmp" "$CONFIG_PATH"
        
        yad --center --fixed --info --button="OK:0" --width=500 --text="Nowe konto zostało dodane!"
    fi
}

# ===================================================================================
# FUNKCJA: delete_account()
# ===================================================================================
delete_account() {
    local all_selections="$1"
    if [[ -z "$all_selections" ]]; then
        yad --center --fixed --warning --text="Najpierw zaznacz konto lub konta, które chcesz usunąć." --width=600
        return
    fi

    local INDICES_TO_DELETE=()
    local LOGINS_TO_DELETE=()
    local IDENTIFIERS_FOR_PROMPT=()

    while IFS= read -r line; do
        local SLOT_NUM
        SLOT_NUM=$(echo "$line" | grep -o -E '[0-9]+')
        [[ -z "$SLOT_NUM" ]] && continue
        local INDEX=$((SLOT_NUM - 1))
        
        local login_to_delete name_to_delete account_identifier
        mapfile -t account_data < <(jq -r --argjson index "$INDEX" '.accounts[$index] | .login, .name' "$CONFIG_PATH")
        login_to_delete="${account_data[0]}"
        name_to_delete="${account_data[1]}"
        
        if [[ "$login_to_delete" != "null" && -n "$login_to_delete" ]]; then
            account_identifier="$login_to_delete"
            LOGINS_TO_DELETE+=("$login_to_delete")
        elif [[ "$name_to_delete" != "null" && -n "$name_to_delete" ]]; then
            account_identifier="$name_to_delete (konto bez loginu)"
        else
            account_identifier="Nieskonfigurowane konto #$SLOT_NUM"
        fi
        INDICES_TO_DELETE+=("$INDEX")
        IDENTIFIERS_FOR_PROMPT+=("$account_identifier")
    done <<< "$all_selections"

    if [ ${#INDICES_TO_DELETE[@]} -eq 0 ]; then
        return;
    fi

    local prompt_list
    prompt_list=$(printf '<b>%s</b>\n' "${IDENTIFIERS_FOR_PROMPT[@]}")
    yad --center --fixed --question --title="Potwierdzenie usunięcia" --width=700 \
        --text="<span size='large'>Czy na pewno chcesz trwale usunąć zaznaczone konta?</span>\n\n${prompt_list}\nTej operacji nie można cofnąć." \
        --button="Tak, usuń:0" --button="Nie, wróć:1"
    
    local DELETE_CONFIRM_STATUS=$?
    if [ $DELETE_CONFIRM_STATUS -eq 0 ]; then
        local sorted_indices
        sorted_indices=($(printf '%s\n' "${INDICES_TO_DELETE[@]}" | sort -nr))
        
        local temp_json
        temp_json=$(cat "$CONFIG_PATH")
        for index in "${sorted_indices[@]}"; do
            temp_json=$(echo "$temp_json" | jq --argjson index "$index" 'del(.accounts[$index])')
        done
        echo "$temp_json" > "$CONFIG_PATH.tmp" && mv "$CONFIG_PATH.tmp" "$CONFIG_PATH"

        local view_updated=false
        if [ -s "$SELECTOR_FILE" ]; then
            for login in "${LOGINS_TO_DELETE[@]}"; do
                if grep -q -x "$login" "$SELECTOR_FILE"; then
                    grep -v -x "$login" "$SELECTOR_FILE" > "$SELECTOR_FILE.tmp" && mv "$SELECTOR_FILE.tmp" "$SELECTOR_FILE"
                    view_updated=true
                fi
            done
            if [ ! -s "$SELECTOR_FILE" ]; then
                echo "0" > "$SELECTOR_FILE"
            fi
        fi
        
        local final_message="Następujące konta zostały usunięte:\n\n${prompt_list}"
        if [ "$view_updated" = true ]; then
            final_message+="\nWidok wyświetlania został zaktualizowany."
        fi
        yad --center --fixed --info --button="OK:0" --width=700 --text="$final_message"
    fi
}

# ===================================================================================
# FUNKCJA: move_account()
# ===================================================================================
move_account() {
    local all_selections="$1"
    local direction="$2"

    if [[ $(echo "$all_selections" | wc -l) -ne 1 ]]; then
        yad --center --fixed --warning --text="Aby zmienić kolejność, musisz zaznaczyć dokładnie jedno konto." --width=600
        return
    fi

    local SLOT_NUM
    SLOT_NUM=$(echo "$all_selections" | grep -o -E '[0-9]+')
    [[ -z "$SLOT_NUM" ]] && return
    local INDEX=$((SLOT_NUM - 1))
    
    local ACCOUNT_COUNT
    ACCOUNT_COUNT=$(jq '.accounts | length' "$CONFIG_PATH")
    
    local TARGET_INDEX
    if [[ "$direction" == "up" ]]; then
        if (( INDEX == 0 )); then
            yad --center --fixed --info --text="Nie można przesunąć pierwszego elementu wyżej." --width=500
            return
        fi
        TARGET_INDEX=$((INDEX - 1))
    elif [[ "$direction" == "down" ]]; then
        if (( INDEX >= ACCOUNT_COUNT - 1 )); then
            yad --center --fixed --info --text="Nie można przesunąć ostatniego elementu niżej." --width=500
            return
        fi
        TARGET_INDEX=$((INDEX + 1))
    else
        return
    fi
    
    jq --argjson i "$INDEX" --argjson j "$TARGET_INDEX" \
       '.accounts[$i] as $elem_i | .accounts[$j] as $elem_j | .accounts[$i] = $elem_j | .accounts[$j] = $elem_i' \
       "$CONFIG_PATH" > "$CONFIG_PATH.tmp" && mv "$CONFIG_PATH.tmp" "$CONFIG_PATH"
}


# ===================================================================================
# GŁÓWNA PĘTLA PROGRAMU
# ===================================================================================
while true; do
    ACCOUNTS_INFO=()
    local ACCOUNT_COUNT
    ACCOUNT_COUNT=$(jq '.accounts | length' "$CONFIG_PATH")

    for i in $(seq 0 $((ACCOUNT_COUNT - 1))); do
        mapfile -t data < <(jq -r ".accounts[$i] | .enabled, .name, .login" "$CONFIG_PATH")
        enabled="${data[0]}"
        name="${data[1]}"
        login="${data[2]}"
        
        if [ "$enabled" == "true" ]; then
            status_text="<span color='green'><b>Aktywne</b></span>";
        else
            status_text="<span color='red'>Nieaktywne</span>";
        fi
        
        if [ "$login" != "null" ] && [ -n "$login" ]; then
            display_name="$login";
        elif [ "$name" != "null" ] && [ -n "$name" ]; then
            display_name="$name";
        else
            display_name="<span color='grey'>Puste miejsce</span>";
        fi
        
        ACCOUNTS_INFO+=("$status_text" "Konto #$((i + 1))" "$display_name")
    done
    
    WIN_WIDTH=800
    WIN_HEIGHT=700 # Możesz dostosować tę wysokość do swoich potrzeb
    POS_X=$(((SCREEN_WIDTH - WIN_WIDTH) / 2))
    POS_Y=$(((SCREEN_HEIGHT - WIN_HEIGHT) / 2))
    
    CHOICE_AND_SELECTION=$(yad --list \
        --title="Konfigurator kont e-mail" \
        --geometry="${WIN_WIDTH}x${WIN_HEIGHT}+$POS_X+$POS_Y" \
        --text="<b>Zarządzaj kontami e-mail.</b>\n- Kliknij dwukrotnie, aby <b>edytować</b> pojedyncze konto.\n- Zaznacz jedno konto i użyj przycisków, aby je <b>przesunąć</b>.\n- Aby <b>usunąć wiele kont naraz</b>, zaznacz je przytrzymując \Ctrl\ lub \Shift\.\n- Użyj przycisków na dole do wykonania pozostałych akcji." \
        --column="Stan:TEXT" --column="Slot" --column="Login / Nazwa:TEXT" \
        --print-column=2 --select-action="echo %s" \
        --multiple \
        --button="Dodaj konto:3" \
        --button="Usuń zaznaczone:4" \
        --button="Przesuń w górę:5" \
        --button="Przesuń w dół:6" \
        --button="Wybierz konta:2" \
        --button="Zamknij:1" \
        "${ACCOUNTS_INFO[@]}")
        
    EXIT_CODE=$?
    
    case $EXIT_CODE in
        0)
            edit_account "$CHOICE_AND_SELECTION"
            ;;
        1)
            break
            ;;
        2)
            select_view
            ;;
        3)
            add_account
            ;;
        4)
            delete_account "$CHOICE_AND_SELECTION"
            ;;
        5)
            move_account "$CHOICE_AND_SELECTION" "up"
            ;;
        6)
            move_account "$CHOICE_AND_SELECTION" "down"
            ;;
        *)
            break
            ;;
    esac
done

# --- POCZĄTEK DODANEGO BLOKU ---
if yad --question --center --fixed \
    --title="Zakończono konfigurację kont" \
    --text="<big><b>Czy chcesz teraz uruchomić skrypt startowy Conky?</b></big>\n\n(4.START_skryptów_oraz_conky.sh)" \
    --button="Tak, uruchom:0" --button="Nie, zakończ:1" --width=600; then

    if [ -f "$SCRIPT_DIR/4.START_skryptów_oraz_conky.sh" ]; then
        bash "$SCRIPT_DIR/4.START_skryptów_oraz_conky.sh" &
    else
        yad --error --center --fixed --text="<b>Błąd:</b> Nie znaleziono pliku '4.START_skryptów_oraz_conky.sh'!" --width=500
    fi
fi
# --- KONIEC DODANEGO BLOKU ---

exit 0
