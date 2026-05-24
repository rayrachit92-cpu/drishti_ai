# DRISHTI — Disaster Intelligence System

## Quick start (web app)

**Terminal 1 — start backend + database:**

```bash
cd /Users/rachitray/Downloads/Minor-main-2
pip3 install -r requirements.txt
python3 launch.py
```

Open **http://localhost:5001** in your browser.

**Demo login:** `demo@drishti.gov.in` / `demo1234`

If port 5001 is busy:

```bash
lsof -ti:5001 | xargs kill -9
python3 launch.py
```

---

## Flutter mobile app (optional)

Requires **Xcode** (iOS/macOS) or **Android Studio** (emulator).

```bash
# Terminal 1 — same Flask server as above
python3 launch.py

# Terminal 2
cd drishti_ai
flutter pub get
flutter run -d macos    # needs Xcode
# or
flutter run             # with Android emulator running
```

Set server URL on login: `http://127.0.0.1:5001` (simulator) or `http://10.0.2.2:5001` (Android emulator).

---

## Files needed to run

| File | Purpose |
|------|---------|
| `launch.py` | Creates DB + starts server |
| `app_combined.py` | Flask API + web UI |
| `database.py` | SQLite users / logs |
| `flood_predictor.py` | ML predictions |
| `index_combined.html` | Web frontend |
| `models/*.pkl` | Trained ML models |
| `india_2000_2024_daily_weather.csv` | Historical weather data |
| `requirements.txt` | Python packages |
| `drishti.db` | Created on first run |

Retrain models (optional): `python3 flood_predictor.py train`
