#!/bin/bash

# Zupix-Py2Lua-Mail-conky – 2.Podmiana_lokalizacji_zmiennych.sh (wersja połączona)

zen_echo() {
    # Używamy nazwy projektu kolegi dla spójności
    zenity --info --title="Mail_python_zupix – konfiguracja" --no-wrap --text="$1"
}

zen_error() {
    # Używamy nazwy projektu kolegi dla spójności
    zenity --error --title="Mail_python_zupix – błąd" --no-wrap --text="$1"
}

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$PROJECT_DIR" =~ [[:space:]] ]]; then
    MSG="Wykryto spacje w ścieżce projektu:\n$PROJECT_DIR\n\nZmień nazwę katalogu lub przenieś projekt do ścieżki bez spacji.\n(np. /home/user/Mail_python_zupix)\n\nTo ograniczenie Conky – pliki z taką ścieżką nie będą działać!"
    if command -v zenity &>/dev/null; then
        zen_error "$MSG"
    else
        echo -e "$MSG"
    fi
    exit 1
fi

if ! command -v zenity &>/dev/null; then
    echo "Brak programu 'zenity'. Zainstaluj pakiet zenity"
    exit 1
fi

# ==========================================================
#  SEKCJA 1: Przeniesiona tablica CONFIGS ze skryptu kolegi
# ==========================================================
CONFIGS=(
    "lua/e-mail.lua|NEW_MAIL_SOUND = \".*\"|NEW_MAIL_SOUND = \"$PROJECT_DIR/sound/nowy_mail.wav\"|NEW_MAIL_SOUND = \"$PROJECT_DIR/sound/nowy_mail.wav\"|.e-mail.lua.bak"
    "lua/e-mail.lua|MAIL_DISAPPEAR_SOUND = \".*\"|MAIL_DISAPPEAR_SOUND = \"$PROJECT_DIR/sound/remove_mail.wav\"|MAIL_DISAPPEAR_SOUND = \"$PROJECT_DIR/sound/remove_mail.wav\"|.e-mail.lua.bak"
    "lua/e-mail.lua|ENVELOPE_IMAGE = \".*\"|ENVELOPE_IMAGE = \"$PROJECT_DIR/icons/mail.png\"|ENVELOPE_IMAGE = \"$PROJECT_DIR/icons/mail.png\"|.e-mail.lua.bak"
    "lua/e-mail.lua|ATTACHMENT_ICON_IMAGE = \".*\"|ATTACHMENT_ICON_IMAGE = \"$PROJECT_DIR/icons/spinacz1.png\"|ATTACHMENT_ICON_IMAGE = \"$PROJECT_DIR/icons/spinacz1.png\"|.e-mail.lua.bak"
    "lua/e-mail.lua|local count_file = \".*\"|local count_file = \"$PROJECT_DIR/config/mail_count.conf\"|local count_file = \"$PROJECT_DIR/config/mail_count.conf\"|.e-mail.lua.bak"
    "lua/e-mail.lua|local preview_file = \".*\"|local preview_file = \"$PROJECT_DIR/config/mail_preview_lines.conf\"|local preview_file = \"$PROJECT_DIR/config/mail_preview_lines.conf\"|.e-mail.lua.bak"
    "conkyrc_mail|^ *lua_load *=.*|    lua_load = '$PROJECT_DIR/lua/e-mail.lua',|lua_load = '$PROJECT_DIR/lua/e-mail.lua'|.conkyrc_mail.bak"
)
# ==========================================================

for conf in "${CONFIGS[@]}"; do
    IFS="|" read -r FILE _ _ _ _ <<<"$conf"
    FULL_PATH="$PROJECT_DIR/$FILE"
    if [ ! -f "$FULL_PATH" ]; then
        zen_error "Nie znaleziono pliku: $FULL_PATH"
        exit 2
    fi
done

# Twój ulepszony, dynamiczny separator zostaje
Z_WIDTH=1200
CHAR_WIDTH=9
SEP_LEN=$((Z_WIDTH / CHAR_WIDTH))
SEP_LINE=$(printf '─%.0s' $(seq 1 $SEP_LEN))
SEPARATOR="<span foreground='gray'>$SEP_LINE</span>"

