# DARB Design System

Version: 2.0  
Scope: Flutter mobile app (customer, driver, vendor, administration)  
Source of truth: `mobile-overrides/design_system.dart`

This document defines the shared visual and interaction language for DARB. It does not authorize changing product behavior or backend contracts.

## Product principles

- Arabic-first experience with correct RTL layout; English and Turkish remain supported.
- Clear primary action on every screen. Avoid competing calls to action.
- Use real API data. Never fill empty screens with invented stores, orders, prices, ratings, or driver offers.
- Every network-driven screen must represent loading, success, empty, and recoverable error states.
- Keep forms short, validate before sending, and preserve entered data after recoverable failures.
- Maintain accessible contrast, readable touch targets, and responsive layouts for small Android devices.
- Separate API/business logic from presentation when adding or restructuring screens.
- Preserve authentication, package identity, release signing, and existing API contracts unless a separately reviewed change requires otherwise.

## Approved visual direction: DARB PULSE 2026

DARB should feel like a live logistics network: confident, clear, fast, and premium. The interface is map-aware and task-first, not a generic shopping template.

- **Visual hierarchy:** one dominant task per screen; supporting actions remain secondary.
- **Customer experience:** make the two service paths unmistakable—ordering from stores and independent parcel delivery. Do not hide independent delivery when stores are unavailable.
- **Driver experience:** prioritize availability, nearby eligible requests, active delivery progress, and the next required action.
- **Vendor experience:** prioritize incoming orders and the preparation/hand-off sequence.
- **Administration:** prioritize operational queues, approvals, exceptions, and delivery-zone controls.
- **Navigation:** role-specific destinations remain stable and predictable. Do not add tabs merely for decoration.
- **Map use:** show maps only where location materially helps a task. A map must not displace the primary action or make weak-network startup heavier.
- **Motion:** dynamic and rich, but purposeful. Motion explains state, hierarchy, and transitions; it never delays critical actions.
- **Surface language:** the persisted Glass mode is a real frosted-glass system across customer, driver, vendor, administration, account, settings, and navigation surfaces. Use the shared `DarbGlassBackdrop`, `DarbGlassSurface`, `DarbGlassCard`, and `DarbGlassMaterial` primitives for atmospheric backgrounds, blur, translucency, fine highlights, and layered depth. Standard mode remains opaque and disables blur. Keep text and critical controls high-contrast; do not apply blur to text itself.
- **Content integrity:** no fake live data, placeholder ratings, fabricated availability, or invented delivery prices.

## Color system

### Shared brand anchors

| Token | Hex | Usage |
|---|---|---|
| forest | #102B26 | Primary brand and high-emphasis actions |
| forestSoft | #1C443B | Secondary brand surfaces |
| mint | #B9E4D2 | Selected and supportive states |
| danger | #B94747 | Destructive actions and errors |
| success | #287A50 | Confirmed/success states |
| warning | #B7791F | Pending/attention states |
| info | #356D9A | Informational states |

### Light semantic surfaces

| Token | Hex | Usage |
|---|---|---|
| canvas | #F5F6F2 | Main application background |
| surface | #FFFFFF | Cards, sheets, and fields |
| ink | #17231F | Main text |
| muted | #77837D | Secondary text and hints |
| line | #E4E9E3 | Dividers and subtle borders |
| borderStrong | #CBD5CE | Stronger boundaries |
| scrim | #990B1713 | Modal backdrops |

### Dark semantic surfaces

The dark theme must use a separate semantic palette; do not invert the light palette mechanically.

| Semantic role | Target color | Usage |
|---|---|---|
| canvas | #0B1512 | App background |
| surface | #13221D | Main cards and navigation surfaces |
| surfaceElevated | #1A2D26 | Sheets, dialogs, elevated cards |
| ink | #F1F5F1 | Primary text |
| muted | #A4B2AA | Secondary text and hints |
| line | #2A3B33 | Dividers and subtle borders |
| borderStrong | #40564A | Stronger boundaries |
| primary | #B9E4D2 | Main interactive emphasis on dark surfaces |
| onPrimary | #102B26 | Text/icons on primary |
| scrim | #B3000000 | Modal backdrops |

Dark palette values are implemented through adaptive `DarbColors` semantic tokens, including `primary` / `onPrimary` for interactive controls and `surfaceElevated` for raised containers. The palette uses forest green and muted mint only; lime green is not part of the product palette. The app defaults to the operating-system appearance and supports persisted System / Light / Dark selection. `surfaceAlt` is the adaptive soft-surface token for icon wells and secondary containers. Brand anchors remain stable; semantic foregrounds, backgrounds, borders, and status colors adapt to the active brightness. Contrast and component states must be verified in implementation before this theme is considered complete.

