#!/usr/bin/env python3
# ============================================================
# mail_conky_watchdog.py – watchdog do pilnowania 1 instancji Conky (np. mailowego widgetu)
#
# Skrypt monitoruje wybraną instancję Conky:
# - Jeśli RAM przekroczy limit LUB minie czas – restartuje tylko tę instancję
# - Jeśli WSZYSTKIE Conky zostaną zabite (np. killall conky) – watchdog sam się kończy (nie wznawia widgetu)
# ============================================================

import os
import psutil
import subprocess
import time
import sys
from contextlib import suppress
import logging

# ------------- ŚCIEŻKI I USTAWIENIA KONFIGURACYJNE -------------

# Katalog, w którym jest ten skrypt (np. .../py/)
mydir = os.path.dirname(os.path.abspath(__file__))

# Katalog główny projektu – poziom wyżej niż ten skrypt
project_dir = os.path.dirname(mydir)

# Pełna ścieżka do pliku conkyrc_mail w głównym katalogu projektu
CONKY_CONF = os.path.join(project_dir, "conkyrc_mail")

# Komenda uruchamiająca Conky z powyższym configiem
PROCESS_CMD = ["conky", "-c", CONKY_CONF]

# Tryb działania:
# "off"  – tylko start widgetu i koniec
# "ram"  – restart gdy RAM przekroczy LIMIT_RAM_MB
# "czas" – restart po LIMIT_CZAS sekundach działania
RESET_MODE = "ram"         

LIMIT_RAM_MB = 300          # Limit RAM MB (gdy RESET_MODE == "ram")
LIMIT_CZAS = 1000           # Limit czasu działania procesu w sekundach (gdy RESET_MODE == "czas")
CHECK_INTERVAL = 2        # Co ile sekund sprawdzać RAM
RESTART_SLEEP_TIME = 0.2    # Minimalny czas między zabiciem a ponownym startem (sekundy)

# ------------- LOGOWANIE (możesz przełączyć level na DEBUG) -------------
logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')
def log(msg): logging.info(msg)

# ------------- FUNKCJE WSPOMAGAJĄCE -------------

def _get_conky_status():
    """
    Znajduje proces Conky korzystający z wybranego pliku konfiguracyjnego
    i jednocześnie zlicza wszystkie uruchomione procesy Conky w systemie.
    Zwraca krotkę: (psutil.Process lub None dla monitorowanego Conky, int - liczba wszystkich procesów Conky).
    """
    my_conky_proc = None
    total_conky_count = 0
    # Iteruje przez wszystkie procesy systemowe
    for p in psutil.process_iter(['pid', 'name', 'cmdline']):
        with suppress(Exception): # Pomija procesy, do których nie ma dostępu
            cmd = p.info.get('cmdline') # Bezpieczne pobieranie cmdline
            name = p.info.get('name')

            # Zlicza wszystkie procesy Conky, niezależnie od konfiguracji
            if name == "conky":
                total_conky_count += 1

            # Sprawdza, czy to jest monitorowany proces Conky (z konkretnym configiem)
            # Upewnia się, że cmd nie jest None i ma odpowiednią długość oraz zawiera prawidłowe argumenty
            if cmd and len(cmd) >= 3 and cmd[0] == "conky" and cmd[1] == "-c" and cmd[2] == CONKY_CONF:
                if p.is_running():
                    my_conky_proc = p # Zapisuje referencję do monitorowanego Conky
    return my_conky_proc, total_conky_count

def kill_my_conky(timeout=2):
    """
    Zabija tylko tę konkretną instancję Conky, identyfikowaną przez CONKY_CONF.
    Najpierw wysyła sygnał terminate(), a jeśli proces nie zakończy się w timeout, używa kill().
    """
    killed = False
    for p in psutil.process_iter(['pid', 'cmdline']):
        with suppress(Exception):
            cmd = p.info.get('cmdline')
            # Szuka procesu Conky z dokładnie tym plikiem konfiguracyjnym
            if cmd and len(cmd) >= 3 and cmd[0] == "conky" and cmd[1] == "-c" and cmd[2] == CONKY_CONF:
                p.terminate()
                try:
                    p.wait(timeout=timeout) # Czeka na zakończenie procesu
                except psutil.TimeoutExpired:
                    p.kill() # Jeśli nie zakończył się, zabija siłowo
                log("Zabiłem instancję Conky.")
                killed = True
                break # Zakłada, że jest tylko jeden taki Conky, więc można zakończyć pętlę
    if not killed:
        log("Nie znaleziono instancji Conky do zabicia (lub już nie działa).")

def start_my_conky():
    """
    Uruchamia widget Conky z wybraną konfiguracją, jeśli nie jest już uruchomiony.
    Sprawdza to za pomocą _get_conky_status.
    """
    proc, _ = _get_conky_status() # Pobiera status, interesuje nas tylko czy nasz Conky działa
    if proc is None:
        subprocess.Popen(PROCESS_CMD) # Uruchamia nowy proces
        log("Uruchamiam widget Conky.")
    else:
        log("Widget Conky już działa, nie uruchamiam ponownie.")

