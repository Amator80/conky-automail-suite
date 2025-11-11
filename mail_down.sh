#!/bin/bash

FILE="/dev/shm/conky-automail-suite/conky_mail_scroll_offset"
FLAG_FILE="/dev/shm/conky-automail-suite/scroll.active" # <--- DODAJ TĘ LINIĘ

# 1. Bezpieczne wczytanie wartości (domyślnie 0)
offset=0
if [[ -s "$FILE" ]]; then
    read -r raw < "$FILE"
    if [[ "$raw" =~ ^-?[0-9]+$ ]]; then
        offset=$raw
    fi
fi

# 2. Zmniejsz wartość
offset=$((offset - 1))

# 3. Zapisz nową wartość
echo "$offset" > "$FILE"

# 4. Zasygnalizuj aktywność przewijania (tak jak w skrypcie UP)
touch "$FLAG_FILE" # <--- I TĘ LINIĘ
