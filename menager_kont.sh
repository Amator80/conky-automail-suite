#!/bin/bash

# ===================================================================================
#  UNIWERSALNY KONFIGURATOR I SELEKTOR KONT E-MAIL
# ===================================================================================
# Skrypt służący do zarządzania kontami e-mail i wybierania, które z nich mają być
# aktywne do celów wyświetlania (np. w Conky). Wykorzystuje YAD do interfejsu
# graficznego i jq do manipulacji plikiem konfiguracyjnym w formacie JSON.
# Większość okien dialogowych jest teraz skalowalna przez użytkownika.
# ===================================================================================

# --- ŚCIEŻKI KONFIGURACYJNE ---
# Zmodyfikowane ścieżki, aby wskazywały na podkatalog 'config'
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
CONFIG_PATH="$SCRIPT_DIR/config/config.json"
SELECTOR_FILE="$SCRIPT_DIR/config/active_account_selector"

# --- SPRAWDZENIE ZALEŻNOŚCI ---
# Skrypt wymaga zainstalowanych narzędzi: jq, yad, xrandr, notify-send.
if ! command -v jq &> /dev/null || \
   ! command -v yad &> /dev/null || \
   ! command -v xrandr &> /dev/null || \
   ! command -v notify-send &> /dev/null; then
    # Okno błędu pozostaje stałe (fixed).
    yad --center --fixed --error \
        --text="<b>Błąd: Brakujące zależności!</b>\n\nUpewnij się, że zainstalowane są pakiety:\n'jq', 'yad', 'x11-xserver-utils' (dla xrandr) oraz 'libnotify-bin' (dla notify-send).\n\nPrzykładowa komenda instalacji w systemach Debian/Ubuntu:\n<b>sudo apt install jq yad x11-xserver-utils libnotify-bin</b>" \
        --width=800
    exit 1
fi

# Sprawdzenie, czy plik konfiguracyjny istnieje.
if [ ! -f "$CONFIG_PATH" ]; then
    # Okno błędu pozostaje stałe (fixed).
    yad --center --fixed --error \
        --text="<b>Błąd: Nie znaleziono pliku konfiguracyjego.</b>\n\nOczekiwana ścieżka:\n$CONFIG_PATH\n\nUpewnij się, że plik 'config.json' istnieje w katalogu 'config' obok skryptu." \
        --width=800
    exit 1
fi

# --- OBLICZENIE GEOMETRII EKRANU ---
# Pobiera aktualną rozdzielczość ekranu, aby móc centrować okna dialogowe.
SCREEN_GEOMETRY=$(xrandr | grep '*' | head -n 1 | awk '{print $1}')
SCREEN_WIDTH=$(echo "$SCREEN_GEOMETRY" | cut -d'x' -f1)
SCREEN_HEIGHT=$(echo "$SCREEN_GEOMETRY" | cut -d'x' -f2)


