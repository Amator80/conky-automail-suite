#!/bin/bash
cd "$(dirname "$(readlink -f "$0")")"
CACHE_DIR="/dev/shm/conky-automail-suite"

# Utwórz katalog, jeśli nie istnieje
mkdir -p "$CACHE_DIR"

# Zapewnij, że tylko jedna instancja skryptu działa w danym momencie
exec 200>/dev/shm/conky-automail-suite/.myconkyluadir.lock
if ! flock -n 200; then
    echo "Inna instancja skryptu już działa!"
    # Jeśli inna instancja działa, spróbuj przenieść okno YAD na pierwszy plan
    # (wymaga `wmctrl`, zainstaluj np. `sudo apt-get install wmctrl` jeśli go nie masz)
    if command -v wmctrl &> /dev/null; then
        wmctrl -a "Konfiguracja Widgetu Mail"
    fi
    exit 1
fi

# Pułapka, aby zwolnić blokadę przy zamykaniu skryptu (np. przez Ctrl+C)
trap 'rm -f /dev/shm/conky-automail-suite/.myconkyluadir.lock' EXIT

# === Ścieżki do plików ===
LUA_FILE="lua/e-mail.lua"
CONKY_FILE="conkyrc_mail"

# === Konfiguracja bazowa (dla skali 1.00) ===
BASE_WIDTH=1275
BASE_HEIGHT=510

declare -A ALIGNMENTS=(
    ["down"]="bottom_middle"
    ["up"]="top_middle"
    ["down_left"]="bottom_left"
    ["down_right"]="bottom_right"
    ["up_left"]="top_left"
    ["up_right"]="top_right"
)

# Przygotuj tekst z podglądami ASCII
ASCII_PREVIEWS="<tt>
 _______________________________________________
|         [mail]                                |
|         [mail]                                |
|         [mail]                                | - <b>DOWN</b>
|         [mail]                                |
|[koperta][E-MAIL: Konto] --------------------- |
 ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
 _______________________________________________
|[koperta][E-MAIL: Konto] --------------------- |
|         [mail]                                |
|         [mail]                                | - <b>UP</b>
|         [mail]                                |
|         [mail]                                |
 ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
 _______________________________________________
|         [mail]                                |
|         [mail]                                |
|         [mail]                                | - <b>DOWN_RIGHT</b>
|         [mail]                                |
|[koperta][E-MAIL: Konto]---------------------- |
 ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
 _______________________________________________
|[koperta][E-MAIL: Konto]---------------------- |
|         [mail]                                |
|         [mail]                                | - <b>UP_RIGHT</b>
|         [mail]                                |
|         [mail]                                |
 ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
 _______________________________________________
|[mail]                                         |
|[mail]                                         |
|[mail]                                         | - <b>DOWN_LEFT</b>
|[mail]                                         |
|[E-MAIL: Konto]---------------------- [koperta]|
 ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
 _______________________________________________
|[E-MAIL: Konto]---------------------- [koperta]|
|[mail]                                         |
|[mail]                                         | - <b>UP_LEFT</b>
|[mail]                                         |
|         [mail]                                |
 ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
</tt>"


