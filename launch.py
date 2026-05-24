#!/usr/bin/env python3
"""
DRISHTI — one command to create the database and start the app.

Usage:
    python3 launch.py
"""

import os
import sys
import subprocess

ROOT = os.path.dirname(os.path.abspath(__file__))


def main():
    os.chdir(ROOT)

    print("\n" + "═" * 50)
    print("  DRISHTI — Launch")
    print("═" * 50)

    # Step 1: create / update SQLite database
    print("\n[1/2] Creating database (drishti.db)…")
    try:
        from database import init_db, DB_PATH
    except ImportError as e:
        print("\n❌ Missing packages. Run first:")
        print("   pip3 install -r requirements.txt")
        print(f"\n   ({e})")
        sys.exit(1)

    try:
        init_db()
        db_file = os.path.join(ROOT, DB_PATH)
        if os.path.isfile(db_file):
            size_kb = os.path.getsize(db_file) // 1024
            print(f"   📁 {db_file} ({size_kb} KB)")
        else:
            print("   ⚠️  drishti.db was not created — check errors above.")
            sys.exit(1)
    except Exception as e:
        print(f"\n❌ Database setup failed: {e}")
        sys.exit(1)

    # Step 2: start Flask app (also calls init_db again on import — safe)
    print("\n[2/2] Starting server at http://localhost:5001 …\n")
    print("═" * 50 + "\n")
    result = subprocess.run([sys.executable, "app_combined.py"], cwd=ROOT)
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
