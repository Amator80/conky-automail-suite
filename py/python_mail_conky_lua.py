# ==========================================================
#  SKRYPT MAILFETCHER DLA CONKY/LUA - WERSJA Z WĄTKAMI POOLINGOWYMI
#  - Obsługa wielu kont e-mail w osobnych wątkach
#  - Trwałe połączenia IMAP z NOOP
#  - Proaktywne sprawdzanie sieci przez dedykowany wątek
#  - Poprawka przewijania (flaga "is_new")
#  - Wszystkie zaawansowane funkcje (GeoIP, diagnostyka etc.)
# ==========================================================
import ipaddress
import imaplib
import email
from email.header import decode_header
import quopri
import html
import json
import argparse
import re
import os
import sys
import time
import email.utils
import urllib.request
import datetime
from collections import Counter
import socket
import threading
import signal

# --- Lepsze parsowanie ---
from email.utils import parsedate_to_datetime, parseaddr
from email import policy
from email.parser import BytesParser
try:
    from zoneinfo import ZoneInfo  # Python 3.9+
except Exception:
    ZoneInfo = None

# =================== PARAMETRY / STAŁE ===================

# IMAP
IMAP_BATCH_CHUNK = 50  # ile UID-ów w jednym UID FETCH

# PREVIEW
MAX_PREVIEW_LEN = 500

# GeoIP (przełącznik globalny + timeouty)
ENABLE_GEOIP = True
GEOIP_TIMEOUT_S = 1.5
GEOIP_LOOKUPS_PER_TICK = 5  # zwiększ na czas testów (np. 999)

# Cache plikowe (domyślne ścieżki)
DEFAULT_GEOIP_CACHE_FILE = "/dev/shm/conky-automail-suite/mail_geoip.cache.json"
DEFAULT_DIAG_FILE = "/dev/shm/conky-automail-suite/mail_diag.json"
LAST_SEEN_FILE = "/dev/shm/conky-automail-suite/last_seen_mails.json"


# Sieć: twardy timeout socketów
SOCKET_TIMEOUT = 15  # s
NETWORK_CHECK_TIMEOUT = 2 # s - dla is_internet_available
NETWORK_MONITOR_INTERVAL = 5 # s - jak często wątek monitorujący sieć sprawdza status

# --- KLUCZ PŁATNEGO GEOIP (PRIORYTET #2 – nadpisywalny przez CLI) ---
# Klucz API dla serwisu ipgeolocation.io (używany w funkcji 'from_ipgeolocation')
# Strona serwisu: https://ipgeolocation.io/
IPGEOLOCATION_API_KEY = "" # <-- opcjonalny klucz API (może być pusty)

# --- DEBUG GEOIP (głosowanie providerów) ---
GEOIP_DEBUG_DEFAULT = True

# Globalny event do kontrolowania działania wątków
GLOBAL_RUNNING_EVENT = threading.Event()
GLOBAL_RUNNING_EVENT.set() # Domyślnie ustawiony na uruchomiony

# ===============================================================
#                                   KOLORY ANSI / FORMATOWANIE LOGU
# ===============================================================
COLOR_MODE = "auto"  # "auto" | "always" | "never"  (CLI może nadpisać)

ANSI = {
    "reset": "\x1b[0m",
    "bold": "\x1b[1m",
    "dim": "\x1b[2m",
    "underline": "\x1b[4m",
    "red": "\x1b[31m",
    "green": "\x1b[32m",
    "yellow": "\x1b[33m",
    "blue": "\x1b[34m",
    "magenta": "\x1b[35m",
    "cyan": "\x1b[36m",
    "gray": "\x1b[90m",
    "orange": "\x1b[38;5;214m", # custom color
    "purple": "\x1b[38;5;129m", # custom color
    "teal": "\x1b[38;5;51m", # custom color
}

def _color_enabled():
    if COLOR_MODE == "always":
        return True
    if COLOR_MODE == "never":
        return False
    # auto
    return sys.stdout.isatty()

def C(txt, *styles):
    if not _color_enabled() or not styles:
        return str(txt)
    codes = "".join(ANSI[s] for s in ANSI if s in styles)
    return f"{codes}{txt}{ANSI['reset']}"

# ===============================================================
#                                   GEOIP CACHE & LIMITER (ZAMKI!)
# ===============================================================

_geoip_cache_mem = {}      # pamięć
_geoip_cache_dirty = False  # czy zrzucić do pliku
_geoip_budget = GEOIP_LOOKUPS_PER_TICK
_last_budget_ts = 0.0

_geoip_cache_lock = threading.Lock() # Zamek dla dostępu do cache GeoIP i budżetu

