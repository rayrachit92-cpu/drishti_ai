# ============================================================
# DRISHTI — SQLite Database Module
# Handles: users, sos_alerts, prediction_logs
# ============================================================

import sqlite3
import bcrypt
import requests
from datetime import datetime
from typing import Optional

DB_PATH = "drishti.db"
FIREBASE_API_KEY = "AIzaSyBSTvyfoIVRLXrscxk7gZLq79fUUdHgJwk"

def firebase_send_verification_email(id_token: str) -> bool:
    """Send verification email to the user via Firebase sendOobCode"""
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key={FIREBASE_API_KEY}"
    payload = {
        "requestType": "VERIFY_EMAIL",
        "idToken": id_token
    }
    try:
        r = requests.post(url, json=payload, timeout=10)
        return r.status_code == 200
    except Exception:
        return False

def firebase_check_email_verified(id_token: str) -> bool:
    """Check if operator's email is verified in Firebase"""
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:lookup?key={FIREBASE_API_KEY}"
    payload = {
        "idToken": id_token
    }
    try:
        r = requests.post(url, json=payload, timeout=10)
        if r.status_code == 200:
            users = r.json().get("users", [])
            if users:
                return users[0].get("emailVerified", False)
        return False
    except Exception:
        return False

def firebase_register(email: str, password: str):
    """Register a new user in Firebase Auth and send verification email. Returns (success_bool, local_id_or_error_msg)"""
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={FIREBASE_API_KEY}"
    payload = {
        "email": email,
        "password": password,
        "returnSecureToken": True
    }
    try:
        r = requests.post(url, json=payload, timeout=10)
        res = r.json()
        if r.status_code == 200:
            id_token = res.get("idToken")
            if id_token:
                firebase_send_verification_email(id_token)
            return True, res.get("localId")
        else:
            error_msg = res.get("error", {}).get("message", "Unknown registration error")
            return False, error_msg
    except Exception as e:
        return False, str(e)

def firebase_login(email: str, password: str):
    """Verify login in Firebase Auth. Returns (success_bool, data_dict_or_error_msg)"""
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={FIREBASE_API_KEY}"
    payload = {
        "email": email,
        "password": password,
        "returnSecureToken": True
    }
    try:
        r = requests.post(url, json=payload, timeout=10)
        res = r.json()
        if r.status_code == 200:
            return True, {
                "localId": res.get("localId"),
                "idToken": res.get("idToken"),
                "refreshToken": res.get("refreshToken"),
                "expiresIn": res.get("expiresIn")
            }
        else:
            error_msg = res.get("error", {}).get("message", "Unknown login error")
            return False, error_msg
    except Exception as e:
        return False, str(e)

# ── Demo account credentials ─────────────────────────────────
DEMO_EMAIL    = "demo@drishti.gov.in"
DEMO_PASSWORD = "demo1234"
DEMO_NAME     = "Demo Operator"
DEMO_ORG      = "NDMA"


# ── Internal helper ──────────────────────────────────────────
def _get_conn():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row   # rows behave like dicts
    return conn


