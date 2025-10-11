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

# --- Wczytanie nazw włączonych kont z pliku JSON ---
mapfile -t ACCOUNTS < <(jq -r '.accounts[] | select(.enabled == true) | .name' "$CONFIG_FILE")
if [ ${#ACCOUNTS[@]} -eq 0 ]; then
    yad --info --center --text="Nie znaleziono żadnych aktywnych kont w pliku konfiguracyjnym." --icon=dialog-information
    exit 0
fi

# --- Okno 1: Wybór kont ---
### ZMIANA START ###
# Inicjalizujemy pustą tablicę dla opcji YAD
YAD_ACCOUNTS=()

# Sprawdzamy, czy jest więcej niż jedno konto. Jeśli tak, dodajemy opcję "WSZYSTKIE KONTA".
if [ ${#ACCOUNTS[@]} -gt 1 ]; then
    YAD_ACCOUNTS+=("FALSE" "WSZYSTKIE KONTA")
fi
### ZMIANA KONIEC ###

# Zawsze dodajemy wszystkie znalezione konta do listy
for acc in "${ACCOUNTS[@]}"; do YAD_ACCOUNTS+=("FALSE" "$acc"); done

SELECTED_ACCOUNTS_STR=$(yad --list --checklist --separator=" " \
    --title="Manager Poczty" --text="<b>Wybierz konta, na których chcesz wykonać akcję:</b>" \
    --width=400 --height=300 --icon="$YAD_ICON" \
    --center \
    --column="Wybierz" --column="Nazwa konta" "${YAD_ACCOUNTS[@]}")
[[ $? -ne 0 ]] && exit 0 # Anulowano

if [[ -z "$SELECTED_ACCOUNTS_STR" ]]; then
    yad --info --center --text="Nie wybrano żadnego konta. Przerywam." --icon=dialog-information
    exit 0
fi

# --- Okno 2: Wybór akcji ---
ACTION=$(yad --form --title="Manager Poczty" --text="<b>Wybierz akcję do wykonania:</b>" \
    --width=400 --icon="$YAD_ICON" --field="Akcja:CB" \
    --center \
    "Oznacz wiadomości jako przeczytane!Oznacz wiadomości jako nieprzeczytane!Przenieś wiadomości do kosza!Opróżnij kosz")
[[ $? -ne 0 ]] && exit 0 # Anulowano

ACTION_ARG_RAW=$(echo "$ACTION" | cut -d'|' -f1)
case "$ACTION_ARG_RAW" in
    "Oznacz wiadomości jako przeczytane") ACTION_ARG="mark-read";;
    "Oznacz wiadomości jako nieprzeczytane") ACTION_ARG="mark-unread";;
    "Przenieś wiadomości do kosza") ACTION_ARG="move-to-trash";;
    "Opróżnij kosz") ACTION_ARG="empty-trash";;
    *) yad --error --center --text="Nieznana akcja!"; exit 1;;
esac

# --- Potwierdzenie dla niebezpiecznych akcji ---
if [[ "$ACTION_ARG" == "empty-trash" ]]; then
    yad --question --title="POTWIERDZENIE" --text-align=center \
        --text="<span color='red' font='14'><b>UWAGA!</b></span>\n\nCzy na pewno chcesz <b>TRWALE USUNĄĆ</b> wiadomości z kosza?\nTa operacja jest <b>NIEODWRACALNA!</b>" \
        --icon=dialog-warning --center
    [[ $? -ne 0 ]] && exit 0 # Anulowano
fi

# --- Budowanie i wykonanie komendy ---
COMMAND_ARGS=("--config" "$CONFIG_FILE" "--action" "$ACTION_ARG" "--accounts")
if [[ "$SELECTED_ACCOUNTS_STR" == *"WSZYSTKIE KONTA"* ]]; then
    COMMAND_ARGS+=("ALL")
else
    # shellcheck disable=SC2206
    COMMAND_ARGS+=($SELECTED_ACCOUNTS_STR)
fi

# Wykonaj skrypt i pokaż wynik w oknie tekstowym YAD
python3 "$PYTHON_MANAGER_SCRIPT" "${COMMAND_ARGS[@]}" | yad --text-info --title="Wynik operacji" --width=800 --height=400 --wrap --monospace --center