Do not introduce near-duplicate brand colors in individual screens. Add genuinely new semantic colors centrally and document their use. All screen colors must resolve through the active theme; screen-specific hard-coded palette values are not permitted except for intentional brand artwork and media. Use `DarbColors.primary` with `DarbColors.onPrimary` for primary controls; use `DarbColors.brandForeground` for text and icons placed on ordinary surfaces. Keep `forest` and `forestSoft` only for intentional fixed brand artwork and photo overlays.

## Spacing

Use the `DarbSpace` scale:
- xxs: 4
- xs: 8
- sm: 12
- md: 16
- lg: 20
- xl: 24
- xxl: 32
- section: 40

Prefer 16–20 px screen gutters, 12–16 px internal card spacing, and 24–40 px between major sections. Avoid arbitrary spacing values unless a specific visual alignment requires them.

## Shape and elevation

Use `DarbRadius`:
- sm: 12
- md: 16
- lg: 22
- xl: 28
- hero: 36
- pill: 999

Use `DarbElevation.card` for ordinary cards and `DarbElevation.floating` for floating/high-priority surfaces. Do not stack heavy shadows on every element. Prefer borders and tonal separation.

## Typography

Use the shared theme text styles. Maintain readable Arabic typography and consistent hierarchy across Arabic, English, and Turkish. Keep titles concise, body copy comfortably readable, and secondary labels visually subordinate. Avoid long all-bold paragraphs. Use localized strings through the existing localization helpers.

## Motion

Use the shared primitives and tokens in `mobile-overrides/design_system.dart`:
- press feedback: 120 ms
- fast: 160 ms
- standard: 260 ms
- route: 340 ms
- expressive: 420 ms
- stagger step: 55 ms
- enter: easeOutCubic
- exit: easeInCubic
- expressive emphasis: easeOutBack

Reusable building blocks:
- `DarbFadeSlide` for staggered content entrances; use `DarbMotion.staggerDelay(index)` for list items.
- `DarbPressScale` for tactile press feedback on custom interactive surfaces.
- `DarbMotion.effectiveDuration(context, duration)` and `DarbMotion.reduceMotion(context)` to honor the operating-system accessibility preference.
- `DarbPageTransitionsBuilder` supplies the same short fade/slide/scale route transition in light and dark themes.
- `DarbCityCarousel` rotates locally bundled, attributed Syrian city photography on the login hero; transitions respect Reduce Motion and do not require network access.

Use motion for screen transitions, selected navigation, expanding details, order progression, and confirmation feedback. Stagger only small groups; avoid animating every row in long lists. Never delay a critical action for decorative animation. All motion must become immediate when reduced motion is enabled.

## Components and interaction

- Primary action: `FilledButton`, one clear primary action per view.
- Secondary action: `OutlinedButton` or `TextButton`.
- Destructive action: use the active theme's error color and require confirmation when consequential.
- Cards: use `DarbGlassCard` in Glass mode (real `BackdropFilter` blur plus translucent fill) and opaque semantic surfaces in Standard mode.
- Inputs: shared `InputDecorationTheme`; show validation beside the relevant field.
- Navigation: shared Material 3 navigation; preserve role-specific destinations.
- Dialogs and sheets: shared theme shapes and surfaces.
- Loading: use a clear progress indicator or skeleton that matches the final content footprint.
- Empty: explain what is absent and offer a relevant next action where possible.
- Error: explain the failure in user language and provide retry without discarding user input.
- Success: confirm the completed action and make the next step clear.

## Role-specific information architecture

### Customer
Home, store discovery, store catalog, cart/checkout, independent parcel delivery, active orders, order history, saved addresses, account and support.

### Driver
Availability and online status, available delivery requests, fare/offer flow where supported by the API, active deliveries, pickup/drop-off progression, delivery history, account.

### Vendor
Store status, incoming orders, order detail and status progression, product catalog, account.

### Administration
Pending vendor/driver approvals, delivery-zone and fee configuration, operational order visibility, account. Do not expose administrative capabilities to non-admin roles.

## RTL and localization

- Use the app's existing locale state and localization helper.
- Let directional layout follow the active locale; do not hard-code left/right for semantic navigation.
- Phone numbers, email addresses, URLs, and numeric identifiers should retain appropriate LTR direction.
- Do not remove Arabic, English, or Turkish support while redesigning screens.

## Architecture and quality gates

- Keep widgets focused on rendering and interaction.
- Move API orchestration, validation, and state transitions into dedicated controllers/services when refactoring.
- Do not duplicate endpoint strings or business rules across screens.
- Preserve current endpoint payloads until backend compatibility is verified.
- Run `flutter analyze` and the available tests before publishing.
- A UI phase is not complete until tested on a real device for RTL, small screens, loading, empty, error, and success states.
- Preserve authentication, package identity, release signing, and installed-app update compatibility.
- Do not merge or publish a release before review and explicit approval.

## Current implementation notes

The token implementation lives in `mobile-overrides/design_system.dart`. Keep this document aligned with the code. A theme is incomplete until all customer, driver, vendor, and administration screens use semantic colors and all key components are legible in both modes.