def _geoip_load_cache_file(path, diag=None):
    global _geoip_cache_mem
    initial_size = 0
    with _geoip_cache_lock:
        try:
            if os.path.exists(path):
                with open(path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    if isinstance(data, dict):
                        _geoip_cache_mem = data
                        initial_size = len(_geoip_cache_mem)
        except Exception:
            pass # Ignoruj błędy ładowania cache
        if diag is not None:
            diag['geoip_cache_initial_size'] = initial_size

def _geoip_save_cache_file(path, diag=None):
    global _geoip_cache_dirty
    saved = False
    error_msg = None
    with _geoip_cache_lock:
        if not _geoip_cache_dirty:
            if diag is not None:
                diag['geoip_cache_final_size'] = len(_geoip_cache_mem)
                diag['geoip_cache_saved'] = False # Nie było zmian do zapisania
                diag['geoip_cache_save_error'] = None
            return

        try:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            tmp = path + ".tmp"
            with open(tmp, "w", encoding="utf-8") as f:
                json.dump(_geoip_cache_mem, f, ensure_ascii=False, indent=2) # indent dla czytelności
            os.replace(tmp, path)
            _geoip_cache_dirty = False
            saved = True
        except Exception as e:
            error_msg = str(e)
        finally:
            if diag is not None:
                diag['geoip_cache_final_size'] = len(_geoip_cache_mem)
                diag['geoip_cache_saved'] = saved
                diag['geoip_cache_save_error'] = error_msg

def _geoip_budget_allow():
    """Limiter: maksymalnie GEOIP_LOOKUPS_PER_TICK na ~1 s."""
    global _geoip_budget, _last_budget_ts
    with _geoip_cache_lock: # Ochrona dostępu do budżetu
        now = time.time()
        if now - _last_budget_ts > 1.0:
            _geoip_budget = GEOIP_LOOKUPS_PER_TICK
            _last_budget_ts = now
        if _geoip_budget > 0:
            _geoip_budget -= 1
            return True
        return False

def is_private_ipv4(ip):
    if not ip:
        return False
    try:
        o1, o2, o3, o4 = map(int, ip.split("."))
    except Exception:
        return False
    if o1 == 10:
        return True
    if o1 == 127:
        return True
    if o1 == 192 and o2 == 168:
        return True
    if o1 == 172 and 16 <= o2 <= 31:
        return True
    return False

def is_ipv6(ip):
    return ":" in (ip or "")

# ===============================================================
#                                   GEOIP – DEBUG LOG (GŁOSOWANIE)
# ===============================================================

GEOIP_DEBUG = GEOIP_DEBUG_DEFAULT  # ustawiane z CLI

def _geoip_debug_log(ip, providers, final):
    """
    Kolorowy debug GEOIP:
    - na górze: IP + wszyscy providerzy z ich wartościami;
      wartości, które pokrywają się z final, są podświetlone na zielono i z ✓
    - niżej: kolorowe podsumowanie głosów (histogramy) dla city/country/cc/isp + mobile
    """
    if not GEOIP_DEBUG: return

    if not providers:
        print(f"{C('[GEOIP]', 'magenta')}[{C(ip, 'bold')}] {C('brak dostawców', 'yellow')}")
        return

    # Helpery
    def votes_for(field):
        hist = {}
        owners = {}  # map value -> [providers]
        for name, data in providers.items():
            v = (data or {}).get(field, "")
            v = (v or "").strip()
            if not v:
                continue
            hist[v] = hist.get(v, 0) + 1
            owners.setdefault(v, []).append(name)
        if not hist:
            return "", 0, hist, owners
        top_val, top_cnt = sorted(hist.items(), key=lambda x: (-x[1], -len(x[0])))[0]
        return top_val, top_cnt, hist, owners

    def mark(val, field):
        # Podświetl wartość, jeśli jest „final”
        fv = (final.get(field, "") or "").strip()
        v = (val or "").strip()
        if not v:
            return C("''", "gray")
        if fv and v == fv:
            return C(f"{v} ✓", "green", "bold")
        return C(v, "gray")

    # Nagłówek
    print(f"{C('[GEOIP]', 'magenta')}[{C(ip, 'bold')}] {C('--- wyniki dostawców ---', 'cyan')}")

    # Linia na providera
    order = ("ipwho", "ipapi", "ipinfo", "ipgeolocation")
    for name in order:
        if name not in providers:
            continue
        d = providers[name] or {}
        city = mark(d.get("city", ""), "city")
        country = mark(d.get("country", ""), "country")
        cc = mark(d.get("country_code", ""), "country_code")
        isp = mark(d.get("isp", ""), "isp")
        mob = d.get("mobile", False)
        mob_s = C("True", "green") if (mob and final.get("mobile")) else (C("True", "yellow") if mob else C("False", "gray"))
        print("  " + C(name, "blue", "bold") + ": "
              f"city='{city}', country='{country}', cc='{cc}', isp='{isp}', mobile={mob_s}")

    # Podsumowanie głosów (histogramy)
    def print_hist(field, label=None):
        label = label or field
        top_val, top_cnt, hist, owners = votes_for(field)
        if not hist:
            print(f"  {C('[głosy]', 'dim')} {label}: {C('brak niepustych wartości', 'yellow')} "
                  f"-> wybrane: '{C(final.get(field, ''), 'green', 'bold')}'")
            return
        parts = []
        for k, cnt in sorted(hist.items(), key=lambda x: (-x[1], -len(x[0]))):
            color = "green" if k == top_val else "gray"
            parts.append(f"'{C(k, color)}':{cnt}")
        chosen = C(final.get(field, ''), "green", "bold")
        # Remis?
        max_cnt = max(hist.values())
        tie = sum(1 for v in hist.values() if v == max_cnt) > 1
        tail = C("(remis)", "yellow") if tie else f"(top='{C(top_val, 'green')}'/{top_cnt})"
        print(f"  {C('[głosy]', 'dim')} {label}: " + ", ".join(parts) + f" -> wybrane: '{chosen}' {tail}")

    print_hist("city")
    print_hist("country")
    print_hist("country_code", "country_code")
    print_hist("isp")

    # Mobile
    mobile_true_from = [name for name, d in providers.items() if (d or {}).get("mobile", False)]
    mob_list = ", ".join(mobile_true_from) if mobile_true_from else ""
    mob_final = C(str(bool(final.get("mobile", False))), "green" if final.get("mobile") else "gray")
    print(f"  {C('[głosy]', 'dim')} mobile: true od [{C(mob_list, 'yellow')}] -> final: {mob_final}")

    print(f"{C('[GEOIP]', 'magenta')}[{C(ip, 'bold')}] {C('--- koniec ---', 'cyan')}")

# ===============================================================
#                                   GEOIP – 4 PROVIDERÓW (+płatny)
# ===============================================================

# klucz (finalny) ustawię w MAIN wg priorytetu
_FINAL_IPGEO_KEY = None

def _prefer_human(values, bad_keywords):
    """Wybiera najbardziej 'ludzki' opis z kilku wartości."""
    filtered = [v for v in values if v and not any(b in v.lower() for b in bad_keywords)]
    if filtered:
        filtered = sorted(filtered, key=lambda x: -len(x))
        return filtered[0]
    nonempty = [v for v in values if v]
    if nonempty:
        c = Counter(nonempty)
        return c.most_common(1)[0][0]
    return ""

def geoip_lookup(ip, cache_file=DEFAULT_GEOIP_CACHE_FILE, diag=None):
    """
    Pełny GeoIP z 4 providerów:
      - ipwho.is
      - ip-api.com
      - ipinfo.io
      - api.ipgeolocation.io (wymaga klucza – opcjonalny)
    Z pamięciowym cache i opcjonalnym logiem głosowania.
    """
    global _geoip_cache_dirty

    if diag is not None:
        diag['geoip_calls'] = diag.get('geoip_calls', 0) + 1

    if not ip or is_private_ipv4(ip) or is_ipv6(ip):
        if diag is not None:
            diag['geoip_skipped'] = diag.get('geoip_skipped', 0) + 1
        return {}

    # RAM cache
    with _geoip_cache_lock: # Ochrona dostępu do _geoip_cache_mem
        cached = _geoip_cache_mem.get(ip)
    if cached:
        if diag is not None:
            diag['geoip_cache_hits'] = diag.get('geoip_cache_hits', 0) + 1
        if GEOIP_DEBUG:
            _geoip_debug_log(ip, {"cache": cached}, cached)
        return cached

    # --- źródła ---
    def from_ipwho(ip):
        t0 = time.perf_counter()
        try:
            with urllib.request.urlopen(f"https://ipwho.is/{ip}", timeout=GEOIP_TIMEOUT_S) as resp:
                data = json.load(resp)
                if not data.get("success"):
                    return {}
                return {
                    "city": data.get("city", ""),
                    "country": data.get("country", ""),
                    "country_code": data.get("country_code", ""),
                    "isp": data.get("connection", {}).get("org", ""),
                    "mobile": data.get("connection", {}).get("mobile", False)
                }
        except Exception:
            return {}
        finally:
            if diag is not None:
                diag['geoip_net_calls'] = diag.get('geoip_net_calls', 0) + 1
                diag['geoip_net_s_total'] = diag.get('geoip_net_s_total', 0.0) + (time.perf_counter() - t0)

    def from_ipapi(ip):
        t0 = time.perf_counter()
        try:
            with urllib.request.urlopen(
                f"http://ip-api.com/json/{ip}?fields=status,country,countryCode,city,isp,org,message",
                timeout=GEOIP_TIMEOUT_S
            ) as resp:
                data = json.load(resp)
                if data.get("status") != "success":
                    return {}
                return {
                    "city": data.get("city", ""),
                    "country": data.get("country", ""),
                    "country_code": data.get("countryCode", ""),
                    "isp": data.get("isp", ""),
                    "mobile": False
                }
        except Exception:
            return {}
        finally:
            if diag is not None:
                diag['geoip_net_calls'] = diag.get('geoip_net_calls', 0) + 1
                diag['geoip_net_s_total'] = diag.get('geoip_net_s_total', 0.0) + (time.perf_counter() - t0)

    def from_ipinfo(ip):
        t0 = time.perf_counter()
        try:
            with urllib.request.urlopen(f"https://ipinfo.io/{ip}/json", timeout=GEOIP_TIMEOUT_S) as resp:
                data = json.load(resp)
                return {
                    "city": data.get("city", ""),
                    "country": data.get("country", ""),
                    "country_code": data.get("country", ""),
                    "isp": data.get("org", ""),
                    "mobile": False
                }
        except Exception:
            return {}
        finally:
            if diag is not None:
                diag['geoip_net_calls'] = diag.get('geoip_net_calls', 0) + 1
                diag['geoip_net_s_total'] = diag.get('geoip_net_s_total', 0.0) + (time.perf_counter() - t0)

    def from_ipgeolocation(ip):
        key = _FINAL_IPGEO_KEY or ""
        if not key or key in ("TWOJ_API_KEY_TUTAJ",):
            return {}
        t0 = time.perf_counter()
        try:
            url = f"https://api.ipgeolocation.io/ipgeo?apiKey={key}&ip={ip}"
            with urllib.request.urlopen(url, timeout=GEOIP_TIMEOUT_S) as resp:
                data = json.load(resp)
                mobile_val = str(data.get("is_mobile_connection", "")).lower() == "true"
                return {
                    "city": data.get("city", ""),
                    "country": data.get("country_name", ""),
                    "country_code": data.get("country_code2", ""),
                    "isp": data.get("isp", ""),
                    "mobile": mobile_val
                }
        except Exception:
            return {}
        finally:
            if diag is not None:
                diag['geoip_net_calls'] = diag.get('geoip_net_calls', 0) + 1
                diag['geoip_net_s_total'] = diag.get('geoip_net_s_total', 0.0) + (time.perf_counter() - t0)

    # limiter lookupów (całościowo – jeśli chcesz testować, zwiększ GEOIP_LOOKUPS_PER_TICK)
    if not _geoip_budget_allow():
        if diag is not None:
            diag['geoip_skipped'] = diag.get('geoip_skipped', 0) + 1
        return {}

    providers = {
        "ipwho": from_ipwho(ip),
        "ipapi": from_ipapi(ip),
        "ipinfo": from_ipinfo(ip),
        "ipgeolocation": from_ipgeolocation(ip),
    }

    bad_isp_keywords = [
        "static","dynamic","broadband","unknown","no-rdns","internet","customer",
        "residential","cloud","server","vps","unassigned","host","datacenter","hosteurope","ovh","colo","net"
    ]

    city_vals = [providers[k].get("city","") for k in providers]
    country_vals = [providers[k].get("country","") for k in providers]
    cc_vals = [providers[k].get("country_code","") for k in providers]
    isp_vals = [providers[k].get("isp","") for k in providers]
    mobiles = [providers[k].get("mobile", False) for k in providers]

    out = {
        "city":           _prefer_human(city_vals, ["unknown","null","n/a",""]),
        "country":        _prefer_human(country_vals, ["unknown","null","n/a",""]),
        "country_code": _prefer_human(cc_vals, []),
        "isp":            _prefer_human(isp_vals, bad_isp_keywords),
        "mobile":         any(mobiles),
    }

    with _geoip_cache_lock: # Ochrona dostępu do _geoip_cache_mem
        _geoip_cache_mem[ip] = out
        _geoip_cache_dirty = True

    if GEOIP_DEBUG:
        _geoip_debug_log(ip, providers, out)

    return out

# ===============================================================
#                                   KONFIG
# ===============================================================

def load_config(config_path="config.json"):
    """Ładuje dane logowania do IMAP z pliku JSON (z buforowaniem)."""
    global _config_cache_mem, _config_cache_mtime
    
    try:
        current_mtime = os.path.getmtime(config_path)
    except FileNotFoundError:
        current_mtime = 0

    # Szybka ścieżka: zwróć dane z bufora, jeśli plik się не zmienił
    if current_mtime > 0 and current_mtime == _config_cache_mtime and _config_cache_mem is not None:
        return _config_cache_mem

    # Wolna ścieżka: wczytaj plik z dysku
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            data = json.load(f)
            _config_cache_mem = data
            _config_cache_mtime = current_mtime
            return data
    except Exception:
        # W przypadku błędu, zresetuj bufor pustymi danymi
        _config_cache_mem = {}
        _config_cache_mtime = current_mtime
        return {}

# ===============================================================
#               Nowa funkcji dla active_account_selector
# ===============================================================

def load_active_accounts(selector_path):
    """Wczytuje listę aktywnych kont z pliku (z buforowaniem)."""
    global _selector_cache_mem, _selector_cache_mtime
    
    try:
        current_mtime = os.path.getmtime(selector_path)
    except FileNotFoundError:
        current_mtime = 0

    # Szybka ścieżka: zwróć dane z bufora, jeśli plik się nie zmienił
    if current_mtime > 0 and current_mtime == _selector_cache_mtime and _selector_cache_mem is not None:
        return _selector_cache_mem

    # Wolna ścieżka: wczytaj plik z dysku
    show_all = True
    selected_logins = []
    try:
        with open(selector_path, "r", encoding="utf-8") as f:
            lines = [line.strip() for line in f if line.strip()]
            if lines:
                if lines[0] == "0":
                    show_all = True
                else:
                    selected_logins = lines
                    show_all = False
    except Exception:
        # W przypadku błędu (np. brak pliku), użyj wartości domyślnych
        show_all = True
        selected_logins = []

    result = (show_all, selected_logins)
    _selector_cache_mem = result
    _selector_cache_mtime = current_mtime
    return result

# ===============================================================
#                          DATETIME / 'TEMU'
# ===============================================================

def parse_email_datetime(date_header):
    """Przetwarza datę z maila na timestamp i sformatowany string z TZ z nagłówka."""
    if not date_header:
        return None, None
    try:
        dt = parsedate_to_datetime(date_header)
        if dt is None:
            return None, None
        if dt.tzinfo is None:
            if ZoneInfo is not None:
                dt = dt.replace(tzinfo=ZoneInfo("UTC"))
            else:
                dt = dt.replace(tzinfo=datetime.timezone.utc)
        if ZoneInfo is not None:
            local = dt.astimezone(ZoneInfo("Europe/Warsaw"))
        else:
            local = datetime.datetime.fromtimestamp(dt.timestamp())
        return int(local.timestamp()), local.strftime("%Y-%m-%d %H:%M:%S")
    except Exception:
        return None, None

def get_age_text(mail_epoch):
    if not mail_epoch:
        return ""
    diff = int(time.time() - mail_epoch)
    if diff < 60:
        return f"{diff}s temu"
    elif diff < 3600:
        return f"{diff // 60}m temu"
    elif diff < 86400:
        return f"{diff // 3600}h temu"
    elif diff < 604800:
        return f"{diff // 86400}d temu"
    elif diff < 31536000:
        return f"{diff // 604800} tyg temu"
    else:
        return f"{diff // 31536000} lat temu"

# ===============================================================
#                                   DEKODERY / PREVIEW
# ===============================================================

def decode_mime_header(header):
    if not header:
        return ""
    parts = decode_header(header)
    out = []
    for bytes_or_str, enc in parts:
        if isinstance(bytes_or_str, bytes):
            tried = [enc, "utf-8", "windows-1250", "windows-1252", "iso-8859-2"]
            text = None
            for cand in tried:
                if not cand:
                    continue
                try:
                    text = bytes_or_str.decode(cand, errors="strict")
                    break
                except Exception:
                    continue
            if text is None:
                text = bytes_or_str.decode("utf-8", errors="replace")
            out.append(text)
        else:
            out.append(bytes_or_str)
    s = " ".join(out)
    s = re.sub(r"[\r\n\t]+", " ", s)
    s = re.sub(r"\s{2,}", " ", s)
    return s.strip()

def decode_quoted_printable(text):
    if not text:
        return ""
    if isinstance(text, str):
        text = text.encode("utf-8", errors="replace")
    try:
        return quopri.decodestring(text).decode("utf-8", errors="replace")
    except Exception:
        return text.decode("utf-8", errors="replace")

def decode_html_entities(text):
    return html.unescape(text or "")

# ================== POCZĄTEK ZMIAN (ZGODNIE Z SUGESTIĄ) ==================

def normalize_html_tail(html: str) -> str:
    """Naprawia typowe krzywizny: ucina niedomknięty tag na końcu
    i zawęża do <body>…</body> jeśli występuje.
    """
    if not html:
        return ""
    # Usuń niewidzialne znaki, które potrafią psuć regexy
    html = html.replace("\x00", "").replace("\ufeff", "")
    # Jeśli jest <body>…</body>, bierz tylko to
    m = re.search(r"(?is)<body[^>]*>(.*)</body\s*>", html)
    if m:
        html = m.group(1)
    # Utnij ewentualny niedomknięty tag na samym końcu (np. '</html')
    html = re.sub(r"<[^>]*$", "", html)
    return html

def clean_html(text: str) -> str:
    """
    Czyści HTML i zamienia bloki na nowe linie. Działa stabilnie na krzywych mailach.
    - usuwa <head>, <style>, <script>, komentarze
    - wycina trackery 1x1 / width/height=0
    - konwertuje br/p/div/li/td/h* na \n
    - usuwa wszystkie tagi i normalizuje białe znaki
    """
    if not text:
        return ""

    # 1) Normalizacja końcówki / zakresu <body>
    text = normalize_html_tail(text)

    # 2) Usuń HEAD/STYLE/SCRIPT/KOMENTARZE
    text = re.sub(r"(?is)<head\b.*?</head\s*>", "", text)
    text = re.sub(r"(?is)<style\b.*?</style\s*>", "", text)
    text = re.sub(r"(?is)<script\b.*?</script\s*>", "", text)
    text = re.sub(r"(?is)<!--.*?-->", "", text)

    # 3) Usuń trackery obrazków (1x1, 0x0 albo width/height=0/1)
    #    oraz IMG bez sensownej zawartości
    text = re.sub(
        r'(?is)<img[^>]*(?:\bwidth\s*=\s*["\']?\s*[01]\s*["\']?|\bheight\s*=\s*["\']?\s*[01]\s*["\']?)[^>]*>',
        "",
        text,
    )

    # 4) Zamiany bloków na nowe linie
    text = re.sub(r"(?i)<br\s*/?>", "\n", text)
    text = re.sub(r"(?i)</p\s*>", "\n\n", text)
    text = re.sub(r"(?i)</div\s*>", "\n", text)
    text = re.sub(r"(?i)</td\s*>", "\n", text)
    text = re.sub(r"(?i)</h[1-6]\s*>", "\n\n", text)
    text = re.sub(r"(?is)<li\s*>", "• ", text)
    text = re.sub(r"(?is)</li\s*>", "\n", text)

    # 5) Usuń resztę tagów
    text = re.sub(r"<[^>]+>", "", text)

    # 6) Rozkoduj encje i oczyść whitespace
    text = decode_html_entities(text)
    text = re.sub(r"[ \t]+", " ", text)

    # 7) Usuń zero-width i &nbsp;
    invisible = ['\u200B', '\u200C', '\u200D', '\uFEFF', '\u2060', '\u00AD', '\u034F']
    for ch in invisible:
        text = text.replace(ch, "")
    text = text.replace("\u00A0", " ")

    # 8) Usuń „linie z kresek”, które bywają artefaktem tabel
    text = "\n".join(
        line for line in text.splitlines()
        if not re.fullmatch(r"[\|¦ ]+", line)
    )

    # 9) Zbij nadmiar pustych linii
    text = re.sub(r"\n{3,}", "\n\n", text)

    return text.strip()

# =================== KONIEC ZMIAN ===================

def line_priority(line):
    l = line.lower().strip()
    powitania = ["dzień dobry","witam","cześć","witaj","hello","dear","hej","hi"]
    for pow in powitania:
        if l.startswith(pow):
            return 100
    if sum(c.isalpha() for c in line) > 10 and 15 < len(line) < 120:
        return 80
    if 10 < len(line) < 160:
        return 60
    return 10

_QUOTE_PATTERNS = [
    r"^>+",
    r"^On .* wrote:$",
    r"^W dniu .* pisze:$",
]
_SIG_SPLIT = re.compile(r"(?m)^\s*--\s*$")

def _strip_quotes_and_signatures(text):
    text = _SIG_SPLIT.split(text, 1)[0]
    lines = []
    for ln in text.splitlines():
        if any(re.search(p, ln.strip(), re.IGNORECASE) for p in _QUOTE_PATTERNS):
            continue
        lines.append(ln)
    return "\n".join(lines)

def clean_preview(text, line_mode, sort_preview=False):
    if not text:
        return ""
    text = clean_html(text)
    text = _strip_quotes_and_signatures(text)

    lines = []
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        lines.append(stripped)

    if sort_preview:
        lines = sorted(lines, key=line_priority, reverse=True)

    if line_mode == "auto" or str(line_mode) == "0":
        preview_lines = lines
    else:
        try:
            max_lines = int(line_mode)
            preview_lines = lines[:max_lines]
        except Exception:
            preview_lines = lines

    out = "\n".join(preview_lines)
    if len(out) > MAX_PREVIEW_LEN:
        out = out[:MAX_PREVIEW_LEN].rstrip() + "..."
    return out

def extract_sender_name(from_header):
    if not from_header:
        return ""
    name, addr = parseaddr(from_header)
    name = decode_mime_header(name) or addr or ""
    return name.strip().strip('"').strip()

def get_mail_preview(msg, line_mode, sort_preview=False, diag=None):
    t0 = time.perf_counter()
    best_plain = None
    cleaned_time = 0.0

    if msg.is_multipart():
        for part in msg.walk():
            ctype = part.get_content_type()
            disp = (part.get("Content-Disposition") or "").lower()
            if ctype == "text/plain" and "attachment" not in disp:
                payload = part.get_payload(decode=True) or b""
                charset = part.get_content_charset() or "utf-8"
                try:
                    text = payload.decode(charset, errors="replace")
                except Exception:
                    text = payload.decode("utf-8", errors="replace")
                if not best_plain or len(text) > len(best_plain):
                    best_plain = text
        if best_plain:
            t1 = time.perf_counter()
            out = clean_preview(best_plain, line_mode, sort_preview)
            t2 = time.perf_counter()
            cleaned_time += (t2 - t1)
            if diag is not None:
                diag['preview_total_s_total'] = diag.get('preview_total_s_total', 0.0) + (t2 - t0)
                diag['preview_clean_html_s_total'] = diag.get('preview_clean_html_s_total', 0.0) + cleaned_time
            return out

        for part in msg.walk():
            if part.get_content_type() == "text/html":
                payload = part.get_payload(decode=True) or b""
                charset = part.get_content_charset() or "utf-8"
                try:
                    text = payload.decode(charset, errors="replace")
                except Exception:
                    text = payload.decode("utf-8", errors="replace")
                t1 = time.perf_counter()
                out = clean_preview(text, line_mode, sort_preview)
                t2 = time.perf_counter()
                cleaned_time += (t2 - t1)
                if diag is not None:
                    diag['preview_total_s_total'] = diag.get('preview_total_s_total', 0.0) + (t2 - t0)
                    diag['preview_clean_html_s_total'] = diag.get('preview_clean_html_s_total', 0.0) + cleaned_time
                return out
    else:
        payload = msg.get_payload(decode=True) or b""
        charset = msg.get_content_charset() or "utf-8"
        try:
            text = payload.decode(charset, errors="replace")
        except Exception:
            text = payload.decode("utf-8", errors="replace")

        t1 = time.perf_counter()
        out = clean_preview(text, line_mode, sort_preview)
        t2 = time.perf_counter()
        cleaned_time += (t2 - t1)
        if diag is not None:
            diag['preview_total_s_total'] = diag.get('preview_total_s_total', 0.0) + (t2 - t0)
            diag['preview_clean_html_s_total'] = diag.get('preview_clean_html_s_total', 0.0) + cleaned_time
        return out

    if diag is not None:
        diag['preview_total_s_total'] = diag.get('preview_total_s_total', 0.0) + (time.perf_counter() - t0)
    return "(brak podglądu)"

# ===============================================================
#                                   INNE POMOCNICZE
# ===============================================================

def has_mail_attachment(msg, diag=None):
    t0 = time.perf_counter()
    res = False
    for part in msg.walk():
        ctype = part.get_content_type()
        disp = (part.get("Content-Disposition") or "").lower()
        filename = part.get_filename()
        if ("attachment" in disp) or (filename and "inline" in disp and ctype != "text/html"):
            res = True
            break
    if diag is not None:
        diag['attachments_check_s_total'] = diag.get('attachments_check_s_total', 0.0) + (time.perf_counter() - t0)
    return res

def is_internet_available(host="1.1.1.1", port=53, timeout=NETWORK_CHECK_TIMEOUT):
    """Szybko sprawdza, czy jest połączenie z internetem, unikając długich timeoutów."""
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except (socket.timeout, OSError):
        return False

# Zamki dla dostępu do plików cache
_last_seen_file_lock = threading.Lock()
_diag_file_lock = threading.Lock()
# <<< NOWE ZMIENNE DLA BUFORA ODCZYTU >>>
_last_seen_cache_mem = None
_last_seen_cache_mtime = 0
# <<< NOWE ZMIENNE DLA BUFORÓW KONFIGURACJI >>>
_config_cache_mem = None
_config_cache_mtime = 0
_selector_cache_mem = None
_selector_cache_mtime = 0

def load_last_seen():
    global _last_seen_cache_mem, _last_seen_cache_mtime
    
    try:
        current_mtime = os.path.getmtime(LAST_SEEN_FILE)
    except FileNotFoundError:
        current_mtime = 0

    # Szybka ścieżka: jeśli czas modyfikacji się zgadza i mamy coś w pamięci, zwróć bufor
    if current_mtime > 0 and current_mtime == _last_seen_cache_mtime and _last_seen_cache_mem is not None:
        return _last_seen_cache_mem

    # Wolna ścieżka: plik się zmienił lub to pierwszy odczyt
    with _last_seen_file_lock:
        try:
            with open(LAST_SEEN_FILE, "r", encoding="utf-8") as f:
                # Wczytaj, zaktualizuj bufor i czas modyfikacji
                data = set(json.load(f))
                _last_seen_cache_mem = data
                _last_seen_cache_mtime = current_mtime
                return data
        except Exception:
            # W przypadku błędu (np. plik nie istnieje), zresetuj bufor
            _last_seen_cache_mem = set()
            _last_seen_cache_mtime = current_mtime
            return set()

def save_last_seen(uids):
    with _last_seen_file_lock:
        try:
            os.makedirs(os.path.dirname(LAST_SEEN_FILE), exist_ok=True)
            with open(LAST_SEEN_FILE, "w", encoding="utf-8") as f:
                json.dump(list(uids), f)
        except Exception:
            pass

_PRIV4 = (
    re.compile(r"^10\.\d+\.\d+\.\d+$"),
    re.compile(r"^192\.168\.\d+\.\d+$"),
    re.compile(r"^127\.\d+\.\d+\.\d+$"),
    re.compile(r"^172\.(1[6-9]|2\d|3[0-1])\.\d+\.\d+$"),
)
def _is_private_v4(ip):
    return any(p.match(ip) for p in _PRIV4)

def _is_private_v6(ip):
    ip = (ip or "").lower()
    return ip.startswith("fc") or ip.startswith("fd") or ip.startswith("fe80") or ip == "::1"

def extract_public_ip(received_headers, diag=None):
    t0 = time.perf_counter()
    if not received_headers:
        if diag is not None:
            diag['extract_ip_s_total'] = diag.get('extract_ip_s_total', 0.0) + (time.perf_counter() - t0)
        return ""

    re_v4 = re.compile(r'\b(\d{1,3}(?:\.\d{1,3}){3})\b')
    re_v6 = re.compile(r'\b(?:[A-Fa-f0-9]{1,4}:){1,}[A-Fa-f0-9:]*\b')

    def is_public_ip(ip_str):
        try:
            ipobj = ipaddress.ip_address(ip_str)
            return not (ipobj.is_private or ipobj.is_loopback or ipobj.is_link_local)
        except ValueError:
            return False

    for header in reversed(received_headers):
        for ip4 in re_v4.findall(header):
            try:
                octs = list(map(int, ip4.split(".")))
                if any(o > 255 for o in octs):
                    continue
            except Exception:
                continue
            if is_public_ip(ip4):
                if diag is not None:
                    diag['extract_ip_s_total'] = diag.get('extract_ip_s_total', 0.0) + (time.perf_counter() - t0)
                return ip4

        for ip6 in re_v6.findall(header):
            if re.fullmatch(r'\d{1,2}:\d{1,2}:\d{1,2}', ip6):
                continue
            if is_public_ip(ip6):
                if diag is not None:
                    diag['extract_ip_s_total'] = diag.get('extract_ip_s_total', 0.0) + (time.perf_counter() - t0)
                return ip6

    if diag is not None:
        diag['extract_ip_s_total'] = diag.get('extract_ip_s_total', 0.0) + (time.perf_counter() - t0)
    return ""

# ===============================================================
#                                   IMAP – UID SEARCH / UID FETCH
# (zmodyfikowane tak, aby przyjmować już podłączony obiekt IMAP)
# ===============================================================

def get_unread_uids(imap_conn, diag=None):
    t0 = time.perf_counter()
    typ, data = imap_conn.uid('search', None, "UNSEEN")
    if diag is not None:
        diag['imap_uid_search_s_total'] = diag.get('imap_uid_search_s_total', 0.0) + (time.perf_counter() - t0)
    uids = (data[0].split() if data and data[0] else [])
    return len(uids), uids

def get_all_uids(imap_conn, diag=None):
    t0 = time.perf_counter()
    typ, data = imap_conn.uid('search', None, "ALL")
    if diag is not None:
        diag['imap_uid_search_s_total'] = diag.get('imap_uid_search_s_total', 0.0) + (time.perf_counter() - t0)
    uids = (data[0].split() if data and data[0] else [])
    return len(uids), uids

def _imap_batch_fetch_uid(imap_conn, uids, chunk=IMAP_BATCH_CHUNK, diag=None):
    """UID FETCH w chunkach. Zwraca listę raw_msg wg kolejności UID; brak = None."""
    if not uids:
        return []

    raw_by_uid = {}
    uid_list = [(uid.decode() if isinstance(uid, (bytes, bytearray)) else str(uid)) for uid in uids]

    rounds = 0
    t_start = time.perf_counter()
    for i in range(0, len(uid_list), chunk):
        part = uid_list[i:i+chunk]
        msg_set = ",".join(part)
        t0 = time.perf_counter()
        typ, data = imap_conn.uid('fetch', msg_set, '(BODY.PEEK[])')
        t1 = time.perf_counter()
        rounds += 1
        if typ == "OK" and data:
            for item in data:
                if isinstance(item, tuple) and len(item) >= 2:
                    header = item[0]
                    body = item[1]
                    try:
                        hdr = header.decode('utf-8', errors='ignore')
                        m = re.search(r'UID\s+(\d+)', hdr)
                        if m:
                            curr_uid = m.group(1)
                            raw_by_uid[curr_uid] = body
                    except Exception:
                        pass
    t_end = time.perf_counter()

    if diag is not None:
        diag['imap_batch_roundtrips'] = diag.get('imap_batch_roundtrips', 0) + rounds
        diag['imap_fetch_s_total'] = diag.get('imap_fetch_s_total', 0.0) + (t_end - t_start)

    raws = [raw_by_uid.get(uid) for uid in uid_list]
    return raws

# ===============================================================
#                                   BUDOWANIE REKORDU MAILA
# ===============================================================

def _build_mail_entry(raw_msg, preview_lines, sort_preview, include_meta, do_geoip, geoip_cache_path, diag=None):
    t_parse0 = time.perf_counter()
    msg = BytesParser(policy=policy.default).parsebytes(raw_msg)
    t_parse1 = time.perf_counter()
    if diag is not None:
        diag['parse_msg_s_total'] = diag.get('parse_msg_s_total', 0.0) + (t_parse1 - t_parse0)

    raw_from = msg.get("From", "")
    raw_subject = msg.get("Subject", "")
    raw_date = msg.get("Date", "")

    subject = decode_mime_header(raw_subject)
    from_addr = decode_mime_header(raw_from)
    from_name = extract_sender_name(from_addr)
    preview = get_mail_preview(msg, preview_lines, sort_preview, diag=diag)
    has_attachment = has_mail_attachment(msg, diag=diag)
    
    mail_epoch, mail_dt = parse_email_datetime(raw_date)

    meta = {}
    if include_meta:
        received_headers = msg.get_all("Received", [])
        ip = extract_public_ip(received_headers, diag=diag)
        user_agent = msg.get("User-Agent", "") or msg.get("X-Mailer", "") or msg.get("X-Originating-Client", "")
        ua_lower = (user_agent or "").lower()
        if "windows" in ua_lower:
            system = "Windows"
        elif "linux" in ua_lower:
            system = "Linux"
        elif "mac" in ua_lower or "os x" in ua_lower:
            system = "Mac"
        else:
            system = "?"
        
        # =================================================================
        # === ZMIANA: USUNIĘTO OBLICZANIE "age_text" ===
        # Obliczanie wieku maila ("X minut temu") zostało przeniesione do skryptu Lua,
        # aby plik cache był statyczny i nie aktualizował się co minutę.
        # age_text = get_age_text(mail_epoch) # <-- USUNIĘTA LINIA
        # =================================================================
        
        ip_meta = geoip_lookup(ip, cache_file=geoip_cache_path, diag=diag) if (do_geoip and ip) else {}
        meta = {
            "datetime": mail_dt,
            # "age_text": age_text, # <-- USUNIĘTA LINIA
            "ip": ip,
            "ip_city": ip_meta.get("city", ""),
            "isp": ip_meta.get("isp", ""),
            "country": ip_meta.get("country", ""),
            "country_code": ip_meta.get("country_code", ""),
            "agent": user_agent,
            "system": system,
            "mobile": ip_meta.get("mobile", False)
        }

    return {
        "from": from_addr,
        "from_name": from_name,
        "subject": subject,
        "preview": preview,
        "has_attachment": has_attachment,
        "timestamp": mail_epoch or 0,
        "meta": meta
    }

# ===============================================================
#                       GŁÓWNA FUNKCJA POBIERANIA MAIL
# (przyjmuje już podłączony obiekt imap, nie zarządza połączeniem)
# ===============================================================

def get_last_mails_imap(imap_conn, email_conf, n=6, show_all=False, preview_lines=3, sort_preview=False,
                        include_meta=True, do_geoip=True, geoip_cache_path=DEFAULT_GEOIP_CACHE_FILE,
                        diag=None):
    mails = []
    
    # Przełącz do folderu INBOX - zakładamy, że połączenie jest już aktywne
    imap_conn.select("INBOX")
    
    unread_count, unread_uids = get_unread_uids(imap_conn, diag=diag)
    all_count, _ = get_all_uids(imap_conn, diag=diag)

    t0_search = time.perf_counter()
    typ, data = imap_conn.uid('search', None, ("ALL" if show_all else "UNSEEN"))
    t1_search = time.perf_counter()
    if diag is not None:
        diag['imap_uid_search_s_total'] = diag.get('imap_uid_search_s_total', 0.0) + (t1_search - t0_search)

    uids = (data[0].split() if data and data[0] else [])
    if not uids:
        return {"unread": unread_count, "all": all_count, "unread_cache": 0, "mails": []}
    uids = uids[-n:]

    raws = _imap_batch_fetch_uid(imap_conn, uids, chunk=IMAP_BATCH_CHUNK, diag=diag)

    per_uid_fallbacks = 0
    for uid, raw_msg in zip(reversed(uids), reversed(raws)):
        uid_str = uid.decode() if isinstance(uid, (bytes, bytearray)) else str(uid)
        if raw_msg is None:
            t0_f = time.perf_counter()
            typ_f, data_f = imap_conn.uid('fetch', uid_str, '(BODY.PEEK[])')
            t1_f = time.perf_counter()
            if diag is not None:
                diag['imap_fetch_s_total'] = diag.get('imap_fetch_s_total', 0.0) + (t1_f - t0_f)
            if typ_f == "OK" and data_f:
                for it in data_f:
                    if isinstance(it, tuple) and len(it) >= 2 and isinstance(it[1], (bytes, bytearray)):
                        raw_msg = it[1]; break
            if raw_msg is None:
                continue
            per_uid_fallbacks += 1

        entry = _build_mail_entry(raw_msg, preview_lines, sort_preview, include_meta, do_geoip, geoip_cache_path, diag=diag)
        entry["uid"] = uid_str
        entry["account_name"] = email_conf.get("name")
        entry["color"] = email_conf.get("color")
        mails.append(entry)

    if diag is not None:
        diag['imap_per_uid_fallback'] = diag.get('imap_per_uid_fallback', 0) + per_uid_fallbacks

    if show_all:
        unseen_set = set(u.decode() for u in unread_uids) if unread_uids else set()
        visible_unread = sum(1 for mail in mails if mail.get("uid") in unseen_set)
    else:
        visible_unread = len(mails)

    return {"unread": unread_count, "all": all_count, "unread_cache": visible_unread, "mails": mails}

# ===============================================================
#                                   ZAPIS CACHE JSON
# ===============================================================

def safe_write_json(data, cache_file):
    """Szybki atomowy zapis."""
    try:
        os.makedirs(os.path.dirname(cache_file), exist_ok=True)
        tmp = cache_file + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False)
        os.replace(tmp, cache_file)
    except Exception as e:
        print(f"Błąd zapisu cache: {e}", file=sys.stderr)

