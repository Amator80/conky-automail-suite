# -*- coding: utf-8 -*-

import imaplib
import json
import argparse
import sys
import socket
import os
import subprocess

# Ustawienie globalnego limitu czasu dla operacji sieciowych.
SOCKET_TIMEOUT = 15

# =================== KONFIGURACJA ŚCIEŻEK ===================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# Logika dla wersji Portable (Config w folderze projektu)
# Sprawdzamy czy folder config jest obok skryptu, czy piętro wyżej
if os.path.isdir(os.path.join(SCRIPT_DIR, 'config')):
    BASE_DIR = SCRIPT_DIR
else:
    BASE_DIR = os.path.dirname(SCRIPT_DIR)

# Klucz szukamy w bezpiecznym katalogu użytkownika (zgodnie z nowym standardem)
SECRET_KEY_PATH = os.path.expanduser("~/.config/conky-mail-secret-key/.secret_key")

# =================== FUNKCJA DESZYFRUJĄCA ===================

def decrypt_password(encrypted_pass):
    """
    Odszyfrowuje hasło przy użyciu klucza z pliku .secret_key (AES-256-CBC).
    """
    if not encrypted_pass:
        return ""
    
    # Jeśli brak pliku klucza, zwracamy oryginał (może to plain text ze starych wersji)
    if not os.path.exists(SECRET_KEY_PATH):
        return encrypted_pass

    try:
        # Wywołanie openssl identyczne jak w skryptach Bash
        result = subprocess.run(
            ['openssl', 'enc', '-d', '-aes-256-cbc', 
             '-salt', '-pbkdf2', 
             '-pass', f'file:{SECRET_KEY_PATH}', 
             '-a', '-A'],
            input=encrypted_pass.encode('utf-8'),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True
        )
        return result.stdout.decode('utf-8')
    except Exception:
        return encrypted_pass

# =================== ORYGINALNA LOGIKA SKRYPTU ===================

def mask_string(s, visible_chars=3):
    """
    Zwraca oryginalny ciąg znaków bez maskowania.
    """
    return s

def find_trash_folder(imap_connection):
    """
    Próbuje automatycznie zlokalizować folder kosza na serwerze IMAP.
    """
    common_trash_names = ['[Gmail]/Trash', 'Trash', 'Deleted Items', 'Kosz']
    
    for name in common_trash_names:
        try:
            status_select, _ = imap_connection.select(f'"{name}"', readonly=True)
            if status_select == 'OK':
                return name
        except imaplib.IMAP4.error:
            continue
    return None

