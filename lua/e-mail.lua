-- ====================================================================================
-- === SKALOWANIE WIDGETU - ZARZĄDZANE ZEWNĘTRZNIE ===
--
--                       !!! WAŻNE - NIE EDYTUJ RĘCZNIE !!!
--
-- Tym parametrem, oraz pozycją widgetu, zarządza dedykowany skrypt:
--          -> Konfiguracja_pozycji_layoutow_i_skali_conky.sh <-
-- Użyj go, aby dostosować rozmiar i położenie.
--
-- ----------------------------------------------------------------------------------
-- Dlaczego ta opcja musi być na samej górze?
-- Wiele opcji konfiguracyjnych poniżej (np. rozmiary czcionek, grubości ramek)
-- natychmiast używa tej wartości do obliczenia swoich wymiarów. Musi być ona
-- zdefiniowana jako pierwsza, aby reszta konfiguracji wczytała się poprawnie.
-- ----------------------------------------------------------------------------------
--
GLOBAL_SCALE_FACTOR = 1.00
-- ====================================================================================


------------------- KONFIGURACJA – TYLKO TUTAJ (wstęp + info) -------------------
--[[
#########################################################
#           											#
#           KONFIGURACJA – TYLKO TUTAJ                  #
#       Tutaj ustawiasz wszystko pod siebie – możesz    #
#       zmieniać parametry czcionek, kolorów itd.       #
#       Każda opcja ma komentarz co ustawia.            #
#       Poniżej tej sekcji jest kod GŁÓWNY –            #
#       tam nie grzeb jeśli nie wiesz co robisz!        #
#           											#
#########################################################
]]

-- ====================================================================================
-- === GŁÓWNE TŁO WIDGETU ("MLEKO") ===
-- ====================================================================================
-- Ustawienia tła. Możesz włączyć wypełnienie, ramkę, oba lub żadne.

-- Wypełnienie (kolor w środku)
MAIN_BG_FILL_ENABLE = true                        -- [true/false] Włącza kolorowe WYPEŁNIENIE tła.
MAIN_BG_FILL_COLOR = {0, 0, 0}                    -- Kolor tego wypełnienia (RGB).
MAIN_BG_FILL_ALPHA = 0.80                         -- Przezroczystość wypełnienia.

-- Ramka (obrys)
MAIN_BG_BORDER_ENABLE = true                      -- [true/false] Włącza RAMKĘ wokół tła.
MAIN_BG_BORDER_COLOR = {0, 240, 255}              -- Kolor tej ramki (RGB).
MAIN_BG_BORDER_ALPHA = 0.45                       -- Przezroczystość ramki.
MAIN_BG_BORDER_WIDTH = 5.0 * GLOBAL_SCALE_FACTOR  -- Grubość ramki.

-- Kształt i pozycja
MAIN_BG_RADIUS = 25 * GLOBAL_SCALE_FACTOR         -- Zaokrąglenie rogów.
MAIN_BG_PADDING = 1.0 * GLOBAL_SCALE_FACTOR       -- Wewnętrzny margines od krawędzi okna conky.
MAIN_BG_OFFSET_X = 0                              -- Ręczna korekta pozycji w osi X (+ w prawo, - w lewo).
MAIN_BG_OFFSET_Y = 0                              -- Ręczna korekta pozycji w osi Y (+ w dół, - w górę).


------------------- GŁÓWNE USTAWIENIA WIDGETU -------------------

---------------------------------------ZUPIX FIX BLOK----------------------------------------------------------
---------------  PRZEWIJANIE LISTY MAILI - Globalne zmienne przewijania listy maili ------------
-- === SCROLLING MAILS ===
MAIL_SCROLL_FILE = "/dev/shm/conky-automail-suite/conky_mail_scroll_offset"
SCROLL_TIMEOUT   = 15  -- sekundy; po tym czasie od ostatniej modyfikacji offset wraca do 0 (zazwyczaj timeouty nie skalujemy, bo czas to czas)

--------------- LAYOUT - Globalne zmienne związane z działaniem layoutów -----------------------
SHOW_SENDER_EMAIL = false              -- [true/false] Jeśli true, pokaże adres e-mail
SHOW_MAIL_PREVIEW = true              -- [true/false] Jeśli true, pokaże fragment treści maila pod tematem
----------------------------------------------------------------------------------------------------------------

------------------- DŹWIĘKI (nowa/znikająca wiadomość) -------------------
NEW_MAIL_SOUND_ENABLE = true                                                     -- [true/false] Włącz dźwięk nowej wiadomości pocztowej
MAIL_DISAPPEAR_SOUND_ENABLE = true                                               -- [true/false] Dźwięk przy znikaniu maila z listy
NEW_MAIL_SOUND = "/home/linux/Pulpit/conky-automail-suite/sound/nowy_mail.wav"          -- Ścieżka do dźwięku nowej poczty (WAV)
MAIL_DISAPPEAR_SOUND = "/home/linux/Pulpit/conky-automail-suite/sound/remove_mail.wav"  -- Ścieżka do dźwięku znikającego maila z listy (WAV)

------------------- KOPERTA – IKONA GŁÓWNA -------------------
SHOW_ENVELOPE_ICON = true                                                        -- [true/false] Pokazuj ikonę koperty
ENVELOPE_IMAGE = "/home/linux/Pulpit/conky-automail-suite/icons/mail.png"               -- Ścieżka do obrazka koperty (PNG)

ENVELOPE_SIZE = { w = 141 * GLOBAL_SCALE_FACTOR, h = 141 * GLOBAL_SCALE_FACTOR } -- Rozmiar (szerokość, wysokość) koperty w px


------------------- USTAWIENIA LISTY MAILI (ilość, odstępy, zachowanie) -------------------
-- NOWE: źródło wartości dla badge
--  "unread"          -> globalne nieprzeczytane z całej skrzynki (data.unread)
--  "all"             -> wszystkie z całej skrzynki (data.all)
--  "unread_cache" -> ile NIEPRZECZYTANYCH faktycznie jest na liście po ograniczeniu N
--                       (Python: data.unread_cache)
BADGE_SOURCE = "unread"
MAX_MAILS = 5                                     -- Maksymalna liczba wyświetlanych maili na liście (nie skalujemy, to jest ilość)
MAIL_PREVIEW_LINES = 5                            -- Ilość linii podglądu maila (0 = automatycznie) (nie skalujemy, to jest ilość)
PREVIEW_INDENT = false                            -- [true/false] Czy podgląd ma być z wcięciem
MAIL_ROW_SPACING = 30 * GLOBAL_SCALE_FACTOR       -- Odstęp pionowy między mailami (px)
MAIL_PREVIEW_SPACING = 7 * GLOBAL_SCALE_FACTOR    -- Odstęp pionowy między tematem a podgląдом maila (px)
META_LINE_SPACING = 7 * GLOBAL_SCALE_FACTOR       -- Odstęp pionowy między preview a meta-linią (px, czyli trzecia linia)
FROM_TO_SUBJECT_GAP = 12 * GLOBAL_SCALE_FACTOR    -- Odstęp poziomy między nadawcą a tematem (px)

------------------- MLECZNA POŚWIATA POD KAŻDYM MAILEM – KONFIGURACJA -------------------
-- Ten blok kontroluje WYGLĄD tła (kolor, ramkę, rogi) oraz jego WYMIARY POZIOME.
-- Wymiary pionowe (wysokość i margines Y) są zarządzane w sekcji PROFILI WYSOKOŚCI poniżej.

-- Wypełnienie (kolor w środku)
PER_MAIL_MILK_FILL_ENABLE = true                  -- [true/false] Włącza wypełnienie „mlekiem” pod każdym mailem
PER_MAIL_MILK_FILL_COLOR = {255, 255, 255}        -- Kolor wypełnienia (RGB, np. biały, niebieski, czerwony)
PER_MAIL_MILK_FILL_ALPHA = 0.15                   -- Przezroczystość wypełnienia (0 = całkiem przezroczysty, 1 = pełny kolor)

-- Ramka (obramowanie)
PER_MAIL_MILK_BORDER_ENABLE = false                     -- [true/false] Włącza ramkę wokół poświaty
PER_MAIL_MILK_BORDER_COLOR = {175, 238, 238}            -- Kolor ramki (RGB, np. niebieski, szary itd.)
PER_MAIL_MILK_BORDER_ALPHA = 0.35                       -- Przezroczystość ramki (0 = niewidoczna, 1 = pełny kolor)
PER_MAIL_MILK_BORDER_WIDTH = 4 * GLOBAL_SCALE_FACTOR    -- Grubość ramki w pikselach

-- Wygląd i wymiary poziome poświaty
PER_MAIL_MILK_RADIUS =  15 * GLOBAL_SCALE_FACTOR     -- Zaokrąglenie rogów poświaty oraz ramki
PER_MAIL_MILK_MARGIN_X = -30 * GLOBAL_SCALE_FACTOR   -- Dodatkowy margines na szerokość (ujemna wartość = większa poświata)
PER_MAIL_MILK_WIDTH = 1102 * GLOBAL_SCALE_FACTOR     -- Szerokość poświaty (dopasuj do szerokości sekcji maili)

------------------- KONFIGURACJA PROFILI UKŁADU (DLA 1, 2 LUB 3 LINII) -------------------
-- Zdefiniuj tutaj idealne wymiary dla każdego możliwego wariantu wyświetlania.
-- Skrypt automatycznie wybierze odpowiedni profil na podstawie tego, czy
-- włączone są SHOW_MAIL_PREVIEW oraz META_LINE_ENABLE.

-- PROFIL 1: Gdy wyświetlana jest TYLKO 1 LINIA (sam Nadawca/Temat)
HEIGHT_1_LINE                 = 75 * GLOBAL_SCALE_FACTOR    -- Wysokość "mleka" dla 1 linii
SPACING_1_LINE                = 95 * GLOBAL_SCALE_FACTOR    -- Całkowity odstęp pionowy do następnego maila
MARGIN_Y_1_LINE               = -27 * GLOBAL_SCALE_FACTOR   -- Korekta pionowa TŁA "mleka" (góra/dół)
SENDER_OFFSET_Y_1_LINE        = 18 * GLOBAL_SCALE_FACTOR    -- Korekta pionowa linii Nadawca/Temat
ATTACHMENT_ICON_OFFSET_1_LINE = { dx = -33 * GLOBAL_SCALE_FACTOR, dy = -27 * GLOBAL_SCALE_FACTOR } -- Przesunięcie ikony załącznika (x, y)
ATTACHMENT_DOT_OFFSET_1_LINE  = { dx = -15 * GLOBAL_SCALE_FACTOR, dy = -30 * GLOBAL_SCALE_FACTOR } -- Przesunięcie kropki załącznika (x, y)

-- PROFIL 2: Gdy wyświetlane są 2 LINIE (np. Nadawca/Temat + Podgląd LUB Nadawca/Temat + Meta)
HEIGHT_2_LINES                = 87 * GLOBAL_SCALE_FACTOR    -- Wysokość "mleka" dla 2 linii
SPACING_2_LINES               = 96 * GLOBAL_SCALE_FACTOR    -- Całkowity odstęp pionowy do następnego maila
MARGIN_Y_2_LINES              = -27 * GLOBAL_SCALE_FACTOR   -- Korekta pionowa TŁA "mleka" (góra/dół)
SENDER_OFFSET_Y_2_LINES       = 5 * GLOBAL_SCALE_FACTOR     -- Korekta pionowa linii Nadawca/Temat
PREVIEW_OFFSET_Y_2_LINES      = 40 * GLOBAL_SCALE_FACTOR    -- Odstęp od góry do linii podglądu (jeśli włączona)
META_OFFSET_Y_2_LINES         = 40 * GLOBAL_SCALE_FACTOR    -- Odstęp od góry do linii meta (jeśli włączona)
ATTACHMENT_ICON_OFFSET_2_LINES = { dx = -33 * GLOBAL_SCALE_FACTOR, dy = -10 * GLOBAL_SCALE_FACTOR } -- Przesunięcie ikony załącznika (x, y)
ATTACHMENT_DOT_OFFSET_2_LINES  = { dx = -15 * GLOBAL_SCALE_FACTOR, dy = -15 * GLOBAL_SCALE_FACTOR } -- Przesunięcie kropki załącznika (x, y)

-- PROFIL 3: Gdy wyświetlane są WSZYSTKIE 3 LINIE (Nadawca/Temat + Podgląd + Meta)
HEIGHT_3_LINES                = 85 * GLOBAL_SCALE_FACTOR    -- Wysokość "mleka" dla 3 linii
SPACING_3_LINES               = 96 * GLOBAL_SCALE_FACTOR    -- Całkowity odstęp pionowy do następnego maila
MARGIN_Y_3_LINES              = -23 * GLOBAL_SCALE_FACTOR   -- Korekta pionowa TŁA "mleka" (góra/dół)
SENDER_OFFSET_Y_3_LINES       = 0 * GLOBAL_SCALE_FACTOR     -- Korekta pionowa linii Nadawca/Temat
PREVIEW_OFFSET_Y_3_LINES      = 27 * GLOBAL_SCALE_FACTOR    -- Odstęp od góry bloku do linii podglądu (preview)
META_OFFSET_Y_3_LINES         = 53 * GLOBAL_SCALE_FACTOR    -- Odstęp od góry bloku do linii z meta-danymi
ATTACHMENT_ICON_OFFSET_3_LINES = { dx = -33 * GLOBAL_SCALE_FACTOR, dy = -15 * GLOBAL_SCALE_FACTOR } -- Przesunięcie ikony załącznika (x, y)
ATTACHMENT_DOT_OFFSET_3_LINES  = { dx = -15 * GLOBAL_SCALE_FACTOR, dy = -15 * GLOBAL_SCALE_FACTOR } -- Przesunięcie kropki załącznika (x, y)

------------------- ANIMACJA PULSOWANIA TŁA I RAMKI NOWEGO MAILA -------------------
-- Efekty pulsowania dla nowych maili (zarówno tła, jak i ramki) działają NIEZALEŻNIE
-- od globalnych, statycznych ustawień 'mlecznej poświaty'.
-- Oznacza to, że możesz mieć wyłączone stałe tło (`PER_MAIL_MILK_FILL_ENABLE = false`)
-- oraz stałą ramkę (`PER_MAIL_MILK_BORDER_ENABLE = false`) dla wszystkich maili,
-- a animacja i tak pojawi się dla nowo odebranej wiadomości, aby ją wyróżnić.

PULSE_ANIM_ENABLE = true              -- [true/false] Włącz pulsowanie tła ("mleka") dla nowych maili.
PULSE_ANIM_DELAY = 1                  -- [0/...] Czas w sekundach opóźnienia przed rozpoczęciem pulsowania.
PULSE_ANIM_DURATION = 8.0             -- Czas trwania animacji w sekundach. Po tym czasie element wraca do normalnego wyglądu.
PULSE_ANIM_SPEED = 5.0                -- Szybkość pulsowania (większa wartość = szybsze migotanie).

-- === Ustawienia pulsowania WYPEŁNIENIA (TŁA) ===
-- Ustaw DOKŁADNY zakres przezroczystości dla animacji tła
PULSE_ANIM_MIN_ALPHA = 0.25           -- Minimalna przezroczystość w trakcie pulsowania (dolna granica).
PULSE_ANIM_MAX_ALPHA = 0.45           -- Maksymalna przezroczystość w trakcie pulsowania (górna granica).

-- Opcje koloru pulsowania tła
PULSE_ANIM_USE_CUSTOM_COLOR = true    -- [true/false] Ustaw 'true', jeśli pulsowanie tła ma używać niestandardowego koloru/kolorów.
PULSE_ANIM_USE_TWO_COLORS = true      -- [true/false] Ustaw 'true', aby tło pulsowało MIĘDZY dwoma kolorami. Jeśli 'false', użyje tylko KOLORU A.
PULSE_ANIM_CUSTOM_COLOR_A = {255, 60, 0}   -- KOLOR A (RGB) - kolor startowy lub jedyny kolor pulsowania.
PULSE_ANIM_CUSTOM_COLOR_B = {0, 255, 255}  -- KOLOR B (RGB) - kolor docelowy, do którego będzie przechodzić animacja.

-- === Ustawienia pulsowania RAMKI ===
PULSE_BORDER_ANIM_ENABLE = true       -- [true/false] Włącz pulsowanie RAMKI wokół "mleka" dla nowych maili.

-- Ustaw DOKŁADNY zakres przezroczystości dla animacji ramki
PULSE_BORDER_ANIM_MIN_ALPHA = 0.45    -- Minimalna przezroczystość ramki w trakcie pulsowania.
PULSE_BORDER_ANIM_MAX_ALPHA = 0.75    -- Maksymalna przezroczystość ramki w trakcie pulsowania.

-- Opcje koloru pulsowania ramki
PULSE_BORDER_ANIM_USE_TWO_COLORS = true -- [true/false] Ustaw 'true', aby ramka pulsowała MIĘDZY dwoma kolorami.
PULSE_BORDER_ANIM_CUSTOM_COLOR_A = {255, 255, 0} -- KOLOR A (RGB) ramki.
PULSE_BORDER_ANIM_CUSTOM_COLOR_B = {220, 20, 60} -- KOLOR B (RGB) ramki.

------------------- FORMATOWANIE "NADAWCA" (FROM) -------------------
FROM_FONT_NAME = "Arial"          -- Nazwa czcionki (np. Arial, Ubuntu, Noto Sans)
FROM_FONT_SIZE = 18 * GLOBAL_SCALE_FACTOR            -- Rozmiar czcionki nadawcy w px
FROM_FONT_BOLD = true                                -- [true/false] Czy tekst nadawcy ma być pogrubiony?
FROM_FONT_ITALIC = false                             -- [true/false] Czy tekst nadawcy ma być pochylony? (italic)
FROM_COLOR_TYPE = "custom"                           -- Kolor tekstu nadawcy: "white", "black" lub "custom"
FROM_COLOR_CUSTOM = {0.98, 0.145, 0.196}             -- Jeśli powyżej "custom", to tu ustawiasz RGB (0-1 lub 0-255)
FROM_MAX_WIDTH = 400 * GLOBAL_SCALE_FACTOR           -- **Maksymalna szerokość pola nadawcy w pikselach** (jeśli tekst za długi, może się przewijać)