def safe_read_json(cache_file):
    """Bezpieczny odczyt JSON, zwraca pusty dict w przypadku błędu."""
    try:
        if os.path.exists(cache_file):
            with open(cache_file, "r", encoding="utf-8") as f:
                return json.load(f)
    except Exception:
        pass
    return {}


# ===============================================================
#                                   DRUK DIAGNOSTYKI (ROZSZERZONA)
# ===============================================================

def mask_string(s, visible_chars=2):
    if not s:
        return ""
    if len(s) <= visible_chars * 2:
        return s[:visible_chars] + "***"
    return s[:visible_chars] + "***" + s[-visible_chars:]

def print_diag_table(diag):
    # ... (cała funkcja print_diag_table bez zmian - pominięta dla zwięzłości)
    pass

# ===============================================================
#                                   DIAG JSON (append do tablicy)
# ===============================================================

def _append_diag_array(diag: dict, path: str):
    with _diag_file_lock: # Ochrona dostępu do pliku diagnostycznego
        full_diag_data = []
        try:
            if os.path.exists(path):
                with open(path, "r", encoding="utf-8") as f:
                    full_diag_data = json.load(f)
                    if not isinstance(full_diag_data, list): # Jeśli plik nie jest listą, zacznij od nowa
                        full_diag_data = []
        except Exception:
            full_diag_data = []

        full_diag_data.append(diag)
        # Ogranicz rozmiar tablicy, np. do ostatnich 100 wpisów
        if len(full_diag_data) > 100:
            full_diag_data = full_diag_data[-100:]

        try:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            tmp = path + ".tmp"
            with open(tmp, "w", encoding="utf-8") as f:
                json.dump(full_diag_data, f, ensure_ascii=False, indent=2)
            os.replace(tmp, path)
        except Exception as e:
            print(f"Błąd zapisu diagnostyki: {e}", file=sys.stderr)


