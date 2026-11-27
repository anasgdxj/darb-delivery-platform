#!/usr/bin/env bash
set -euo pipefail
M="${1:?mobile project directory is required}"
CITY_DIR="$M/assets/cities"
mkdir -p "$CITY_DIR"
fetch() { curl --fail --location --silent --show-error --retry 3 --retry-delay 2 -A 'DarbApp city hero asset bundle' "$1" -o "$2"; }
fetch 'https://commons.wikimedia.org/wiki/Special:FilePath/Citadel%20of%20Aleppo%2C%20View%20of%20the%20city%2C%20Aleppo%2C%20Syria.jpg?width=1440' "$CITY_DIR/aleppo.jpg"
fetch 'https://commons.wikimedia.org/wiki/Special:FilePath/Al-Dablan%20Street.jpg?width=1440' "$CITY_DIR/homs.jpg"
fetch 'https://commons.wikimedia.org/wiki/Special:FilePath/Hama%20008-009%20Pan.jpg?width=1440' "$CITY_DIR/hama.jpg"
fetch 'https://commons.wikimedia.org/wiki/Special:FilePath/Damascus%20Panorama.jpg?width=1440' "$CITY_DIR/damascus.jpg"
fetch 'https://commons.wikimedia.org/wiki/Special:FilePath/Latakia%20City.jpg?width=1440' "$CITY_DIR/latakia.jpg"
cat > "$CITY_DIR/ATTRIBUTION.txt" <<'CREDITS'
DARB city hero photography — attribution

Aleppo — “Citadel of Aleppo, View of the city, Aleppo, Syria.jpg”, Vyacheslav Argenberg, CC BY 4.0.
https://commons.wikimedia.org/wiki/File:Citadel_of_Aleppo,_View_of_the_city,_Aleppo,_Syria.jpg

Homs — “Al-Dablan Street.jpg”, Bo yaser, CC BY-SA 2.5.
https://commons.wikimedia.org/wiki/File:Al-Dablan_Street.jpg

Hama — “Hama 008-009 Pan.jpg”, Yvonnefm, CC BY-SA 3.0.
https://commons.wikimedia.org/wiki/File:Hama_008-009_Pan.jpg

Damascus — “Damascus Panorama.jpg”, Wurzelgnohm, CC0 1.0.
https://commons.wikimedia.org/wiki/File:Damascus_Panorama.jpg

Latakia — “Latakia City.jpg”, Toni Elias, CC BY-SA 4.0.
https://commons.wikimedia.org/wiki/File:Latakia_City.jpg

Photos are downloaded and bundled at build time; the installed app does not need a network connection to display them.
CREDITS
python3 - "$M/pubspec.yaml" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
if 'assets/cities/' not in s:
    if '\nflutter:\n' not in s: raise SystemExit('flutter section missing from pubspec.yaml')
    s=s.replace('\nflutter:\n', '\nflutter:\n  assets:\n    - assets/cities/\n', 1)
p.write_text(s)
PY