def classic_restart_my_conky(sleep_time):
    """
    Wykonuje pełny restart widgetu: najpierw zabija istniejący proces,
    następnie czeka krótki czas i uruchamia nowy.
    Minimalizuje to czas, przez który widget jest niewidoczny.
    """
    log("Wykonuję klasyczny restart widgetu Conky.")
    kill_my_conky()
    time.sleep(sleep_time) # Krótka przerwa po zabiciu
    start_my_conky()
    time.sleep(sleep_time) # Krótka przerwa po uruchomieniu, aby dać mu czas na start

def get_ram_mb(proc):
    """
    Odczytuje zużycie RAM procesu w megabajtach (MB).
    Zwraca None w przypadku błędu (np. proces już nie istnieje).
    """
    try:
        return proc.memory_info().rss // 1024 // 1024
    except (psutil.NoSuchProcess, psutil.AccessDenied, AttributeError):
        return None

# ------------- GŁÓWNA LOGIKA WATCHDOGA -------------

def main():
    # Tryb "off" – tylko start widgetu i zakończenie programu bez monitorowania
    if RESET_MODE == "off":
        classic_restart_my_conky(RESTART_SLEEP_TIME)
        log("Tryb 'off' zakończony.")
        return

    # Zawsze na starcie: zapewnia, że tylko jeden widget działa i jest to nasz monitorowany Conky
    classic_restart_my_conky(RESTART_SLEEP_TIME)

    # Główna pętla nadzoru, działająca bez końca
    while True:
        # Pobiera status monitorowanego Conky i ogólną liczbę wszystkich Conky w jednej operacji
        my_conky_proc, total_conky_count = _get_conky_status()

        # Jeśli WSZYSTKIE procesy Conky w systemie są ubite (np. przez 'killall conky'),
        # to watchdog kończy swoją pracę, uznając, że nie ma czego pilnować.
        if total_conky_count == 0:
            log("Brak procesów Conky w systemie. Watchdog kończy pracę.")
            sys.exit(1)

        # Jeśli nasz monitorowany widget Conky nie działa (został zabity lub nie uruchomił się poprawnie),
        # próbuje go zrestartować.
        if my_conky_proc is None or not my_conky_proc.is_running():
            log("Nie znaleziono monitorowanego widgetu Conky lub przestał działać – restartuję.")
            classic_restart_my_conky(RESTART_SLEEP_TIME)
            # Po próbie restartu, ponownie pobiera status, aby sprawdzić, czy się powiodło
            my_conky_proc, total_conky_count = _get_conky_status()
            if my_conky_proc is None:
                log("Nie udało się uruchomić Conky po restarcie. Czekam na kolejną próbę.")
                time.sleep(CHECK_INTERVAL) # Czeka, aby uniknąć szybkiej pętli w przypadku ciągłych awarii
                continue # Przechodzi do następnej iteracji pętli nadzoru

        # Logika resetowania widgetu na podstawie zużycia RAM
        if RESET_MODE == "ram":
            ram_mb = get_ram_mb(my_conky_proc)
            if ram_mb is not None and ram_mb >= LIMIT_RAM_MB:
                log(f"RAM {ram_mb} MB przekroczył limit {LIMIT_RAM_MB} MB. Restartuję widget.")
                classic_restart_my_conky(RESTART_SLEEP_TIME)
                continue # Po restarcie, zaczyna pętlę od nowa, aby pobrać nowy proces i jego RAM
            time.sleep(CHECK_INTERVAL) # Czeka ustalony interwał przed kolejnym sprawdzeniem RAM

        # Logika resetowania widgetu na podstawie czasu działania
        elif RESET_MODE == "czas":
            seconds = 0
            while seconds < LIMIT_CZAS:
                # Regularnie sprawdza status Conky w trakcie odliczania czasu
                proc_inner, total_conky_count_inner = _get_conky_status()

                # Jeśli wszystkie Conky zniknęły podczas odliczania czasu, watchdog kończy
                if total_conky_count_inner == 0:
                    log("Brak procesów Conky w systemie (podczas trybu czasowego). Watchdog kończy pracę.")
                    sys.exit(1)

                # Jeśli nasz monitorowany Conky zniknął podczas odliczania, restartuje
                if proc_inner is None or not proc_inner.is_running():
                    log("Nie znaleziono monitorowanego widgetu Conky (w trybie czasowym) – restartuję.")
                    classic_restart_my_conky(RESTART_SLEEP_TIME)
                    break # Wychodzi z wewnętrznej pętli czasowej, aby główna pętla mogła zresetować timer

                time.sleep(5) # Czeka 5 sekund przed kolejnym sprawdzeniem w trybie czasowym
                seconds += 5
            log(f"Limit czasu {LIMIT_CZAS} sekund dla widgetu Conky minął. Restartuję.")
            classic_restart_my_conky(RESTART_SLEEP_TIME) # Restart po upływie zadanego czasu
        else:
            log(f"Nieznany tryb resetu: {RESET_MODE}. Watchdog kończy pracę.")
            break # Kończy działanie, jeśli tryb resetu jest niepoprawny

# ------------- START PROGRAMU -------------
if __name__ == "__main__":
    main()
