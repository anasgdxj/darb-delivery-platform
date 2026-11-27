#!/usr/bin/env bash
set -euo pipefail

M="${1:?mobile project directory is required}"

python3 - "$M/pubspec.yaml" "$M/assets/cities" <<'PY'
from pathlib import Path
import shutil
import sys

pubspec = Path(sys.argv[1])
city_assets = Path(sys.argv[2])
lines = pubspec.read_text(encoding="utf-8").splitlines()
result = []
index = 0

while index < len(lines):
    line = lines[index]
    if line.strip() == "assets:" and len(line) - len(line.lstrip()) == 2:
        index += 1
        children = []
        while index < len(lines):
            candidate = lines[index]
            if candidate.strip() and len(candidate) - len(candidate.lstrip()) <= 2:
                break
            if candidate.strip() and "assets/cities/" not in candidate:
                children.append(candidate)
            index += 1
        if children:
            result.append(line)
            result.extend(children)
        continue
    if "assets/cities/" not in line:
        result.append(line)
    index += 1

pubspec.write_text("\n".join(result) + "\n", encoding="utf-8")
shutil.rmtree(city_assets, ignore_errors=True)
print("Vector-only city artwork enabled; obsolete city photo assets removed.")
PY
