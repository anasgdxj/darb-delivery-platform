#!/usr/bin/env python3
"""Validate DARB semantic design tokens and WCAG AA text contrast."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / "DESIGN_SYSTEM.md"
TOKENS = ROOT / "mobile-overrides" / "lib" / "core" / "theme" / "darb_design_system.dart"
ADMIN = ROOT / "admin-web" / "index.html"

TOKEN_COLORS = {
    "forest": "#102B26",
    "forestSoft": "#1C443B",
    "mint": "#B9E4D2",
    "danger": "#B94747",
    "success": "#287A50",
    "warning": "#8A5A12",
    "info": "#356D9A",
    "canvas": "#F5F6F2",
    "surface": "#FFFFFF",
    "ink": "#17231F",
    "muted": "#626F69",
    "line": "#E4E9E3",
    "borderStrong": "#CBD5CE",
    "darkCanvas": "#0B1512",
    "darkSurface": "#13221D",
    "darkSurfaceElevated": "#1A2D26",
    "darkInk": "#F1F5F1",
    "darkMuted": "#A4B2AA",
    "darkLine": "#2A3B33",
    "darkBorderStrong": "#40564A",
    "darkDanger": "#E56868",
    "darkSuccess": "#4FB982",
    "darkWarning": "#E2A84B",
    "darkInfo": "#63A6DC",
}

CONTRAST_PAIRS = {
    "light primary text on canvas": ("#17231F", "#F5F6F2", 4.5),
    "light primary text on surface": ("#17231F", "#FFFFFF", 4.5),
    "light muted text on canvas": ("#626F69", "#F5F6F2", 4.5),
    "light muted text on surface": ("#626F69", "#FFFFFF", 4.5),
    "dark primary text on canvas": ("#F1F5F1", "#0B1512", 4.5),
    "dark primary text on surface": ("#F1F5F1", "#13221D", 4.5),
    "dark muted text on canvas": ("#A4B2AA", "#0B1512", 4.5),
    "dark muted text on surface": ("#A4B2AA", "#13221D", 4.5),
    "light danger status": ("#B94747", "#F5F6F2", 4.5),
    "light success status": ("#287A50", "#F5F6F2", 4.5),
    "light warning status": ("#8A5A12", "#F5F6F2", 4.5),
    "light info status": ("#356D9A", "#F5F6F2", 4.5),
    "dark danger status": ("#E56868", "#13221D", 4.5),
    "dark success status": ("#4FB982", "#13221D", 4.5),
    "dark warning status": ("#E2A84B", "#13221D", 4.5),
    "dark info status": ("#63A6DC", "#13221D", 4.5),
    "light button label": ("#FFFFFF", "#102B26", 4.5),
    "dark button label": ("#102B26", "#B9E4D2", 4.5),
}


def luminance(hex_color: str) -> float:
    rgb = [int(hex_color[1 + i:3 + i], 16) / 255 for i in (0, 2, 4)]
    linear = [
        channel / 12.92 if channel <= 0.04045
        else ((channel + 0.055) / 1.055) ** 2.4
        for channel in rgb
    ]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def contrast(foreground: str, background: str) -> float:
    high, low = sorted(
        (luminance(foreground), luminance(background)), reverse=True
    )
    return (high + 0.05) / (low + 0.05)


def main() -> int:
    missing = [
        str(path.relative_to(ROOT))
        for path in (DOC, TOKENS, ADMIN)
        if not path.is_file()
    ]
    if missing:
        print("Missing design-system source files: " + ", ".join(missing))
        return 1

    doc_text = DOC.read_text(encoding="utf-8")
    token_text = TOKENS.read_text(encoding="utf-8")
    admin_text = ADMIN.read_text(encoding="utf-8")
    failures = []

    for token, color in TOKEN_COLORS.items():
        dart_value = "0xFF" + color[1:]
        pattern = rf"static const {re.escape(token)}\s*=\s*Color\({dart_value}\);"
        if not re.search(pattern, token_text):
            failures.append(f"DarbColors.{token} does not match {color}")
        if color not in doc_text:
            failures.append(f"{color} for {token} is missing from DESIGN_SYSTEM.md")

    for name, (foreground, background, minimum) in CONTRAST_PAIRS.items():
        ratio = contrast(foreground, background)
        if ratio < minimum:
            failures.append(f"{name}: {ratio:.2f}:1 is below {minimum:.1f}:1")

    for alias in ("darkPrimary = mint", "darkOnPrimary = forest", "darkAccent = mint"):
        if alias not in token_text:
            failures.append(f"Missing adaptive dark semantic alias: {alias}")

    if "lime" in token_text.lower() or "#C8F169" in doc_text or "--lime" in admin_text:
        failures.append("Obsolete lime accent remains in the mobile, design, or admin palette")

    if "mobile-overrides/lib/core/theme/darb_design_system.dart" not in doc_text:
        failures.append("DESIGN_SYSTEM.md does not point to the modular Flutter token source")

    if failures:
        print("DARB design-system contract FAILED:")
        for failure in failures:
            print(f" - {failure}")
        return 1

    print(
        f"DARB design-system contract passed: {len(TOKEN_COLORS)} semantic tokens "
        f"and {len(CONTRAST_PAIRS)} WCAG AA contrast pairs verified."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
