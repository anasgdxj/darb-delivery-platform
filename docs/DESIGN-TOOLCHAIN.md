# DARB Visual Design and UI Quality Toolchain

## Goal

Make the customer, courier, vendor, and administration experiences visually consistent, accessible, and testable in both light and dark modes. This toolchain supplements `DESIGN_SYSTEM.md`; it does not replace it.

## Approved design source of truth

1. `DESIGN_SYSTEM.md` defines visual principles, semantic color values, typography, spacing, shape, motion, RTL, and interaction states.
2. `mobile-overrides/design_system.dart` is the current Flutter token implementation.
3. Figma is the design collaboration and screen-specification workspace. Components and variables must use the same semantic token names as the code; do not create screen-local brand palettes.
4. The rendered Flutter app remains the final authority for behavior, responsive layout, localization, and accessibility.

## Recommended toolchain

| Tool | Responsibility | Adoption rule |
|---|---|---|
| Figma | Screen flows, design variables, component specs, review comments, handoff | Use shared semantic tokens and named components; do not treat an unimplemented mock as shipped UI. |
| Widgetbook | Interactive catalog of reusable Flutter components and their light/dark states | Add after the real Flutter source and package manifest are extracted and inspected. |
| Flutter widget tests + golden tests | Deterministic screenshots for important components and screens | Capture light/dark, Arabic RTL, English/Turkish LTR, small-screen, loading, empty, error, and success states. |
| Patrol | Android end-to-end tests for real app journeys | Add only after inspecting the current app navigation/auth setup; keep OTP/SMS tests mocked unless an explicitly approved live test is requested. |
| Flutter accessibility guideline tests | Contrast, labels, tap target size, and text scaling checks | Run in CI for reusable components and critical flows. |
| GitHub Actions | Run design-token contract and UI tests on pull requests | A visual change is not accepted on analyzer success alone. |

Do not add packages blindly. First inspect the actual Flutter `pubspec.yaml` inside `DARB-source.zip`, the Android build configuration, and existing test conventions. Pin compatible versions and update the lockfile in the same pull request.

## Color repair protocol

- Use only `DarbColors` and the active `ThemeData` for semantic foregrounds, surfaces, borders, and status colors.
- Do not hard-code colors in feature screens, except for intentional brand artwork and media.
- Check every component state: default, pressed, focused, disabled, selected, loading, validation error, and success.
- Verify text contrast at WCAG 2.2 AA: at least 4.5:1 for normal text and 3:1 for large text and meaningful non-text UI boundaries.
- Do not assume a color is correct because it looks acceptable on one phone; test both brightness modes and text scaling.
- Use screenshot comparisons to catch accidental theme regressions. Review golden diffs rather than blindly updating baselines.

## Initial contrast correction

The light semantic muted text color was `#77837D`, which measured below 4.5:1 on the approved light canvas and white surface. It is changed to `#626F69`. The light warning color `#B7791F` also failed normal-text contrast on the light canvas; it is changed to `#8A5A12`. Dark-mode semantic colors remain unchanged in this correction.

A no-dependency CI checker in `scripts/verify-design-system.py` verifies the documented semantic color pairs and their contrast ratios. This is a token-level gate, not a substitute for auditing every rendered widget.

## Screen acceptance matrix

For each role (customer, driver, vendor, administration), verify:
- Light, dark, and system appearance; switching modes updates every visible component.
- Arabic RTL and English/Turkish LTR; phone, email, URLs, and numeric identifiers preserve appropriate LTR direction.
- Small Android viewport, keyboard open, and enlarged system text.
- Loading, empty, error/retry, and success states.
- Contrast, focus/pressed/disabled states, touch targets, and screen-reader labels.
- Reduced-motion preference; no critical action is delayed by animation.
- Weak or interrupted network; user-entered form data survives recoverable failures.

## Design review workflow

1. Describe the user problem and affected role/flow.
2. Update the Figma flow/component specification using existing tokens.
3. Implement a focused Flutter change; preserve API contracts and business behavior.
4. Add or update widget, golden, accessibility, and relevant end-to-end tests.
5. Attach before/after screenshots for light and dark modes to the pull request.
6. Run analyzer and tests; inspect golden diffs on a real Android device.
7. Merge only after review. Do not publish an APK merely because the UI test job passed.

## Current limitations

The complete Flutter source is stored in `DARB-source.zip`; the repository also carries backend overlays and the shared design-token overlay. Widgetbook, Patrol, and golden tests must not be installed or scaffolded until that archive's manifests, app entry points, and existing tests have been inspected. This avoids introducing incompatible versions or a second competing design system.