# ===================================================================================
#  FUNKCJA: select_view()
# ===================================================================================
# Zarządza wyborem kont do wyświetlenia: wszystkie lub konkretne wybrane przez użytkownika.
# Wynik wyboru (indeksy kont lub '0' dla wszystkich) jest zapisywany do pliku $SELECTOR_FILE.
# ===================================================================================
select_view() {
    local ACCOUNT_LOGINS=()
    while IFS= read -r line; do
        ACCOUNT_LOGINS+=("$line")
    done < <(jq -r '.accounts[] | select(.enabled == true) | .login' "$CONFIG_PATH")

    local ACCOUNT_COUNT=${#ACCOUNT_LOGINS[@]}

    # --- LOGIKA WYBORU KONT ---
    if [ "$ACCOUNT_COUNT" -eq 0 ]; then
        # Okno informacyjne pozostaje stałe (fixed).
        yad --center --fixed --info \
            --text="<b>Informacja:</b> Nie znaleziono żadnych włączonych kont.\nNie ma czego wyświetlić." \
            --width=700
        return
    elif [ "$ACCOUNT_COUNT" -eq 1 ]; then
        echo "1" > "$SELECTOR_FILE"
        # Okno informacyjne pozostaje stałe (fixed).
        yad --center --fixed --info \
            --title="Automatyczny wybór" \
            --text="Wykryto tylko jedno aktywne konto. Zostało ono wybrane automatycznie:\n\n<b>${ACCOUNT_LOGINS[0]}</b>\n\n<i>Gdy aktywujesz co najmniej dwa konta, menu wyboru pozwoli na przełączanie.</i>" \
            --width=800
        return
    else
        # KROK 1: Wybór trybu (Podsumowanie vs Wybór konkretnych).
        # Usunięto --fixed, dodano --center.
        local MODE_CHOICE_RAW
        MODE_CHOICE_RAW=$(yad --list --radiolist --center \
            --title="Wybierz tryb wyświetlania" \
            --text="W jaki sposób chcesz wyświetlić konta?" \
            --width=600 --height=200 \
            --column="Wybór:RD" --column="Opcja" \
            TRUE "Podsumowanie wszystkich aktywnych kont" \
            FALSE "Wybiorę konkretne konta")
        
        if [ $? -ne 0 ]; then return; fi

        local MODE_CHOICE=$(echo "$MODE_CHOICE_RAW" | cut -d'|' -f2)

        if [[ "$MODE_CHOICE" == "Podsumowanie wszystkich aktywnych kont" ]]; then
            echo "0" > "$SELECTOR_FILE"
            notify-send "Przełączono widok poczty" "Wyświetlane: <b>Wszystkie konta</b>"
            return
        fi

        # KROK 2: Użytkownik chce wybrać konkretne konta.
        # Usunięto --fixed, dodano --center.
        local YAD_ACCOUNTS=()
        for login in "${ACCOUNT_LOGINS[@]}"; do
            YAD_ACCOUNTS+=("FALSE" "$login")
        done
        
        local CHOICE
        CHOICE=$(yad --list --checklist --center \
            --title="Wybierz konta do wyświetlenia" \
            --text="Zaznacz konta, które mają być widoczne w Conky." \
            --width=600 --height=450 \
            --column="Wybierz:CHK" --column="Dostępne konta" \
            --multiple --separator="|" \
            "${YAD_ACCOUNTS[@]}")

        if [ $? -ne 0 ]; then return; fi
        
        local SELECTED_INDICES=()
        IFS='|' read -ra CHOSEN_ITEMS <<< "$CHOICE"
        
        for item in "${CHOSEN_ITEMS[@]}"; do
            for i in "${!ACCOUNT_LOGINS[@]}"; do
                if [[ "${ACCOUNT_LOGINS[$i]}" == "$item" ]]; then
                    SELECTED_INDICES+=("$((i + 1))")
                    break
                fi
            done
        done

        if [ ${#SELECTED_INDICES[@]} -gt 0 ] && [ "${#SELECTED_INDICES[@]}" -eq "$ACCOUNT_COUNT" ]; then
            # Okno informacyjne pozostaje stałe (fixed).
            echo "0" > "$SELECTOR_FILE"
            yad --center --fixed --info \
                --title="Automatyczne Podsumowanie" \
                --text="Zaznaczono wszystkie dostępne konta.\nWidok został automatycznie przełączony na <b>'Podsumowanie'</b>." \
                --width=750
            notify-send "Przełączono widok poczty" "Wyświetlane: <b>Wszystkie konta (Automatycznie)</b>"
        elif [ ${#SELECTED_INDICES[@]} -gt 0 ]; then
            echo "${SELECTED_INDICES[*]}" > "$SELECTOR_FILE"
            local PRETTY_CHOICE="${CHOICE//|/, }"
            notify-send "Przełączono widok poczty" "Wyświetlane: <b>$PRETTY_CHOICE</b>"
        fi
    fi
}

# ===================================================================================
#  FUNKCJA: edit_account()
# ===================================================================================
# Otwiera formularz do edycji szczegółów wybranego konta e-mail.
# Pozwala zmienić status, nazwę, host, port, login, hasło, SZYFROWANIE oraz kolor.
# Zmiany są zapisywane z powrotem do pliku config.json.
# ===================================================================================
edit_account() {
    local choice_string="$1"
    local SLOT_NUM=$(echo "$choice_string" | grep -o -E '[0-9]+')
    if [ -z "$SLOT_NUM" ]; then return; fi

    local INDEX=$((SLOT_NUM - 1))

    # Krok 1: Wczytaj dane z JSON, w tym nowe pole 'encryption'
    local values
    mapfile -t values < <(jq -r \
        --argjson index "$INDEX" \
        '.accounts[$index] | [ .enabled, .name, .host, .port, .login, .password, .encryption, (.color // [255, 255, 255, 255] | .[0]), (.color // [255, 255, 255, 255] | .[1]), (.color // [255, 255, 255, 255] | .[2]), (.color // [255, 255, 255, 255] | .[3]) ] | .[]' \
        "$CONFIG_PATH")

    # Krok 2: Przypisz wczytane wartości do zmiennych, uwzględniając przesunięcie
    local ENABLED=${values[0]}
    local NAME=$([ "${values[1]}" == "null" ] && echo "" || echo "${values[1]}")
    local HOST=$([ "${values[2]}" == "null" ] && echo "" || echo "${values[2]}")
    local PORT=$([ "${values[3]}" == "null" ] && echo "" || echo "${values[3]}")
    local LOGIN=$([ "${values[4]}" == "null" ] && echo "" || echo "${values[4]}")
    local PASSWORD=$([ "${values[5]}" == "null" ] && echo "" || echo "${values[5]}")
    local ENCRYPTION=$([ "${values[6]}" == "null" ] && echo "SSL" || echo "${values[6]}") # Domyślnie SSL, jeśli brak
    local ALPHA=${values[7]}
    local RED=${values[8]}
    local GREEN=${values[9]}
    local BLUE=${values[10]}
    
    local COLOR_HEX=$(printf "#%02x%02x%02x" "$RED" "$GREEN" "$BLUE")
    local ALPHA_WITH_RANGE="$ALPHA!0..255..1"
    local CHECKED_STATE=$([ "$ENABLED" == "true" ] && echo "TRUE" || echo "FALSE")
    
    # Przygotuj opcje dla pola ComboBox w YAD. '^' oznacza wartość domyślną, '!' to separator.
    local ENCRYPTION_OPTIONS
    if [[ "$ENCRYPTION" == "STARTTLS" ]]; then
        ENCRYPTION_OPTIONS="^STARTTLS!SSL"
    else
        ENCRYPTION_OPTIONS="^SSL!STARTTLS"
    fi

    # --- Definicja rozmiarów okna edycji konta (zwiększona wysokość) ---
    local EDIT_WIN_WIDTH=650
    local EDIT_WIN_HEIGHT=400
    local EDIT_POS_X=$(((SCREEN_WIDTH - EDIT_WIN_WIDTH) / 2))
    local EDIT_POS_Y=$(((SCREEN_HEIGHT - EDIT_WIN_HEIGHT) / 2))

    local EDIT_DATA
    # Krok 3: Dodaj pole ComboBox ":CB" do formularza YAD
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
        # Krok 4: Odczytaj nową wartość 'new_encryption' z wyniku YAD
        local new_enabled new_name new_host new_port new_encryption new_login new_password new_color_hex new_alpha
        IFS='|' read -r new_enabled new_name new_host new_port new_encryption new_login new_password new_color_hex new_alpha <<< "$EDIT_DATA"
        
        local hex_clean=${new_color_hex#\#}
        local r=$((16#${hex_clean:0:2}))
        local g=$((16#${hex_clean:2:2}))
        local b=$((16#${hex_clean:4:2}))
        local alpha=$(printf "%.0f" "$new_alpha")
        local new_enabled_json=$([ "$new_enabled" == "TRUE" ] && echo "true" || echo "false")
        
        # Krok 5: Zaktualizuj pole 'encryption' w pliku JSON za pomocą jq
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
#  GŁÓWNA PĘTLA APLIKACJI
# ===================================================================================
# Główna pętla skryptu, która wyświetla listę kont i reaguje na interakcję użytkownika.
# ===================================================================================
while true; do
    ACCOUNTS_INFO=()
    for i in {0..4}; do
        mapfile -t data < <(jq -r ".accounts[$i] | .enabled, .name, .login" "$CONFIG_PATH")
        enabled="${data[0]}"
        name="${data[1]}"
        login="${data[2]}"
        
        if [ "$enabled" == "true" ]; then
            status_text="<span color='green'><b>Aktywne</b></span>"
        else
            status_text="<span color='red'>Nieaktywne</span>"
        fi

        if [ "$name" != "null" ] && [ -n "$name" ]; then
            display_name="<b>$name</b>"
        elif [ "$login" != "null" ] && [ -n "$login" ]; then
            display_name="$login"
        else
            display_name="<span color='grey'>Puste miejsce</span>"
        fi
        
        ACCOUNTS_INFO+=("$status_text" "Konto #$((i + 1))" "$display_name")
    done

    # --- Definicja rozmiarów głównego okna programu ---
    WIN_WIDTH=600
    WIN_HEIGHT=350

    # Obliczenie pozycji okna na środku ekranu.
    POS_X=$(((SCREEN_WIDTH - WIN_WIDTH) / 2))
    POS_Y=$(((SCREEN_HEIGHT - WIN_HEIGHT) / 2))
    
    # Usunięto --fixed z głównego okna, aby było skalowalne.
    CHOICE=$(yad --list \
        --title="Konfigurator kont e-mail" \
        --width="$WIN_WIDTH" --height="$WIN_HEIGHT" \
        --geometry="+$POS_X+$POS_Y" \
        --text="<b>Zarządzaj kontami e-mail.</b>\n- Kliknij dwukrotnie, aby <b>edytować</b> konto.\n- Użyj przycisku, aby <b>wybrać konta do wyświetlenia</b>." \
        --column="Stan:TEXT" --column="Slot" --column="Nazwa / Login:TEXT" \
        --print-column=2 \
        --button="Wybierz konta:2" \
        --button="Zamknij:1" \
        "${ACCOUNTS_INFO[@]}")
    
    EXIT_STATUS=$?

    # --- OBSŁUGA AKCJI UŻYTKOWNIKA ---
    case $EXIT_STATUS in
        0)  # Podwójne kliknięcie na liście
            edit_account "$CHOICE"
            ;;
        1)  # Przycisk "Zamknij" lub zamknięcie okna
            break
            ;;
        2)  # Przycisk "Wybierz konta"
            select_view
            ;;
        *)  # Inne zamknięcie okna (np. przez menedżer okien)
            break
            ;;
    esac
done

exit 0