# === GŁÓWNA PĘTLA APLIKACJI ===
# Pętla będzie działać, dopóki użytkownik nie kliknie "Zamknij" lub nie zamknie okna
while true; do

    # Odczytaj aktualne wartości, aby ustawić je jako domyślne w YAD
    CURRENT_LAYOUT=$(grep -oP 'LAYOUT_MODE = "\K[^"]+' "$LUA_FILE")
    CURRENT_SCALE_FACTOR=$(grep -oP 'GLOBAL_SCALE_FACTOR = \K[0-9.]+' "$LUA_FILE")
    CURRENT_SCALE_PERCENT=$(printf "%.0f" $(bc <<< "$CURRENT_SCALE_FACTOR * 100"))

    # === Logika listy rozwijanej, aby zawsze było 6 opcji ===
    # 1. Zdefiniuj statyczną listę wszystkich 6 opcji.
    #    Używamy separatora, który nie występuje w tekstach (np. potok |)
    BASE_LAYOUT_LIST="down_left: dolny lewy róg, blok maili w górę|down: okno na dole, blok maili w górę|up: okno na górze, blok maili w dół|down_right: dolny prawy róg, blok maili w górę|up_right: górny prawy róg, blok maili w dół|up_left: górny lewy róg, blok maili w dół"

    # 2. Użyj `sed`, aby dodać znacznik `^` na początku opcji, która jest aktualnie wybrana.
    #    Najpierw zamieniamy nasz separator '|' na nową linię, aby `sed` mógł działać na każdej opcji osobno.
    #    Potem z powrotem łączymy wszystko separatorem '!' wymaganym przez YAD.
    YAD_LAYOUT_OPTIONS=$(echo "$BASE_LAYOUT_LIST" | tr '|' '\n' | sed "s/^$CURRENT_LAYOUT:/\^&/" | tr '\n' '!')
    # Usuń ostatni, nadmiarowy separator '!'
    YAD_LAYOUT_OPTIONS=${YAD_LAYOUT_OPTIONS%?}

    FORM_OUTPUT=$(yad --form --center \
        --title="Konfiguracja Widgetu Mail" \
        --width=800 \
        --text-align=left \
        --text="<b>Podgląd dostępnych układów:</b>\n$ASCII_PREVIEWS\n<b>Wybierz układ i skalowanie widgetu:</b>" \
        --field="Układ:CB" \
            "$YAD_LAYOUT_OPTIONS" \
        --field="Skalowanie (%):SCL" \
            "$CURRENT_SCALE_PERCENT[50,200,5]" \
        --button="Zastosuj:0" \
        --button="Zamknij:1"
    )
    EXIT_CODE=$?

    # Jeśli użytkownik kliknął "Zamknij" (kod 1) lub zamknął okno (kod 252), zakończ pętlę
    if [ $EXIT_CODE -ne 0 ]; then
        break
    fi

    # === PRZETWARZANIE DANYCH ===
    IFS='|' read -r SELECTED_LAYOUT_FULL SCALE_VALUE _ <<< "$FORM_OUTPUT"
    SELECTED_LAYOUT="${SELECTED_LAYOUT_FULL%%:*}"
    SCALE_INTEGER="${SCALE_VALUE%.*}"

    if [ -z "$SELECTED_LAYOUT" ] || [ -z "$SCALE_INTEGER" ]; then
        notify-send "Mail Widget - Błąd" "Nie wybrano wartości. Spróbuj ponownie."
        continue # Wróć na początek pętli
    fi

    # === Obliczenia i modyfikacje plików ===
    SCALE_FACTOR=$(bc -l <<< "$SCALE_INTEGER / 100")
    NEW_WIDTH=$(printf "%.0f" $(bc -l <<< "$BASE_WIDTH * $SCALE_FACTOR"))
    NEW_HEIGHT=$(printf "%.0f" $(bc -l <<< "$BASE_HEIGHT * $SCALE_FACTOR"))
    FORMATTED_SCALE_FACTOR=$(LC_NUMERIC=C printf "%.2f" "$SCALE_FACTOR")
    ALIGN_VAL="${ALIGNMENTS[$SELECTED_LAYOUT]}"

    # === Blok zapisu ===
    sed -i "s|^LAYOUT_MODE = \".*\"|LAYOUT_MODE = \"$SELECTED_LAYOUT\"|" "$LUA_FILE"
    sed -i "s|^GLOBAL_SCALE_FACTOR = .*|GLOBAL_SCALE_FACTOR = $FORMATTED_SCALE_FACTOR|" "$LUA_FILE"
    sed -i "s|^\s*alignment\s*=.*|    alignment               = '$ALIGN_VAL',|" "$CONKY_FILE"
    sed -i "s|^\s*minimum_width\s*=.*|    minimum_width           = $NEW_WIDTH,|" "$CONKY_FILE"
    sed -i "s|^\s*minimum_height\s*=.*|    minimum_height          = $NEW_HEIGHT,|" "$CONKY_FILE"

    pkill -u "$USER" -f "conky.*$CONKY_FILE"

    # === Informacja zwrotna ===
    INFO_MSG="Zastosowano zmiany:
Układ: $SELECTED_LAYOUT
Skala: ${SCALE_INTEGER}%
Nowy rozmiar: ${NEW_WIDTH}x${NEW_HEIGHT}"
    
    notify-send "Mail Widget" "$INFO_MSG"
    sleep 1 # Daj chwilę na restart conky

done

# === Sprzątanie po zakończeniu pętli ===
notify-send "Mail Widget" "Konfigurator został zamknięty."
echo "Konfigurator zamknięty."
# Blokada pliku zostanie automatycznie zwolniona dzięki `trap`
