import imaplib
import json
import argparse
import sys
import socket

SOCKET_TIMEOUT = 15

def mask_string(s, visible_chars=3):
    if not s or len(s) <= visible_chars * 2: return s
    return s[:visible_chars] + "***" + s[-visible_chars:]

def find_trash_folder(imap_connection):
    """Próbuje znaleźć folder kosza na serwerze."""
    common_trash_names = ['[Gmail]/Trash', 'Trash', 'Deleted Items', 'Kosz']
    for name in common_trash_names:
        try:
            # Używamy LIST zamiast SELECT, żeby nie zmieniać wybranego folderu
            status, _ = imap_connection.list(pattern=name)
            if status == 'OK':
                # Sprawdzamy, czy folder faktycznie istnieje
                status_select, _ = imap_connection.select(f'"{name}"', readonly=True)
                if status_select == 'OK':
                    return name
        except Exception:
            continue
    return None

def perform_action(config_path, action, target_accounts):
    socket.setdefaulttimeout(SOCKET_TIMEOUT)
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            all_accounts = json.load(f).get("accounts", [])
    except Exception as e:
        print(f"BŁĄD: Nie można wczytać pliku konfiguracyjnego '{config_path}': {e}", file=sys.stderr)
        sys.exit(1)

    accounts_to_process = [acc for acc in all_accounts if acc.get("enabled") and ("ALL" in target_accounts or acc.get("name") in target_accounts)]
    if not accounts_to_process:
        print("INFO: Nie znaleziono aktywnych kont pasujących do wyboru.")
        sys.exit(0)

    print(f"Wybrano akcję: '{action}' dla kont: {', '.join(acc['name'] for acc in accounts_to_process)}\n")

    for acc in accounts_to_process:
        acc_name = acc.get("name", "Bezimienne")
        print(f"--- Przetwarzanie konta: {acc_name} ({mask_string(acc.get('login', ''))}) ---")
        try:
            with imaplib.IMAP4_SSL(acc["host"], acc["port"]) as imap:
                imap.login(acc["login"], acc["password"])

                mailbox = "INBOX"
                if action == "empty-trash":
                    trash_folder = find_trash_folder(imap)
                    if not trash_folder:
                        print(f"  [OSTRZEŻENIE] Nie udało się zlokalizować folderu Kosz. Pomijam.")
                        continue
                    mailbox = trash_folder
                
                imap.select(f'"{mailbox}"')

                criteria_map = {'mark-read': 'UNSEEN', 'mark-unread': 'SEEN', 'move-to-trash': 'ALL', 'empty-trash': 'ALL'}
                search_criteria = criteria_map[action]

                typ, data = imap.uid('search', None, search_criteria)
                if typ != 'OK' or not data[0]:
                    print(f"  [INFO] W folderze '{mailbox}' brak wiadomości pasujących do kryterium '{search_criteria}'.")
                    continue

                uids_str = b','.join(data[0].split()).decode('utf-8')
                count = len(data[0].split())

                if action == 'mark-read':
                    imap.uid('store', uids_str, '+FLAGS', r'(\Seen)')
                    print(f"  [OK] Oznaczono {count} wiadomości jako przeczytane.")
                elif action == 'mark-unread':
                    imap.uid('store', uids_str, '-FLAGS', r'(\Seen)')
                    print(f"  [OK] Przywrócono {count} wiadomości jako nieprzeczytane.")
                
                elif action == 'move-to-trash':
                    trash_folder = find_trash_folder(imap)
                    if not trash_folder:
                        print(f"  [BŁĄD] Nie udało się zlokalizować folderu Kosz. Nie można przenieść wiadomości.")
                        continue
                    
                    # --- POPRAWKA ---
                    # Ponownie wybierz INBOX, aby upewnić się, że jest w trybie read-write
                    # po tym jak find_trash_folder zmienił stan połączenia.
                    imap.select('"INBOX"')
                    # --- KONIEC POPRAWKI ---

                    # Komenda MOVE jest standardem i większość serwerów ją wspiera
                    typ, response = imap.uid('move', uids_str, f'"{trash_folder}"')
                    if typ == 'OK':
                        print(f"  [OK] Przeniesiono {count} wiadomości do kosza ('{trash_folder}').")
                    else:
                        print(f"  [BŁĄD] Serwer nie mógł przenieść wiadomości: {response}")

                elif action == 'empty-trash':
                    imap.uid('store', uids_str, '+FLAGS', r'(\Deleted)')
                    print(f"  [INFO] Oznaczono {count} wiadomości w koszu do usunięcia...")
                    typ, response = imap.expunge()
                    num_expunged = len(response) if response and response[0] else count
                    print(f"  [OK] Trwale usunięto {num_expunged} wiadomości z kosza.")

        except (imaplib.IMAP4.error, socket.timeout, ConnectionRefusedError) as e:
            print(f"  [BŁĄD] Problem z IMAP lub siecią dla konta {acc_name}: {e}", file=sys.stderr)
        except Exception as e:
            print(f"  [BŁĄD] Nieoczekiwany problem dla konta {acc_name}: {e}", file=sys.stderr)
        finally:
            print("-" * (25 + len(acc_name)))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Zarządza pocztą e-mail przez IMAP.")
    parser.add_argument("--config", required=True, help="Ścieżka do pliku config.json.")
    parser.add_argument("--action", required=True, choices=['mark-read', 'mark-unread', 'move-to-trash', 'empty-trash'], help="Akcja do wykonania.")
    parser.add_argument("--accounts", required=True, nargs='+', help="Lista nazw kont lub 'ALL'.")
    args = parser.parse_args()
    perform_action(args.config, args.action, args.accounts)