# ===============================================================
#                           THREAD: InternetMonitor
# ===============================================================

class InternetMonitor(threading.Thread):
    def __init__(self, global_running_event):
        super().__init__(daemon=True)
        self.online = False
        self._global_running_event = global_running_event
        print(f"{C('[InternetMonitor]', 'teal')} Startuję monitor internetu.")

    def run(self):
        while self._global_running_event.is_set():
            current_status = is_internet_available()
            if current_status != self.online:
                self.online = current_status
                if self.online:
                    print(f"{C('[InternetMonitor]', 'teal')} Internet DOSTĘPNY.")
                else:
                    print(f"{C('[InternetMonitor]', 'teal')} Internet NIEDOSTĘPNY.", file=sys.stderr)
            time.sleep(NETWORK_MONITOR_INTERVAL)
        print(f"{C('[InternetMonitor]', 'teal')} Zakończono działanie.")

# ===============================================================
#                           THREAD: AccountWorker
# ===============================================================

class AccountWorker(threading.Thread):
    # ================== POCZĄTEK ZMIAN ==================
    def __init__(self, account_conf, global_config, internet_monitor_ref, diag_file_lock, global_running_event, initial_state=None):
        super().__init__(daemon=True)
        self.account_conf = account_conf
        self.global_config = global_config
        self.internet_monitor = internet_monitor_ref
        self.diag_file_lock = diag_file_lock
        self._global_running_event = global_running_event
        
        self._imap_conn = None
        self._connected = False
        
        # Użyj przekazanego stanu (z poprzedniego wątku) lub stwórz nowy, domyślny
        if initial_state:
            self.last_known_state = initial_state
            # Natychmiast zaktualizuj pola, które mogły się zmienić (alias i kolor)
            self.last_known_state['account_name'] = account_conf.get("name", "Nieznane")
            for mail in self.last_known_state.get('mails', []):
                mail['color'] = account_conf.get("color")
        else:
            self.last_known_state = {
                "account_name": account_conf.get("name", "Nieznane"),
                "unread": 0,
                "all": 0,
                "unread_cache": 0,
                "mails": [],
                "last_error": "Nie połączono"
            }
        
        self._stop_event = threading.Event()
        self.login_id = self.account_conf.get("login") or "Nieznane"
        
        socket.setdefaulttimeout(SOCKET_TIMEOUT)
        print(f"{C(f'[AccountWorker {self.login_id}]', 'purple')} Startuję wątek dla konta.")
    # ================== KONIEC ZMIAN ==================

    def run(self):
        while self._global_running_event.is_set() and not self._stop_event.is_set():
            diag = {}
            current_loop_error = None
            
            if not self.account_conf.get("host") or not self.account_conf.get("login"):
                time.sleep(self.global_config["polling_interval"])
                continue

            if not self.internet_monitor.online:
                current_loop_error = f"Brak połączenia z internetem dla konta {self.login_id}. Próbuję ponownie za chwilę."
                print(f"{C('[WARN]', 'red')} [AccountWorker {self.login_id}] {current_loop_error}")
                self._disconnect_imap()
                self.last_known_state["last_error"] = current_loop_error
                self._connected = False
                time.sleep(5)
                continue

            if not self._connected or self._imap_conn is None:
                try:
                    self._connect_imap()
                    self._connected = True
                    self.last_known_state["last_error"] = None
                except Exception as e:
                    current_loop_error = f"Błąd połączenia/logowania IMAP dla konta {self.login_id}: {e}"
                    print(f"{C('[ERROR]', 'red', 'bold')} [AccountWorker {self.login_id}] {current_loop_error}", file=sys.stderr)
                    self._connected = False
                    self.last_known_state["last_error"] = current_loop_error
                    self._disconnect_imap()
                    time.sleep(SOCKET_TIMEOUT)
                    continue
            
            try:
                if self._imap_conn:
                    self._imap_conn.noop()
            except (imaplib.IMAP4.error, socket.timeout, ConnectionRefusedError, socket.gaierror) as e:
                current_loop_error = f"Połączenie IMAP zerwane dla konta {self.login_id} (NOOP failed): {e}"
                print(f"{C('[WARN]', 'yellow')} [AccountWorker {self.login_id}] {current_loop_error}", file=sys.stderr)
                self._connected = False
                self.last_known_state["last_error"] = current_loop_error
                self._disconnect_imap()
                time.sleep(SOCKET_TIMEOUT)
                continue
            except Exception as e:
                current_loop_error = f"Nieoczekiwany błąd podczas NOOP dla konta {self.login_id}: {e}"
                print(f"{C('[ERROR]', 'red', 'bold')} [AccountWorker {self.login_id}] {current_loop_error}", file=sys.stderr)
                self._connected = False
                self.last_known_state["last_error"] = current_loop_error
                self._disconnect_imap()
                time.sleep(SOCKET_TIMEOUT)
                continue

            try:
                mails_result = get_last_mails_imap(
                    imap_conn=self._imap_conn,
                    email_conf=self.account_conf,
                    n=self.global_config["max_mails"],
                    show_all=self.global_config["show_all"],
                    preview_lines=self.global_config["preview_lines"],
                    sort_preview=self.global_config["sort_preview"],
                    include_meta=True,
                    do_geoip=self.global_config["do_geoip"],
                    geoip_cache_path=self.global_config["geoip_cache_path"],
                    diag=diag
                )
                self.last_known_state = {
                    "account_name": self.account_conf.get("name", "Nieznane"),
                    "unread": mails_result.get("unread", 0),
                    "all": mails_result.get("all", 0),
                    "unread_cache": mails_result.get("unread_cache", 0),
                    "mails": mails_result.get("mails", []),
                    "last_error": None
                }
                print(f"{C('[OK]', 'green')} [AccountWorker {self.login_id}] Sprawdzono. Nieprzeczytane: {self.last_known_state['unread']}/{self.last_known_state['all']}")

            except (imaplib.IMAP4.error, socket.timeout, ConnectionRefusedError, socket.gaierror) as e:
                current_loop_error = f"Błąd pobierania maili IMAP dla konta {self.login_id}: {e}"
                print(f"{C('[ERROR]', 'red', 'bold')} [AccountWorker {self.login_id}] {current_loop_error}", file=sys.stderr)
                self._connected = False
                self.last_known_state["last_error"] = current_loop_error
                self._disconnect_imap()
                time.sleep(SOCKET_TIMEOUT)
            except Exception as e:
                current_loop_error = f"Nieoczekiwany błąd pobierania maili dla konta {self.login_id}: {e}"
                print(f"{C('[ERROR]', 'red', 'bold')} [AccountWorker {self.login_id}] {current_loop_error}", file=sys.stderr)
                self._connected = False
                self.last_known_state["last_error"] = current_loop_error
                self._disconnect_imap()
                time.sleep(SOCKET_TIMEOUT)
            finally:
                if diag and self.global_config.get("enable_diag_log", True):
                    _append_diag_array(diag, self.global_config["diag_file"])
            
            time.sleep(self.global_config["polling_interval"])

        self._disconnect_imap()
        print(f"{C(f'[AccountWorker {self.login_id}]', 'purple')} Zakończono działanie.")

    def _connect_imap(self):
        encryption_type = self.account_conf.get("encryption", "ssl").lower()
        host = self.account_conf["host"]
        
        if encryption_type == "starttls":
            port = self.account_conf.get("port", 143)
        else:
            port = self.account_conf.get("port", 993)

        try:
            if encryption_type == "starttls":
                print(f"{C('[INFO]', 'cyan')} [AccountWorker {self.login_id}] Łączenie z {host}:{port} (tryb STARTTLS)...")
                conn = imaplib.IMAP4(host, port, timeout=SOCKET_TIMEOUT)
                conn.starttls()
            else:
                print(f"{C('[INFO]', 'cyan')} [AccountWorker {self.login_id}] Łączenie z {host}:{port} (tryb SSL/TLS)...")
                conn = imaplib.IMAP4_SSL(host, port, timeout=SOCKET_TIMEOUT)
            
            conn.login(self.account_conf["login"], self.account_conf["password"])
            self._imap_conn = conn
            self._connected = True
            print(f"{C('[OK]', 'green')} [AccountWorker {self.login_id}] Połączono i zalogowano do IMAP.")

        except Exception as e:
            self._imap_conn = None
            self._connected = False
            raise

    def _disconnect_imap(self):
        if self._imap_conn:
            try:
                self._imap_conn.logout()
            except Exception as e:
                print(f"{C('[WARN]', 'yellow')} [AccountWorker {self.login_id}] Błąd podczas wylogowania: {e}", file=sys.stderr)
            finally:
                self._imap_conn = None
                self._connected = False
                print(f"{C('[INFO]', 'cyan')} [AccountWorker {self.login_id}] Rozłączono z IMAP.")

    def stop(self):
        self._stop_event.set()
        print(f"{C(f'[AccountWorker {self.login_id}]', 'purple')} Sygnalizuję zatrzymanie wątku.")

