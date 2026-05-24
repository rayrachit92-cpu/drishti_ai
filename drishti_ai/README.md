# DRISHTI Flutter App

Mobile client for the DRISHTI disaster intelligence system. It uses your **existing Flask backend** (`app_combined.py`) for ML predictions, login, and SOS — the ML models stay on Python.

## Architecture

```
Flutter app (drishti_ai)  →  HTTP  →  Flask API (port 5001)  →  SQLite + Firebase + ML
```

## Run (two terminals)

### Terminal 1 — Backend

```bash
cd /Users/rachitray/Downloads/Minor-main-2
pip3 install -r requirements.txt
python3 launch.py
```

### Terminal 2 — Flutter

```bash
cd /Users/rachitray/Downloads/Minor-main-2/drishti_ai
flutter pub get
flutter run
```

## Server URL on login screen

| Device | Flask server URL |
|--------|------------------|
| Android emulator | `http://10.0.2.2:5001` |
| iOS simulator / same Mac | `http://127.0.0.1:5001` |
| Physical phone | `http://YOUR_PC_IP:5001` (same Wi‑Fi) |

Demo login: `demo@drishti.gov.in` / `demo1234`

## Features

- Sign in / Register (Flask `/api/login`, `/api/register`)
- Dashboard quick predict
- Weather lookup
- Disaster prediction (flood, drought, heatwave)
- Live rainfall alert + map
- India risk map (all 20 cities)
- Emergency SOS with GPS + Telegram

## Project structure

```
lib/
  config/       # API base URL, cities list
  services/     # HTTP client for Flask
  screens/      # UI pages
  widgets/      # Reusable cards, panels
  theme/        # Colors matching web UI
```
