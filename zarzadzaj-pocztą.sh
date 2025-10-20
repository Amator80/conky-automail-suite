#!/bin/bash

# Przejdź do katalogu, w którym znajduje się skrypt, aby ścieżki względne zawsze działały
cd "$(dirname "$(readlink -f "$0")")"

# --- Konfiguracja ścieżek ---
CONFIG_FILE="./config/config.json"
PYTHON_MANAGER_SCRIPT="./py/mail_manager.py"
YAD_ICON="mail-mark-unread"

# --- Sprawdzenie zależności ---
for cmd in yad jq python3; do
    if ! command -v $cmd &> /dev/null; then
        yad --error --center --text="Błąd: Program '$cmd' nie jest zainstalowany. Zainstaluj go i spróbuj ponownie." --icon=dialog-error
        exit 1
    fi
done
if [ ! -f "$CONFIG_FILE" ]; then
    yad --error --center --text="Błąd krytyczny: Nie znaleziono pliku konfiguracyjnego w '$CONFIG_FILE'!" --icon=dialog-error
    exit 1
fi

# Ta funkcja przyjmuje string rozdzielany potokami '|' i zwraca (wypisuje)
# listę elementów, każdy w nowej linii. To uniwersalna metoda.
function get_clean_list_from_str() {
    local input_string="$1"
    mapfile -t temp_array < <(echo -n "$input_string" | tr '|' '\n')
    for item in "${temp_array[@]}"; do
        if [[ -n "$item" ]]; then
            echo "$item"
        fi
    done
}

