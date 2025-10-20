#!/bin/bash
cd "$(dirname "$(readlink -f "$0")")"

LUA_FILE="lua/e-mail.lua"
CONKY_FILE="conkyrc_mail"

# Mapowanie trybów na alignment
declare -A ALIGNMENTS=(
    ["down"]="bottom_middle"
    ["up"]="top_middle"
    ["down_left"]="bottom_left"
    ["down_right"]="bottom_right"
    ["up_left"]="top_left"
    ["up_right"]="top_right"
)

# Lista trybów, przez które ma przechodzić demo
LAYOUTS=("down" "up" "down_left" "down_right" "up_left" "up_right")

DELAY=3  # sekundy między zmianami

echo "Demo startuje... (przerwij Ctrl+C)"
sleep 1

while true; do
    for layout in "${LAYOUTS[@]}"; do
        ALIGN_VAL="${ALIGNMENTS[$layout]}"
        
        # Zabijamy obecne conky
        pkill -u "$USER" -f "conky.*$CONKY_FILE"

        # Zmieniamy layout w Lua
        sed -i "s|^LAYOUT_MODE = \".*\"|LAYOUT_MODE = \"$layout\"|" "$LUA_FILE"

        # Zmieniamy alignment w conkyrc
        sed -i "s|^\s*alignment\s*=.*|    alignment               = '$ALIGN_VAL',|" "$CONKY_FILE"

        echo "Ustawiono: LAYOUT_MODE = \"$layout\", alignment = '$ALIGN_VAL'"
        sleep "$DELAY"
    done
done

