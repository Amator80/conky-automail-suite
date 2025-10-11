#!/bin/bash

# Automatycznie wykryj katalog projektu nawet dla dowiązań/symlinków/skrótów!
PROJECT_DIR="$(dirname "$(readlink -f "$0")")"
CONKY_CONF_NAME="conkyrc_mail" # Używamy samej nazwy pliku, a nie pełnej ścieżki
CONKY_CONF_PATH="$PROJECT_DIR/$CONKY_CONF_NAME"

# 1. Usuwamy plik cache maili
rm -f /tmp/conky-automail-suite/last_seen_mails.json

# 2. Zabijamy Conky z tym configiem (wyszukując po samej nazwie pliku)
#    ==================== TUTAJ JEST POPRAWKA ====================
pid=$(pgrep -f "conky.*$CONKY_CONF_NAME")
#    =============================================================

if [[ -n "$pid" ]]; then
    echo "Znaleziono działający proces Conky (PID: $pid). Zatrzymuję..."
    kill "$pid"
    # Czekamy aż proces zniknie, max 3 sekundy
    for i in {1..30}; do
        sleep 0.1
        if ! ps -p "$pid" > /dev/null; then
            echo "Proces zatrzymany."
            break
        fi
    done
else
    echo "Nie znaleziono działającego procesu Conky pasującego do '$CONKY_CONF_NAME'."
fi

# 3. Startujemy ponownie Conky z pełną ścieżką
echo "Uruchamiam nową instancję Conky..."
conky -c "$CONKY_CONF_PATH" &

exit 0
