#!/bin/bash
cd "$(dirname "$(readlink -f "$0")")"
exec 200>/tmp/conky-automail-suite/.myconkyluadir.lock
flock -n 200 || { echo "Inna instancja skryptu działa!"; exit 1; }

LUA_FILE="lua/e-mail.lua"
CONKY_FILE="conkyrc_mail"

declare -A ALIGNMENTS=(
    ["down"]="bottom_middle"
    ["up"]="top_middle"
    ["down_left"]="bottom_left"
    ["down_right"]="bottom_right"
    ["up_left"]="top_left"
    ["up_right"]="top_right"
)

ASCII_LAYOUT_FILE=$(mktemp)
cat <<EOF >"$ASCII_LAYOUT_FILE"
 _______________________________________________
|         [mail]                                |
|         [mail]                                | 
|         [mail]                                | - DOWN
|         [mail]                                |
|[koperta][E-MAIL: Konto] --------------------- |
 ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
 _______________________________________________
|[koperta][E-MAIL: Konto] --------------------- |
|         [mail]                                | 
|         [mail]                                | - UP
|         [mail]                                |
|         [mail]                                |
 ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
 _______________________________________________
|         [mail]                                |
|         [mail]                                |
|         [mail]                                | - DOWN_RIGHT
|         [mail]                                |
|[koperta][E-MAIL: Konto]---------------------- |
 ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
 _______________________________________________
|[koperta][E-MAIL: Konto]---------------------- |
|         [mail]                                | 
|         [mail]                                | - UP_RIGHT
|         [mail]                                |
|         [mail]                                |
 ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
 _______________________________________________
|[mail]                                         |
|[mail]                                         |
|[mail]                                         | - DOWN_LEFT
|[mail]                                         |
|[E-MAIL: Konto]---------------------- [koperta]|
 ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
 _______________________________________________
|[E-MAIL: Konto]---------------------- [koperta]|
|[mail]                                         | 
|[mail]                                         | - UP_LEFT
|[mail]                                         |
|[mail]                                         |
 ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
EOF

zenity --text-info --title="Podgląd układów maili (ASCII)" \
    --font="monospace 10" --width=1000 --height=1100 \
    --filename="$ASCII_LAYOUT_FILE" &
ASCII_PID=$!

sleep 0.3
zenity_layout=$(zenity --list --radiolist \
    --title="Wybierz układ maili" \
    --width=550 --height=320 \
    --column="" --column="Kod układu" --column="Opis" \
    TRUE "down" "okno na dole, blok maili w górę" \
    FALSE "up" "okno na górze, blok maili w dół" \
    FALSE "down_right" "dolny prawy róg, blok maili w górę" \
    FALSE "up_right" "górny prawy róg, blok maili w dół" \
    FALSE "down_left" "dolny lewy róg, blok maili w górę" \
    FALSE "up_left" "górny lewy róg, blok maili w dół" \
)

kill $ASCII_PID 2>/dev/null
rm -f "$ASCII_LAYOUT_FILE"

if [ -z "$zenity_layout" ]; then
    notify-send "Mail_python_amator80" "Nie wybrano układu – operacja anulowana."
    exit 0
fi

SELECTED="$zenity_layout"
ALIGN_VAL="${ALIGNMENTS[$SELECTED]}"

# zmiana w Lua — ustawiamy LAYOUT_MODE zamiast MAILS_DIRECTION
pkill -u "$USER" -f "conky.*$CONKY_FILE"
sed -i "s|^LAYOUT_MODE = \".*\"|LAYOUT_MODE = \"$SELECTED\"|" "$LUA_FILE"
sed -i "s|^\s*alignment\s*=.*|    alignment               = '$ALIGN_VAL',|" "$CONKY_FILE"

echo "Ustawiono: LAYOUT_MODE = \"$SELECTED\", alignment = '$ALIGN_VAL' (Conky zrestartowany)"
notify-send "Mail_python_amator80" "Ustawiono LAYOUT_MODE: $SELECTED, alignment: $ALIGN_VAL (Conky zrestartowany)"

sleep 1
rm -f /tmp/conky-automail-suite/.myconkyluadir.lock

