#!/usr/bin/env python3
"""
Minimal example: fetch models.dev/api.json and pipe into models_pricing.py.
"""

import subprocess
import sys
from pathlib import Path

script_dir = Path(__file__).resolve().parent
pricing_script = script_dir / "models_pricing.py"

if not pricing_script.exists():
    print("Error: models_pricing.py not found at %s" % pricing_script, file=sys.stderr)
    sys.exit(1)

fetch = subprocess.Popen(
    ["curl", "-sL", "https://models.dev/api.json"],
    stdout=subprocess.PIPE,
)
run = subprocess.run(
    [sys.executable, str(pricing_script)],
    stdin=fetch.stdout,
)
fetch.wait()
sys.exit(run.returncode)
