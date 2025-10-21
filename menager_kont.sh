#!/bin/bash

# ===================================================================================
#  UNIWERSALNY KONFIGURATOR I SELEKTOR KONT E-MAIL
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
#  FUNKCJA: select_view()
# ===================================================================================
# Ta funkcja jest oparta na "bliźniaczym projekcie".
# Jest mądrzejsza: przekazuje numery slotów do YAD i odczytuje je z powrotem,
# a następnie "pancernie" zapisuje je do pliku ze spacjami.
# ===================================================================================
select_view() {
    mkdir -p "$(dirname "$SELECTOR_FILE")"

    local ENABLED_SLOTS=()
    local ACCOUNT_DISPLAY_NAMES=() # Będziemy tu trzymać loginy lub nazwy

    # Zbuduj listy slotów i loginów/nazw dla aktywnych kont
    while IFS=$'\t' read -r key enabled name login; do
        if [[ "$enabled" == "true" ]]; then
            ENABLED_SLOTS+=("$((key + 1))")
            
            # Użyj 'login' jeśli istnieje, inaczej 'name', inaczej 'Brak danych'
            if [[ "$login" != "null" && -n "$login" ]]; then
                ACCOUNT_DISPLAY_NAMES+=("$login")
            elif [[ "$name" != "null" && -n "$name" ]]; then
                ACCOUNT_DISPLAY_NAMES+=("$name")
            else
                ACCOUNT_DISPLAY_NAMES+=("Konto #$((key + 1))")
            fi
        fi
    done < <(jq -r '.accounts | to_entries[] |
                    "\(.key)\t\(.value.enabled)\t\(.value.name)\t\(.value.login)"' "$CONFIG_PATH")

    local ACCOUNT_COUNT=${#ENABLED_SLOTS[@]}

    if (( ACCOUNT_COUNT == 0 )); then
        yad --center --fixed --info \
            --text="<b>Informacja:</b> Nie znaleziono żadnych aktywnych kont." \
            --width=600
        return
    elif (( ACCOUNT_COUNT == 1 )); then
        echo "${ENABLED_SLOTS[0]}" > "$SELECTOR_FILE"
        yad --center --fixed --info \
            --title="Automatyczny wybór" \
            --text="Wykryto jedno aktywne konto:\n\n<b>${ACCOUNT_DISPLAY_NAMES[0]}</b>" \
            --width=700
        return
    fi

    # --- Wybór trybu ---
    local MODE_CHOICE_RAW MODE_CHOICE
    MODE_CHOICE_RAW=$(yad --list --radiolist --center \
        --title="Wybierz tryb wyświetlania" \
        --text="W jaki sposób chcesz wyświetlać konta?" \
        --width=600 --height=200 \
        --column="Wybór:RD" --column="Opcja" \
        TRUE "Podsumowanie wszystkich aktywnych kont" \
        FALSE "Wybiorę konkretne konta") || return

    MODE_CHOICE=$(echo "$MODE_CHOICE_RAW" | cut -d'|' -f2)
    if [[ "$MODE_CHOICE" == "Podsumowanie wszystkich aktywnych kont" ]]; then
        echo "0" > "$SELECTOR_FILE"
        notify-send "Przełączono widok poczty" "Wyświetlane: <b>Wszystkie konta</b>"
        return
    fi

    # --- Wybór konkretnych kont ---
    local YAD_ROWS=()
    for i in "${!ENABLED_SLOTS[@]}"; do
        YAD_ROWS+=("FALSE" "${ENABLED_SLOTS[$i]}" "${ACCOUNT_DISPLAY_NAMES[$i]}")
    done

    local CHOICE
    CHOICE=$(yad --list --checklist --center \
        --title="Wybierz konta do wyświetlenia" \
        --text="Zaznacz konta (loginy), które mają być widoczne w Conky." \
        --width=640 --height=480 \
        --column="Wybierz:CHK" --column="Slot:NUM" --column="Login / Nazwa:TEXT" \
        --multiple --print-column=2 --separator=$'\n' \
        "${YAD_ROWS[@]}") || return

    # --- Parsowanie wyników ---
    local SELECTED_SLOTS=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && SELECTED_SLOTS+=("$line")
    done < <(printf '%s\n' "$CHOICE")

    # Jeśli użytkownik wcisnął OK, ale nic nie wybrał
    (( ${#SELECTED_SLOTS[@]} == 0 )) && \
        yad --center --fixed --warning --text="Nie wybrano żadnego konta. Operacja anulowana." --width=500 && \
        return

    # --- Wszystkie wybrane -> podsumowanie ---
    if (( ${#SELECTED_SLOTS[@]} == ACCOUNT_COUNT )); then
        echo "0" > "$SELECTOR_FILE"
        notify-send "Przełączono widok poczty" "Wyświetlane: <b>Wszystkie konta (automatycznie)</b>"
        return
    fi

    # --- KLUCZOWA POPRAWKA: Zapis wybranych slotów ---
    # `printf` gwarantuje spacje, `sed` usuwa ostatnią niepotrzebną spację.
    printf '%s ' "${SELECTED_SLOTS[@]}" | sed 's/ $//' > "$SELECTOR_FILE"

    # --- Powiadomienie z loginami ---
    local SELECTED_LOGINS=()
    for s in "${SELECTED_SLOTS[@]}"; do
        for i in "${!ENABLED_SLOTS[@]}"; do
            if [[ "${ENABLED_SLOTS[$i]}" == "$s" ]]; then
                SELECTED_LOGINS+=("${ACCOUNT_DISPLAY_NAMES[$i]}")
            fi
        done
    done

    local LOGINS_STR
    LOGINS_STR=$(printf '%s, ' "${SELECTED_LOGINS[@]}")
    LOGINS_STR="${LOGINS_STR%, }" # Usuń ostatni przecinek i spację

    notify-send "Przełączono widok poczty" "Wybrane konta: <b>$LOGINS_STR</b>"
}

# ===================================================================================
#  FUNKCJA: edit_account()
# ===================================================================================
edit_account() {
    local choice_string="$1"
    local SLOT_NUM
    SLOT_NUM=$(echo "$choice_string" | grep -o -E '[0-9]+')
    [[ -z "$SLOT_NUM" ]] && return

    local INDEX=$((SLOT_NUM - 1))

    local values
    mapfile -t values < <(jq -r \
        --argjson index "$INDEX" \
        '.accounts[$index] | [ .enabled, .name, .host, .port, .login, .password, .encryption, (.color // [255, 255, 255, 255] | .[0]), (.color // [255, 255, 255, 255] | .[1]), (.color // [255, 255, 255, 255] | .[2]), (.color // [255, 255, 255, 255] | .[3]) ] | .[]' \
        "$CONFIG_PATH")

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
        ENCRYPTION_OPTIONS="^STARTTLS!SSL"
    else
        ENCRYPTION_OPTIONS="^SSL!STARTTLS"
    fi

    local EDIT_WIN_WIDTH=650
    local EDIT_WIN_HEIGHT=400
    local EDIT_POS_X=$(((SCREEN_WIDTH - EDIT_WIN_WIDTH) / 2))
    local EDIT_POS_Y=$(((SCREEN_HEIGHT - EDIT_WIN_HEIGHT) / 2))

    local EDIT_DATA
    EDIT_DATA=$(yad --form \
        --title="Edycja konta #$SLOT_NUM" \
        --width="$EDIT_WIN_WIDTH" --height="$EDIT_WIN_HEIGHT" \
        --geometry="+$EDIT_POS_X+$EDIT_POS_Y" \
        --field="Aktywne:CHK" \
        --field="Nazwa konta (opis):" \
        --field="Host IMAP:" \
        --field="Port:" \
        --field="Szyfrowanie:CB" \
        --field="Login (e-mail):" \
        --field="Hasło:VER" \
        --field="Kolor nazwy:CLR" \
        --field="Przezroczystość (0-255):NUM" \
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

        jq \
            --argjson index "$INDEX" --argjson enabled "$new_enabled_json" --arg name "$new_name" \
            --argjson a "$alpha" --argjson r "$r" --argjson g "$g" --argjson b "$b" \
            --arg host "$new_host" --arg port "$new_port" --arg encryption "$new_encryption" \
            --arg login "$new_login" --arg password "$new_password" \
            '
            .accounts[$index].enabled = $enabled |
            .accounts[$index].name = (if $name == "" then null else $name end) |
            .accounts[$index].host = (if $host == "" then null else $host end) |
            .accounts[$index].port = (if $port == "" then null else ($port | tonumber) end) |
            .accounts[$index].encryption = (if $encryption == "" then "SSL" else $encryption end) |
            .accounts[$index].login = (if $login == "" then null else $login end) |
            .accounts[$index].password = (if $password == "" then null else $password end) |
            .accounts[$index].color = [$a, $r, $g, $b]
            ' "$CONFIG_PATH" > "$CONFIG_PATH.tmp" && mv "$CONFIG_PATH.tmp" "$CONFIG_PATH"

        yad --center --fixed --info --button="OK:0" --width=600 --text="Zmiany dla konta #$SLOT_NUM zostały zapisane!"
    fi
}


# ===================================================================================
#  GŁÓWNA PĘTLA PROGRAMU
# ===================================================================================
while true; do
    ACCOUNTS_INFO=()
    
    # --- POPRAWKA: Dynamiczne wczytywanie wszystkich kont (a nie tylko 5) ---
    local ACCOUNT_COUNT
    ACCOUNT_COUNT=$(jq '.accounts | length' "$CONFIG_PATH")

    for i in $(seq 0 $((ACCOUNT_COUNT - 1))); do
    # --- KONIEC POPRAWKI ---
    
        mapfile -t data < <(jq -r ".accounts[$i] | .enabled, .name, .login" "$CONFIG_PATH")
        enabled="${data[0]}"
        name="${data[1]}"
        login="${data[2]}"

        if [ "$enabled" == "true" ]; then
            status_text="<span color='green'><b>Aktywne</b></span>"
        else
            status_text="<span color='red'>Nieaktywne</span>"
        fi

        # Lepsza logika wyświetlania nazwy
        if [ "$login" != "null" ] && [ -n "$login" ]; then
            display_name="$login"
        elif [ "$name" != "null" ] && [ -n "$name" ]; then
            display_name="$name"
        else
            display_name="<span color='grey'>Puste miejsce</span>"
        fi

        ACCOUNTS_INFO+=("$status_text" "Konto #$((i + 1))" "$display_name")
    done

    WIN_WIDTH=600
    WIN_HEIGHT=350
    POS_X=$(((SCREEN_WIDTH - WIN_WIDTH) / 2))
    POS_Y=$(((SCREEN_HEIGHT - WIN_HEIGHT) / 2))

    CHOICE=$(yad --list \
        --title="Konfigurator kont e-mail" \
        --width="$WIN_WIDTH" --height="$WIN_HEIGHT" \
        --geometry="+$POS_X+$POS_Y" \
        --text="<b>Zarządzaj kontami e-mail.</b>\n- Kliknij dwukrotnie, aby <b>edytować</b> konto.\n- Użyj przycisku, by <b>wybrać konta do wyświetlenia</b>." \
        --column="Stan:TEXT" --column="Slot" --column="Login / Nazwa:TEXT" \
        --print-column=2 \
        --button="Wybierz konta:2" \
        --button="Zamknij:1" \
        "${ACCOUNTS_INFO[@]}")

    # Czystsza obsługa wyjścia
    case $? in
        0) edit_account "$CHOICE" ;;
        1) break ;;
        2) select_view ;;
        *) break ;;
    esac
done

exit 0
