#!/usr/bin/env bash
set -euo pipefail

M="${1:?mobile project directory is required}"

# DARB uses abstract vector city artwork. Never download or bundle city photos.
rm -rf "$M/assets/cities"

python3 - "$M/pubspec.yaml" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
if not path.is_file():
    raise SystemExit("pubspec.yaml not found")

source = path.read_text(encoding="utf-8")
source = re.sub(
    r"(?m)^  assets:\n(?=    - assets/cities/\s*$)(?:    - assets/cities/\s*\n)+",
    "",
    source,
)
source = re.sub(r"(?m)^    - assets/cities/\s*\n", "", source)
path.write_text(source, encoding="utf-8")
PY

if grep -R -n "assets/cities/" "$M/lib" "$M/pubspec.yaml"; then
  echo "City photo assets are forbidden in the DARB mobile build." >&2
  exit 1
fi