-- PRZEWIJANIE NADAWCY (dla długich nazw, np. korporacyjnych adresów)
FROM_SCROLL_ENABLE = true                            -- [true/false] Czy przewijać nadawcę jeśli się nie mieści w polu?
FROM_SCROLL_SPEED = 37 * GLOBAL_SCALE_FACTOR         -- Prędkość przewijania w px/s (im wyższa, tym szybciej)
FROM_SCROLL_REPEAT = 2                               -- Ile razy przewinąć nadawcę (potem się zatrzyma)
FROM_SCROLL_DELAY = 1                                -- Opóźnienie startu przewijania (s) (zazwyczaj timeouty nie skalujemy)
FROM_SCROLL_PAUSE_END = 0.25                         -- Czas pauzy w sekundach PO zakończeniu przewijania, a PRZED powtórzeniem.
FROM_SCROLL_EASE = "easeOut"                         -- Styl przewijania: "easeOut" (wolniejsze końcówki), "linear" (stałe tempo)
FROM_SCROLL_EXTRA = 0 * GLOBAL_SCALE_FACTOR          -- Dodatkowy "bufor" na końcu przewijania (px)

------------------- FORMATOWANIE "TEMAT" (SUBJECT) -------------------
SUBJECT_FONT_NAME = "Arial"         -- Czcionka tematu
SUBJECT_FONT_SIZE = 18 * GLOBAL_SCALE_FACTOR          -- Rozmiar czcionki tematu
SUBJECT_FONT_BOLD = true                              -- [true/false] Czy temat ma być pogrubiony?
SUBJECT_FONT_ITALIC = false                           -- [true/false] Czy temat ma być pochylony?
SUBJECT_COLOR_TYPE = "white"                          -- Kolor tematu: "white", "black", "custom"
SUBJECT_COLOR_CUSTOM = {0.424, 1, 0}                  -- Własny kolor RGB tematu (gdy powyżej "custom")
SUBJECT_MAX_WIDTH = 1065 * GLOBAL_SCALE_FACTOR        -- **Maksymalna szerokość pola tematu w px**

-- PRZEWIJANIE TEMATU (Subject)
SUBJECT_SCROLL_ENABLE = true                          -- [true/false] Czy przewijać temat jeśli się nie mieści?
SUBJECT_SCROLL_SPEED = 37 * GLOBAL_SCALE_FACTOR       -- Prędkość przewijania tematu (px/s)
SUBJECT_SCROLL_REPEAT = 2                             -- Ile razy przewinąć temat
SUBJECT_SCROLL_DELAY = 1                              -- Opóźnienie startu przewijania (s) (zazwyczaj timeouty nie skalujemy)
SUBJECT_SCROLL_PAUSE_END = 0.25                       -- Czas pauzy w sekundach PO zakończeniu przewijania, a PRZED powtórzeniem.
SUBJECT_SCROLL_EASE = "easeOut"                       -- Styl przewijania: "easeOut" (płynnie), "linear" (stałe tempo)
SUBJECT_SCROLL_EXTRA = 36 * GLOBAL_SCALE_FACTOR       -- Dodatkowy bufor na końcu przewijania (px)

------------------- FORMATOWANIE "TREŚĆ PODGLĄDU" (PREVIEW) -------------------
PREVIEW_FONT_NAME = "Arial"                           -- Czcionka podglądu (preview)
PREVIEW_FONT_SIZE = 16 * GLOBAL_SCALE_FACTOR        -- Rozmiar czcionki podglądu
PREVIEW_FONT_BOLD = true                              -- [true/false] Czy tekst preview ma być pogrubiony?
PREVIEW_FONT_ITALIC = false                           -- [true/false] Czy tekst preview ma być pochylony?
PREVIEW_COLOR_TYPE = "custom"                         -- Kolor preview: "white", "black", "custom"
PREVIEW_COLOR_CUSTOM = {22, 217, 197}                 -- Własny kolor RGB (jeśli wybrałeś "custom")
PREVIEW_MAX_WIDTH = 1065 * GLOBAL_SCALE_FACTOR        -- **Maksymalna szerokość pola preview w px**

-- PRZEWIJANIE PREVIEW
PREVIEW_SCROLL_ENABLE = true                          -- [true/false] Czy przewijać podgląd jeśli za długi?
PREVIEW_SCROLL_SPEED = 67 * GLOBAL_SCALE_FACTOR       -- Prędkość przewijania preview (px/s)
PREVIEW_SCROLL_REPEAT = 2                             -- Ile razy przewinąć podgląd (preview)
PREVIEW_SCROLL_DELAY = 1                              -- Opóźnienie startu przewijania (s) (zazwyczaj timeouty nie skalujemy)
PREVIEW_SCROLL_PAUSE_END = 0.25                       -- Czas pauzy w sekundach PO zakończeniu przewijania, a PRZED powtórzeniem.
PREVIEW_SCROLL_EASE = "easeOut"                       -- Styl przewijania: "easeOut", "linear"
PREVIEW_SCROLL_EXTRA = 36 * GLOBAL_SCALE_FACTOR       -- Bufor przewijania na końcu (px)

------------------- FORMATOWANIE "ALIASU" KONTA (np. [Nazwa Firmy]) -------------------
ALIAS_FONT_NAME = "Arial"                             -- Nazwa czcionki dla aliasu (np. Ubuntu, Noto Sans)
ALIAS_FONT_SIZE = 18 * GLOBAL_SCALE_FACTOR            -- Rozmiar czcionki aliasu w px
ALIAS_FONT_BOLD = true                                -- [true/false] Czy tekst aliasu ma być pogrubiony?
ALIAS_FONT_ITALIC = false                             -- [true/false] Czy tekst aliasu ma być pochylony?
-- UWAGA: Kolor aliasu ustawia się bezpośrednio w menedżerze kont podczas edycji.

------------------- BADGE (KÓŁKO Z LICZBĄ NIEPRZECZYTANYCH) -------------------
BADGE_COLOR_TYPE = "red"                              -- Kolor środka badge: "red", "white", "black", "custom"
BADGE_COLOR_CUSTOM = {22, 217, 197}                   -- Własny kolor RGB środka (jeśli powyżej "custom")
BADGE_TEXT_COLOR_TYPE = "white"                       -- Kolor cyfry (liczby maili) na badge
BADGE_TEXT_COLOR_CUSTOM = {255, 255, 0}               -- Własny kolor cyfry (gdy "custom")
BADGE_BORDER_COLOR_TYPE = "white"                     -- Kolor obwódki badge
BADGE_BORDER_COLOR_CUSTOM = {0, 255, 0}               -- Własny kolor obwódki (gdy "custom")
SHOW_BADGE = true                                     -- [true/false] Pokazuj kółko z liczbą maili (badge)

------------------- KROPKA LUB IKONA ZAŁĄCZNIKA PRZY MAILU -------------------
ATTACHMENT_DOT_ENABLE = false                         -- [true/false] Czy wyświetlać kropkę przy nadawcy, jeśli mail ma załącznik?
ATTACHMENT_DOT_COLOR_TYPE = "orange"                  -- Kolor kropki: "orange", "white", "black", "custom"
ATTACHMENT_DOT_COLOR_CUSTOM = {255, 140, 0}           -- Własny kolor kropki (jeśli "custom")
ATTACHMENT_DOT_RADIUS = 7 * GLOBAL_SCALE_FACTOR       -- Promień kropki (px)

ATTACHMENT_ICON_ENABLE = true                         -- [true/false] Czy wyświetlać ikonę zamiast kropki?
ATTACHMENT_ICON_SIZE = { w = 36 * GLOBAL_SCALE_FACTOR, h = 42 * GLOBAL_SCALE_FACTOR }      -- Rozmiar ikony (szerokość, wysokość)
ATTACHMENT_ICON_ANGLE = 0                             -- Obrót ikony (w stopniach)
ATTACHMENT_ICON_MIRROR = false                        -- [true/false] Lustrzane odbicie ikony
ATTACHMENT_ICON_IMAGE = "/home/linux/Pulpit/conky-automail-suite/icons/spinacz1.png" -- Ścieżka do ikony (np. spinacz)
-- UWAGA: Pozycja ikony/kropki (OFFSET) została przeniesiona do KONFIGURACJA PROFILI UKŁADU (DLA 1, 2 LUB 3 LINII)


------------------- MIGANIE ZAŁĄCZNIKA (WIDOCZNE OPCJE) -------------------
ATTACHMENT_BLINK_ENABLE = true      -- [true/false] Miganie kropki/ikony dla NOWYCH maili z załącznikiem
ATTACHMENT_BLINK_DELAY = 8          -- [0/...] Czas w sekundach opóźnienia przed rozpoczęciem migania.
ATTACHMENT_BLINK_COUNT  = 10         -- Ile razy ma „zamrugać” (ile cykli ON). Potem pozostaje widoczny na stałe
ATTACHMENT_BLINK_INTERVAL = 1.0     -- Szybkość migania (w sekundach). 1.0 = 1s ON, 1s OFF.


------------------- WŁASNY NAGŁÓWEK/NOTKA -------------------
CUSTOM_TEXT_ENABLE = true             -- [true/false] Czy wyświetlać własny tekst?
CUSTOM_TEXT_VALUE = "Mail@Desk Twój osobisty asystent poczty" -- Twój tekst nagłówka
CUSTOM_TEXT_FONT = "Arial"            -- Czcionka tekstu
CUSTOM_TEXT_SIZE = 27 * GLOBAL_SCALE_FACTOR   -- Rozmiar tekstu
CUSTOM_TEXT_BOLD = true               -- [true/false] Pogrubienie tekstu?
CUSTOM_TEXT_ITALIC = false            -- [true/false] Pochylenie tekstu?
CUSTOM_TEXT_COLOR_TYPE = "custom"     -- Kolor: "white", "black", "custom"
CUSTOM_TEXT_COLOR_CUSTOM = {255, 60, 0}  -- Własny kolor RGB tekstu (jeśli custom)


------------------- SEPARATOR (LINIA OZDOBNA MIĘDZY NAGŁÓWKIEM A MAJLAMI) -------------------
SEPARATOR_ENABLE = true               -- [true/false] Czy wyświetlać linię oddzielającą?
SEPARATOR_LENGTH = 550 * GLOBAL_SCALE_FACTOR  -- Długość linii w px
SEPARATOR_COLOR_TYPE = "white"        -- Kolor linii: "white", "black", "custom"
SEPARATOR_COLOR_CUSTOM = {150, 150, 150}  -- Własny kolor RGB (gdy "custom")
SEPARATOR_WIDTH = 3 * GLOBAL_SCALE_FACTOR   -- Grubość linii (px)

------------------- 3 LINIA META (POD MAILEM – DANE TECHNICZNE, GODZINA, IP itp.) -------------------
META_LINE_ENABLE = true   -- [true/false] Czy pokazywać trzecią linię pod każdym mailem (meta-info)
META_LINE_ORDER = {       -- Tutaj ustawiasz w jakiej kolejności będą wyświetlane informacje w meta-linii:
    "age_text",   -- ile temu (np. "2h temu")
    "hour",       -- godzina odebrania maila
    "date",       -- data odebrania maila
    "ip",         -- IP z prefixem IP:
    "ip_city",    -- miasto
    "isp",        -- operator
    "agent",      -- user-agent (np. Thunderbird)
    "country",    -- kraj
    "mobile",     -- czy wysłany z mobilnego
}
META_SHOW_IP = true         -- [true/false] Czy pokazywać IP (jeśli nie operator mobilny)
META_SHOW_IP_CITY = true    -- [true/false] Czy pokazywać miasto (jeśli nie operator mobilny)
META_SHOW_IP_ISP = true     -- [true/false] Czy pokazywać nazwę operatora internetu (ISP)
META_SHOW_AGE_TEXT = true   -- [true/false] Czy pokazywać "wiek" maila ("2h temu" itd.)
META_SHOW_DATETIME = true   -- [true/false] Czy pokazywać datę/godzinę odebrania maila
META_SHOW_AGENT = true      -- [true/false] Czy pokazywać User-Agent (np. Thunderbird, Gmail)
META_SHOW_COUNTRY = true    -- [true/false] Czy pokazywać kraj nadawcy
META_SHOW_MOBILE = true     -- [true/false] Czy pokazywać "MOBILNY" jeśli mail wysłany przez sieć mobilną
META_LINE_MAX_WIDTH = 1050 * GLOBAL_SCALE_FACTOR    -- **Maksymalna szerokość meta-linii w px**
META_LINE_SCROLL_ENABLE = true    -- [true/false] Czy przewijać meta-linię, jeśli za długa
META_LINE_SCROLL_SPEED = 37 * GLOBAL_SCALE_FACTOR    -- Prędkość przewijania (px/s)
META_LINE_SCROLL_REPEAT = 2         -- Ile razy przewinąć meta-linię
META_LINE_SCROLL_DELAY = 1          -- Opóźnienie startu przewijania (sekundy) (zazwyczaj timeouty nie skalujemy)
META_LINE_SCROLL_PAUSE_END = 0.25   --  Czas pauzy w sekundach PO zakończeniu przewijania, a PRZED powtórzeniem.
META_LINE_SCROLL_EASE = "easeOut" -- Styl przewijania: "easeOut" lub "linear"
META_LINE_SCROLL_EXTRA = 36 * GLOBAL_SCALE_FACTOR        -- Bufor przewijania na końcu (px)

-- Kolory poszczególnych informacji w meta-linii (podaj w formacie 0-1, np. 1 = 255)
META_COLOR_IP = {144, 182, 238}       -- Kolor IP
META_COLOR_CITY = {144, 182, 238}       -- Kolor miasta
META_COLOR_ISP = {144, 182, 238}        -- Kolor operatora
META_COLOR_AGE = {144, 182, 238}        -- Kolor "wiek maila"
META_COLOR_DATETIME = {144, 182, 238}   -- Kolor daty/godziny
META_COLOR_AGENT = {144, 182, 238}      -- Kolor User-Agent
META_COLOR_COUNTRY = {144, 182, 238}    -- Kolor kraju
META_COLOR_MOBILE = {144, 182, 238}     -- Kolor napisu MOBILNY
META_COLOR_SEPARATOR = {134, 255, 0}    -- kolor RGB separatora (separator między polami w meta-linii)

META_LINE_FONT_NAME = "Arial"         -- Czcionka meta-linii
META_LINE_FONT_SIZE = 16 * GLOBAL_SCALE_FACTOR      -- Rozmiar czcionki meta-linii
META_LINE_FONT_BOLD = true            -- [true/false] Pogrubienie meta-linii
META_LINE_FONT_ITALIC = false         -- [true/false] Pochylenie meta-linii

META_DATE_FORMAT = "HH:MM DD-MM-YYYY" -- Format daty/godziny (do wyboru kilku typów)
META_DATE_FORMAT_CUSTOM = "%H:%M:%S %d.%m.%Y"      -- Twój własny format, jeśli wybrałeś "custom"

------------------------------------------------------------------------------------------
-- *** KONIEC KONFIGURACJI. PONIŻEJ JEST KOD GŁÓWNY – NIE RUSZAĆ! ***
------------------------------------------------------------------------------------------

--- OSTATECZNA POPRAWKA v5 START (ZMIANA 1/4) ---
-- ====================================================================================
-- === STAN SKRYPTU ===
-- ====================================================================================

-- [[ OPTYMALIZACJA START ]]
-- Zmienne do buforowania zawartości plików w pamięci
local cached_mail_data = nil
local last_mail_cache_mtime = 0
local cached_scroll_offset = 0
local last_scroll_offset_mtime = 0
-- [[ OPTYMALIZACJA KONIEC ]]

if mail_widget_state == nil then
    mail_widget_state = {
        -- Czas ostatniej *potwierdzonej* akcji użytkownika (z pliku scroll.active)
        last_user_interaction_time = 0,
        -- Flaga, która mówi, czy właśnie nastąpił auto-reset
        auto_reset_occurred = false
    }
end
-- ====================================================================================
--- OSTATECZNA POPRAWKA v5 KONIEC ---

-- Ustawienie ścieżki, aby Lua znalazła lokalny plik dkjson.lua
local script_path = debug.getinfo(1, "S").source:match("@(.*/)")
package.path = package.path .. ";" .. script_path .. "?.lua"

require 'cairo'
CAIRO_FORMAT_ARGB32 = 0
pcall(require, 'cairo_xlib')
local json = require("dkjson")

--- POCZĄTEK MODYFIKACJI ---
-- ====================================================================================
-- === UTRWALANIE STANU "WIDZIANYCH" MAILI ORAZ STANU PRZEWIJANIA ===
-- ====================================================================================
local KNOWN_UIDS_FILE = "/dev/shm/conky-automail-suite/known_uids.json"
local SCROLL_STATES_FILE = "/dev/shm/conky-automail-suite/scroll_states.json"
--- ZMIANA START ---
-- Plik-sygnał do ręcznego wymuszenia przewijania tekstów
local FORCE_SCROLL_TRIGGER_FILE = "/dev/shm/conky-automail-suite/force_scroll_trigger"
--- ZMIANA KONIEC ---
-- [[ POPRAWKA PRZEWIJANIA ]] Plik przechowujący UIDy maili widocznych w ostatniej klatce
local LAST_VISIBLE_UIDS_FILE = "/dev/shm/conky-automail-suite/last_visible_uids.json"