def perform_action(config_path, action, target_accounts, mode, count):
    """
    Główna funkcja wykonawcza skryptu. Łączy się z serwerami IMAP
    i wykonuje zdefiniowaną akcję na wybranych kontach i wiadomościach.
    """
    socket.setdefaulttimeout(SOCKET_TIMEOUT)

    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            # Obsługa nowej struktury (master_hash + accounts) oraz starej (tylko accounts)
            if "accounts" in data and isinstance(data["accounts"], list):
                all_accounts = data["accounts"]
            else:
                # Fallback dla bardzo starych plików (choć menedżer je naprawia)
                all_accounts = data.get("accounts", [])

    except (IOError, json.JSONDecodeError) as e:
        print(f"BŁĄD: Nie można wczytać lub przetworzyć pliku konfiguracyjnego '{config_path}': {e}", file=sys.stderr)
        sys.exit(1)

    accounts_to_process = [
        acc for acc in all_accounts 
        if acc.get("enabled") and ("ALL" in target_accounts or acc.get("name") in target_accounts)
    ]
    
    if not accounts_to_process:
        print("INFO: Nie znaleziono aktywnych kont pasujących do kryterium.")
        sys.exit(0)

    print(f"Akcja: '{action}' | Konta: {', '.join(acc['name'] for acc in accounts_to_process)}\n")

    for acc in accounts_to_process:
        acc_name = acc.get("name", "Bezimienne")
        print(f"--- Przetwarzanie konta: {acc_name} ({mask_string(acc.get('login', ''))}) ---")
        
        imap = None
        try:
            encryption = acc.get("encryption", "SSL").upper()

            if encryption == "STARTTLS":
                print(f"  [INFO] Nawiązywanie połączenia z {acc['host']}:{acc['port']} (tryb: STARTTLS)")
                imap = imaplib.IMAP4(acc["host"], acc["port"])
                imap.starttls()
            elif encryption == "SSL":
                print(f"  [INFO] Nawiązywanie połączenia z {acc['host']}:{acc['port']} (tryb: SSL/TLS)")
                imap = imaplib.IMAP4_SSL(acc["host"], acc["port"])
            else:
                raise ValueError(f"Niewspierany typ szyfrowania: '{encryption}'")

            # === [ZMIANA] Odszyfrowanie hasła przed logowaniem ===
            raw_password = acc["password"]
            real_password = decrypt_password(raw_password)
            
            imap.login(acc["login"], real_password)
            # =====================================================

            mailbox = "INBOX"
            if action == "empty-trash":
                trash_folder = find_trash_folder(imap)
                if not trash_folder:
                    print(f"  [OSTRZEŻENIE] Nie zlokalizowano folderu kosza. Pomijanie konta.")
                    continue
                mailbox = trash_folder
            
            imap.select(f'"{mailbox}"')

            # [POPRAWKA] Używamy ALL dla wszystkiego, żeby licznik "first/last" działał poprawnie na całej skrzynce
            criteria_map = {'mark-read': 'ALL', 'mark-unread': 'ALL', 'move-to-trash': 'ALL', 'empty-trash': 'ALL'}
            search_criteria = criteria_map[action]

            typ, data = imap.uid('search', None, search_criteria)
            if typ != 'OK' or not data[0]:
                print(f"  [INFO] W folderze '{mailbox}' brak wiadomości do przetworzenia.")
                continue

            all_uids = data[0].split()
            total_found = len(all_uids) # Zapamiętujemy, ile łącznie wiadomości znaleziono.

            # === ORYGINALNA LOGIKA FILTROWANIA (ZACHOWANA 1:1) ===
            target_uids = []
            
            if action == 'empty-trash':
                mode = 'all'

            # Sprawdzamy, czy użytkownik nie poprosił o więcej wiadomości, niż jest dostępnych.
            if (mode == 'first' or mode == 'last') and count > total_found:
                print(f"  [INFO] Poproszono o {count} wiadomości, ale znaleziono tylko {total_found}. Przetwarzanie wszystkich znalezionych.")
                # Nie musimy zmieniać wartości `count`, ponieważ krojenie listy w Pythonie
                # i tak bezpiecznie obsłuży ten przypadek, biorąc wszystkie dostępne elementy.
            
            if mode == 'first':
                target_uids = all_uids[-count:]
                print(f"  [INFO] Wybrano {len(target_uids)} najnowszych wiadomości z {total_found} znalezionych (tryb: first).")
            elif mode == 'last':
                target_uids = all_uids[:count]
                print(f"  [INFO] Wybrano {len(target_uids)} najstarszych wiadomości z {total_found} znalezionych (tryb: last).")
            else:  # Domyślnie tryb 'all'
                target_uids = all_uids

            if not target_uids:
                print(f"  [INFO] Po filtrowaniu brak wiadomości do przetworzenia.")
                continue
            
            uids_str = b','.join(target_uids).decode('utf-8')
            final_count = len(target_uids)
            # === KONIEC ORYGINALNEJ LOGIKI ===

            if action == 'mark-read':
                imap.uid('store', uids_str, '+FLAGS', r'(\Seen)')
                print(f"  [OK] Oznaczono {final_count} wiadomości jako przeczytane.")
            
            elif action == 'mark-unread':
                imap.uid('store', uids_str, '-FLAGS', r'(\Seen)')
                print(f"  [OK] Przywrócono {final_count} wiadomości jako nieprzeczytane.")

            elif action == 'move-to-trash':
                trash_folder = find_trash_folder(imap)
                if not trash_folder:
                    print(f"  [BŁĄD] Nie zlokalizowano folderu kosza. Nie można przenieść wiadomości.")
                    continue
                
                # Upewniamy się, że operujemy na INBOX.
                imap.select('"INBOX"')

                # Krok 1: Kopiujemy wiadomości do kosza.
                typ_copy, response_copy = imap.uid('copy', uids_str, f'"{trash_folder}"')
                if typ_copy != 'OK':
                    print(f"  [BŁĄD] Nie można skopiować wiadomości do kosza: {response_copy}")
                    continue

                # Krok 2: Oznaczamy oryginalne wiadomości do usunięcia.
                typ_store, response_store = imap.uid('store', uids_str, '+FLAGS', r'(\Deleted)')
                if typ_store != 'OK':
                    print(f"  [BŁĄD] Nie można oznaczyć wiadomości do usunięcia: {response_store}")
                    continue
                
                # Krok 3: Usuwamy oznaczone wiadomości z oryginalnego folderu.
                typ_expunge, response_expunge = imap.expunge()
                if typ_expunge == 'OK':
                    print(f"  [OK] Przeniesiono {final_count} wiadomości do kosza ('{trash_folder}').")
                else:
                    print(f"  [BŁĄD] Błąd podczas finalizowania usuwania: {response_expunge}")


            elif action == 'empty-trash':
                imap.uid('store', uids_str, '+FLAGS', r'(\Deleted)')
                print(f"  [INFO] Oznaczono {final_count} wiadomości w koszu do usunięcia.")
                
                typ, response = imap.expunge()
                num_expunged = len(response) if response and response[0] else final_count
                print(f"  [OK] Trwale usunięto {num_expunged} wiadomości z kosza.")

        except (imaplib.IMAP4.error, socket.error, ValueError) as e:
            print(f"  [BŁĄD] Wystąpił błąd IMAP, sieciowy lub konfiguracyjny dla konta {acc_name}: {e}", file=sys.stderr)
        except Exception as e:
            print(f"  [BŁĄD] Wystąpił nieoczekiwany błąd dla konta {acc_name}: {e}", file=sys.stderr)
        finally:
            if imap:
                try:
                    imap.close()
                    imap.logout()
                except:
                    pass
            print("-" * (25 + len(acc_name)))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Zarządza pocztą e-mail przez IMAP.")
    
    parser.add_argument("--config", required=True, help="Ścieżka do pliku config.json.")
    parser.add_argument("--action", required=True, choices=['mark-read', 'mark-unread', 'move-to-trash', 'empty-trash'], help="Akcja do wykonania.")
    parser.add_argument("--accounts", required=True, nargs='+', help="Lista nazw kont lub 'ALL'.")

    parser.add_argument(
        "--mode", 
        default='all', 
        choices=['all', 'first', 'last'], 
        help="Tryb wyboru wiadomości: 'all' (wszystkie), 'first' (N najnowszych), 'last' (N najstarszych)."
    )
    parser.add_argument(
        "--count", 
        type=int, 
        default=50, 
        help="Liczba wiadomości do przetworzenia w trybie 'first' lub 'last'."
    )

    args = parser.parse_args()
    
    perform_action(args.config, args.action, args.accounts, args.mode, args.count)