# ════════════════════════════════════════════════════════════
#  INIT — create tables + seed demo account
# ════════════════════════════════════════════════════════════
def init_db():
    conn = _get_conn()
    c = conn.cursor()

    # ── Users table ─────────────────────────────────────────
    c.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            name          TEXT    NOT NULL,
            org           TEXT    NOT NULL DEFAULT '',
            email         TEXT    NOT NULL UNIQUE,
            password_hash TEXT    NOT NULL,
            role          TEXT    NOT NULL DEFAULT 'user',
            created_at    TEXT    NOT NULL
        )
    """)

    # ── SOS alerts table ────────────────────────────────────
    c.execute("""
        CREATE TABLE IF NOT EXISTS sos_alerts (
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            name          TEXT    NOT NULL,
            latitude      REAL    NOT NULL,
            longitude     REAL    NOT NULL,
            maps_link     TEXT    NOT NULL,
            telegram_sent INTEGER NOT NULL DEFAULT 0,
            timestamp     TEXT    NOT NULL
        )
    """)

    # ── Prediction logs table ────────────────────────────────
    c.execute("""
        CREATE TABLE IF NOT EXISTS prediction_logs (
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            city          TEXT    NOT NULL,
            flood_pct     REAL,
            drought_pct   REAL,
            heatwave_pct  REAL,
            max_risk      TEXT,
            timestamp     TEXT    NOT NULL
        )
    """)

    conn.commit()

    # ── Seed demo account if not already present ─────────────
    # Also register in Firebase Auth
    firebase_register(DEMO_EMAIL, DEMO_PASSWORD)

    existing = c.execute(
        "SELECT id FROM users WHERE email = ?", (DEMO_EMAIL,)
    ).fetchone()

    if not existing:
        pw_hash = bcrypt.hashpw(DEMO_PASSWORD.encode(), bcrypt.gensalt()).decode()
        c.execute(
            "INSERT INTO users (name, org, email, password_hash, role, created_at) VALUES (?,?,?,?,?,?)",
            (DEMO_NAME, DEMO_ORG, DEMO_EMAIL, pw_hash, "admin", datetime.now().isoformat())
        )
        conn.commit()
        print(f"✅ Demo account seeded locally → {DEMO_EMAIL}")
    else:
        print(f"✅ Demo account already exists locally → {DEMO_EMAIL}")

    conn.close()
    print("✅ Database initialised →", DB_PATH)


# ════════════════════════════════════════════════════════════
#  USER OPERATIONS
# ════════════════════════════════════════════════════════════

def create_user(name: str, org: str, email: str, password: str) -> dict:
    """
    Register a new user in Firebase Auth and sync their profile locally in SQLite.
    Returns dict with 'ok' or 'error'.
    """
    # 1. Register user on Firebase Auth first
    success, result = firebase_register(email, password)
    if not success:
        error_msg = result
        if result == "EMAIL_EXISTS":
            error_msg = "Email already registered in Firebase Auth."
        return {"ok": False, "error": error_msg}

    # 2. On success, store the user profile in local SQLite DB
    pw_hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()
    try:
        conn = _get_conn()
        conn.execute(
            "INSERT INTO users (name, org, email, password_hash, role, created_at) VALUES (?,?,?,?,?,?)",
            (name, org, email, pw_hash, "user", datetime.now().isoformat())
        )
        conn.commit()
        conn.close()
        return {"ok": True}
    except sqlite3.IntegrityError:
        # User already exists locally, which is fine since they are created on Firebase now
        return {"ok": True}
    except Exception as e:
        return {"ok": False, "error": f"Firebase registration succeeded, but SQLite sync failed: {str(e)}"}


def verify_user(email: str, password: str) -> Optional[dict]:
    """
    Verify login credentials via Firebase Auth.
    Syncs user details locally if missing.
    Checks email verification (skips for demo account).
    Returns user dict with Firebase idToken on success, or None on failure.
    """
    # 1. Verify credentials via Firebase Auth
    success, result = firebase_login(email, password)
    if not success:
        print(f"⚠️ Firebase login verification failed: {result}")
        return None

    id_token = result.get("idToken")

    # 2. Check if email is verified in Firebase (skip for demo user)
    if email.lower() != DEMO_EMAIL.lower():
        verified = firebase_check_email_verified(id_token)
        if not verified:
            # Re-send verification email to be helpful!
            firebase_send_verification_email(id_token)
            print(f"📧 User {email} is unverified. Verification email triggered.")
            return {"unverified": True, "email": email}

    # 3. Fetch or dynamically create user profile in SQLite
    conn = _get_conn()
    row = conn.execute(
        "SELECT * FROM users WHERE email = ?", (email,)
    ).fetchone()
    conn.close()

    # Dynamic SQLite sync if user registered externally or database was cleared
    if not row:
        name = email.split('@')[0].capitalize()
        pw_hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()
        try:
            conn = _get_conn()
            conn.execute(
                "INSERT INTO users (name, org, email, password_hash, role, created_at) VALUES (?,?,?,?,?,?)",
                (name, "External Operator", email, pw_hash, "user", datetime.now().isoformat())
            )
            conn.commit()
            row = conn.execute("SELECT * FROM users WHERE email = ?", (email,)).fetchone()
            conn.close()
            print(f"✨ Dynamically synced user profile to SQLite for: {email}")
        except Exception as e:
            print(f"⚠️ Failed to dynamically sync user to SQLite: {e}")

    if not row:
        return None

    return {
        "id":         row["id"],
        "name":       row["name"],
        "org":        row["org"],
        "email":      row["email"],
        "role":       row["role"],
        "created_at": row["created_at"],
        "idToken":    id_token,
        "localId":    result.get("localId")
    }


def get_all_users() -> list:
    """Return all users (without password hashes)."""
    conn = _get_conn()
    rows = conn.execute(
        "SELECT id, name, org, email, role, created_at FROM users ORDER BY created_at DESC"
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


# ════════════════════════════════════════════════════════════
#  SOS OPERATIONS
# ════════════════════════════════════════════════════════════

def log_sos_alert(name: str, lat: float, lon: float, maps_link: str, telegram_sent: bool) -> int:
    """
    Save an SOS alert to the database. Returns the new row id.
    """
    conn = _get_conn()
    cur = conn.execute(
        "INSERT INTO sos_alerts (name, latitude, longitude, maps_link, telegram_sent, timestamp) VALUES (?,?,?,?,?,?)",
        (name, lat, lon, maps_link, 1 if telegram_sent else 0, datetime.now().isoformat())
    )
    conn.commit()
    row_id = cur.lastrowid
    conn.close()
    return row_id


def get_sos_logs(limit: int = 50) -> list:
    """Return latest SOS alerts."""
    conn = _get_conn()
    rows = conn.execute(
        "SELECT * FROM sos_alerts ORDER BY timestamp DESC LIMIT ?", (limit,)
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


# ════════════════════════════════════════════════════════════
#  PREDICTION LOG OPERATIONS
# ════════════════════════════════════════════════════════════

def log_prediction(city: str, flood_pct: float, drought_pct: float,
                   heatwave_pct: float, max_risk: str) -> int:
    """Save a prediction result to the database."""
    conn = _get_conn()
    cur = conn.execute(
        "INSERT INTO prediction_logs (city, flood_pct, drought_pct, heatwave_pct, max_risk, timestamp) VALUES (?,?,?,?,?,?)",
        (city, flood_pct, drought_pct, heatwave_pct, max_risk, datetime.now().isoformat())
    )
    conn.commit()
    row_id = cur.lastrowid
    conn.close()
    return row_id


def get_prediction_logs(city: str = None, limit: int = 100) -> list:
    """Return latest prediction logs, optionally filtered by city."""
    conn = _get_conn()
    if city:
        rows = conn.execute(
            "SELECT * FROM prediction_logs WHERE city = ? ORDER BY timestamp DESC LIMIT ?",
            (city, limit)
        ).fetchall()
    else:
        rows = conn.execute(
            "SELECT * FROM prediction_logs ORDER BY timestamp DESC LIMIT ?", (limit,)
        ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


if __name__ == "__main__":
    init_db()