local function load_previously_known_uids()
    local f = io.open(KNOWN_UIDS_FILE, "r")
    if not f then return {} end
    
    local content = f:read("*a")
    f:close()
    
    local ok, uids_array = pcall(json.decode, content)
    if not ok or type(uids_array) ~= "table" then
        return {}
    end
    
    local uids_set = {}
    for _, uid in ipairs(uids_array) do
        uids_set[uid] = true
    end
    print("[INFO] Wczytano " .. #uids_array .. " znanych UID z poprzedniej sesji.")
    return uids_set
end

local function save_previously_known_uids(uids_set)
    if type(uids_set) ~= "table" then return end

    local uids_array = {}
    for uid, _ in pairs(uids_set) do
        table.insert(uids_array, uid)
    end
    
    local ok, json_string = pcall(json.encode, uids_array)
    if not ok then
        print("[ERROR] Nie udało się zakodować listy UID do JSON: " .. tostring(json_string))
        return
    end
    
    local f = io.open(KNOWN_UIDS_FILE, "w")
    if f then
        f:write(json_string)
        f:close()
    else
        print("[ERROR] Nie udało się otworzyć pliku do zapisu znanych UID: " .. KNOWN_UIDS_FILE)
    end
end

-- [[ POPRAWKA PRZEWIJANIA START ]]
-- ====================================================================================
-- === UTRWALANIE STANU WIDOCZNYCH MAILI (PAMIĘĆ KRÓTKOTRWAŁA) ===
-- Te funkcje zapobiegają restartowi animacji po przeładowaniu skryptu Conky.
-- ====================================================================================

local function load_last_visible_uids()
    local f = io.open(LAST_VISIBLE_UIDS_FILE, "r")
    if not f then return {} end

    local content = f:read("*a")
    f:close()

    local ok, uids_array = pcall(json.decode, content)
    if not ok or type(uids_array) ~= "table" then
        return {}
    end

    local uids_set = {}
    for _, uid in ipairs(uids_array) do
        uids_set[uid] = true
    end
    return uids_set
end

local function save_last_visible_uids(uids_set)
    if type(uids_set) ~= "table" then return end

    local uids_array = {}
    for uid, _ in pairs(uids_set) do
        table.insert(uids_array, uid)
    end

    local ok, json_string = pcall(json.encode, uids_array)
    if not ok then
        return
    end

    local f = io.open(LAST_VISIBLE_UIDS_FILE, "w")
    if f then
        f:write(json_string)
        f:close()
    end
end
-- [[ POPRAWKA PRZEWIJANIA KONIEC ]]

-- ====================================================================================
-- === UTRWALANIE STANU PRZEWIJANIA TEKSTU ===
-- Te funkcje zapisują i wczytują stan animacji przewijania (nadawcy, tematu itd.),
-- aby uniknąć resetowania animacji po każdym przeładowaniu skryptu Conky.
-- ====================================================================================

local function save_scroll_states(from_states, subject_states, preview_states, meta_states)
    local all_states = {
        from = from_states,
        subject = subject_states,
        preview = preview_states,
        meta = meta_states
    }
    
    local ok, json_string = pcall(json.encode, all_states)
    if not ok then
        return
    end
    
    local f = io.open(SCROLL_STATES_FILE, "w")
    if f then
        f:write(json_string)
        f:close()
    else
        print("[ERROR] Nie udało się otworzyć pliku do zapisu stanów przewijania: " .. SCROLL_STATES_FILE)
    end
end

local function load_scroll_states()
    local f = io.open(SCROLL_STATES_FILE, "r")
    if not f then
        return {}, {}, {}, {}
    end
    
    local content = f:read("*a")
    f:close()
    
    local ok, decoded_states = pcall(json.decode, content)
    if not ok or type(decoded_states) ~= "table" then
        print("[WARN] Nie udało się wczytać stanów przewijania. Plik może być uszkodzony. Zaczynam od nowa.")
        return {}, {}, {}, {}
    end
    
    return decoded_states.from or {}, decoded_states.subject or {}, decoded_states.preview or {}, decoded_states.meta or {}
end
--- KONIEC MODYFIKACJI ---

-- Inicjalizuj listę, wczytując stan z pliku
local previously_known_uids = load_previously_known_uids()

-- =========================================================================
-- === ZMIANA: OPTYMALIZACJA ZAPISU (START) ===
-- =========================================================================
-- Te zmienne przechowują kopię ostatnio zapisanych danych.
-- Dzięki nim unikamy niepotrzebnych zapisów na dysk w każdej klatce.
local last_saved_scroll_states = {}
-- [[ OPTYMALIZACJA ZAPISU v2 ]]
local last_saved_visible_uids = {}

-- Funkcja pomocnicza do głębokiego porównywania tablic.
-- Jest niezbędna, aby wykryć, czy stan faktycznie się zmienił.
local function are_tables_equal(t1, t2)
    -- Szybkie sprawdzenie typów i ilości kluczy
    if type(t1) ~= "table" or type(t2) ~= "table" then return t1 == t2 end
    local keys1, keys2 = 0, 0
    for _ in pairs(t1) do keys1 = keys1 + 1 end
    for _ in pairs(t2) do keys2 = keys2 + 1 end
    if keys1 ~= keys2 then return false end
    
    -- Porównanie wartości
    for k, v1 in pairs(t1) do
        local v2 = t2[k]
        if type(v1) == "table" and type(v2) == "table" then
            if not are_tables_equal(v1, v2) then return false end
        elseif v1 ~= v2 then
            return false
        end
    end
    return true
end
-- =========================================================================
-- === ZMIANA: OPTYMALIZACJA ZAPISU (KONIEC) ===
-- =========================================================================


-- =========================================================================
-- === ZMIENNE PRZENIESIONE Z KONFIGURACJI (logika wewnętrzna skryptu) ===
-- =========================================================================
-- Domyślny tryb layoutu. Ta wartość jest ustawiana na starcie, ale może być
-- dynamicznie zmieniana przez zewnętrzne skrypty.
-- Dostępne tryby: "up", "down", "up_left", "up_right", "down_left", "down_right"
LAYOUT_MODE = "down_left"

-- Domyślny kierunek rysowania maili ("up" lub "down"). Wartość ta jest
-- dynamicznie i automatycznie nadpisywana przez wybraną funkcję layoutu
-- (np. set_layout_down_left ustawia ją na "up").
MAILS_DIRECTION = "up"
-- =========================================================================

-- =========================================================================
-- === POPRAWKA WYCIEKU PAMIĘCI: Globalny obiekt do mierzenia tekstu      ===
-- Zamiast tworzyć nowy obiekt w pętli, używamy tego jednego wielokrotnie.
-- =========================================================================
local GLOBAL_TEXT_EXTENTS = cairo_text_extents_t:create()


-----------------(Zupix FIX)-------------------
-- BLOK LAYOUTÓW – pełna kontrola pozycji      --
-----------------------------------------------

ENVELOPE_CORR  = { x = 0, y = 0 }
MAILS_CORR     = { x = 0, y = 0 }
SEPARATOR_CORR = { x = 0, y = 0 }
TEXT_CORR      = { x = 0, y = 0 }

ENVELOPE_POS    = { x = 0, y = 0 }
MAILS_POS       = { x = 0, y = 0 }
CUSTOM_TEXT_POS = { x = 0, y = 0 }
SEPARATOR_X     = 0
SEPARATOR_Y     = 0

-- Pomocnicze stałe bazowe (możesz zmienić pod swój gust)
local BASE_LEFT   = 45 * GLOBAL_SCALE_FACTOR      -- baza od lewej krawędzi
local BASE_RIGHT  = 60 * GLOBAL_SCALE_FACTOR      -- baza od prawej krawędzi
local BASE_TOP    = 37 * GLOBAL_SCALE_FACTOR      -- baza od górnej krawędzi
local BASE_BOTTOM = 37 * GLOBAL_SCALE_FACTOR      -- baza od dolnej krawędzi

-- Wysokości separacji między elementami (nagłówek/separator/mail-list/envelope)
local GAP_HEADER_TO_SEP    = 57 * GLOBAL_SCALE_FACTOR  -- Odstęp między nagłówkiem a separatorem (linią)
local GAP_SEP_TO_MAILS     = 27 * GLOBAL_SCALE_FACTOR  -- Odstęp między separatorem a listą maili
local GAP_MAILS_TO_ENV     = 18 * GLOBAL_SCALE_FACTOR  -- ile px między ostatnią linią a kopertą (gdy envelope pod listą)

-- =========================================================================
-- === ZMIANA: PRZENIESIENIE LOGIKI WIEKU MAILA (START) ===
-- =========================================================================
-- Ta funkcja, przeniesiona z Pythona, oblicza "wiek" maila na bieżąco,
-- dzięki czemu plik cache nie musi być aktualizowany co minutę.
local function get_age_text(mail_epoch)
    if not mail_epoch or mail_epoch == 0 then return "" end
    
    local diff = os.time() - tonumber(mail_epoch)
    
    if diff < 60 then
        return diff .. "s temu"
    elseif diff < 3600 then
        return math.floor(diff / 60) .. "m temu"
    elseif diff < 86400 then
        return math.floor(diff / 3600) .. "h temu"
    elseif diff < 604800 then
        return math.floor(diff / 86400) .. "d temu"
    elseif diff < 31536000 then
        return math.floor(diff / 604800) .. " tyg temu"
    else
        return math.floor(diff / 31536000) .. " lat temu"
    end
end
-- =========================================================================
-- === ZMIANA: PRZENIESIENIE LOGIKI WIEKU MAILA (KONIEC) ===
-- =========================================================================


-- Dla trybów up/down lista od góry/dół (Twoja logika kierunku jest dalej w kodzie)
-- Tu ustawiamy tylko punkt referencyjny MAILS_POS i od niego liczymy resztę.

-- ============ UP (wyśrodkowany, koperta po prawej końcówce bloku) ============
function set_layout_up()
    -- LOKALNE KOREKTORY
    MAILS_DIRECTION = "down"                                                         -- Kierunek rysowania listy maili (z góry na dół)
    ENVELOPE_MIRROR = true                                                           -- [true/false] Lustrzane odbicie ikony koperty
    ENVELOPE_IMAGE_ANGLE = 0                                                         -- Obrót koperty w stopniach
    BADGE_RADIUS = 22 * GLOBAL_SCALE_FACTOR                                          -- Promień kółka z liczbą nieprzeczytanych maili
    BADGE_POS = { dx = 15 * GLOBAL_SCALE_FACTOR, dy = 7 * GLOBAL_SCALE_FACTOR }      -- Przesunięcie badge'a (kółka) względem koperty (oś X, oś Y)
    local ENV_X, ENV_Y = 126 * GLOBAL_SCALE_FACTOR, -25 * GLOBAL_SCALE_FACTOR        -- Korekta pozycji dla ikony koperty (oś X, oś Y)
    local MAIL_X, MAIL_Y = -37 * GLOBAL_SCALE_FACTOR, -60 * GLOBAL_SCALE_FACTOR      -- Korekta pozycji dla całej listy maili (oś X, oś Y)
    local SEP_X, SEP_Y = 519 * GLOBAL_SCALE_FACTOR, -64 * GLOBAL_SCALE_FACTOR        -- Korekta pozycji dla separatora (linii) (oś X, oś Y)
    local TXT_X, TXT_Y = -28 * GLOBAL_SCALE_FACTOR, -7 * GLOBAL_SCALE_FACTOR         -- Korekta pozycji dla własnego tekstu/nagłówka (oś X, oś Y)

    -- MAILS (środek poziomy, od góry)
    MAILS_POS.x = (conky_window.width - (PER_MAIL_MILK_WIDTH or (1080 * GLOBAL_SCALE_FACTOR))) / 2 + MAILS_CORR.x + MAIL_X
    MAILS_POS.y = BASE_TOP + GAP_HEADER_TO_SEP + GAP_SEP_TO_MAILS + MAILS_CORR.y + MAIL_Y

    -- SEPARATOR (pod nagłówkiem, wyśrodkowany względem MAILS_POS.x)
    SEPARATOR_X = MAILS_POS.x + SEPARATOR_CORR.x + SEP_X
    SEPARATOR_Y = BASE_TOP + GAP_HEADER_TO_SEP + SEPARATOR_CORR.y + SEP_Y

    -- CUSTOM HEADER (nad separatorem)
    CUSTOM_TEXT_POS.x = MAILS_POS.x + TEXT_CORR.x + TXT_X
    CUSTOM_TEXT_POS.y = BASE_TOP + TEXT_CORR.y + TXT_Y

    -- ENVELOPE (po prawej końcówce bloku mailowego)
    ENVELOPE_POS.x = MAILS_POS.x + (PER_MAIL_MILK_WIDTH or (1080 * GLOBAL_SCALE_FACTOR)) - ENVELOPE_SIZE.w + ENVELOPE_CORR.x + ENV_X
    ENVELOPE_POS.y = SEPARATOR_Y + GAP_SEP_TO_MAILS + ENVELOPE_CORR.y + ENV_Y
end


-- ============ DOWN (wyśrodkowany, koperta po prawej końcówce bloku) ============
function set_layout_down()
    -- LOKALNE KOREKTORY
    MAILS_DIRECTION = "up"                                                           -- Kierunek rysowania listy maili (z góry na dół)
    ENVELOPE_MIRROR = true                                                           -- [true/false] Lustrzane odbicie ikony koperty
    ENVELOPE_IMAGE_ANGLE = 0                                                         -- Obrót koperty w stopniach
    BADGE_RADIUS = 22 * GLOBAL_SCALE_FACTOR                                          -- Promień kółka z liczbą nieprzeczytanych maili
    BADGE_POS = { dx = 15 * GLOBAL_SCALE_FACTOR, dy = 7 * GLOBAL_SCALE_FACTOR }      -- Przesunięcie badge'a (kółka) względem koperty (oś X, oś Y)
    local ENV_X, ENV_Y = 132 * GLOBAL_SCALE_FACTOR, 22 * GLOBAL_SCALE_FACTOR         -- Korekta pozycji dla ikony koperty (oś X, oś Y)
    local MAIL_X, MAIL_Y = -45 * GLOBAL_SCALE_FACTOR, -52 * GLOBAL_SCALE_FACTOR      -- Korekta pozycji dla całej listy maili (oś X, oś Y)
    local SEP_X, SEP_Y = 521 * GLOBAL_SCALE_FACTOR, 206 * GLOBAL_SCALE_FACTOR        -- Korekta pozycji dla separatora (linii) (oś X, oś Y)
    local TXT_X, TXT_Y = -27 * GLOBAL_SCALE_FACTOR, 47 * GLOBAL_SCALE_FACTOR         -- Korekta pozycji dla własnego tekstu/nagłówka (oś X, oś Y)

    -- MAILS (środek poziomy, od dołu)
    MAILS_POS.x = (conky_window.width - (PER_MAIL_MILK_WIDTH or (1080 * GLOBAL_SCALE_FACTOR))) / 2 + MAILS_CORR.x + MAIL_X
    MAILS_POS.y = BASE_BOTTOM + GAP_MAILS_TO_ENV + MAILS_CORR.y + MAIL_Y

    -- SEPARATOR (nad kopertą lub nad mailami)
    SEPARATOR_X = MAILS_POS.x + SEPARATOR_CORR.x + SEP_X
    SEPARATOR_Y = conky_window.height - BASE_BOTTOM - GAP_MAILS_TO_ENV - ENVELOPE_SIZE.h - (18 * GLOBAL_SCALE_FACTOR) + SEPARATOR_CORR.y + SEP_Y

    -- CUSTOM HEADER (nad separatorem)
    CUSTOM_TEXT_POS.x = MAILS_POS.x + TEXT_CORR.x + TXT_X
    CUSTOM_TEXT_POS.y = SEPARATOR_Y - (GAP_HEADER_TO_SEP - (9 * GLOBAL_SCALE_FACTOR)) + TEXT_CORR.y + TXT_Y

    -- ENVELOPE (po prawej końcówce bloku mailowego)
    ENVELOPE_POS.x = MAILS_POS.x + (PER_MAIL_MILK_WIDTH or (1080 * GLOBAL_SCALE_FACTOR)) - ENVELOPE_SIZE.w + ENVELOPE_CORR.x + ENV_X
    ENVELOPE_POS.y = conky_window.height - BASE_BOTTOM - ENVELOPE_SIZE.h + ENVELOPE_CORR.y + ENV_Y
end


-- ============ UP_LEFT (góra-lewo; koperta po prawej końcówce bloku) ============
function set_layout_up_left()
    -- LOKALNE KOREKTORY
    MAILS_DIRECTION = "down"                                                          -- Kierunek rysowania listy maili (z góry na dół)
    ENVELOPE_MIRROR = true                                                            -- [true/false] Lustrzane odbicie ikony koperty
    ENVELOPE_IMAGE_ANGLE = 0                                                          -- Obrót koperty w stopniach
    BADGE_RADIUS = 22 * GLOBAL_SCALE_FACTOR                                           -- Promień kółka z liczbą nieprzeczytanych maili
    BADGE_POS = { dx = 15 * GLOBAL_SCALE_FACTOR, dy = 7 * GLOBAL_SCALE_FACTOR }       -- Przesunięcie badge'a (kółka) względem koperty (oś X, oś Y)
    local ENV_X, ENV_Y = 132 * GLOBAL_SCALE_FACTOR, -22 * GLOBAL_SCALE_FACTOR         -- Korekta pozycji dla ikony koperty (oś X, oś Y)
    local MAIL_X, MAIL_Y = 0 * GLOBAL_SCALE_FACTOR, -60 * GLOBAL_SCALE_FACTOR         -- Korekta pozycji dla całej listy maili (oś X, oś Y)
    local SEP_X, SEP_Y = 521 * GLOBAL_SCALE_FACTOR, -67 * GLOBAL_SCALE_FACTOR         -- Korekta pozycji dla separatora (linii) (oś X, oś Y)
    local TXT_X, TXT_Y = -27 * GLOBAL_SCALE_FACTOR, -10 * GLOBAL_SCALE_FACTOR         -- Korekta pozycji dla własnego tekstu/nagłówka (oś X, oś Y)

    MAILS_POS.x = BASE_LEFT + MAILS_CORR.x + MAIL_X
    MAILS_POS.y = BASE_TOP + GAP_HEADER_TO_SEP + GAP_SEP_TO_MAILS + MAILS_CORR.y + MAIL_Y

    SEPARATOR_X = MAILS_POS.x + SEPARATOR_CORR.x + SEP_X
    SEPARATOR_Y = BASE_TOP + GAP_HEADER_TO_SEP + SEPARATOR_CORR.y + SEP_Y

    CUSTOM_TEXT_POS.x = MAILS_POS.x + TEXT_CORR.x + TXT_X
    CUSTOM_TEXT_POS.y = BASE_TOP + TEXT_CORR.y + TXT_Y

    ENVELOPE_POS.x = MAILS_POS.x + (PER_MAIL_MILK_WIDTH or (1080 * GLOBAL_SCALE_FACTOR)) - ENVELOPE_SIZE.w + ENVELOPE_CORR.x + ENV_X
    ENVELOPE_POS.y = SEPARATOR_Y + GAP_SEP_TO_MAILS + ENVELOPE_CORR.y + ENV_Y
end

-- ============ UP_RIGHT (góra-prawo; koperta po LEWEJ stronie bloku) ============
function set_layout_up_right()
    -- LOKALNE KOREKTORY
    MAILS_DIRECTION = "down"                                                           -- Kierunek rysowania listy maili (z góry na dół)
    ENVELOPE_MIRROR = false                                                            -- [true/false] Lustrzane odbicie ikony koperty
    ENVELOPE_IMAGE_ANGLE = 0                                                           -- Obrót koperty w stopniach
    BADGE_RADIUS = 22 * GLOBAL_SCALE_FACTOR                                            -- Promień kółka z liczbą nieprzeczytanych maili
    BADGE_POS = { dx = 120 * GLOBAL_SCALE_FACTOR, dy = 7 * GLOBAL_SCALE_FACTOR }       -- Przesunięcie badge'a (kółka) względem koperty (oś X, oś Y)
    local ENV_X, ENV_Y = -185 * GLOBAL_SCALE_FACTOR, -22 * GLOBAL_SCALE_FACTOR         -- Korekta pozycji dla ikony koperty (oś X, oś Y)
    local MAIL_X, MAIL_Y = 75 * GLOBAL_SCALE_FACTOR, -63 * GLOBAL_SCALE_FACTOR         -- Korekta pozycji dla całej listy maili (oś X, oś Y)
    local SEP_X, SEP_Y = 522 * GLOBAL_SCALE_FACTOR, -67 * GLOBAL_SCALE_FACTOR          -- Korekta pozycji dla separatora (linii) (oś X, oś Y)
    local TXT_X, TXT_Y = -27 * GLOBAL_SCALE_FACTOR, -10 * GLOBAL_SCALE_FACTOR          -- Korekta pozycji dla własnego tekstu/nagłówka (oś X, oś Y)

    -- MAILS przyklejone do prawej krawędzi okna
    MAILS_POS.x = conky_window.width - (PER_MAIL_MILK_WIDTH or (1080 * GLOBAL_SCALE_FACTOR)) - BASE_RIGHT + MAILS_CORR.x + MAIL_X
    MAILS_POS.y = BASE_TOP + GAP_HEADER_TO_SEP + GAP_SEP_TO_MAILS + MAILS_CORR.y + MAIL_Y

    SEPARATOR_X = MAILS_POS.x + SEPARATOR_CORR.x + SEP_X
    SEPARATOR_Y = BASE_TOP + GAP_HEADER_TO_SEP + SEPARATOR_CORR.y + SEP_Y

    CUSTOM_TEXT_POS.x = MAILS_POS.x + TEXT_CORR.x + TXT_X
    CUSTOM_TEXT_POS.y = BASE_TOP + TEXT_CORR.y + TXT_Y

    -- koperta po LEWEJ stronie bloku (początek)
    ENVELOPE_POS.x = MAILS_POS.x + ENVELOPE_CORR.x + ENV_X
    ENVELOPE_POS.y = SEPARATOR_Y + GAP_SEP_TO_MAILS + ENVELOPE_CORR.y + ENV_Y
end

-- ============ DOWN_LEFT (dół-lewo; koperta po prawej końcówce bloku) ============
function set_layout_down_left()
    -- LOKALNE KOREKTORY
    MAILS_DIRECTION = "up"                                                            -- Kierunek rysowania listy maili (z góry na dół)
    ENVELOPE_MIRROR = true                                                            -- [true/false] Lustrzane odbicie ikony koperty
    ENVELOPE_IMAGE_ANGLE = 0                                                          -- Obrót koperty w stopniach
    BADGE_RADIUS = 22 * GLOBAL_SCALE_FACTOR                                           -- Promień kółka z liczbą nieprzeczytanych maili
    BADGE_POS = { dx = 15 * GLOBAL_SCALE_FACTOR, dy = 7 * GLOBAL_SCALE_FACTOR }       -- Przesunięcie badge'a (kółka) względem koperty (oś X, oś Y)
    local ENV_X, ENV_Y = 135 * GLOBAL_SCALE_FACTOR, 30 * GLOBAL_SCALE_FACTOR          -- Korekta pozycji dla ikony koperty (oś X, oś Y)
    local MAIL_X, MAIL_Y = 0 * GLOBAL_SCALE_FACTOR, -52 * GLOBAL_SCALE_FACTOR         -- Korekta pozycji dla całej listy maili (oś X, oś Y)
    local SEP_X, SEP_Y = 521 * GLOBAL_SCALE_FACTOR, 206 * GLOBAL_SCALE_FACTOR         -- Korekta pozycji dla separatora (linii) (oś X, oś Y)
    local TXT_X, TXT_Y = -27 * GLOBAL_SCALE_FACTOR, 47 * GLOBAL_SCALE_FACTOR          -- Korekta pozycji dla własnego tekstu/nagłówka (oś X, oś Y)

    MAILS_POS.x = BASE_LEFT + MAILS_CORR.x + MAIL_X
    MAILS_POS.y = BASE_BOTTOM + GAP_MAILS_TO_ENV + MAILS_CORR.y + MAIL_Y

    SEPARATOR_X = MAILS_POS.x + SEPARATOR_CORR.x + SEP_X
    SEPARATOR_Y = conky_window.height - BASE_BOTTOM - GAP_MAILS_TO_ENV - ENVELOPE_SIZE.h - (18 * GLOBAL_SCALE_FACTOR) + SEPARATOR_CORR.y + SEP_Y

    CUSTOM_TEXT_POS.x = MAILS_POS.x + TEXT_CORR.x + TXT_X
    CUSTOM_TEXT_POS.y = SEPARATOR_Y -  (GAP_HEADER_TO_SEP - (9 * GLOBAL_SCALE_FACTOR)) + TEXT_CORR.y + TXT_Y

    -- ENVELOPE (po prawej końcówce bloku mailowego)
    ENVELOPE_POS.x = MAILS_POS.x + (PER_MAIL_MILK_WIDTH or (1080 * GLOBAL_SCALE_FACTOR)) - ENVELOPE_SIZE.w + ENVELOPE_CORR.x + ENV_X
    ENVELOPE_POS.y = conky_window.height - BASE_BOTTOM - ENVELOPE_SIZE.h + ENVELOPE_CORR.y + ENV_Y
end

-- ============ DOWN_RIGHT (dół-prawo; koperta po LEWEJ stronie bloku) ============
function set_layout_down_right()
    -- LOKALNE KOREKTORY
    MAILS_DIRECTION = "up"                                                              -- Kierunek rysowania listy maili (z góry na dół)
    ENVELOPE_MIRROR = false                                                             -- [true/false] Lustrzane odbicie ikony koperty
    ENVELOPE_IMAGE_ANGLE = 0                                                            -- Obrót koperty w stopniach
    BADGE_RADIUS = 22 * GLOBAL_SCALE_FACTOR                                             -- Promień kółka z liczbą nieprzeczytanych maili
    BADGE_POS = { dx = 123 * GLOBAL_SCALE_FACTOR, dy = 7 * GLOBAL_SCALE_FACTOR }        -- Przesunięcie badge'a (kółka) względem koperty (oś X, oś Y)
    local ENV_X, ENV_Y = -185 * GLOBAL_SCALE_FACTOR , 30 * GLOBAL_SCALE_FACTOR          -- Korekta pozycji dla ikony koperty (oś X, oś Y)
    local MAIL_X, MAIL_Y = 75 * GLOBAL_SCALE_FACTOR, -52 * GLOBAL_SCALE_FACTOR          -- Korekta pozycji dla całej listy maili (oś X, oś Y)
    local SEP_X, SEP_Y = 520 * GLOBAL_SCALE_FACTOR, 205 * GLOBAL_SCALE_FACTOR           -- Korekta pozycji dla separatora (linii) (oś X, oś Y)
    local TXT_X, TXT_Y = -27 * GLOBAL_SCALE_FACTOR, 48 * GLOBAL_SCALE_FACTOR            -- Korekta pozycji dla własnego tekstu/nagłówka (oś X, oś Y)

    MAILS_POS.x = conky_window.width - (PER_MAIL_MILK_WIDTH or (1080 * GLOBAL_SCALE_FACTOR)) - BASE_RIGHT + MAILS_CORR.x + MAIL_X
    MAILS_POS.y = BASE_BOTTOM + GAP_MAILS_TO_ENV + MAILS_CORR.y + MAIL_Y

    SEPARATOR_X = MAILS_POS.x + SEPARATOR_CORR.x + SEP_X
    SEPARATOR_Y = conky_window.height - BASE_BOTTOM - GAP_MAILS_TO_ENV - ENVELOPE_SIZE.h - (18 * GLOBAL_SCALE_FACTOR) + SEPARATOR_CORR.y + SEP_Y

    CUSTOM_TEXT_POS.x = MAILS_POS.x + TEXT_CORR.x + TXT_X
    CUSTOM_TEXT_POS.y = SEPARATOR_Y -  (GAP_HEADER_TO_SEP - (9 * GLOBAL_SCALE_FACTOR)) + TEXT_CORR.y + TXT_Y

    -- koperta po LEWEJ stronie bloku (początek)
    ENVELOPE_POS.x = MAILS_POS.x + ENVELOPE_CORR.x + ENV_X
    ENVELOPE_POS.y = conky_window.height - BASE_BOTTOM - ENVELOPE_SIZE.h + ENVELOPE_CORR.y + ENV_Y
end

-- ============ Router trybu ============
function set_layout_by_mode()
    if       LAYOUT_MODE == "up"         then set_layout_up()
    elseif LAYOUT_MODE == "down"       then set_layout_down()
    elseif LAYOUT_MODE == "up_left"    then set_layout_up_left()
    elseif LAYOUT_MODE == "up_right"   then set_layout_up_right()
    elseif LAYOUT_MODE == "down_left"  then set_layout_down_left()
    elseif LAYOUT_MODE == "down_right" then set_layout_down_right()
    else
        set_layout_down_left() -- domyślnie
    end
end


local function utf8_sub(s, i, j)
    local pos = 1
    local bytes = #s
    local start, end_ = nil, nil
    local k = 0
    while pos <= bytes do
        k = k + 1
        if k == i then start = pos end
        if k == (j and j + 1 or nil) then end_ = pos - 1 break end
        local c = s:byte(pos)
        if c < 0x80 then pos = pos + 1
        elseif c < 0xE0 then pos = pos + 2
        elseif c < 0xF0 then pos = pos + 3
        else pos = pos + 4 end
    end
    if start then return s:sub(start, end_ or bytes) end
    return ""
end

local function utf8_len(s)
    local _, count = s:gsub("[^\128-\193]", "")
    return count
end

local function safe_str(s, fallback)
    if s == nil then return fallback or "" end
    if type(s) == "string" then return s end
    return tostring(s)
end

local function set_font(cr, font_name, font_size, bold, italic)
    cairo_select_font_face(
        cr,
        font_name,
        italic and CAIRO_FONT_SLANT_ITALIC or CAIRO_FONT_SLANT_NORMAL,
        bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL
    )
    cairo_set_font_size(cr, font_size)
end

local function split_emoji(text)
    local res = {}
    local pattern = "[\xF0-\xF7][\x80-\xBF][\x80-\xBF][\x80-\xBF]"
    local last_end = 1
    for start_pos, end_pos in function() return text:find(pattern, last_end) end do
        if start_pos > last_end then
            table.insert(res, {emoji=false, txt=text:sub(last_end, start_pos-1)})
        end
        table.insert(res, {emoji=true, txt=text:sub(start_pos, end_pos)})
        last_end = end_pos + 1
    end
    if last_end <= #text then
        table.insert(res, {emoji=false, txt=text:sub(last_end)})
    end
    return res
end

-- Liczenie szerokości tekstu z emoji
local function text_width_with_emoji(cr, text, font_name, font_size, font_bold, font_italic)
    local width = 0
    local emoji_chunks = split_emoji(text)
    for idx, chunk in ipairs(emoji_chunks) do
        if chunk.emoji then
            cairo_select_font_face(cr, "Noto Color Emoji", CAIRO_FONT_SLANT_NORMAL, font_bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL)
        else
            cairo_select_font_face(cr, font_name, font_italic and CAIRO_FONT_SLANT_ITALIC or CAIRO_FONT_SLANT_NORMAL, font_bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL)
        end
        cairo_set_font_size(cr, font_size)
        cairo_text_extents(cr, chunk.txt, GLOBAL_TEXT_EXTENTS)
        width = width + GLOBAL_TEXT_EXTENTS.x_advance
    end
    return width
end

-- Obcinanie tekstu z emoji do max_width
local function trim_line_to_width_emoji(cr, text, max_width, font_name, font_size, font_bold, font_italic)
    local ellipsis = "..."
    local trimmed = ""
    for i = 1, utf8_len(text) do
        local chunk = utf8_sub(text, 1, i)
        local w = text_width_with_emoji(cr, chunk .. ellipsis, font_name, font_size, font_bold, font_italic)
        if w > max_width then
            break
        end
        trimmed = chunk
    end
    -- Jeśli tekst się mieści, zwróć całość:
    if text_width_with_emoji(cr, text, font_name, font_size, font_bold, font_italic) <= max_width then
        return text
    end
    return trimmed .. ellipsis
end


-- Sprawdź, czy to pierwszy start po reboocie (nie ma pliku last_seen)
local function file_exists(path)
    local ok, f = pcall(io.open, path, "r")
    if ok and f then f:close(); return true end
    return false
end
local FIRST_RUN = not file_exists("/dev/shm/conky-automail-suite/last_seen_mails.json")

-- ===================================================================
-- POCZĄTEK MODYFIKACJI
-- ===================================================================
-- Flaga jednorazowa: brak migania załączników po przewijaniu "na żądanie"
local MANUAL_SCROLL_FLAG_PATH = "/dev/shm/conky-automail-suite/noblink.manualscroll"

-- Czy dla TEJ sesji wyłączyć miganie załączników?
local SUPPRESS_BLINK_THIS_SESSION = file_exists(MANUAL_SCROLL_FLAG_PATH)
if SUPPRESS_BLINK_THIS_SESSION then
    -- Jednorazowe – usuń flagę, żeby nie wpływała na kolejne uruchomienia
    os.remove(MANUAL_SCROLL_FLAG_PATH)
end

-- NOWE: Zestaw maili obecnych przy starcie sesji (po manual scroll)
local SUPPRESS_BLINK_IDS = nil
-- ===================================================================
-- KONIEC MODYFIKACJI
-- ===================================================================


--- POCZĄTEK POPRAWKI: ZMIENNE GLOBALNE DO KONTROLI STANU ---
-- Flaga wykrywająca pierwsze uruchomienie skryptu po przeładowaniu.
local is_first_run_of_script = true
-- Przechowuje zbiór UID maili, które były widoczne w poprzedniej klatce animacji.
local uids_visible_in_last_frame = load_last_visible_uids() -- [[ POPRAWKA PRZEWIJANIA ]]
--- KONIEC POPRAWKI: ZMIENNE GLOBALNE DO KONTROLI STANU ---


-- ===============================================
-- Wczytywanie listy UID ostatnio wyświetlonych maili (do przewijania)
-- ===============================================
local last_seen_uids = {}

local function load_last_seen_uids()
    local f = io.open("/dev/shm/conky-automail-suite/last_seen_mails.json", "r")
    if not f then return {} end
    local content = f:read("*a")
    f:close()
    local ok, uids = pcall(function() return json.decode(content) end)
    if ok and type(uids) == "table" then
        local set = {}
        for _, uid in ipairs(uids) do set[uid] = true end
        return set
    end
    return {}
end

-- Załaduj UID-y na starcie Conky
last_seen_uids = load_last_seen_uids()

-- ===============================================
-- Pomocnicze funkcje logiki "nowości" maila
-- ===============================================

--- OSTATECZNA POPRAWKA v5 START (ZMIANA 2/4) ---
-- Ta funkcja decyduje, czy należy uruchomić animację przewijania tekstu.
local function should_start_scrolling(mail)
    -- Zasada 0: Jeśli właśnie nastąpił automatyczny reset, NIGDY nie przewijaj.
    if mail_widget_state.auto_reset_occurred then
        return false
    end
    
    -- Zasada 1: Czy mail jest autentycznie nowy (dopiero co przyszedł)?
    if mail.is_genuinely_new then
        return true
    end

    -- Zasada 2: Czy mail NIE BYŁ widoczny w poprzedniej klatce?
    -- (To obsługuje maile pojawiające się po przewinięciu listy przez użytkownika).
    local uid = mail.uid or get_mail_id(mail)
    if not uids_visible_in_last_frame[uid] then
        return true
    end

    -- Jeśli żaden z powyższych warunków nie jest spełniony, nie uruchamiaj nowej animacji.
    return false
end
--- OSTATECZNA POPRAWKA v5 KONIEC ---


-- Funkcja 2: Czy mail jest "PRAWDZIWIE NOWY" (dla pulsowania i migania)
-- Decyduje, czy należy uruchomić efektowne animacje, ponieważ mail dopiero co przyszedł.
local function should_animate_pulse_blink(mail)
    -- Twoja istniejąca logika tłumienia migania po manualnym resecie jest ważna, zostawiamy ją.
    if SUPPRESS_BLINK_THIS_SESSION then
        local id = mail.uid or ((mail.subject or "") .. (mail.from or ""))
        if SUPPRESS_BLINK_IDS and SUPPRESS_BLINK_IDS[id] then
            return false -- Nie animuj, jeśli to część snapshotu po ręcznym resecie
        end
    end
    -- Główny warunek: animuj tylko, jeśli mail ma flagę "prawdziwie nowy"
    return mail.is_genuinely_new == true
end

-- CACHE PNG: Ładuje obrazek tylko raz i trzyma w pamięci
--- POPRAWKA START ---
local png_cache = {}
--- POPRAWKA KONIEC ---
local function get_png_surface(path)
    if not png_cache[path] then
        local surface = cairo_image_surface_create_from_png(path)
        if cairo_surface_status(surface) ~= 0 then
            print("BŁĄD: Nie można załadować pliku PNG: " .. tostring(path))
            surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 1, 1)
        end
        png_cache[path] = surface
    end
    return png_cache[path]
