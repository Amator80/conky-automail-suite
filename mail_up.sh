#!/bin/bash

# ==============================================================================
# 1. AUTOMATYCZNE WYKRYWANIE ŚCIEŻKI (Dla wersji Portable/Git)
# ==============================================================================
# Ta linia pobiera pełną ścieżkę do katalogu, w którym znajduje się TEN skrypt.
# Niezależnie od tego, gdzie użytkownik rozpakuje projekt, to zadziała.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Definicje plików
# Pliki w RAM (/dev/shm) są systemowe, więc tu ścieżka jest stała i bezpieczna
FILE="/dev/shm/conky-automail-suite/conky_mail_scroll_offset"
FLAG_FILE="/dev/shm/conky-automail-suite/scroll.active"
CACHE_FILE="/dev/shm/conky-automail-suite/mail_cache.json"

# Plik konfiguracyjny szukamy WZGLĘDEM skryptu
# Jeśli skrypt jest w głównym folderze, a config w podfolderze 'config':
CONFIG_COUNT="$SCRIPT_DIR/config/mail_count.conf"

# ==============================================================================
# 2. LOGIKA SKRYPTU
# ==============================================================================

# Wczytaj obecny offset
offset=0
if [[ -s "$FILE" ]]; then
  read -r raw < "$FILE"
  [[ "$raw" =~ ^-?[0-9]+$ ]] && offset=$raw
fi

# Pobierz liczbę wszystkich maili z pliku cache (Python)
total_mails=$(python3 -c "import json, sys; 
try:
    with open('$CACHE_FILE') as f:
        data = json.load(f)
        print(len(data.get('mails', [])))
except:
    print(0)" 2>/dev/null)

# Pobierz ustawienie MAX_MAILS (ile widać na raz) z pliku
visible_mails=5
if [[ -s "$CONFIG_COUNT" ]]; then
    read -r raw_conf < "$CONFIG_COUNT"
    # Sprawdź czy to liczba
    [[ "$raw_conf" =~ ^[0-9]+$ ]] && visible_mails=$raw_conf
fi

# Oblicz maksymalny sensowny offset
max_offset=$((total_mails - visible_mails))

# Zabezpieczenie: max_offset nie może być mniejszy niż 0
if (( max_offset < 0 )); then
    max_offset=0
fi

# Logika przewijania z blokadą
if (( offset < max_offset )); then
    new=$((offset + 1))
    printf '%d\n' "$new" > "$FILE"
    touch "$FLAG_FILE"
else
    # Jeśli już jesteśmy na końcu, korygujemy ewentualne przekroczenie
    if (( offset > max_offset )); then
        printf '%d\n' "$max_offset" > "$FILE"
        touch "$FLAG_FILE"
    fi
fi
