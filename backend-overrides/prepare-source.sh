#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:?source root required}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATION_DIR="$ROOT/backend/prisma/migrations/20261119120000_delivery_offers"
mkdir -p "$MIGRATION_DIR"
AI_MIGRATION_DIR="$ROOT/backend/prisma/migrations/20261120120000_ai_order_assistant"
mkdir -p "$AI_MIGRATION_DIR"
cp "$SCRIPT_DIR/ai-order-assistant.migration.sql" "$AI_MIGRATION_DIR/migration.sql"
cp "$SCRIPT_DIR/delivery-offers.migration.sql" "$MIGRATION_DIR/migration.sql"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import json, sys
root = Path(sys.argv[1])
backend = root / "backend"
mobile = root / "mobile"

package = backend / "package.json"
data = json.loads(package.read_text())
data.setdefault("dependencies", {})["google-auth-library"] = "^9.15.1"
data["dependencies"]["firebase-admin"] = "^12.7.0"
package.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")

pubspec = mobile / "pubspec.yaml"
s = pubspec.read_text()
deps = [
    "  google_sign_in: ^6.2.1",
    "  geolocator: ^13.0.2",
    "  url_launcher: ^6.3.1",
    "  firebase_core: ^3.8.1",
    "  firebase_messaging: ^15.1.6",
]
for dep in deps:
    name = dep.split(":")[0].strip()
    if name + ":" in s:
        continue
    lines = s.splitlines()
    dep_index = next((idx for idx, line in enumerate(lines) if line.strip() == "dependencies:"), None)
    if dep_index is None:
        raise SystemExit("pubspec.yaml: dependencies section missing")
    lines.insert(dep_index + 1, dep)
    s = "\n".join(lines) + "\n"
pubspec.write_text(s)

manifest = mobile / "android/app/src/main/AndroidManifest.xml"
m = manifest.read_text()
for permission in [
    '<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />',
    '<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />',
    '<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />',
]:
    if permission not in m:
        m = m.replace(
            '<uses-permission android:name="android.permission.INTERNET" />',
            '<uses-permission android:name="android.permission.INTERNET" />\n    ' + permission,
        )
manifest.write_text(m)
PY