end

local previous_unread_count = nil
local last_good_mails = {}
local last_mail_json_ok = false

--- POCZĄTEK MODYFIKACJI ---
-- Wczytujemy zapisane stany przewijania lub tworzymy puste, jeśli to pierwszy start
local from_scroll_states, subject_scroll_states, preview_scroll_states, meta_scroll_states = load_scroll_states()

-- Struktura `scroll_states` jest trochę inna (zawiera pod-tabele), więc musimy ją złożyć
local scroll_states = {
    subject = subject_scroll_states,
    preview = preview_scroll_states,
}
-- Sprzątamy, żeby nie trzymać duplikatów w pamięci
subject_scroll_states = nil
preview_scroll_states = nil
--- KONIEC MODYFIKACJI ---


-- [PATCH] Cache’y: szerokości, cięcia tekstu, preview i meta szerokości
local width_cache = {}
local trim_cache  = {}
local meta_width_cache = {}

local function cache_key_width(text, font, size, bold, italic)
    return table.concat({text or "", font or "", size or 0, bold and "b" or "n", italic and "i" or "n"}, "|")
end

local function cached_text_width_emoji(cr, text, font, size, bold, italic)
    local k = cache_key_width(text, font, size, bold, italic)
    local w = width_cache[k]
    if w then return w end
    w = text_width_with_emoji(cr, text or "", font, size, bold, italic)
    width_cache[k] = w
    return w