# ===============================================================
#                                   MAIN (WERSJA POPRAWIONA)
# ===============================================================

def manage_workers(current_workers, enabled_accounts_config, global_config, internet_monitor, diag_file_lock, global_running_event):
    """
    Synchronizuje działające wątki AccountWorker z aktualną konfiguracją.
    Zatrzymuje niepotrzebne wątki i uruchamia nowe dla nowo włączonych kont.
    """
    running_logins = {worker.login_id: worker for worker in current_workers}
    configured_logins = {acc['login']: acc for acc in enabled_accounts_config if acc.get('login')}

    # Krok 1: Znajdź wątki do zatrzymania
    logins_to_stop = set(running_logins.keys()) - set(configured_logins.keys())
    for login in logins_to_stop:
        worker_to_stop = running_logins[login]
        print(f"{C('[MAIN]', 'yellow')} Wyłączono konto {login}. Zatrzymuję powiązany wątek.")
        worker_to_stop.stop()
        current_workers.remove(worker_to_stop)

    # Krok 2: Znajdź konta, dla których trzeba uruchomić nowe wątki
    logins_to_start = set(configured_logins.keys()) - set(running_logins.keys())
    for login in logins_to_start:
        account_conf = configured_logins[login]
        print(f"{C('[MAIN]', 'green')} Włączono nowe konto {login}. Uruchamiam nowy wątek.")
        new_worker = AccountWorker(account_conf, global_config, internet_monitor, diag_file_lock, global_running_event)
        new_worker.start()
        current_workers.append(new_worker)
        
    # Krok 3: Restart wątków dla kont, których konfiguracja się zmieniła
    for login, worker in running_logins.items():
        if login in configured_logins:
            new_conf = configured_logins[login]
            old_conf = worker.account_conf
            # Sprawdź WSZYSTKIE kluczowe pola, w tym 'encryption'
            if (new_conf.get('host') != old_conf.get('host') or
                new_conf.get('port') != old_conf.get('port') or
                new_conf.get('encryption') != old_conf.get('encryption') or
                new_conf.get('password') != old_conf.get('password') or
                new_conf.get('name') != old_conf.get('name') or
                new_conf.get('color') != old_conf.get('color')):
                
                print(f"{C('[MAIN]', 'orange')} Zmieniono konfigurację dla {login}. Restartuję wątek.")
                
                # Zachowaj ostatni znany stan, aby uniknąć "mrugania"
                previous_state = worker.last_known_state.copy()
                
                # Zatrzymaj stary wątek
                worker.stop()
                current_workers.remove(worker)
                
                # Uruchom nowy, przekazując mu odziedziczony stan
                restarted_worker = AccountWorker(new_conf, global_config, internet_monitor, diag_file_lock, global_running_event, initial_state=previous_state)
                restarted_worker.start()
                current_workers.append(restarted_worker)

    return current_workers


