#!/usr/bin/env python3
"""Validate documented Darb semantic colors and WCAG AA text contrast."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / "DESIGN_SYSTEM.md"
TOKENS = ROOT / "mobile-overrides" / "design_system.dart"

PAIRS = {
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
    "dark danger status": ("#E47777", "#13221D", 4.5),
    "dark success status": ("#75C99A", "#13221D", 4.5),
    "dark warning status": ("#E5B968", "#13221D", 4.5),
    "dark info status": ("#83B8E0", "#13221D", 4.5),
    "light button label": ("#FFFFFF", "#102B26", 4.5),
    "dark button label": ("#102B26", "#B9E4D2", 4.5),
}


def luminance(hex_color: str) -> float:
    rgb = [int(hex_color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
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
    missing = [str(path.relative_to(ROOT)) for path in (DOC, TOKENS) if not path.is_file()]
    if missing:
        print("Missing design-system source files: " + ", ".join(missing))
        return 1

    doc_text = DOC.read_text(encoding="utf-8")
    token_text = TOKENS.read_text(encoding="utf-8")
    failures = []

    for name, (foreground, background, minimum) in PAIRS.items():
        ratio = contrast(foreground, background)
        if ratio < minimum:
            failures.append(f"{name}: {ratio:.2f}:1 is below {minimum:.1f}:1")

        for color in (foreground, background):
            if color not in doc_text:
                failures.append(f"{name}: {color} is missing from DESIGN_SYSTEM.md")
            dart_literal = "0xFF" + color[1:]
            if dart_literal not in token_text and color != "#FFFFFF":
                failures.append(
                    f"{name}: {dart_literal} is missing from mobile-overrides/design_system.dart"
                )

    required_implementation = (
        "static Color get muted",
        "static Color get warning",
        "class DarbTheme",
        "class DarbPageTransitionsBuilder",
    )
    for marker in required_implementation:
        if marker not in token_text:
            failures.append(f"Missing implementation marker: {marker}")

    if failures:
        print("DARB design-system contract FAILED:")
        for failure in failures:
            print(f" - {failure}")
        return 1

    print(f"DARB design-system contract passed: {len(PAIRS)} contrast pairs meet WCAG AA.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