end

local function cached_trim_emoji(cr, text, maxw, font, size, bold, italic)
    local k = table.concat({text or "", maxw or 0, font or "", size or 0, bold and "b" or "n", italic and "i" or "n"}, "|")
    local v = trim_cache[k]
    if v then return v end
    v = trim_line_to_width_emoji(cr, text or "", maxw, font, size, bold, italic)
    trim_cache[k] = v
    return v
end
-- [/PATCH]

-- [[ ZMIANA START ]]
local auto_reset_suppress_list = {}
local suppress_list_signature = "" -- Przechowuje "podpis" listy maili w momencie resetu
local last_known_mtime = 0
-- [[ ZMIANA KONIEC ]]


-- [[ OPTYMALIZACJA START ]]
    
local function get_file_mtime(path)
    if not path then return 0 end
    -- ZASTOSOWANO NIEZAWODNE POLECENIE 'date' ZAMIAST 'stat'
    local command = "LC_NUMERIC=C date -r '" .. path .. "' +%s.%N 2>/dev/null"
    local handle = io.popen(command)
    if handle then
        local mtime_str = handle:read("*a")
        handle:close()
        -- Wynik jest już w poprawnym formacie (sekundy.nanosekundy),
        -- więc wystarczy go przekonwertować na liczbę.
        return tonumber(mtime_str) or 0
    end
    return 0
end

local function fetch_mails_from_cache()
    local CACHE_FILE = "/dev/shm/conky-automail-suite/mail_cache.json"
    
    local current_mtime = get_file_mtime(CACHE_FILE)

    if current_mtime > 0 and current_mtime == last_mail_cache_mtime and cached_mail_data ~= nil then
        last_mail_json_ok = true
        return cached_mail_data
    end
    
    local f = io.open(CACHE_FILE, "r")
    if not f then
        print("Nie znaleziono pliku cache!")
        last_mail_json_ok = false
        cached_mail_data = {} 
        last_mail_cache_mtime = 0
        return {}
    end
    
    local result = f:read("*a")
    f:close()
    
    local data, pos, err = json.decode(result, 1, nil)
    
    if not data or type(data) ~= "table" then
        print("Błąd dekodowania JSON z pliku cache:", err)
        last_mail_json_ok = false
        cached_mail_data = {}
        last_mail_cache_mtime = 0
        return {}
    end
    
    if type(data.mails) ~= "table" then data.mails = {} end
    
    last_mail_json_ok = true
    cached_mail_data = data
    last_mail_cache_mtime = current_mtime
    
    return cached_mail_data
end
-- [[ OPTYMALIZACJA KONIEC ]]


local function save_max_mails_to_file()
    local count_file = "/home/linux/Pulpit/conky-automail-suite/config/mail_count.conf"
    local f = io.open(count_file, "w")
    if f then
        f:write(MAX_MAILS, "\n")
        f:close()
    end
end
save_max_mails_to_file()

local function save_preview_lines_to_file()
    local preview_file = "/home/linux/Pulpit/conky-automail-suite/config/mail_preview_lines.conf"
    local f = io.open(preview_file, "w")
    if f then
        f:write(MAIL_PREVIEW_LINES, "\n")
        f:close()
    end
end
save_preview_lines_to_file()

-- POPRAWKA: użycie cache dla PNG
local function draw_png_rotated(cr, x, y, w, h, path, angle_deg, mirror_x)
    local image = get_png_surface(path)
    local img_w = cairo_image_surface_get_width(image)
    local img_h = cairo_image_surface_get_height(image)
    cairo_save(cr)
    cairo_translate(cr, x + w/2, y + h/2)
    cairo_rotate(cr, math.rad(angle_deg or 0))
    if mirror_x then
        cairo_scale(cr, -w / img_w, h / img_h)
        cairo_translate(cr, -img_w / 2, -img_h / 2)
    else
        cairo_scale(cr, w / img_w, h / img_h)
        cairo_translate(cr, -img_w / 2, -img_h / 2)
    end
    cairo_set_source_surface(cr, image, 0, 0)
    cairo_paint(cr)
    cairo_restore(cr)
    -- NIE niszczymy surface, bo cache!
end

local function get_mail_id(mail)
    local subj = tostring(mail.subject or ""):sub(1,64)
    local from = tostring(mail.from or ""):sub(1,32)
    local preview = tostring(mail.preview or ""):sub(1,32)
    return subj .. "|" .. from .. "|" .. preview
end

local function trim_line_to_width(cr, text, max_width)
    local ellipsis = "..."
    cairo_text_extents(cr, ellipsis, GLOBAL_TEXT_EXTENTS)
    local ellipsis_width = GLOBAL_TEXT_EXTENTS.width

    local trimmed = text
    local total_width = 0
    local last_good = ""

    for i = 1, utf8_len(text) do
        local chunk = utf8_sub(text, 1, i)
        cairo_text_extents(cr, chunk .. ellipsis, GLOBAL_TEXT_EXTENTS)
        if GLOBAL_TEXT_EXTENTS.width > max_width then
            break
        end
        last_good = chunk
    end

    cairo_text_extents(cr, text, GLOBAL_TEXT_EXTENTS)
    if GLOBAL_TEXT_EXTENTS.width <= max_width then
        return text
    end

    return last_good .. ellipsis
end

-- DEKODER BEZPIECZNYCH WARTOŚCI RGB
local function decode_rgb(val)
    val = tonumber(val) or 0
    if val ~= val then return 0 end -- NaN
    if val < 0 then return 0 end
    if val > 255 then return 1 end
    if val <= 1 then return val end
    return val / 255
end

local function decode_rgb3(rgb)
    if type(rgb) ~= "table" then return 0, 0, 0 end
    return decode_rgb(rgb[1]), decode_rgb(rgb[2]), decode_rgb(rgb[3])
end

-- BEZPIECZNY CLAMP DO ZAKRESU 0..1 (np. dla przezroczystości)
local function clamp01(a)
    a = tonumber(a) or 0
    if a < 0 then return 0 end
    if a > 1 then return 1 end
    return a
end

local function set_color(cr, typ, custom)
    if typ == "white" then
        cairo_set_source_rgb(cr, 1, 1, 1)
    elseif typ == "black" then
        cairo_set_source_rgb(cr, 0, 0, 0)
    elseif typ == "red" then
        cairo_set_source_rgb(cr, 1, 0, 0)
    elseif typ == "orange" then
        cairo_set_source_rgb(cr, 1, 0.55, 0)
    elseif typ == "custom" and custom then
    local r, g, b = decode_rgb3(custom)
    cairo_set_source_rgb(cr, r, g, b)
    else
        cairo_set_source_rgb(cr, 1, 1, 1)
    end
end

local function draw_emoji_text(cr, text, font_name, font_bold, font_size, x, y, font_italic)
    if not text or text == "" then return 0 end
    local cursor = x
    local emoji_chunks = split_emoji(text)
    for idx, chunk in ipairs(emoji_chunks) do
        cairo_move_to(cr, cursor, y)
        if chunk.emoji then
            cairo_select_font_face(cr, "Noto Color Emoji", CAIRO_FONT_SLANT_NORMAL, font_bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL)
        else
            cairo_select_font_face(cr, font_name, font_italic and CAIRO_FONT_SLANT_ITALIC or CAIRO_FONT_SLANT_NORMAL, font_bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL)
        end
        cairo_set_font_size(cr, font_size)
        cairo_show_text(cr, chunk.txt)
        cairo_text_extents(cr, chunk.txt, GLOBAL_TEXT_EXTENTS)
        cursor = cursor + GLOBAL_TEXT_EXTENTS.x_advance
    end
    return cursor - x
end

local function ease_out(t)
    return 1 - (1 - t) * (1 - t)
end

local function join_preview_lines(preview_txt, max_lines)
    if not preview_txt or preview_txt == "" then return "" end
    local lines = {}
    for line in preview_txt:gmatch("[^\r\n]+") do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" then
            table.insert(lines, line)
        end
        if max_lines and max_lines > 0 and #lines >= max_lines then break end
    end
    if #lines == 0 then return preview_txt end
    return table.concat(lines, " ")
end

local function get_mail_from_id(mail, from_txt)
    local from_base = tostring(mail.from or "") .. "|" .. tostring(mail.from_name or "")
    local subject = tostring(mail.subject or "")
    return from_base:sub(1,64) .. "|" .. subject:sub(1,64) .. "|" .. (from_txt or "")
end

print("[diag] conky_parse:", type(_G.conky_parse))
-- w okolicach definicji now_time() wstaw zamiast starej:
local _tick_counter = 0
local function now_time()
    local dt = (type(_G.conky_info) == "table" and tonumber(_G.conky_info.update_interval)) or 1
    if type(_G.conky_parse) == "function" then
        local ok, updates = pcall(_G.conky_parse, "${updates}")
        local upd = tonumber(ok and updates or 0) or 0
        return upd * dt
    else
        _tick_counter = _tick_counter + 1
        return _tick_counter * dt
    end
end

-- =========================
-- MIGANIE ZAŁĄCZNIKA (LOGIKA)
-- =========================
-- Stan migania (cache)
local attachment_blink_states = {}      -- mapa: id_maila -> { start = t0 }

-- Zwraca true, jeśli w danej chwili załącznik (kropka/ikona) powinien być widoczny (ON)
local function attachment_blink_is_visible(mail, now)
    if not ATTACHMENT_BLINK_ENABLE then
        return true
    end

    if SUPPRESS_BLINK_THIS_SESSION then
        local id_suppress = mail.uid or ((mail.subject or "") .. (mail.from or ""))
        if SUPPRESS_BLINK_IDS and SUPPRESS_BLINK_IDS[id_suppress] then
            return true
        end
    end
    
    local id = mail.uid or get_mail_id(mail)
    local st = attachment_blink_states[id]
    
    if not st then
        if should_animate_pulse_blink(mail) then
            st = { start = now }
            attachment_blink_states[id] = st
        else
            return true
        end
    end
    
    local elapsed_total = now - (st.start or now)
    
    -- Obsługa opóźnienia
    if elapsed_total < (ATTACHMENT_BLINK_DELAY or 0) then
        return true -- Przed rozpoczęciem migania, ikona jest po prostu widoczna
    end

    local elapsed = elapsed_total - (ATTACHMENT_BLINK_DELAY or 0) -- Czas trwania fazy migania
    local phase = math.floor(elapsed / ATTACHMENT_BLINK_INTERVAL)
    local max_phases = (tonumber(ATTACHMENT_BLINK_COUNT) or 0) * 2

    if phase >= max_phases then
        return true
    end
    return (phase % 2) == 0
end


-- Sprzątanie stanów migania kiedy lista maili się zmienia
local function cleanup_attachment_blink_states(current_mails)
    if type(current_mails) ~= "table" then return end
    local valid = {}
    for _, m in ipairs(current_mails) do
        local id = m.uid or get_mail_id(m)
        valid[id] = true
    end
    for id, _ in pairs(attachment_blink_states) do
        if not valid[id] then attachment_blink_states[id] = nil end
    end
end

-- =========================
-- PULSOWANIE TŁA MAILA (LOGIKA)
-- =========================
-- Stan pulsowania (cache)
local mail_pulse_states = {} -- mapa: id_maila -> { start_time = t0 }

-- Sprzątanie stanów pulsowania, kiedy lista maili się zmienia
local function cleanup_pulse_states(current_mails)
    if type(current_mails) ~= "table" then return end
    local valid = {}
    for _, m in ipairs(current_mails) do
        local id = m.uid or get_mail_id(m)
        valid[id] = true
    end
    for id, _ in pairs(mail_pulse_states) do
        if not valid[id] then mail_pulse_states[id] = nil end
    end
end

-- Zwraca aktualny stan animacji pulsowania (aktywność, alpha, postęp)
local function get_pulse_state(mail, now)
    local default_state = {
        is_animating = false,
        fill_alpha = PER_MAIL_MILK_FILL_ALPHA,
        border_alpha = PER_MAIL_MILK_BORDER_ALPHA,
        progress = 0
    }

    if not PULSE_ANIM_ENABLE then
        return default_state
    end

    local id = mail.uid or get_mail_id(mail)
    local state = mail_pulse_states[id]
    
    if not state then
        if should_animate_pulse_blink(mail) then
            state = { start_time = now }
            mail_pulse_states[id] = state
        else
            return default_state
        end
    end

    local elapsed_total = now - (state.start_time or now)

    -- Obsługa opóźnienia
    if elapsed_total < (PULSE_ANIM_DELAY or 0) then
        return default_state -- Jeszcze nie czas na animację
    end

    local elapsed = elapsed_total - (PULSE_ANIM_DELAY or 0) -- Czas trwania animacji

    if elapsed > PULSE_ANIM_DURATION then
        return default_state
    end

    local sin_wave = math.sin(elapsed * PULSE_ANIM_SPEED)
    local normalized_wave = (sin_wave + 1) / 2

    local current_fill_alpha = PULSE_ANIM_MIN_ALPHA + (PULSE_ANIM_MAX_ALPHA - PULSE_ANIM_MIN_ALPHA) * normalized_wave
    local current_border_alpha = PULSE_BORDER_ANIM_MIN_ALPHA + (PULSE_BORDER_ANIM_MAX_ALPHA - PULSE_BORDER_ANIM_MIN_ALPHA) * normalized_wave

    return {
        is_animating = true,
        fill_alpha = current_fill_alpha,
        border_alpha = current_border_alpha,
        progress = normalized_wave
    }
end

-- ===================================================================
-- NOWA FUNKCJA: Interpolacja między dwoma kolorami
-- ===================================================================
local function interpolate_color(color_a, color_b, t)
    local r = color_a[1] * (1.0 - t) + color_b[1] * t
    local g = color_a[2] * (1.0 - t) + color_b[2] * t
    local b = color_a[3] * (1.0 - t) + color_b[3] * t
    return { r, g, b }
end