if __name__ == "__main__":
    SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
    BASE_DIR = os.path.dirname(SCRIPT_DIR)
    DEFAULT_CONFIG_PATH = os.path.join(BASE_DIR, 'config', 'config.json')
    SELECTOR_FILE_PATH = os.path.join(BASE_DIR, 'config', 'active_account_selector')

    parser = argparse.ArgumentParser(description="Mail fetcher for Conky Lua (UID batch-fetch + GeoIP + diagnostyka + threading pooling)")
    parser.add_argument("--config", default=DEFAULT_CONFIG_PATH, help=f"Ścieżka do pliku konfiguracyjnego (domyślnie: {DEFAULT_CONFIG_PATH})")
    parser.add_argument("--max-mails", type=int, default=20, help="Ilość maili do pobrania (domyślnie 20)")
    parser.add_argument("--show-all", action="store_true", help="Pokaż wszystkie maile, nie tylko nieprzeczytane")
    parser.add_argument("--preview-lines", default="auto", help="Ile linii w podglądzie maila (liczba lub 'auto')")
    parser.add_argument("--output", help="Zapisz wynik do pliku (dodatkowo, obok cache)")
    parser.add_argument("--sort-preview", action="store_true", help="Sortuj linie podglądu wg ważności")
    parser.add_argument("--cache", default="/dev/shm/conky-automail-suite/mail_cache.json", help="Cache JSON (domyślnie: /dev/shm/conky-automail-suite/mail_cache.json)")
    parser.add_argument("--polling-interval", type=int, default=60, help="Interwał pollingu dla każdego konta w sekundach (domyślnie 60).")
    parser.add_argument("--count-file", help="Ścieżka do pliku z liczbą maili (z Lua)")
    parser.add_argument("--preview-lines-file", help="Ścieżka do pliku z liczbą linii podglądu (z Lua)")
    parser.add_argument("--no-geoip", action="store_true", help="Wyłącz GeoIP (nadpisuje ENABLE_GEOIP)")
    parser.add_argument("--geoip-cache", default=DEFAULT_GEOIP_CACHE_FILE, help=f"Plik cache GeoIP (domyślnie: {DEFAULT_GEOIP_CACHE_FILE})")
    parser.add_argument("--imap-chunk", type=int, default=IMAP_BATCH_CHUNK, help="Rozmiar chunku UID FETCH (domyślnie 50)")
    parser.add_argument("--diag-file", default=DEFAULT_DIAG_FILE, help=f"Plik diagnostyczny JSON (domyślnie: {DEFAULT_DIAG_FILE})")
    parser.add_argument("--stdout-json", action="store_true", help="Wypisz wynik JSON na stdout (domyślnie nie)")
    parser.add_argument("--geoip-debug", action="store_true", help="Loguj per-IP wyniki providerów i wybór finalny")
    parser.add_argument("--ipgeo-key", help="Klucz API dla api.ipgeolocation.io (PRIORYTET #1)")
    parser.add_argument("--color", choices=["auto", "always", "never"], default="auto", help="Kolorowe logi: auto/always/never (domyślnie auto)")
    # ---> ZMIANA 1/3: Dodanie argumentu wiersza poleceń <---
    parser.add_argument("--no-diag-log", action="store_true", help="Wyłącz zapisywanie logów diagnostycznych do pliku JSON.")

    args = parser.parse_args()

    COLOR_MODE = args.color
    IMAP_BATCH_CHUNK = max(1, int(args.imap_chunk))
    GEOIP_EFFECTIVE = (ENABLE_GEOIP and not args.no_geoip)
    GEOIP_DEBUG = bool(args.geoip_debug or GEOIP_DEBUG_DEFAULT)
    _FINAL_IPGEO_KEY = (args.ipgeo_key or IPGEOLOCATION_API_KEY or os.environ.get("IPGEOLOCATION_API_KEY", "")).strip()
    
    socket.setdefaulttimeout(SOCKET_TIMEOUT)

    # ---> ZMIANA 2/3: Przekazanie ustawienia do globalnej konfiguracji <---
    global_worker_config = {
        "max_mails": args.max_mails,
        "show_all": args.show_all,
        "preview_lines": args.preview_lines,
        "sort_preview": args.sort_preview,
        "do_geoip": GEOIP_EFFECTIVE,
        "geoip_cache_path": args.geoip_cache,
        "diag_file": args.diag_file,
        "polling_interval": args.polling_interval,
        "enable_diag_log": not args.no_diag_log
    }

    _geoip_load_cache_file(args.geoip_cache)

    internet_monitor = InternetMonitor(GLOBAL_RUNNING_EVENT)
    internet_monitor.start()

    workers = []

    def graceful_shutdown(signum, frame):
        print(f"\n{C('[MAIN]', 'red', 'bold')} Odebrano sygnał {signum}. Zamykanie programu...")
        GLOBAL_RUNNING_EVENT.clear()
        for worker in workers:
            worker.stop()

    signal.signal(signal.SIGINT, graceful_shutdown)
    signal.signal(signal.SIGTERM, graceful_shutdown)
    
    last_cache_write_time = 0
    CACHE_AGGREGATION_INTERVAL = 1
    
    last_config_check_time = 0
    CONFIG_CHECK_INTERVAL = 5

    # =========================================================================
    # === ZMIANA: OPTYMALIZACJA ZAPISU (START) ===
    # =========================================================================
    # Ta zmienna będzie przechowywać ostatnio zapisaną wersję danych.
    # Użyjemy jej do porównania, czy dane faktycznie się zmieniły.
    last_written_data = None
    # =========================================================================
    # === ZMIANA: OPTYMALIZACJA ZAPISU (KONIEC) ===
    # =========================================================================

    print(f"\n{C('[MAIN]', 'blue', 'bold')} Uruchomiono tryb daemona. Agreguję cache co {CACHE_AGGREGATION_INTERVAL}s. Sprawdzam zmiany w konfiguracji co {CONFIG_CHECK_INTERVAL}s.")
    print(f"{C('[MAIN]', 'blue', 'bold')} Naciśnij CTRL+C aby zatrzymać.")

    try:
        while GLOBAL_RUNNING_EVENT.is_set():
            current_time = time.time()
            
            # Sekcja zarządzania workerami
            if current_time - last_config_check_time >= CONFIG_CHECK_INTERVAL:
                try:
                    full_config = load_config(args.config)
                    accounts_list = full_config.get("accounts", [])
                    if not isinstance(accounts_list, list):
                        raise TypeError("Klucz 'accounts' w pliku konfiguracyjnym nie jest listą.")
                    
                    enabled_accounts = [acc for acc in accounts_list if acc.get("enabled", False)]
                    
                    workers = manage_workers(workers, enabled_accounts, global_worker_config, internet_monitor, _diag_file_lock, GLOBAL_RUNNING_EVENT)

                except Exception as e:
                    print(f"{C('[ERROR]', 'red', 'bold')} Błąd podczas odczytu konfiguracji i zarządzania wątkami: {e}", file=sys.stderr)
                
                last_config_check_time = current_time

            # Sekcja agregacji i zapisu cache
            if current_time - last_cache_write_time >= CACHE_AGGREGATION_INTERVAL:
                
                aggregated_results = {}
                any_network_failure_in_workers = False
                
                active_workers = [w for w in workers if w.is_alive()]

                for worker in active_workers:
                    snapshot = worker.last_known_state.copy()
                    aggregated_results[worker.login_id] = snapshot
                    if snapshot.get("last_error"):
                        any_network_failure_in_workers = True
                
                # ================================================================= #
                # <<< ZMIANA: Odczyt selektora konta przez zoptymalizowaną funkcję >>> #
                # ================================================================= #
                show_all_mode, selected_logins_from_file = load_active_accounts(SELECTOR_FILE_PATH)
                # ================================================================= #


                final_output_data = {}

                try:
                    current_config = load_config(args.config)
                    all_accounts_from_config = current_config.get("accounts", [])
                except Exception:
                    all_accounts_from_config = []


                if any_network_failure_in_workers and not internet_monitor.online:
                    final_output_data = safe_read_json(args.cache)
                    if not final_output_data:
                         final_output_data = {"unread": 0, "all": 0, "unread_cache": 0, "mails": [], "account_name": "Błąd sieci/IMAP (brak cache)"}
                else:
                    # ================================================================= #
                    # <<< POCZĄTEK KLUCZOWEJ ZMIANY: Logika filtrowania po loginach >>> #
                    # ================================================================= #
                    if show_all_mode:
                        # Tryb "Wszystkie konta"
                        total_unread = sum(res.get("unread", 0) for res in aggregated_results.values())
                        total_all = sum(res.get("all", 0) for res in aggregated_results.values())
                        total_unread_cache = sum(res.get("unread_cache", 0) for res in aggregated_results.values())
                        all_mails = [mail for res in aggregated_results.values() for mail in res.get("mails", [])]
                        all_mails.sort(key=lambda m: m.get('timestamp', 0), reverse=True)
                        final_output_data = {
                            "unread": total_unread,
                            "all": total_all,
                            "unread_cache": total_unread_cache,
                            "mails": all_mails,
                            "account_name": "Wszystkie konta"
                        }
                    else:
                        # Tryb "Wybrane konta"
                        total_unread, total_all, total_unread_cache, all_mails = 0, 0, 0, []
                        
                        # Filtruj wyniki workerów na podstawie wczytanych loginów
                        filtered_results = {login: res for login, res in aggregated_results.items() if login in selected_logins_from_file}

                        for res in filtered_results.values():
                            total_unread += res.get("unread", 0)
                            total_all += res.get("all", 0)
                            total_unread_cache += res.get("unread_cache", 0)
                            all_mails.extend(res.get("mails", []))
                        
                        all_mails.sort(key=lambda m: m.get('timestamp', 0), reverse=True)
                        
                        # Budowanie nazwy dla wyświetlacza
                        account_name_display = "Wybrane konta"
                        if selected_logins_from_file:
                            names_to_display = []
                            for login in selected_logins_from_file:
                                name_found = False
                                for acc in all_accounts_from_config:
                                    if acc.get("login") == login:
                                        names_to_display.append(acc.get("name") or login)
                                        name_found = True
                                        break
                                if not name_found:
                                    names_to_display.append(login)
                            account_name_display = ", ".join(names_to_display)

                        final_output_data = {
                            "unread": total_unread,
                            "all": total_all,
                            "unread_cache": total_unread_cache,
                            "mails": all_mails,
                            "account_name": account_name_display
                        }
                    # ================================================================= #
                    # <<< KONIEC KLUCZOWEJ ZMIANY >>>                                   #
                    # ================================================================= #

                last_seen_uids = load_last_seen()
                current_uids_in_output = set()
                if 'mails' in final_output_data:
                    for mail in final_output_data.get('mails', []):
                        uid = mail.get('uid')
                        if uid:
                            mail['is_new'] = uid not in last_seen_uids
                            current_uids_in_output.add(uid)
                        else:
                            mail['is_new'] = False
                
                # =========================================================================
                # === ZMIANA: OPTYMALIZACJA ZAPISU (START) ===
                # =========================================================================
                # Sprawdzamy, czy nowo zagregowane dane dla mail_cache.json się zmieniły.
                if final_output_data != last_written_data:
                    if internet_monitor.online:
                        safe_write_json(final_output_data, args.cache)
                        # Po udanym zapisie, aktualizujemy stan w pamięci.
                        last_written_data = final_output_data
                        # Możesz odkomentować poniższą linię, aby widzieć w logach, kiedy zapis faktycznie następuje
                        # print(f"{C('[CACHE]', 'dim')} Zapisano zmiany w mail_cache.json")

                # <<< NOWA ZMIANA: Osobna, warunkowa logika zapisu dla last_seen_mails.json >>>
                # Porównujemy zbiór UID-ów z pliku ze zbiorem nowo wygenerowanym.
                # Zapisujemy plik TYLKO wtedy, gdy te zbiory się różnią.
                if current_uids_in_output != last_seen_uids:
                    if internet_monitor.online:
                        save_last_seen(list(current_uids_in_output))
                        # Możesz odkomentować poniższą linię, aby widzieć w logach, kiedy zapis faktycznie następuje
                        # print(f"{C('[CACHE]', 'dim')} Zapisano zmiany w last_seen_mails.json")
                # =========================================================================
                # === ZMIANA: OPTYMALIZACJA ZAPISU (KONIEC) ===
                # =========================================================================

                _geoip_save_cache_file(args.geoip_cache)
                last_cache_write_time = current_time

            time.sleep(0.1)

    except Exception as main_error:
        print(f"{C('[CRITICAL ERROR]', 'red', 'bold')} Niespodziewany błąd w głównej pętli: {main_error}", file=sys.stderr)
    finally:
        print(f"{C('[MAIN]', 'blue', 'bold')} Oczekiwanie na zakończenie wątków...")
        GLOBAL_RUNNING_EVENT.clear()
        
        active_workers = [w for w in workers if w.is_alive()]
        for worker in active_workers:
            worker.join(timeout=global_worker_config.get("polling_interval", 60) + 5)
        
        internet_monitor.join(timeout=NETWORK_MONITOR_INTERVAL + 5)
        print(f"{C('[MAIN]', 'green', 'bold')} Program zakończył działanie.")