# --- GŁÓWNA PĘTLA APLIKACJI (PĘTLA ZEWNĘTRZNA) ---
while true; do
    # --- Etap 1: Wybór kont ---
    mapfile -t ALL_ENABLED_ACCOUNTS < <(jq -r '.accounts[] | select(.enabled == true) | .name' "$CONFIG_FILE")
    if [ ${#ALL_ENABLED_ACCOUNTS[@]} -eq 0 ]; then
        yad --info --center --text="Nie znaleziono żadnych aktywnych kont w pliku konfiguracyjnym." --button="OK:0"
        exit 0
    fi

    YAD_ACCOUNTS=()
    if [ ${#ALL_ENABLED_ACCOUNTS[@]} -gt 1 ]; then
        YAD_ACCOUNTS+=("FALSE" "WSZYSTKIE KONTA")
    fi
    for acc in "${ALL_ENABLED_ACCOUNTS[@]}"; do YAD_ACCOUNTS+=("FALSE" "$acc"); done

    SELECTED_ACCOUNTS_STR=$(yad --list --checklist --separator="|" \
        --title="Manager Poczty (Krok 1/3)" --text="<b>Wybierz konta, na których chcesz wykonać akcję:</b>" \
        --width=400 --height=300 --icon="$YAD_ICON" \
        --center --print-column=2 \
        --column="Wybierz" --column="Nazwa konta" "${YAD_ACCOUNTS[@]}")
    
    [[ $? -ne 0 ]] && break

    if [[ -z "$SELECTED_ACCOUNTS_STR" ]]; then
        yad --info --center --text="Nie wybrano żadnego konta. Spróbuj ponownie." --icon=dialog-information
        continue
    fi

    # --- PĘTLA WYBORU AKCJI (PĘTLA WEWNĘTRZNA) ---
    while true; do
        ACTION=$(yad --form --title="Manager Poczty (Krok 2/3)" --text="<b>Wybierz akcję dla wybranych kont:</b>" \
            --width=400 --icon="$YAD_ICON" --field="Akcja:CB" \
            --center \
            "Oznacz wiadomości jako przeczytane!Oznacz wiadomości jako nieprzeczytane!Przenieś wiadomości do kosza!Opróżnij kosz!Zmień konta (Wróć)!Zakończ program")
        
        [[ $? -ne 0 ]] && break

        ACTION_ARG_RAW=$(echo "$ACTION" | cut -d'|' -f1)
        ACTION_ARG="" 
        
        case "$ACTION_ARG_RAW" in
            "Oznacz wiadomości jako przeczytane") ACTION_ARG="mark-read";;
            "Oznacz wiadomości jako nieprzeczytane") ACTION_ARG="mark-unread";;
            "Przenieś wiadomości do kosza") ACTION_ARG="move-to-trash";;
            "Opróżnij kosz") ACTION_ARG="empty-trash";;
            "Zmień konta (Wróć)") break;;
            "Zakończ program") 
                yad --info --center --text="Zakończono pracę z managerem poczty." --button="OK:0"
                exit 0;;
            *) yad --error --center --text="Nieznana akcja!"; exit 1;;
        esac

        if [[ "$ACTION_ARG" == "empty-trash" ]]; then
            yad --question --title="POTWIERDZENIE" --text-align=center \
                --text="<span color='red' font='14'><b>UWAGA!</b></span>\n\nCzy na pewno chcesz <b>TRWALE USUNĄĆ</b> wiadomości z kosza?\nTa operacja jest <b>NIEODWRACALNA!</b>" \
                --icon=dialog-warning --center
            [[ $? -ne 0 ]] && continue 
        fi

        FINAL_OUTPUT=""

        ### ZMIANA KLUCZOWA: Tworzymy jedną, ostateczną listę kont do przetworzenia ###
        # Niezależnie od wyboru, zawsze będziemy operować na liście indywidualnych kont.
        accounts_to_process=()
        if [[ "$SELECTED_ACCOUNTS_STR" == *"WSZYSTKIE KONTA"* ]]; then
            # Jeśli wybrano "WSZYSTKIE KONTA", użyj pełnej listy aktywnych kont
            accounts_to_process=("${ALL_ENABLED_ACCOUNTS[@]}")
        else
            # W przeciwnym razie, użyj listy kont wybranych ręcznie
            mapfile -t accounts_to_process < <(get_clean_list_from_str "$SELECTED_ACCOUNTS_STR")
        fi

        if [[ "$ACTION_ARG" == "mark-read" || "$ACTION_ARG" == "mark-unread" || "$ACTION_ARG" == "move-to-trash" ]]; then
            
            MODE_KEY=$(yad --list --radiolist --separator="" \
                --title="Manager Poczty (Krok 3/3)" \
                --text="<b>Wybierz zakres wiadomości do przetworzenia:</b>" \
                --width=400 --height=200 --center \
                --print-column=2 \
                --column="Wybierz" --column="Klucz:HD" --column="Tryb" \
                TRUE  "all"   "Wszystkie" \
                FALSE "first" "Najnowsze wiadomości" \
                FALSE "last"  "Najstarsze wiadomości")
            [[ $? -ne 0 ]] && continue

            if [[ "$MODE_KEY" == "all" ]]; then
                # Tryb "Wszystkie" - proste wywołanie w pętli dla każdego konta
                for account in "${accounts_to_process[@]}"; do
                    FINAL_OUTPUT+="=== WYNIK DLA KONTA: $account ===\n"
                    COMMAND_ARGS=("--config" "$CONFIG_FILE" "--action" "$ACTION_ARG" "--mode" "all" --accounts "$account")
                    FINAL_OUTPUT+=$(python3 "$PYTHON_MANAGER_SCRIPT" "${COMMAND_ARGS[@]}")"\n\n"
                done
            else
                ### ZMIANA: Logika zależy już tylko od liczby kont na liście ###
                if [[ ${#accounts_to_process[@]} -le 1 ]]; then
                    # Pytaj o jedną liczbę, jeśli na liście jest tylko jedno konto
                    COUNT_CHOICE_RAW=$(yad --form --title="Liczba wiadomości" \
                        --text="<b>Wprowadź liczbę wiadomości do przetworzenia (wpisz 0, aby pominąć):</b>" \
                        --field="Liczba wiadomości:NUM" "50!0..10000!1" --center)
                    [[ $? -ne 0 ]] && continue
                    
                    COUNT_CHOICE=$(echo "$COUNT_CHOICE_RAW" | cut -d'|' -f1)
                    if ! [[ "$COUNT_CHOICE" =~ ^[0-9]+$ ]]; then
                        yad --error --center --text="Wprowadzono nieprawidłową wartość. Proszę podać liczbę."
                        continue
                    fi

                    if [[ "$COUNT_CHOICE" -gt 0 ]]; then
                        # Pętla wykona się raz, dla jednego konta
                        for account in "${accounts_to_process[@]}"; do
                            FINAL_OUTPUT+="=== WYNIK DLA KONTA: $account ===\n"
                            COMMAND_ARGS=("--config" "$CONFIG_FILE" "--action" "$ACTION_ARG" "--mode" "$MODE_KEY" "--count" "$COUNT_CHOICE" --accounts "$account")
                            FINAL_OUTPUT+=$(python3 "$PYTHON_MANAGER_SCRIPT" "${COMMAND_ARGS[@]}")"\n\n"
                        done
                    else
                        FINAL_OUTPUT="Operacja pominięta (liczba wiadomości ustawiona na 0).\n"
                    fi
                else
                    # Pytaj o osobną liczbę dla każdego konta, jeśli na liście jest ich więcej
                    YAD_FORM_ARGS=(--form --title="Liczba wiadomości dla każdego konta" --text="<b>Wprowadź liczbę wiadomości (wpisz 0, aby pominąć konto):</b>" --center)
                    for acc in "${accounts_to_process[@]}"; do
                        YAD_FORM_ARGS+=(--field="$acc:NUM" "50!0..10000!1")
                    done

                    COUNTS_CHOICE_RAW=$(yad "${YAD_FORM_ARGS[@]}")
                    [[ $? -ne 0 ]] && continue
                    IFS='|' read -r -a counts_array <<< "$COUNTS_CHOICE_RAW"

                    for i in "${!accounts_to_process[@]}"; do
                        account_name="${accounts_to_process[$i]}"
                        account_count="${counts_array[$i]}"
                        
                        if ! [[ "$account_count" =~ ^[0-9]+$ ]]; then
                            yad --error --center --text="Wprowadzono nieprawidłową wartość dla konta '$account_name'. Pomijam."
                            continue
                        fi

                        if [[ "$account_count" -eq 0 ]]; then
                            FINAL_OUTPUT+="=== POMINIĘTO KONTO: $account_name (liczba: 0) ===\n\n"
                            continue
                        fi

                        FINAL_OUTPUT+="=== WYNIK DLA KONTA: $account_name (Liczba: $account_count) ===\n"
                        COMMAND_ARGS=("--config" "$CONFIG_FILE" "--action" "$ACTION_ARG" --mode "$MODE_KEY" --count "$account_count" --accounts "$account_name")
                        FINAL_OUTPUT+=$(python3 "$PYTHON_MANAGER_SCRIPT" "${COMMAND_ARGS[@]}")"\n\n"
                    done
                fi
            fi
        else
            # Proste akcje (np. opróżnij kosz) - również w pętli dla każdego konta
            for account in "${accounts_to_process[@]}"; do
                 FINAL_OUTPUT+="=== WYNIK DLA KONTA: $account ===\n"
                 COMMAND_ARGS=("--config" "$CONFIG_FILE" "--action" "$ACTION_ARG" --accounts "$account")
                 FINAL_OUTPUT+=$(python3 "$PYTHON_MANAGER_SCRIPT" "${COMMAND_ARGS[@]}")"\n\n"
            done
        fi

        echo -e "$FINAL_OUTPUT" | yad --text-info --title="Wynik operacji" --width=800 --height=400 --wrap --monospace --center
    done
done

yad --info --center --text="Zakończono pracę z managerem poczty." --button="OK:0"
exit 0
