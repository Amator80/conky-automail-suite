#!/bin/bash

# ==============================================================================
# ===      TRIGGER RĘCZNEGO PRZEWIJANIA TEKSTÓW W WIDOCZNYCH MAILACH       ===
# ==============================================================================
#
# Działanie:
# Ten skrypt tworzy plik-flagę, który jest natychmiast wykrywany
# przez skrypt Lua w Conky. Po wykryciu, Lua resetuje i ponownie
# uruchamia wszystkie animacje przewijania długich tekstów.
#
# ------------------------------------------------------------------------------

# --- KONFIGURACJA ---
# WAŻNE: Ta ścieżka musi być DOKŁADNIE taka sama, jak ta zdefiniowana
# w Twoim skrypcie Lua (zmienna FORCE_SCROLL_TRIGGER_FILE).
TRIGGER_FILE="/dev/shm/conky-automail-suite/force_scroll_trigger"

# --- GŁÓWNA LOGIKA ---
# Tworzy pusty plik w określonej lokalizacji.
# To jest sygnał dla skryptu Lua.
touch "$TRIGGER_FILE"

# --- POTWIERDZENIE DLA UŻYTKOWNIKA ---
echo "Sygnał do ponownego przewinięcia tekstów został wysłany."```

### Podsumowanie

1.  Użyj **dokładnie tej wersji skryptu Lua**, którą podałem w poprzedniej odpowiedzi.
2.  Użyj **dokładnie tej wersji skryptu Bash**, którą podałem powyżej.

Po tych dwóch krokach system musi działać poprawnie. Skrypt Bash utworzy odpowiedni plik, a skrypt Lua go wykryje i zareaguje, ponieważ teraz obie części "rozmawiają" o tym samym pliku.
