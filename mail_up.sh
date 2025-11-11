#!/bin/bash
FILE="/dev/shm/conky-automail-suite/conky_mail_scroll_offset"
FLAG_FILE="/dev/shm/conky-automail-suite/scroll.active" # <--- DODAJ TĘ LINIĘ

# wczytaj bezpiecznie liczbę (domyślnie 0)
offset=0
if [[ -s "$FILE" ]]; then
  read -r raw < "$FILE"
  [[ "$raw" =~ ^-?[0-9]+$ ]] && offset=$raw
fi

# jeśli ujemne → 1, inaczej inkrementuj
if (( offset < 0 )); then
  new=1
else
  new=$((offset + 1))
fi

printf '%d\n' "$new" > "$FILE"
touch "$FLAG_FILE" # <--- I TĘ LINIĘ (tworzy pusty plik-flagę)
