#!/bin/bash

# Ścieżki
FILE="/dev/shm/conky-automail-suite/conky_mail_scroll_offset"
FLAG_FILE="/dev/shm/conky-automail-suite/scroll.active"

# 1. Wczytaj obecny offset
offset=0
if [[ -s "$FILE" ]]; then
    read -r raw < "$FILE"
    if [[ "$raw" =~ ^-?[0-9]+$ ]]; then
        offset=$raw
    fi
fi

# 2. Logika przewijania z blokadą (nie schodź poniżej 0)
if (( offset > 0 )); then
    offset=$((offset - 1))
    
    # Zapisz nową wartość
    echo "$offset" > "$FILE"
    
    # Zasygnalizuj aktywność
    touch "$FLAG_FILE"
else
    # Jeśli offset jest mniejszy niż 0 (błąd) lub 0, upewnij się że jest 0
    if (( offset < 0 )); then
        echo "0" > "$FILE"
        touch "$FLAG_FILE"
    fi
fi