RESULTS=""
for conf in "${CONFIGS[@]}"; do
    IFS="|" read -r FILE SED_PATTERN SED_NEW RE_PATTERN BACKUP <<<"$conf"
    FULL_PATH="$PROJECT_DIR/$FILE"
    # Twoja lepsza nazwa pliku (bez ścieżki) zostaje
	BASENAME=$(basename "$FILE")
    BACKUP_PATH="$(dirname "$FULL_PATH")/$BACKUP"

    cp "$FULL_PATH" "$BACKUP_PATH"
    sed -i "s|$SED_PATTERN|$SED_NEW|g" "$FULL_PATH"

    # ==========================================================
    #  SEKCJA 2: Przeniesiona logika parsowania nazwy zmiennej
    # ==========================================================
    if [[ "$SED_PATTERN" =~ ^\^.*lua_load ]]; then
        VAR_NAME="lua_load ="
    elif [[ "$SED_PATTERN" =~ local[[:space:]]+([A-Za-z0-9_]+)[[:space:]]*=[[:space:]]*.* ]]; then
        VAR_NAME="${BASH_REMATCH[1]} ="
    elif [[ "$SED_PATTERN" =~ ([A-Za-z0-9_]+)[[:space:]]*=[[:space:]]*.* ]]; then
        VAR_NAME="${BASH_REMATCH[1]} ="
    elif [[ "$SED_PATTERN" =~ open\(\"([^\"]+)\" ]]; then
        VAR_NAME="open(\"${BASH_REMATCH[1]}\")"
    else
        VAR_NAME="$SED_PATTERN"
    fi
    # ==========================================================

    if grep -qF "$RE_PATTERN" "$FULL_PATH"; then
        NEW_LINE=$(grep -m1 -F "$RE_PATTERN" "$FULL_PATH")
        [ -z "$NEW_LINE" ] && NEW_LINE="(nie udało się znaleźć nowej wartości)"
        # Twój ulepszony format wiadomości z kolorami zostaje
        MSG="<b>OK</b>: Zmieniono wartość zmiennej \"<b>$VAR_NAME</b>\" w pliku <b>$BASENAME</b> (backup: $BACKUP)\nNowa wartość zmiennej: <b><tt><span foreground='green'>$NEW_LINE</span></tt></b>"
    else
        MSG="<b>BŁĄD:</b> Nie udało się podmienić wartości: <b>\"$RE_PATTERN\"</b> w pliku <b>$BASENAME!</b> (backup: <b>$BACKUP</b>)"
        zen_error "$MSG"
    fi

    RESULTS="$RESULTS$MSG\n$SEPARATOR\n"
done

# Twój ulepszony ekran podsumowania zostaje
SUMMARY_TEXT="<big><b>Wynik podmian:</b></big>\n$SEPARATOR\n$RESULTS\n<big><b>Wszystkie backupy zostały utworzone jako ukryte pliki w katalogach docelowych.</b></big>\n\n<big>Czy chcesz teraz uruchomić <b>3.menager_kont.sh</b>, aby skonfigurować konta e-mail?</big>"

SUMMARY_TEXT_ESCAPED="${SUMMARY_TEXT//&/&amp;}"

if zenity --question \
    --title="Sukces! 🎉" \
    --width=$Z_WIDTH \
    --ok-label="Tak" --cancel-label="Nie" \
    --text="$SUMMARY_TEXT_ESCAPED"
then
    if [ -f "$PROJECT_DIR/3.menager_kont.sh" ]; then
        bash "$PROJECT_DIR/3.menager_kont.sh" &
        exit 0
    else
        zen_error "Nie znaleziono pliku \"3.menager_kont.sh\"!"
        exit 1
    fi
else
    zen_echo "<b><big>✅ Zakończono konfigurację.</big></b>\nMożesz teraz ręcznie uruchomić skrypt: <b>3.menager_kont.sh</b>"
fi

exit 0