-- ##################################################################################
-- ### BLOK FUNKCJI: draw_colored_sender ###
-- ##################################################################################
local function draw_colored_sender(cr, mail, text_to_draw, x, y)
    -- Pobierz style dla NADAWCY
    local from_font_name = FROM_FONT_NAME
    local from_font_size = FROM_FONT_SIZE
    local from_font_bold = FROM_FONT_BOLD
    local from_font_italic = FROM_FONT_ITALIC

    -- Pobierz style dla ALIASU
    local alias_font_name = ALIAS_FONT_NAME
    local alias_font_size = ALIAS_FONT_SIZE
    local alias_font_bold = ALIAS_FONT_BOLD
    local alias_font_italic = ALIAS_FONT_ITALIC

    local alias_prefix = ""
    local sender_part = text_to_draw
    local has_color_alias = false

    if mail.account_name and mail.account_name ~= "" and mail.color and type(mail.color) == "table" then
        local prefix_candidate = "[" .. mail.account_name .. "] "
        if text_to_draw:sub(1, #prefix_candidate) == prefix_candidate then
            alias_prefix = prefix_candidate
            sender_part = text_to_draw:sub(#prefix_candidate + 1)
            has_color_alias = true
        end
    end

    if has_color_alias then
        local a = (mail.color[1] or 255) / 255
        local r = (mail.color[2] or 255) / 255
        local g = (mail.color[3] or 255) / 255
        local b = (mail.color[4] or 255) / 255
        cairo_set_source_rgba(cr, r, g, b, a)
        set_font(cr, alias_font_name, alias_font_size, alias_font_bold, alias_font_italic)
        local alias_width = draw_emoji_text(cr, alias_prefix, alias_font_name, alias_font_bold, alias_font_size, x, y, alias_font_italic)

        set_color(cr, FROM_COLOR_TYPE, FROM_COLOR_CUSTOM)
        set_font(cr, from_font_name, from_font_size, from_font_bold, from_font_italic)
        draw_emoji_text(cr, sender_part, from_font_name, from_font_bold, from_font_size, x + alias_width, y, from_font_italic)
    else
        set_color(cr, FROM_COLOR_TYPE, FROM_COLOR_CUSTOM)
        set_font(cr, from_font_name, from_font_size, from_font_bold, from_font_italic)
        draw_emoji_text(cr, text_to_draw, from_font_name, from_font_bold, from_font_size, x, y, from_font_italic)
    end
end

-- ##################################################################################
-- ### BLOK FUNKCJI: draw_from_scrolling ###
-- ##################################################################################
local function draw_from_scrolling(cr, mail, from_txt, x, y, force_scroll_active)
    local maxw = FROM_MAX_WIDTH
    local scroll_enable = FROM_SCROLL_ENABLE
    
    set_font(cr, FROM_FONT_NAME, FROM_FONT_SIZE, FROM_FONT_BOLD, FROM_FONT_ITALIC)
    local total_width = text_width_with_emoji(cr, from_txt, FROM_FONT_NAME, FROM_FONT_SIZE, FROM_FONT_BOLD, FROM_FONT_ITALIC)
    
    local unique_id_for_suppression = get_mail_id(mail)
    local is_suppressed = auto_reset_suppress_list[unique_id_for_suppression] or false

    if total_width <= maxw or not scroll_enable or is_suppressed then
        local text_to_draw = from_txt
        if total_width > maxw then
            text_to_draw = trim_line_to_width_emoji(cr, from_txt, maxw, FROM_FONT_NAME, FROM_FONT_SIZE, FROM_FONT_BOLD, FROM_FONT_ITALIC)
        end
        draw_colored_sender(cr, mail, text_to_draw, x, y)
        
        return x + math.min(total_width, maxw)
    end
    
    local scroll_speed  = FROM_SCROLL_SPEED
    local scroll_repeat = FROM_SCROLL_REPEAT
    local scroll_delay  = FROM_SCROLL_DELAY
    local scroll_ease   = FROM_SCROLL_EASE
    local scroll_extra  = FROM_SCROLL_EXTRA
    local from_font_name     = FROM_FONT_NAME
    local from_font_bold     = FROM_FONT_BOLD
    local from_font_size     = FROM_FONT_SIZE
    local from_font_italic   = FROM_FONT_ITALIC

    local alias_font_name   = ALIAS_FONT_NAME
    local alias_font_bold   = ALIAS_FONT_BOLD
    local alias_font_size   = ALIAS_FONT_SIZE
    local alias_font_italic = ALIAS_FONT_ITALIC

    local mail_id = get_mail_from_id(mail, from_txt)
    local now = now_time()
    local state = from_scroll_states[mail_id]
    
    --- POCZĄTEK POPRAWKI: MODYFIKACJA INICJALIZACJI STANU ---
    if not state or state.last_mail_id ~= mail_id then
        state = {start_time=now, phase="start", rep=0, last_mail_id=mail_id}
        from_scroll_states[mail_id] = state

        --- ZMIANA START ---
        -- [[ POPRAWKA PRZEWIJANIA v2 ]]
        if (not force_scroll_active and should_start_scrolling(mail) == false) or is_first_run_of_script then
        --- ZMIANA KONIEC ---
            state.phase = "done"
        end
    end
    --- KONIEC POPRAWKI: MODYFIKACJA INICJALIZACJI STANU ---

    local alias_prefix = ""
    local sender_part = from_txt
    local has_alias = false

    if mail.account_name and mail.account_name ~= "" then
        local prefix_candidate = "[" .. mail.account_name .. "] "
        if from_txt:sub(1, #prefix_candidate) == prefix_candidate then
            alias_prefix = prefix_candidate
            sender_part = from_txt:sub(#prefix_candidate + 1)
            has_alias = true
        end
    end

    local alias_width = 0
    if has_alias then
        set_font(cr, alias_font_name, alias_font_size, alias_font_bold, alias_font_italic)
        alias_width = text_width_with_emoji(cr, alias_prefix, alias_font_name, alias_font_size, alias_font_bold, alias_font_italic)
    end
    set_font(cr, from_font_name, from_font_size, from_font_bold, from_font_italic)
    local sender_width = text_width_with_emoji(cr, sender_part, from_font_name, from_font_size, from_font_bold, from_font_italic)

    local sender_x = x + alias_width
    local sender_max_w = maxw - alias_width
    if sender_max_w < 0 then sender_max_w = 0 end

    local scroll_len = sender_width - sender_max_w + scroll_extra
    if scroll_len < 1 then scroll_len = 1 end
    
    local delay_start  = scroll_delay or 0
    local pause_end    = FROM_SCROLL_PAUSE_END or 0.25
    local scroll_time  = math.max(scroll_len / (scroll_speed or (72 * GLOBAL_SCALE_FACTOR)), 0.5)
    local elapsed = now - state.start_time
    local phase = state.phase
    local ease_func = scroll_ease or "linear"

    if has_alias then
        local a = (mail.color[1] or 255) / 255
        local r = (mail.color[2] or 255) / 255
        local g = (mail.color[3] or 255) / 255
        local b = (mail.color[4] or 255) / 255
        cairo_set_source_rgba(cr, r, g, b, a)
        set_font(cr, alias_font_name, alias_font_size, alias_font_bold, alias_font_italic)
        draw_emoji_text(cr, alias_prefix, alias_font_name, alias_font_bold, alias_font_size, x, y, alias_font_italic)
    end

    set_color(cr, FROM_COLOR_TYPE, FROM_COLOR_CUSTOM)
    set_font(cr, from_font_name, from_font_size, from_font_bold, from_font_italic)
    
    if phase == "start" then
        if elapsed < delay_start then
            local trimmed_sender = trim_line_to_width_emoji(cr, sender_part, sender_max_w, from_font_name, from_font_size, from_font_bold, from_font_italic)
            draw_emoji_text(cr, trimmed_sender, from_font_name, from_font_bold, from_font_size, sender_x, y, from_font_italic)
        else
            state.phase = "scroll"
            state.start_time = now
            cairo_save(cr)
            cairo_rectangle(cr, sender_x, y - from_font_size, sender_max_w, from_font_size + (12 * GLOBAL_SCALE_FACTOR))
            cairo_clip(cr)
            draw_emoji_text(cr, sender_part, from_font_name, from_font_bold, from_font_size, sender_x, y, from_font_italic)
            cairo_restore(cr)
        end

    elseif phase == "scroll" then
        local t = math.min(1, elapsed / scroll_time)
        local ease_t = (ease_func == "easeOut") and ease_out(t) or t
        local offset = ease_t * scroll_len
        
        cairo_save(cr)
        cairo_rectangle(cr, sender_x, y - from_font_size, sender_max_w, from_font_size + (12 * GLOBAL_SCALE_FACTOR))
        cairo_clip(cr)
        draw_emoji_text(cr, sender_part, from_font_name, from_font_bold, from_font_size, sender_x - offset, y, from_font_italic)
        cairo_restore(cr)
        
        if t >= 1 then
            state.phase = "pause_end"
            state.start_time = now
        end
        
    elseif phase == "pause_end" then
        if elapsed < pause_end then
            cairo_save(cr)
            cairo_rectangle(cr, sender_x, y - from_font_size, sender_max_w, from_font_size + (12 * GLOBAL_SCALE_FACTOR))
            cairo_clip(cr)
            draw_emoji_text(cr, sender_part, from_font_name, from_font_bold, from_font_size, sender_x - scroll_len, y, from_font_italic)
            cairo_restore(cr)
        else
            state.rep = state.rep + 1
            if state.rep < scroll_repeat then
                state.phase = "start"
                state.start_time = now
            else
                state.phase = "done"
            end
        end
        
    elseif phase == "done" then
        local trimmed_sender = trim_line_to_width_emoji(cr, sender_part, sender_max_w, from_font_name, from_font_size, from_font_bold, from_font_italic)
        draw_emoji_text(cr, trimmed_sender, from_font_name, from_font_bold, from_font_size, sender_x, y, from_font_italic)
    end
    
    return x + maxw
end

local function draw_scrolling_text(cr, key, mail, text, x, y, maxw, font_name, font_size, font_bold, font_italic, opt, force_scroll_active)
    if not text or text == "" then return end
    
    local unique_id_for_suppression = get_mail_id(mail)
    if auto_reset_suppress_list[unique_id_for_suppression] then
        set_font(cr, font_name, font_size, font_bold, font_italic)
        local trimmed = cached_trim_emoji(cr, text, maxw, font_name, font_size, font_bold, font_italic)
        draw_emoji_text(cr, trimmed, font_name, font_bold, font_size, x, y, font_italic)
        return
    end

    local state_table = scroll_states[key] or {}
    scroll_states[key] = state_table
    local get_id = function()
        return key .. "|" .. get_mail_id(mail) .. "|" .. (text or "")
    end
    local mail_id = get_id()
    local now = now_time()
    local state = state_table[mail_id]

    --- POCZĄTEK POPRAWKI: MODYFIKACJA INICJALIZACJI STANU ---
    if not state or state.last_mail_id ~= mail_id then
        state = {start_time=now, phase="start", rep=0, last_mail_id=mail_id}
        state_table[mail_id] = state

        --- ZMIANA START ---
        -- [[ POPRAWKA PRZEWIJANIA v2 ]]
        if (not force_scroll_active and should_start_scrolling(mail) == false) or is_first_run_of_script then
        --- ZMIANA KONIEC ---
            state.phase = "done"
        end
    end
    --- KONIEC POPRAWKI: MODYFIKACJA INICJALIZACJI STANU ---

    set_font(cr, font_name, font_size, font_bold, font_italic)
    local text_width = cached_text_width_emoji(cr, text, font_name, font_size, font_bold, font_italic)

if text_width <= maxw or not opt.scroll_enable then
    local trimmed = cached_trim_emoji(cr, text, maxw, font_name, font_size, font_bold, font_italic)
    draw_emoji_text(cr, trimmed, font_name, font_bold, font_size, x, y, font_italic)
    return
end

    local scroll_extra = opt.scroll_extra or (36 * GLOBAL_SCALE_FACTOR)
    local scroll_len = text_width - maxw + scroll_extra
    if scroll_len < 1 then scroll_len = 1 end
    local delay_start  = opt.scroll_delay or 0
    local pause_end    = opt.scroll_pause_end or 0.25
    local scroll_speed = opt.scroll_speed or (72 * GLOBAL_SCALE_FACTOR)
    local scroll_repeat = opt.scroll_repeat or 2
    local scroll_time  = math.max(scroll_len / scroll_speed, 0.5)
    local elapsed = now - state.start_time
    local phase = state.phase
    local ease_func = opt.scroll_ease or "linear"

    if phase == "start" then
        if elapsed < delay_start then
            local trimmed = cached_trim_emoji(cr, text, maxw, font_name, font_size, font_bold, font_italic)
            draw_emoji_text(cr, trimmed, font_name, font_bold, font_size, x, y, font_italic)
        else
            state.phase = "scroll"
            state.start_time = now
        end

    elseif phase == "scroll" then
        local t = math.min(1, elapsed / scroll_time)
        local ease_t = (ease_func == "easeOut") and ease_out(t) or t
        local offset = ease_t * scroll_len

        cairo_save(cr)
        cairo_rectangle(cr, x, y - font_size, maxw, font_size + (12 * GLOBAL_SCALE_FACTOR))
        cairo_clip(cr)
        draw_emoji_text(cr, text, font_name, font_bold, font_size, x - offset, y, font_italic)
        cairo_restore(cr)

        if t >= 1 then
            state.phase = "pause_end"
            state.start_time = now
        end

    elseif phase == "pause_end" then
        if elapsed < pause_end then
            cairo_save(cr)
            cairo_rectangle(cr, x, y - font_size, maxw, font_size + (12 * GLOBAL_SCALE_FACTOR))
            cairo_clip(cr)
            draw_emoji_text(cr, text, font_name, font_bold, font_size, x - scroll_len, y, font_italic)
            cairo_restore(cr)
        else
            state.rep = state.rep + 1
            if state.rep < scroll_repeat then
                state.phase = "start"
                state.start_time = now
            else
                state.phase = "done"
            end
        end

    elseif phase == "done" then
    local trimmed = cached_trim_emoji(cr, text, maxw, font_name, font_size, font_bold, font_italic)
    draw_emoji_text(cr, trimmed, font_name, font_bold, font_size, x, y, font_italic)
    end
end

local function draw_main_background(cr)
    if not MAIN_BG_FILL_ENABLE and not MAIN_BG_BORDER_ENABLE then
        return
    end

    if conky_window == nil then return end

    local padding = MAIN_BG_PADDING or 0
    local x = padding + (MAIN_BG_OFFSET_X or 0)
    local y = padding + (MAIN_BG_OFFSET_Y or 0)
    local w = conky_window.width - (2 * padding)
    local h = conky_window.height - (2 * padding)
    local radius = MAIN_BG_RADIUS or 0
    
    local max_radius = math.min(w, h) / 2
    if radius > max_radius then radius = max_radius end

    cairo_save(cr)
    cairo_new_path(cr)
    cairo_move_to(cr, x + radius, y)
    cairo_arc(cr, x + w - radius, y + radius, radius, -math.pi/2, 0)
    cairo_arc(cr, x + w - radius, y + h - radius, radius, 0, math.pi/2)
    cairo_arc(cr, x + radius, y + h - radius, radius, math.pi/2, math.pi)
    cairo_arc(cr, x + radius, y + radius, radius, math.pi, 1.5*math.pi)
    cairo_close_path(cr)

    if MAIN_BG_FILL_ENABLE then
        local r, g, b = decode_rgb3(MAIN_BG_FILL_COLOR)
        cairo_set_source_rgba(cr, r, g, b, clamp01(MAIN_BG_FILL_ALPHA or 0.5))
        cairo_fill_preserve(cr)
    end

    if MAIN_BG_BORDER_ENABLE then
        local br, bg, bb = decode_rgb3(MAIN_BG_BORDER_COLOR)
        cairo_set_source_rgba(cr, br, bg, bb, clamp01(MAIN_BG_BORDER_ALPHA or 0.2))
        cairo_set_line_width(cr, MAIN_BG_BORDER_WIDTH or 2)
        cairo_stroke(cr)
    else
        cairo_new_path(cr)
    end
    cairo_restore(cr)
end

local function draw_per_mail_milk(
    cr, x, y, w, h, radius,
    fill_enable, fill_color, fill_alpha,
    border_enable, border_color, border_alpha, border_width
)
    cairo_save(cr)
    cairo_new_path(cr)
    cairo_move_to(cr, x + radius, y)
    cairo_arc(cr, x + w - radius, y + radius, radius, -math.pi/2, 0)
    cairo_arc(cr, x + w - radius, y + h - radius, radius, 0, math.pi/2)
    cairo_arc(cr, x + radius, y + h - radius, radius, math.pi/2, math.pi)
    cairo_arc(cr, x + radius, y + radius, radius, math.pi, 1.5*math.pi)
    cairo_close_path(cr)

    if fill_enable then
        local r, g, b = decode_rgb3(fill_color)
        cairo_set_source_rgba(cr, r, g, b, clamp01(fill_alpha or 0.2))
        cairo_fill_preserve(cr)
    end

    if border_enable then
        local br, bg, bb = decode_rgb3(border_color)
        cairo_set_source_rgba(cr, br, bg, bb, clamp01(border_alpha or 0.2))
        cairo_set_line_width(cr, border_width or (3 * GLOBAL_SCALE_FACTOR))
        cairo_stroke(cr)
    else
        cairo_new_path(cr)
    end
    cairo_restore(cr)
end

local function build_meta_line_segments(mail)
    if not mail or not mail.meta then return {} end
    local m = mail.meta
    local segments = {}
    local first = true

    local function add_separator()
        if not first then
            table.insert(segments, {txt=" | ", color=META_COLOR_SEPARATOR})
        end
    end

    for _, field in ipairs(META_LINE_ORDER) do
        local val, color = nil, nil
        
        if field == "age_text" and META_SHOW_AGE_TEXT and mail.timestamp and mail.timestamp > 0 then
            val, color = get_age_text(mail.timestamp), META_COLOR_AGE
        
        elseif field == "hour" and META_SHOW_DATETIME and m.datetime and m.datetime ~= "" then
            local year, month, day, hour, min, sec = m.datetime:match("(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)")
            if hour and min and sec then
                val, color = string.format("%02d:%02d:%02d", tonumber(hour), tonumber(min), tonumber(sec)), META_COLOR_DATETIME
            end
        elseif field == "date" and META_SHOW_DATETIME and m.datetime and m.datetime ~= "" then
            local year, month, day, hour, min, sec = m.datetime:match("(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)")
            if year and month and day then
                val, color = string.format("%02d-%02d-%04d", tonumber(day), tonumber(month), tonumber(year)), META_COLOR_DATETIME
            end
        elseif field == "ip" and META_SHOW_IP and m.ip and m.ip ~= "" and (not m.mobile or not META_SHOW_MOBILE) then
            val, color = "IP:"..m.ip, META_COLOR_IP
        elseif field == "ip_city" and META_SHOW_IP_CITY and m.ip_city and m.ip_city ~= "" and (not m.mobile or not META_SHOW_MOBILE) then
            val, color = m.ip_city, META_COLOR_CITY
        elseif field == "isp" and META_SHOW_IP_ISP and m.isp and m.isp ~= "" and (not m.mobile or not META_SHOW_MOBILE) then
            val, color = m.isp, META_COLOR_ISP
        elseif field == "agent" and META_SHOW_AGENT and m.agent and m.agent ~= "" then
            val, color = m.agent, META_COLOR_AGENT
        elseif field == "country" and META_SHOW_COUNTRY and m.country and m.country ~= "" then
            val, color = m.country, META_COLOR_COUNTRY
        elseif field == "mobile" and META_SHOW_MOBILE and m.mobile then
            val, color = "MOBILNY", META_COLOR_MOBILE
        end
        if val then
            add_separator()
            table.insert(segments, {txt=val, color=color})
            first = false
        end
    end
    return segments
end

local function measure_meta_line_width(cr, segments, font_name, font_bold, font_size, font_italic)
    local width = 0
    for _, seg in ipairs(segments) do
        set_font(cr, font_name, font_size, font_bold, font_italic)
        cairo_text_extents(cr, seg.txt, GLOBAL_TEXT_EXTENTS)
        width = width + GLOBAL_TEXT_EXTENTS.x_advance
    end
    return width
end

local function draw_meta_segments_trimmed(cr, segments, font_name, font_bold, font_size, font_italic, x, y, max_width)
    local cursor = x
    for idx, seg in ipairs(segments) do
        set_color(cr, "custom", seg.color)
        set_font(cr, font_name, font_size, font_bold, font_italic)
        cairo_text_extents(cr, seg.txt, GLOBAL_TEXT_EXTENTS)
        if cursor + GLOBAL_TEXT_EXTENTS.width <= x + max_width then
            draw_emoji_text(cr, seg.txt, font_name, font_bold, font_size, cursor, y, font_italic)
            cursor = cursor + GLOBAL_TEXT_EXTENTS.x_advance
        else
            local sub = seg.txt
            local found = false
            for i = 1, utf8_len(seg.txt) do
                local chunk = utf8_sub(seg.txt, 1, i) .. "..."
                cairo_text_extents(cr, chunk, GLOBAL_TEXT_EXTENTS)
                if cursor + GLOBAL_TEXT_EXTENTS.width > x + max_width then
                    sub = utf8_sub(seg.txt, 1, i-1)
                    found = true
                    break
                end
            end
            draw_emoji_text(cr, sub .. "...", font_name, font_bold, font_size, cursor, y, font_italic)
            cairo_text_extents(cr, sub .. "...", GLOBAL_TEXT_EXTENTS)
            cursor = cursor + GLOBAL_TEXT_EXTENTS.x_advance
            break
        end
    end
    return cursor
end

local function draw_meta_segments_scrolling(cr, segments, font_name, font_bold, font_size, font_italic, x, y, max_width, scroll_offset)
    local cursor = x - (scroll_offset or 0)
    for idx, seg in ipairs(segments) do
        set_color(cr, "custom", seg.color)
        set_font(cr, font_name, font_size, font_bold, font_italic)
        draw_emoji_text(cr, seg.txt, font_name, font_bold, font_size, cursor, y, font_italic)
        cairo_text_extents(cr, seg.txt, GLOBAL_TEXT_EXTENTS)
        cursor = cursor + GLOBAL_TEXT_EXTENTS.x_advance
        if cursor > x + max_width then break end
    end
end

local function segments_signature(segments)
    local t = {}
    for _, seg in ipairs(segments) do
        t[#t+1] = seg.txt or ""
    end
    return table.concat(t, "\31")
end

local function draw_meta_line_rich(cr, mail, x, y, force_scroll_active)
    local meta_id = "meta|" .. (mail.uid or get_mail_id(mail))
    local now = now_time()
    local state = meta_scroll_states[meta_id]
    
    -- [[ POPRAWKA PRZEWIJANIA v3 ]]
    if not state or state.last_mail_id ~= meta_id then
        state = {start_time=now, phase="start", rep=0, last_mail_id=meta_id}
        meta_scroll_states[meta_id] = state
        if (not force_scroll_active and should_start_scrolling(mail) == false) or is_first_run_of_script then
            state.phase = "done"
        end
    end

    local font_name = META_LINE_FONT_NAME
    local font_bold = META_LINE_FONT_BOLD
    local font_size = META_LINE_FONT_SIZE
    local font_italic = META_LINE_FONT_ITALIC

    local segments = build_meta_line_segments(mail)
    if #segments == 0 then return end

    local sig = segments_signature(segments)
    local key = table.concat({sig, font_name, font_size, font_bold and "b" or "n", font_italic and "i" or "n"}, "|")
    local total_width = meta_width_cache[key]
    if not total_width then
        total_width = measure_meta_line_width(cr, segments, font_name, font_bold, font_size, font_italic)
        meta_width_cache[key] = total_width
    end

    if total_width <= META_LINE_MAX_WIDTH or not META_LINE_SCROLL_ENABLE then
        draw_meta_segments_trimmed(cr, segments, font_name, font_bold, font_size, font_italic, x, y, META_LINE_MAX_WIDTH)
        return
    end

    local scroll_extra = META_LINE_SCROLL_EXTRA or (36 * GLOBAL_SCALE_FACTOR)
    local scroll_len = total_width - META_LINE_MAX_WIDTH + scroll_extra
    if scroll_len < 1 then scroll_len = 1 end
    local delay_start  = META_LINE_SCROLL_DELAY or 0
    local pause_end = META_LINE_SCROLL_PAUSE_END or 0.25
    local scroll_speed = META_LINE_SCROLL_SPEED or (72 * GLOBAL_SCALE_FACTOR)
    local scroll_repeat = META_LINE_SCROLL_REPEAT or 2
    local scroll_time  = math.max(scroll_len / scroll_speed, 0.5)
    local elapsed = now - state.start_time
    local phase = state.phase
    local ease_func = META_LINE_SCROLL_EASE or "linear"

    if phase == "start" then
        if elapsed < delay_start then
            draw_meta_segments_trimmed(cr, segments, font_name, font_bold, font_size, font_italic, x, y, META_LINE_MAX_WIDTH)
        else
            state.phase = "scroll"
            state.start_time = now
        end

    elseif phase == "scroll" then
        local t = math.min(1, elapsed / scroll_time)
        local ease_t = (ease_func == "easeOut") and ease_out(t) or t
        local offset = ease_t * scroll_len

        cairo_save(cr)
        cairo_rectangle(cr, x, y - font_size, META_LINE_MAX_WIDTH, font_size + (12 * GLOBAL_SCALE_FACTOR))
        cairo_clip(cr)
        draw_meta_segments_scrolling(cr, segments, font_name, font_bold, font_size, font_italic, x, y, META_LINE_MAX_WIDTH, offset)
        cairo_restore(cr)

        if t >= 1 then
            state.phase = "pause_end"
            state.start_time = now
        end

    elseif phase == "pause_end" then
        if elapsed < pause_end then
            cairo_save(cr)
            cairo_rectangle(cr, x, y - font_size, META_LINE_MAX_WIDTH, font_size + (12 * GLOBAL_SCALE_FACTOR))
            cairo_clip(cr)
            draw_meta_segments_scrolling(cr, segments, font_name, font_bold, font_size, font_italic, x, y, META_LINE_MAX_WIDTH, scroll_len)
            cairo_restore(cr)
        else
            state.rep = state.rep + 1
            if state.rep < scroll_repeat then
                state.phase = "start"
                state.start_time = now
            else
                state.phase = "done"
            end
        end

    elseif phase == "done" then
        draw_meta_segments_trimmed(cr, segments, font_name, font_bold, font_size, font_italic, x, y, META_LINE_MAX_WIDTH)
    end
end

local function draw_custom_user_text(cr)
    if not CUSTOM_TEXT_ENABLE or not CUSTOM_TEXT_VALUE or CUSTOM_TEXT_VALUE == "" then return end
    set_color(cr, CUSTOM_TEXT_COLOR_TYPE, CUSTOM_TEXT_COLOR_CUSTOM)
    set_font(cr, CUSTOM_TEXT_FONT, CUSTOM_TEXT_SIZE, CUSTOM_TEXT_BOLD, CUSTOM_TEXT_ITALIC)
    draw_emoji_text(cr, CUSTOM_TEXT_VALUE, CUSTOM_TEXT_FONT, CUSTOM_TEXT_BOLD, CUSTOM_TEXT_SIZE, CUSTOM_TEXT_POS.x, CUSTOM_TEXT_POS.y, CUSTOM_TEXT_ITALIC)
end

local function draw_separator(cr)
    if not SEPARATOR_ENABLE then return end
    local x1 = SEPARATOR_X
    local y1 = SEPARATOR_Y
    local x2 = SEPARATOR_X + SEPARATOR_LENGTH
    local y2 = SEPARATOR_Y

    set_color(cr, SEPARATOR_COLOR_TYPE, SEPARATOR_COLOR_CUSTOM)
    cairo_set_line_width(cr, SEPARATOR_WIDTH or (1.5 * GLOBAL_SCALE_FACTOR))
    cairo_move_to(cr, x1, y1)
    cairo_line_to(cr, x2, y2)
    cairo_stroke(cr)
end

local function get_mail_block_height(mail)
    local line_count = 1
    if SHOW_MAIL_PREVIEW and mail and mail.preview and mail.preview ~= "" then
        line_count = line_count + 1
    end
    if META_LINE_ENABLE then
        line_count = line_count + 1
    end

    if line_count == 3 then
        return SPACING_3_LINES
    elseif line_count == 2 then
        return SPACING_2_LINES
    else
        return SPACING_1_LINE
    end
end

-- [[ OPTYMALIZACJA START ]]
local function read_mail_scroll_offset()
    local current_mtime = get_file_mtime(MAIL_SCROLL_FILE)

    if current_mtime > 0 and current_mtime == last_scroll_offset_mtime then
        return cached_scroll_offset
    end

    local f = io.open(MAIL_SCROLL_FILE, "r")
    local value = 0
    if f then
        local content = f:read("*a") or "0"
        f:close()
        value = tonumber(content:match("%-?%d+")) or 0
    end

    cached_scroll_offset = value
    last_scroll_offset_mtime = current_mtime
    
    return value
end
-- [[ OPTYMALIZACJA KONIEC ]]


local function write_mail_scroll_offset(offset)
    local f = io.open(MAIL_SCROLL_FILE, "w")
    if f then f:write(tostring(offset)); f:close() end
end

-- [[ OPTYMALIZACJA USUNIĘTA ]]
-- Ta funkcja nie jest już potrzebna, ponieważ zastąpiła ją uniwersalna `get_file_mtime`.
-- local function get_mail_scroll_mtime() ... end
-- [[ OPTYMALIZACJA USUNIĘTA ]]

local function apply_mail_scroll(filtered_mails, MAX_MAILS, MAILS_DIRECTION)
    local offset = read_mail_scroll_offset()

    local N = #filtered_mails
    local max_visible = math.max(0, MAX_MAILS or 0)
    local max_offset  = math.max(N - max_visible, 0)

    if offset < 0 then offset = 0 end
    if offset > max_offset then
        offset = max_offset
        write_mail_scroll_offset(offset) -- Poprawka: upewnij się, że plik ma poprawną wartość
    end

    local first = math.max(1, 1 + offset)
    local last  = math.min(N, first + max_visible - 1)
    local out = {}
    for i = first, last do out[#out+1] = filtered_mails[i] end

    return out, offset, max_offset
end

local function _conky_draw_mail_indicator_impl()
    if conky_window == nil then return end

    -- [[ POPRAWKA PRZEWIJANIA v3 ]]
    -- Ten blok musi być na samym początku, zaraz po wczytaniu stanów z dysku.
    if is_first_run_of_script then
        -- Wymuś zakończenie wszystkich animacji, które mogły być w toku podczas przeładowania.
        -- To zapobiega ich niechcianemu kontynuowaniu lub resetowaniu.
        for id, state in pairs(from_scroll_states) do
            state.phase = "done"
        end
        for id, state in pairs(scroll_states.subject) do
            state.phase = "done"
        end
        for id, state in pairs(scroll_states.preview) do
            state.phase = "done"
        end
        for id, state in pairs(meta_scroll_states) do
            state.phase = "done"
        end
    end

    local now = os.time()
    
    --- OSTATECZNA POPRAWKA v5 START (ZMIANA 3/4) ---
    -- ==================================================================
    -- === CENTRALNA LOGIKA CZASU I STANU                             ===
    -- ==================================================================
    
    -- 1. Sprawdź, czy użytkownik właśnie przewinął listę (jedyny dowód aktywności)
    local SCROLL_ACTIVE_FLAG_FILE = "/dev/shm/conky-automail-suite/scroll.active"
    if file_exists(SCROLL_ACTIVE_FLAG_FILE) then
        mail_widget_state.last_user_interaction_time = now
        os.remove(SCROLL_ACTIVE_FLAG_FILE)
    end
    
    -- 2. Sprawdź, czy nastąpił timeout od ostatniej akcji użytkownika
    local offset = read_mail_scroll_offset()
    if offset ~= 0 and (now - mail_widget_state.last_user_interaction_time > SCROLL_TIMEOUT) then
        write_mail_scroll_offset(0)
        mail_widget_state.auto_reset_occurred = true -- Ustaw flagę!
    end

    -- 3. Sprawdź, czy można aktywować przewijanie tekstu na żądanie
    local force_scroll_active = false
    if (now - mail_widget_state.last_user_interaction_time) > SCROLL_TIMEOUT then
        if file_exists(FORCE_SCROLL_TRIGGER_FILE) then
            print("[INFO] Wykryto ręczny trigger przewijania.")
            force_scroll_active = true
            os.remove(FORCE_SCROLL_TRIGGER_FILE)
        end
    end
    --- OSTATECZNA POPRAWKA v5 KONIEC ---

    -- Jeśli nastąpił auto-reset lub ręczny trigger, wyczyść stany animacji
    if mail_widget_state.auto_reset_occurred or force_scroll_active then
        from_scroll_states = {}
        scroll_states.subject = {}
        scroll_states.preview = {}
        meta_scroll_states = {}
    end

    set_layout_by_mode()

    local data = fetch_mails_from_cache()
    local unread      = tonumber(data.unread) or 0
    local all         = tonumber(data.all) or unread
    local unread_cache = tonumber(data.unread_cache) or 0
    local mails       = data.mails or {}

    local current_uids = {}
    if mails and #mails > 0 then
        for _, mail in ipairs(mails) do
            local uid = mail.uid or ((mail.subject or "") .. (mail.from or ""))
            current_uids[uid] = true
        end
    end

    if SUPPRESS_BLINK_THIS_SESSION and SUPPRESS_BLINK_IDS == nil then
        SUPPRESS_BLINK_IDS = {}
        for _, m in ipairs(mails) do
            local id = m.uid or ((m.subject or "") .. (m.from or ""))
            SUPPRESS_BLINK_IDS[id] = true
        end
    end

    local badge_count
    if BADGE_SOURCE == "all" then
        badge_count = all
    elseif BADGE_SOURCE == "unread_cache" then
        badge_count = unread_cache
    else
        badge_count = unread
    end

    last_good_mails = {}
    for i, mail in ipairs(mails) do
        local from
        if SHOW_SENDER_EMAIL then
            from = safe_str(mail.from, "(brak nadawcy)")
        else
            from = safe_str(mail.from_name, safe_str(mail.from, "(brak nadawcy)"))
        end
        local subject = safe_str(mail.subject, "(brak tematu)")
        local preview = safe_str(mail.preview, "(brak podglądu)")
        
        local current_uid = mail.uid or ((mail.subject or "") .. (mail.from or ""))
        local is_genuinely_new_flag = not previously_known_uids[current_uid]
        
        table.insert(last_good_mails, {
            from=from,
            subject=subject,
            preview=preview,
            has_attachment=mail.has_attachment,
            from_raw=mail.from,
            from_name=mail.from_name,
            meta=mail.meta,
            uid=mail.uid,
            timestamp = mail.timestamp,
            account_name = mail.account_name,
            color = mail.color,
            is_genuinely_new = is_genuinely_new_flag
        })
    end

    do
        if suppress_list_signature ~= "" then
            local current_uids_for_sig = {}
            for _, mail in ipairs(last_good_mails) do
                table.insert(current_uids_for_sig, mail.uid or get_mail_id(mail))
            end
            local current_signature = table.concat(current_uids_for_sig, "|")

            if suppress_list_signature ~= current_signature then
                from_scroll_states = {}
                scroll_states.subject = {}
                scroll_states.preview = {}
                meta_scroll_states = {}

                auto_reset_suppress_list = {}
                local num_to_check = math.min(#last_good_mails, MAX_MAILS)
                for i = 1, num_to_check do
                    local mail = last_good_mails[i]
                    if not mail.is_genuinely_new then
                        auto_reset_suppress_list[get_mail_id(mail)] = true
                    end
                end

                suppress_list_signature = current_signature
            end
        end
    end

    cleanup_attachment_blink_states(last_good_mails)
    cleanup_pulse_states(last_good_mails)

    if NEW_MAIL_SOUND_ENABLE and last_mail_json_ok and previous_unread_count ~= nil and unread > previous_unread_count then
        if file_exists(NEW_MAIL_SOUND) then
            os.execute('paplay "' .. NEW_MAIL_SOUND .. '" &')
        else
            print("BŁĄD: Nie znaleziono pliku dźwięku: " .. NEW_MAIL_SOUND)
        end
    end
    if MAIL_DISAPPEAR_SOUND_ENABLE and last_mail_json_ok and previous_unread_count ~= nil and unread < previous_unread_count then
        if file_exists(MAIL_DISAPPEAR_SOUND) then
            os.execute('paplay "' .. MAIL_DISAPPEAR_SOUND .. '" &')
        else
            print("BŁĄD: Nie znaleziono pliku dźwięku: " .. MAIL_DISAPPEAR_SOUND)
        end
    end
    previous_unread_count = unread

    -- Usunąłem starą funkcję `apply_mail_scroll`, bo cała jej logika jest teraz wyżej
    local N = #last_good_mails
    local max_visible = math.max(0, MAX_MAILS or 0)
    local current_offset = read_mail_scroll_offset()
    local max_offset  = math.max(N - max_visible, 0)
    if current_offset < 0 then current_offset = 0 end
    if current_offset > max_offset then current_offset = max_offset end
    local first = math.max(1, 1 + current_offset)
    local last  = math.min(N, first + max_visible - 1)
    local visible = {}
    for i = first, last do visible[#visible+1] = last_good_mails[i] end
    
    --- POCZĄTEK POPRAWKI: OBSŁUGA PIERWSZEGO URUCHOMIENIA ---
    if is_first_run_of_script then
        -- To jest pierwsza klatka po przeładowaniu.
        -- Zapisujemy aktualnie widoczne maile, aby nie animowały się bez powodu.
        for _, mail in ipairs(visible) do
            local uid = mail.uid or get_mail_id(mail)
            uids_visible_in_last_frame[uid] = true
        end
    end
    --- KONIEC POPRAWKI: OBSŁUGA PIERWSZEGO URUCHOMIENIA ---

    do
        local visible_mail_ids = {}
        for _, mail in ipairs(visible) do
            local from_prefix = ""
            if mail.account_name and mail.account_name ~= "" then
                from_prefix = "[" .. mail.account_name .. "] "
            end
            local from_txt = from_prefix .. (mail.from or ""):gsub(":*$", "") .. ":"
            visible_mail_ids[get_mail_from_id(mail, from_txt)] = true

            local subject_id = "subject|" .. get_mail_id(mail) .. "|" .. (mail.subject or "")
            visible_mail_ids[subject_id] = true

            local preview_line = join_preview_lines(mail.preview, MAIL_PREVIEW_LINES)
            local preview_id = "preview|" .. get_mail_id(mail) .. "|" .. preview_line
            visible_mail_ids[preview_id] = true
            
            local meta_id = "meta|" .. (mail.uid or get_mail_id(mail))
            visible_mail_ids[meta_id] = true
        end

        for id, _ in pairs(from_scroll_states) do
            if not visible_mail_ids[id] then from_scroll_states[id] = nil end
        end
        for id, _ in pairs(scroll_states.subject) do
            if not visible_mail_ids[id] then scroll_states.subject[id] = nil end
        end
        for id, _ in pairs(scroll_states.preview) do
            if not visible_mail_ids[id] then scroll_states.preview[id] = nil end
        end
        for id, _ in pairs(meta_scroll_states) do
            if not visible_mail_ids[id] then meta_scroll_states[id] = nil end
        end
    end

    local cs = cairo_xlib_surface_create(conky_window.display,
                                         conky_window.drawable,
                                         conky_window.visual,
                                         conky_window.width,
                                         conky_window.height)
    local cr = cairo_create(cs)
    
    draw_main_background(cr)
    
    local current_time_for_drawing = now_time()

    draw_custom_user_text(cr)
    draw_separator(cr)

    if SHOW_ENVELOPE_ICON then
        draw_png_rotated(cr, ENVELOPE_POS.x, ENVELOPE_POS.y, ENVELOPE_SIZE.w, ENVELOPE_SIZE.h, ENVELOPE_IMAGE, ENVELOPE_IMAGE_ANGLE, ENVELOPE_MIRROR)
    end

    if SHOW_BADGE and badge_count > 0 then
        local badge_x = ENVELOPE_POS.x + (BADGE_POS.dx or (ENVELOPE_SIZE.w - BADGE_RADIUS + (3 * GLOBAL_SCALE_FACTOR)))
        local badge_y = ENVELOPE_POS.y + (BADGE_POS.dy or (-BADGE_RADIUS + (24 * GLOBAL_SCALE_FACTOR)))
        cairo_arc(cr, badge_x, badge_y, BADGE_RADIUS, 0, 2*math.pi)
        set_color(cr, BADGE_COLOR_TYPE, BADGE_COLOR_CUSTOM)
        cairo_fill_preserve(cr)
        set_color(cr, BADGE_BORDER_COLOR_TYPE, BADGE_BORDER_COLOR_CUSTOM)
        cairo_set_line_width(cr, 3.3 * GLOBAL_SCALE_FACTOR)
        cairo_stroke(cr)
        set_color(cr, BADGE_TEXT_COLOR_TYPE, BADGE_TEXT_COLOR_CUSTOM)
        set_font(cr, FROM_FONT_NAME, FROM_FONT_SIZE + (4.5 * GLOBAL_SCALE_FACTOR), true, FROM_FONT_ITALIC)
        local txt = tostring(badge_count)
        cairo_text_extents(cr, txt, GLOBAL_TEXT_EXTENTS)
        cairo_move_to(cr, badge_x - GLOBAL_TEXT_EXTENTS.width/2 - GLOBAL_TEXT_EXTENTS.x_bearing, badge_y + GLOBAL_TEXT_EXTENTS.height/2)
        cairo_show_text(cr, txt)
    end

    local num_mails = #visible
    local text_x = MAILS_POS.x

    local mail_positions = {}

    if MAILS_DIRECTION == "down" then
        local y = MAILS_POS.y
        for i = 1, num_mails do
            mail_positions[i] = y
            y = y + get_mail_block_height(visible[i] or {})
        end
    else
        local y = conky_window.height - MAILS_POS.y
        for i = num_mails, 1, -1 do
            y = y - get_mail_block_height(visible[i] or {})
            mail_positions[i] = y
        end
    end

    for i = 1, num_mails do
        local mail = visible[i] or {}
        local y_offset = mail_positions[i]

        local current_milk_height, current_milk_margin_y
        local current_preview_offset_y, current_meta_offset_y
        local current_sender_offset_y
        local current_attachment_icon_offset, current_attachment_dot_offset

        local line_count = 1
        if SHOW_MAIL_PREVIEW and mail and mail.preview and mail.preview ~= "" then
            line_count = line_count + 1
        end
        if META_LINE_ENABLE then
            line_count = line_count + 1
        end

        if line_count == 3 then
            current_milk_height = HEIGHT_3_LINES
            current_milk_margin_y = MARGIN_Y_3_LINES
            current_sender_offset_y = SENDER_OFFSET_Y_3_LINES
            current_preview_offset_y = PREVIEW_OFFSET_Y_3_LINES
            current_meta_offset_y = META_OFFSET_Y_3_LINES
            current_attachment_icon_offset = ATTACHMENT_ICON_OFFSET_3_LINES
            current_attachment_dot_offset = ATTACHMENT_DOT_OFFSET_3_LINES
        elseif line_count == 2 then
            current_milk_height = HEIGHT_2_LINES
            current_milk_margin_y = MARGIN_Y_2_LINES
            current_sender_offset_y = SENDER_OFFSET_Y_2_LINES
            if SHOW_MAIL_PREVIEW and mail and mail.preview and mail.preview ~= "" then
                 current_preview_offset_y = PREVIEW_OFFSET_Y_2_LINES
            end
            if META_LINE_ENABLE then
                 current_meta_offset_y = META_OFFSET_Y_2_LINES
            end
            current_attachment_icon_offset = ATTACHMENT_ICON_OFFSET_2_LINES
            current_attachment_dot_offset = ATTACHMENT_DOT_OFFSET_2_LINES
        else
            current_milk_height = HEIGHT_1_LINE
            current_milk_margin_y = MARGIN_Y_1_LINE
            current_sender_offset_y = SENDER_OFFSET_Y_1_LINE
            current_attachment_icon_offset = ATTACHMENT_ICON_OFFSET_1_LINE
            current_attachment_dot_offset = ATTACHMENT_DOT_OFFSET_1_LINE
        end
        
        do
            local pulse_state = get_pulse_state(mail, current_time_for_drawing)
            local final_fill_color = PER_MAIL_MILK_FILL_COLOR
            local final_fill_alpha = PER_MAIL_MILK_FILL_ALPHA
            local final_border_color = PER_MAIL_MILK_BORDER_COLOR
            local final_border_alpha = PER_MAIL_MILK_BORDER_ALPHA
            
            if pulse_state.is_animating then
                final_fill_alpha = pulse_state.fill_alpha
                if PULSE_ANIM_USE_CUSTOM_COLOR then
                    if PULSE_ANIM_USE_TWO_COLORS then
                        final_fill_color = interpolate_color(PULSE_ANIM_CUSTOM_COLOR_A, PULSE_ANIM_CUSTOM_COLOR_B, pulse_state.progress)
                    else
                        final_fill_color = PULSE_ANIM_CUSTOM_COLOR_A
                    end
                end

                if PULSE_BORDER_ANIM_ENABLE then
                    final_border_alpha = pulse_state.border_alpha
                    if PULSE_BORDER_ANIM_USE_TWO_COLORS then
                        final_border_color = interpolate_color(PULSE_BORDER_ANIM_CUSTOM_COLOR_A, PULSE_BORDER_ANIM_CUSTOM_COLOR_B, pulse_state.progress)
                    else
                        final_border_color = PULSE_BORDER_ANIM_CUSTOM_COLOR_A
                    end
                end
            end

            local should_draw_fill = PER_MAIL_MILK_FILL_ENABLE or (pulse_state.is_animating and PULSE_ANIM_ENABLE)
            local should_draw_border = PER_MAIL_MILK_BORDER_ENABLE or (pulse_state.is_animating and PULSE_BORDER_ANIM_ENABLE)

            if should_draw_fill or should_draw_border then
                local milk_x = text_x + (PER_MAIL_MILK_MARGIN_X or 0)
                local milk_y = y_offset + (current_milk_margin_y or 0)
                local milk_w = PER_MAIL_MILK_WIDTH or (1065 * GLOBAL_SCALE_FACTOR)
                local milk_h = current_milk_height or (82.5 * GLOBAL_SCALE_FACTOR)
                local max_radius = math.min(milk_w, milk_h) / 2
                local milk_radius = PER_MAIL_MILK_RADIUS
                if milk_radius < 0 then milk_radius = 0 end
                if milk_radius > max_radius then milk_radius = max_radius end
                
                draw_per_mail_milk(
                    cr, milk_x, milk_y, milk_w, milk_h, milk_radius,
                    should_draw_fill, final_fill_color, final_fill_alpha,
                    should_draw_border, final_border_color, final_border_alpha, PER_MAIL_MILK_BORDER_WIDTH
                )
            end
        end

        set_font(cr, FROM_FONT_NAME, FROM_FONT_SIZE, FROM_FONT_BOLD, FROM_FONT_ITALIC)
        local from_prefix = ""
        if mail.account_name and mail.account_name ~= "" then
            from_prefix = "[" .. mail.account_name .. "] "
        end
        local from_txt = from_prefix .. (mail.from or ""):gsub(":*$", "") .. ":"
        local from_end = draw_from_scrolling(cr, mail, from_txt, text_x, y_offset + (current_sender_offset_y or 0), force_scroll_active)

        if mail.has_attachment then
            local show_attach = attachment_blink_is_visible(mail, current_time_for_drawing)
            if show_attach then
                if ATTACHMENT_ICON_ENABLE then
                    local icon_x = text_x + (current_attachment_icon_offset.dx or 0)
                    local icon_y = (y_offset + (current_sender_offset_y or 0)) + (current_attachment_icon_offset.dy or 0)
                    draw_png_rotated(cr, icon_x, icon_y, ATTACHMENT_ICON_SIZE.w, ATTACHMENT_ICON_SIZE.h, ATTACHMENT_ICON_IMAGE, ATTACHMENT_ICON_ANGLE, ATTACHMENT_ICON_MIRROR)
                end
                if ATTACHMENT_DOT_ENABLE then
                    local dot_x = text_x + (current_attachment_dot_offset.dx or 0)
                    local dot_y = (y_offset + (current_sender_offset_y or 0)) + (current_attachment_dot_offset.dy or 0) + FROM_FONT_SIZE/2
                    cairo_arc(cr, dot_x, dot_y, ATTACHMENT_DOT_RADIUS, 0, 2*math.pi)
                    set_color(cr, ATTACHMENT_DOT_COLOR_TYPE, ATTACHMENT_DOT_COLOR_CUSTOM)
                    cairo_fill(cr)
                end
            end
        end

        set_color(cr, SUBJECT_COLOR_TYPE, SUBJECT_COLOR_CUSTOM)
        set_font(cr, SUBJECT_FONT_NAME, SUBJECT_FONT_SIZE, SUBJECT_FONT_BOLD, SUBJECT_FONT_ITALIC)
        local subject_txt = mail.subject or ""
        local subject_x = from_end + FROM_TO_SUBJECT_GAP
        draw_scrolling_text(
            cr, "subject", mail, subject_txt, subject_x, y_offset + (current_sender_offset_y or 0), SUBJECT_MAX_WIDTH - (subject_x - text_x) - (18 * GLOBAL_SCALE_FACTOR),
            SUBJECT_FONT_NAME, SUBJECT_FONT_SIZE, SUBJECT_FONT_BOLD, SUBJECT_FONT_ITALIC,
            {
                scroll_enable = SUBJECT_SCROLL_ENABLE,
                scroll_speed  = SUBJECT_SCROLL_SPEED,
                scroll_repeat = SUBJECT_SCROLL_REPEAT,
                scroll_delay  = SUBJECT_SCROLL_DELAY,
                scroll_ease   = SUBJECT_SCROLL_EASE,
                scroll_extra  = SUBJECT_SCROLL_EXTRA,
                scroll_pause_end = SUBJECT_SCROLL_PAUSE_END,
            },
            force_scroll_active
        )

        if SHOW_MAIL_PREVIEW and mail.preview and mail.preview ~= "" and current_preview_offset_y then
            local preview_y = y_offset + current_preview_offset_y
            set_color(cr, PREVIEW_COLOR_TYPE, PREVIEW_COLOR_CUSTOM)
            set_font(cr, PREVIEW_FONT_NAME, PREVIEW_FONT_SIZE, PREVIEW_FONT_BOLD, PREVIEW_FONT_ITALIC)
            local preview_line = join_preview_lines(mail.preview, MAIL_PREVIEW_LINES)
            local preview_cursor = PREVIEW_INDENT and (text_x + (27 * GLOBAL_SCALE_FACTOR)) or text_x
            draw_scrolling_text(
                cr, "preview", mail, preview_line, preview_cursor, preview_y,
                PREVIEW_MAX_WIDTH - (18 * GLOBAL_SCALE_FACTOR),
                PREVIEW_FONT_NAME, PREVIEW_FONT_SIZE, PREVIEW_FONT_BOLD, PREVIEW_FONT_ITALIC,
                {
                    scroll_enable = PREVIEW_SCROLL_ENABLE,
                    scroll_speed  = PREVIEW_SCROLL_SPEED,
                    scroll_repeat = PREVIEW_SCROLL_REPEAT,
                    scroll_delay  = PREVIEW_SCROLL_DELAY,
                    scroll_ease   = PREVIEW_SCROLL_EASE,
                    scroll_extra  = PREVIEW_SCROLL_EXTRA,
                    scroll_pause_end = PREVIEW_SCROLL_PAUSE_END,
                },
                force_scroll_active
            )
        end

        if META_LINE_ENABLE and current_meta_offset_y then
            local meta_y = y_offset + current_meta_offset_y
            draw_meta_line_rich(cr, mail, text_x, meta_y, force_scroll_active)
        end
    end

    --- POCZĄTEK POPRAWKI: AKTUALIZACJA STANU WIDOCZNYCH MAILI ---
    do
        local uids_this_frame = {}
        for _, mail in ipairs(visible) do
            local uid = mail.uid or get_mail_id(mail)
            uids_this_frame[uid] = true
        end
        uids_visible_in_last_frame = uids_this_frame
    end
    --- KONIEC POPRAWKI: AKTUALIZACJA STANU WIDOCZNYCH MAILI ---
    
    if not are_tables_equal(current_uids, previously_known_uids) then
        save_previously_known_uids(current_uids)
    end
    previously_known_uids = current_uids
    
    -- [[ OPTYMALIZACJA ZAPISU v2 ]]
    if not are_tables_equal(uids_visible_in_last_frame, last_saved_visible_uids) then
        save_last_visible_uids(uids_visible_in_last_frame)
        last_saved_visible_uids = uids_visible_in_last_frame
    end
    
    local current_scroll_states = {
        from = from_scroll_states,
        subject = scroll_states.subject,
        preview = scroll_states.preview,
        meta = meta_scroll_states
    }

    if not are_tables_equal(current_scroll_states, last_saved_scroll_states) then
        save_scroll_states(from_scroll_states, scroll_states.subject, scroll_states.preview, meta_scroll_states)
        last_saved_scroll_states = current_scroll_states
    end
    
    --- OSTATECZNA POPRAWKA v5 START (ZMIANA 4/4) ---
    -- Na sam koniec klatki, zresetuj flagę auto-resetu, aby nie wpływała na następną klatkę.
    if mail_widget_state.auto_reset_occurred then
        mail_widget_state.auto_reset_occurred = false
    end
    --- OSTATECZNA POPRAWKA v5 KONIEC ---
    
    -- [[ POPRAWKA PRZEWIJANIA v2 ]] Na sam koniec, wyłącz flagę pierwszego uruchomienia.
    is_first_run_of_script = false

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end

function conky_draw_mail_indicator()
    local ok, err = xpcall(_conky_draw_mail_indicator_impl, function(e)
        local traceback = debug.traceback(tostring(e), 2)
        local err_msg = "[conky-mail:err] Execution failed!\n" ..
                        "----------------------------------------\n" ..
                        "ERROR: " .. tostring(e) .. "\n" ..
                        "----------------------------------------\n" ..
                        "STACK TRACEBACK:\n" .. traceback ..
                        "----------------------------------------\n"
        return err_msg
    end)
    if not ok then
        print(err)
    end
end
