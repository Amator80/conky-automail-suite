# Conky AutoMail Suite v2.x.x
![Licencja: GPL v3](https://img.shields.io/badge/Licencja-GPL_v3-blue.svg)
![Wersja: 2.x.x](https://img.shields.io/badge/Wersja-2.x.x-brightgreen)
![Utrzymywany?: Tak](https://img.shields.io/badge/Utrzymywany%3F-Tak-green.svg)
![Platforma: Linux](https://img.shields.io/badge/Platforma-Linux-lightgrey.svg?logo=linux)

![alt text](screenshot.png)

**Conky AutoMail Suite** to nie tylko widżet, ale kompletny, modułowy system do monitorowania poczty e-mail w środowisku Conky na Linuksie. Dzięki zaawansowanej architekturze z demonem w Pythonie, graficznym narzędziom konfiguracyjnym i potężnym możliwościom personalizacji w Lua, projekt zapewnia niezrównaną wydajność, stabilność i wygodę użytkowania.

Wersja **2.x.x** wprowadza przełomowe zmiany: pełne szyfrowanie haseł (Security Pro), system awatarów nadawców oraz asynchroniczne przetwarzanie danych.

---

### Spis Treści
1. [Co nowego w v2.x.x?](#co-nowego-w-v200)
2. [O Projekcie](#o-projekcie)
3. [Główne Filary Projektu](#główne-filary-projektu)
4. [Kluczowe Funkcje](#kluczowe-funkcje)
5. [Bezpieczeństwo (Security Pro)](#bezpieczeństwo-security-pro)
6. [Opis Komponentów](#opis-komponentów)
7. [Wymagania](#wymagania)
8. [Instalacja i Konfiguracja](#instalacja-i-konfiguracja)
9. [Awatary - Konfiguracja](#awatary---konfiguracja)
10. [Użytkowanie i Zarządzanie](#użytkowanie-i-zarządzanie)
11. [Rozwiązywanie problemów](#rozwiązywanie-problemów)
12. [FAQ - Najczęściej Zadawane Pytania](#faq---najczęściej-zadawane-pytania)
13. [Kompatybilność](#kompatybilność)
14. [Autorzy i Licencja](#autorzy-i-licencja)

---

## Co nowego w v2.x.x?
* **Szyfrowanie Haseł:** Koniec z trzymaniem haseł otwartym tekstem. System wykorzystuje OpenSSL i unikalny klucz użytkownika do szyfrowania danych logowania.
* **System Awatarów:** Widżet wyświetla zdjęcia profilowe nadawców. Możesz zarządzać nimi przez dedykowany `Avatar_Manager.sh`.
* **Asynchroniczność:** Pobieranie danych GeoIP (adres IP, kraj, miasto, dostawca ISP itp...) odbywa się teraz w tle, nie blokując startu widżetu.
* **Zintegrowany Watchdog:** Nowy skrypt startowy sam pilnuje stabilności Conky i zużycia RAM – usunięto zbędne, zewnętrzne procesy.
* **Automatyzacja:** Skrypty Lua same wykrywają ścieżki, eliminując potrzebę ręcznej edycji plików po instalacji lub przeniesieniu folderu.

## O Projekcie
Ten projekt jest owocem współpracy człowieka ze sztuczną inteligencją. Twórcy, nie będąc profesjonalnymi programistami, wykorzystali zaawansowane narzędzia AI do stworzenia tego kompleksowego widżetu. Podkreśla to, że zarówno wkład ludzki w ideę i cel projektu, jak i możliwości generatywne sztucznej inteligencji, były absolutnie kluczowe dla powstania i realizacji Conky AutoMail Suite. Bez zaangażowania twórców projekt by nie zaistniał, a bez wsparcia AI jego realizacja w takiej formie byłaby niemożliwa.

## Główne Filary Projektu
System został zbudowany w oparciu o trzy fundamentalne zasady:

1. **Niezawodny Backend w Pythonie**: Sercem systemu jest wielowątkowy demon, który działa w tle, zapewniając, że powolne serwery czy problemy z siecią nigdy nie zamrożą Twojego pulpitu. Utrzymuje stałe połączenia IMAP, proaktywnie monitoruje dostępność internetu i dynamicznie zarządza konfiguracją bez potrzeby restartu.
2. **Dynamiczny Frontend w Lua**: Wszystko, co widzisz na ekranie, jest renderowane przez wysoce zoptymalizowany i w pełni konfigurowalny skrypt Lua. Umożliwia on płynne animacje, inteligentne przewijanie tekstu, elastyczne układy oraz personalizację każdego, nawet najmniejszego elementu wizualnego.
3. **Wygodne Narzędzia Graficzne (YAD & Zenity)**: Zapomnij o ręcznej edycji plików konfiguracyjnych. Pakiet zawiera zestaw intuicyjnych narzędzi z interfejsem graficznym do dodawania i edycji kont, przełączania widoków czy wykonywania szybkich akcji na wiadomościach bezpośrednio z pulpitu.

## Kluczowe Funkcje

### System Multi-Konto i Zarządzanie
* **Obsługa Wielu Kont IMAP**: Monitoruj wszystkie swoje skrzynki w jednym miejscu. Backend uruchamia dedykowany, niezależny wątek dla każdego aktywnego konta, zapewniając maksymalną wydajność i izolację błędów.
* **Rozszerzona Kompatybilność IMAP**: Pełne wsparcie dla obu standardów szyfrowania połączeń: **SSL/TLS** (zazwyczaj port 993) oraz **STARTTLS** (zazwyczaj port 143).
* **Aliasy i Kolory Kont**: Łatwo identyfikuj maile dzięki unikalnym nazwom (aliasom) i kolorom definiowanym dla każdego konta.
* **Graficzny Menedżer Kont (`2.menager_kont.sh`)**: Interaktywnie dodawaj, edytuj, usuwaj, zmieniaj kolejność i aktywuj/deaktywuj konta. Zmiany w konfiguracji (np. hasło, host, alias) są wykrywane w locie, a odpowiednie wątki backendu są automatycznie restartowane bez przerywania pracy całego systemu.
* **Dynamiczny Selektor Widoku**: Przełączaj widok Conky między podsumowaniem wszystkich kont a widokiem jednej lub kilku wybranych skrzynek.
* **Zaawansowane Zarządzanie Pocztą z Pulpitu (`zarzadzaj-pocztą.sh`)**: Wykonuj zbiorcze akcje (oznacz jako przeczytane/nieprzeczytane, przenieś do kosza, opróżnij kosz) na wszystkich, najnowszych lub najstarszych wiadomościach, z możliwością ustawienia osobnego limitu dla każdego konta w jednej operacji.

### Funkcjonalność Widżetu i Backendu
* **Szczegółowe Informacje o Mailach**: Wyświetla nadawcę (z kolorowym aliasem konta), temat oraz wieloliniowy, konfigurowalny podgląd treści.
* **Inteligentne Przewijanie Tekstu**: Długie nazwy nadawców, tematy i inne elementy są automatycznie przewijane (efekt "marquee"), aby zawsze były czytelne, z konfigurowalną prędkością i liczbą powtórzeń.
* **Dynamiczne Animacje dla Nowych Wiadomości**:
    * **Pulsowanie Tła/Ramki**: Nowe maile mogą być wyróżnione przez płynną, pulsacyjną animację tła i/lub ramki, z pełną kontrolą nad kolorami, prędkością i czasem trwania.
    * **Miganie Ikony Załącznika**: Ikona załącznika może migać określoną liczbę razy, aby zwrócić uwagę na nowy plik.
* **Integracja z GeoIP**: Backend wyodrębnia publiczny adres IP z nagłówków wiadomości i wykorzystuje kilka publicznych API do wyświetlania miasta, dostawcy internetu (ISP) i kraju nadawcy, z wbudowanym trwałym cache'owaniem wyników.
* **Konfigurowalna Linia Meta-danych**: Dodatkowe informacje pod każdym mailem (czas otrzymania, IP, User-Agent, kraj, status "mobilny" itp.) z możliwością zmiany kolejności i kolorów każdego elementu.
* **Elastyczne Układy i Skalowanie (`Konfiguracja_pozycji_layoutow_i_skali_conky.sh`)**: Sześć predefiniowanych układów (góra/dół, lewo/prawo, środek) oraz suwak do płynnego skalowania całego widżetu.
* **Stabilność i Odporność**:
    * **Dedykowany Watchdog (wbudowany w `3.START...`)**: Inteligentny strażnik, który czuwa wyłącznie nad stabilnością widżetu pocztowego. Automatycznie restartuje Conky, jeśli ten przestanie odpowiadać, ulegnie awarii lub przekroczy zdefiniowany próg zużycia RAM.
    * **Monitor Internetu**: Dedykowany wątek w backendzie proaktywnie sprawdza dostępność połączenia z internetem, aby uniknąć niepotrzebnych prób połączeń i błędów.
* **Operacje w Pamięci RAM dla Maksymalnej Wydajności**: Wszystkie częste operacje zapisu i odczytu (pliki cache, stany, logi) odbywają się w wirtualnym systemie plików `/dev/shm`, czyli bezpośrednio w pamięci RAM.

## Bezpieczeństwo (Security Pro)
W tej wersji bezpieczeństwo Twoich danych jest priorytetem:
1. **Szyfrowanie AES-256-CBC:** Hasła w pliku `config/config.json` są zaszyfrowane. Nawet jeśli ktoś wykradnie ten plik, nie odczyta haseł.
2. **Klucz Prywatny:** Klucz deszyfrujący (`.secret_key`) jest generowany automatycznie i przechowywany w bezpiecznym katalogu domowym użytkownika (`~/.config/conky-mail-secret-key/`), a nie w folderze projektu.
3. **Master Password:** Menedżer Kont (`2.menager_kont.sh`) może być zabezpieczony hasłem głównym.
4. **Deep Scan:** Przy każdym uruchomieniu konfiguratora system sprawdza integralność pliku. Jeśli wykryje ręcznie dopisane, niezaszyfrowane hasło – dla bezpieczeństwa wykona reset konfiguracji (ochrona przed tamperingiem).

## Opis Komponentów

| Plik/Katalog | Opis |
| :--- | :--- |
| `py/python_mail_conky_lua.py` | **Główny backend.** Wielowątkowy demon Pythona, który pobiera i przetwarza e-maile, obsługuje GeoIP i zapisuje dane do cache. |
| `lua/e-mail.lua` | **Główny frontend.** Skrypt Lua renderujący widżet w Conky. Tutaj odbywa się cała personalizacja wizualna. |
| `config/config.json` | **Baza danych kont.** Plik JSON przechowujący wszystkie dane konfiguracyjne Twoich kont e-mail (hasła są zaszyfrowane). |
| `conkyrc_mail` | Główny plik konfiguracyjny Conky, który ładuje skrypt Lua. |
| `1.Instalacja_zależności_v2.sh` | **Instalator.** Automatycznie wykrywa dystrybucję i instaluje wszystkie wymagane pakiety. |
| `2.menager_kont.sh` | **Menedżer kont.** Główne centrum dowodzenia. Zarządza kontami, szyfruje hasła, obsługuje Master Password. |
| `3.START_skryptów_oraz_conky.sh` | **Skrypt startowy.** Uruchamia demona Pythona, Conky i wbudowanego Watchdoga. Monitoruje zużycie RAM. |
| `Avatar_Manager.sh` | **Menedżer awatarów.** Nowość w v2.x.x. Narzędzie do przypisywania obrazków do adresów e-mail. |
| `Konfiguracja_pozycji...sh` | **Konfigurator wyglądu.** Graficzne narzędzie do zmiany pozycji, układu i rozmiaru widżetu. |
| `zarzadzaj-pocztą.sh` | **Menedżer poczty.** Graficzne narzędzie do wykonywania zbiorczych akcji na wiadomościach (np. "oznacz wszystkie jako przeczytane"). |

## Wymagania
Instalacja jest w pełni zautomatyzowana. Do prawidłowego działania, projekt wymaga następujących komponentów, które zostaną zainstalowane przez skrypt `1.Instalacja_zależności_v2.sh`:
* `conky` (z wkompilowanym wsparciem dla Lua 5.3 lub 5.4)
* `python3` + `openssl` (do szyfrowania)
* `lua` (w wersji zgodnej z Conky)
* `yad`
* `zenity`
* `jq`
* `wget`
* `xrandr` (zwykle w pakiecie `x11-xserver-utils`)
* `libnotify-bin` (dla `notify-send`)

## Instalacja i Konfiguracja
Dzięki automatyzacji, proces instalacji skrócił się do 3 kroków:

1. **Zainstaluj zależności:**
    ```bash
    bash 1.Instalacja_zależności_v2.sh
    ```
    *Skrypt automatycznie wykryje Twoją dystrybucję, zainstaluje wymagane pakiety i zweryfikuje wsparcie Lua w Conky.*

2. **Skonfiguruj konta:**
    ```bash
    bash 2.menager_kont.sh
    ```
    *Przy pierwszym uruchomieniu zostaniesz poproszony o utworzenie **Hasła Głównego**. Następnie dodaj swoje konta e-mail.*

3. **Uruchom widżet:**
    Na koniec zostaniesz zapytany, czy uruchomić główny skrypt startowy:
    ```bash
    bash 3.START_skryptów_oraz_conky.sh
    ```
    *Ten skrypt uruchomi w tle demona Pythona oraz wbudowany watchdog dla Conky.*

## Awatary - Konfiguracja
System v2.x.x pozwala na wyświetlanie zdjęć znajomych lub logotypów sklepów.

1. Uruchom `Avatar_Manager.sh`.
2. Kliknij **"DODAJ NOWY"**.
3. Wpisz adres e-mail nadawcy (np. `powiadomienia@allegro.pl`).
4. Wybierz kategorię (Znajomi / Inne).
5. Wskaż plik graficzny (PNG).
6. Gotowe! Przy następnym mailu od tego nadawcy zobaczysz jego awatar.

> **Wskazówka:** Możesz dostosować rozmiar, kształt (koło/kwadrat) i ramkę awatarów w opcjach Menedżera Awatarów (przycisk "Ustawienia Wyglądu").

## Użytkowanie i Zarządzanie
Po uruchomieniu przez `3.START_skryptów_oraz_conky.sh`, system działa w pełni autonomicznie w tle.

* **Zarządzanie Kontami (`2.menager_kont.sh`)**: Główne narzędzie. Pozwala edytować dane logowania, aktywować/deaktywować konta oraz zarządzać hasłem głównym.
* **Personalizacja Wyglądu (`Konfiguracja_pozycji_layoutow_i_skali_conky.sh`)**: Graficzny konfigurator do szybkiej zmiany pozycji i układu. **Uwaga:** Widżet jest zoptymalizowany dla 4K. Narzędzie do skalowania pozwala na idealne dopasowanie rozmiaru na monitorze 4K.
* **Zaawansowane Akcje (`zarzadzaj-pocztą.sh`)**: Interaktywne narzędzie do wykonywania zaawansowanych operacji na wiadomościach (np. "oznacz 20 najnowszych jako przeczytane").
* **Szczegółowa Personalizacja (`lua/e-mail.lua`)**: To centrum personalizacji wizualnej. Plik jest bogato komentowany, aby ułatwić zmianę czcionek, kolorów, odstępów, ikon i animacji.

## Rozwiązywanie problemów
Jeśli widżet nie działa poprawnie, poniższe kroki pomogą zdiagnozować problem.

### Uruchomienie w Trybie Diagnostycznym (Zalecane)
Najskuteczniejszym sposobem na znalezienie błędu jest uruchomienie systemu ręcznie w terminalu. W tym celu:

1. Otwórz terminal w głównym katalogu projektu.
2. Zatrzymaj wszystkie działające instancje, jeśli istnieją, uruchamiając `3.START_skryptów_oraz_conky.sh` i wybierając opcję zatrzymania.
3. Uruchom skrypt startowy ponownie, ale z flagą debugowania:
    ```bash
    bash 3.START_skryptów_oraz_conky.sh --debug
    ```
Uruchomienie skryptu w ten sposób sprawi, że wszystkie komunikaty, logi i ewentualne błędy z Pythona oraz Conky będą wyświetlane na bieżąco w tym oknie terminala.

### Sprawdzenie Plików Logów
Jeśli problem występuje sporadycznie, sprawdź plik `log/mail_diag.json`. Zawiera on szczegółowe dane diagnostyczne z każdej sesji pobierania poczty.

## FAQ - Najczęściej Zadawane Pytania

* **Q: Czy moje hasła są bezpieczne?**
    * A: Tak. Są zaszyfrowane standardem AES-256. Plik `.secret_key` znajduje się w Twoim katalogu domowym (`~/.config/...`), a plik `config.json` w folderze projektu zawiera tylko zaszyfrowany ciąg znaków, który jest bezużyteczny bez klucza z Twojego komputera.
* **Q: Widżet nie startuje / brak cache.**
    * A: Upewnij się, że uruchomiłeś `3.START...`. Jeśli nadal nie działa, uruchom go z flagą debugowania w terminalu, aby zobaczyć szczegółowe logi błędów:
      ```bash
      bash 3.START_skryptów_oraz_conky.sh --debug
      ```
* **Q: Zniknął skrypt 2.Podmiana...?**
    * A: Tak, w wersji 2.x.x jest on niepotrzebny. Nowy kod Lua jest inteligentny i sam wykrywa ścieżki do plików, niezależnie od tego, gdzie rozpakujesz projekt.
* **Q: Jak zresetować wszystko (zapomniałem Hasła Głównego)?**
    * A: Ze względów bezpieczeństwa hasła nie da się odzyskać. Musisz zresetować konfigurację:
        1. Usuń plik `config/config.json`.
        2. Usuń katalog `~/.config/conky-mail-secret-key/`.
        3. Uruchom `2.menager_kont.sh` i skonfiguruj konta od nowa.
* **Q: Moje konto Gmail/Outlook nie działa mimo poprawnego haseł.**
    * A: Większość dużych dostawców wymaga wygenerowania tzw. **Hasła do aplikacji** (App Password) dla zewnętrznych klientów IMAP. Zaloguj się przez przeglądarkę do ustawień bezpieczeństwa swojego konta e-mail, wygeneruj nowe hasło aplikacji i użyj go w Menedżerze Kont zamiast swojego głównego hasła.

## Kompatybilność
Skrypt instalacyjny (v2.0) został znacznie rozbudowany i posiada dedykowane reguły dla szerokiego spektrum dystrybucji Linuksa. Automatycznie wykrywa system, dobiera odpowiednie wersje bibliotek (Lua 5.3/5.4) i zarządza repozytoriami.

**Pełne wsparcie automatyczne:**
*   **Rodzina Debian/Ubuntu (`apt`)**:
    *   Ubuntu 22.04, 24.04+
    *   Linux Mint 21, 22+
    *   Debian 11 (Bullseye), 12 (Bookworm), 13 (Trixie)
*   **Rodzina Arch Linux (`pacman`)**:
    *   Arch Linux, Manjaro, Garuda Linux, EndeavourOS, Artix Linux
*   **Rodzina RPM (`dnf`, `zypper`)**:
    *   **Fedora**: 38+
    *   **OpenMandriva**: Lx 5.0, Rome (Rolling) & Rock (z automatyczną obsługą repozytoriów dla pakietu `conky`)
    *   **Mageia**: 9+
    *   **openSUSE**: Tumbleweed oraz Leap
*   **Inne**:
    *   Solus (`eopkg`)

**Wsparcie asystowane (tryb interaktywny):**
*   **Gentoo**: Skrypt wykrywa system i instruuje użytkownika, jakie flagi USE i pakiety zainstalować (`emerge`), oczekując na wykonanie poleceń.
*   **NixOS**: Wyświetla instrukcje dotyczące edycji `configuration.nix`.

Projekt działa na większości środowisk graficznych (wymaga `bash`, `zenity` oraz `yad` – skrypt potrafi je doinstalować automatycznie na wspieranych systemach).
## Autorzy i Licencja

### Autorzy projektu
* **Amator_80**: <mmajcher804@gmail.com> (Discord: Amator80)
* **Zupix**: <zupix.py.lua.mail.conky@gmail.com> (Discord: Zupix)

Możesz spotkać autorów na serwerze Discord: **Świat Linuksa** - [https://discord.com/invite/69EMVfN](https://discord.com/invite/69EMVfN)

### Powiązane Projekty
Warto również zapoznać się z siostrzanym projektem autorstwa Zupixa, który stanowi alternatywne podejście do tego samego zagadnienia:
* **Zupix Py2Lua Mail Conky** – Drugi w pełni funkcjonalny widżet do monitorowania poczty, rozwijany równolegle.
* **Repozytorium na GitHub**: [https://github.com/ZupixUI/Zupix-Py2Lua-Mail-conky](https://github.com/ZupixUI/Zupix-Py2Lua-Mail-conky)

> **Warto wiedzieć:** Oba projekty, choć zrodzone z podobnej idei, powstały i były rozwijane niezależnie. Prezentują odmienne filozofie i rozwiązania techniczne. Zachęcamy do zapoznania się z oboma, aby wybrać widżet, który najlepiej pasuje do Twoich oczekiwań i stylu pracy.

### Wkład i Licencja
Wkład w rozwój projektu jest mile widziany. Jeśli masz pomysły na ulepszenia lub znalazłeś błąd, proszę, utwórz zgłoszenie (issue) lub pull request na GitHubie.

Ten projekt jest udostępniany na licencji **GNU General Public License v3.0**. Oznacza to, że możesz swobodnie używać, modyfikować i rozpowszechniać ten kod, pod warunkiem, że Twoje pochodne prace również będą udostępniane na tej samej licencji.
