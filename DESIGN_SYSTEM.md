# DAZREVO Design System

Version: 2026.3 (Obsidian Emerald, Volt Lime & Signal Violet)  
Scope: Flutter mobile app (`mobile-overrides/` & `darb-workspace/darb-project/mobile/`), Public Website (`/`), and Admin Operations Portal (`admin-web/`)  
Source of truth (Mobile): `mobile-overrides/lib/core/theme/darb_design_system.dart`

This document defines the unified visual, motion, typography, and structural architecture for **DAZREVO** (**دازريفو** in Arabic; **DAZREVO** in English & Turkish). Internal `Darb*` Dart symbols, `com.darb.darb` Android/package identity, signing configuration, and `/api/v1/*` backend contracts are intentionally preserved.

---

## 1. Product Principles

- **Arabic-first RTL + English/Turkish LTR**: Every screen and web page adapts cleanly across `ar` (`RTL`), `en` (`LTR`), and `tr` (`LTR`).
- **Clear Primary Action**: Single dominant CTA per decision block (`DarbActionButton` / primary pill action), paired with accessible touch targets (`>= 48dp` mobile, `>= 44px` web).
- **Real Backend Data Only**: Zero synthetic stores, fake wallet balances, mock driver counts, or fabricated ratings. Every ledger strip, AI assistant, order timeline, and admin queue reads live backend APIs.
- **Explicit Async States**: Loading (`DarbShimmer` wireframes), empty, offline cache banner, and recoverable error states preserve entered form data and give shake + haptic feedback (`DarbShakeBox` + `DarbHaptics`).
- **Session & Platform Continuity**: Preserves Google Sign-In, MsgPlus SMS OTP, Firebase/FCM notifications, real coordinate map pickers/tracking, `com.darb.darb` package ID, release signing, and dual-track APK / Play Store releases.

---

## 2. Visual Direction: Obsidian Emerald, Volt Lime & Signal Violet

DAZREVO feels like a precision urban logistics command platform: deep Obsidian Emerald anchors (`#0B2F24`), high-visibility Volt Lime kinetic CTAs and active beacons (`#A7FF00`), Mineral Daylight cards (`#F8FAF7` / `#FFFFFF`), layered Neo Dark surfaces (`#071A14` -> `#0E281F` -> `#14352A`), and dedicated Signal Violet AI surfaces (`#8A5CF6` / `#A78BFA`).

- **Splash & Interactive Onboarding (`main.dart`, `onboarding_screen.dart`)**: Obsidian Emerald splash gate + 3-slide interactive `OnboardingScreen` persisted via `kDazrevoOnboardingSeenKey` (`onboarding_seen_v1`) and replayable from `LoginScreen` and `AccountScreen`.
- **Authentication & Global Shell (`login_screen.dart`, `app_shell.dart`)**: Geometric vector network map (`DarbLoginVectorMap`, zero city photos), `DarbBrandMark`, `1 / 2 -> 2 / 2` auth step pill, LTR Syrian phone formatting + OTP countdown, custom Google emblem CTA, and Signal Violet AI command button in the shell app bar.
- **Customer Experience (`customer_home_screen.dart`, `vendor_catalog_screen.dart`, `checkout_screen.dart`, `ai_order_assistant_screen.dart`)**: Abstract `DarbCitySceneCard` (zero city photos), 6:5 asymmetric Bento action split (`DarbBentoActionCard`), Signal Violet AI order assistant, Obsidian Emerald + Volt Lime floating cart dock, live `DarbOrderTimeline`, and spatial courier GPS tracking (`DriverTrackingScreen`).
- **Account & Live Activity Ledger (`account_screen.dart`)**: Obsidian Emerald header card, live role-aware `DarbActivityLedgerStrip` (fetching `/orders/mine`, `/drivers/stats`, `/vendors/mine/stats`, or `/admin/stats`), dedicated `EditProfileScreen`, 5-step Driver & Vendor onboarding wizards (`DriverApplicationScreen`, `VendorApplicationScreen`), Signal Violet `AiRoleAssistantScreen`, and Glass/Standard + System/Light/Dark appearance controls.
- **Driver, Vendor & Administration**: Unified token resolution across driver cockpit (`DarbPulseDot` + Volt Lime border when online), merchant order progression + product inventory, and multi-tab admin operations portal (`admin-web/index.html`) including an Admin AI Copilot (`POST /ai/assistant/ask`).

---

## 3. Unified Color System

### Brand & Accent Anchors

| Token | Hex | Usage |
|---|---|---|
| `forest` | `#0B2F24` | Obsidian Emerald brand anchor, dark hero containers & floating cart dock |
| `primaryGreen` | `#0D6E4E` | High-contrast interactive primary green in Light mode |
| `forestSoft` | `#144435` | Secondary emerald containers and dark accent washes |
| `mint` | `#A8EBC8` | Supportive highlights, selected states, map route accents |
| `lime` | `#A7FF00` | Volt Lime kinetic CTA, active beacons (`DarbPulseDot`), dark primary |
| `limeInk` | `#3E6800` | Accessible high-contrast lime ink on light mineral surfaces |
| `limeTint` | `#E7FFAD` | Soft lime tint badge background on Light mode |
| `violet` | `#8A5CF6` | Signal Violet AI assistant accent (Light mode) |
| `violetSoft` | `#F1EBFF` | Signal Violet tinted containers (Light mode) |
| `danger` | `#CF3B3B` | Destructive actions and error states |
| `success` | `#17804B` | Confirmed and delivered states |
| `warning` | `#C67A12` | Pending and review alerts |
| `info` | `#1E6FA8` | Informational notices |

### Light Semantic Surfaces (Mineral Daylight Canvas)

| Token | Hex | Usage |
|---|---|---|
| `canvas` | `#F8FAF7` | Main light background canvas |
| `surface` | `#FFFFFF` | Cards, inputs, bottom sheets |
| `surfaceAlt` | `#EDF2EC` | Secondary containers, pills, icon wells |
| `ink` | `#0E221B` | Primary high-contrast typography |
| `muted` | `#586E65` | Secondary metadata and hints |
| `line` | `#D5DFD9` | Hairline dividers and card outlines |
| `borderStrong` | `#B9C7BF` | Interactive focus/selected borders |
| `scrim` | `#99071A14` | Modal overlay scrim |

### Dark Semantic Surfaces (Obsidian Emerald Neo Dark)

| Semantic Role | Hex | Usage |
|---|---|---|
| `darkCanvas` | `#071A14` | App dark canvas background |
| `darkSurface` | `#0E281F` | Primary dark cards and navigation bars |
| `darkSurfaceElevated` | `#14352A` | Dialogs, sheets, elevated panels |
| `darkSurfaceAlt` | `#194033` | Soft secondary containers and chips |
| `darkInk` | `#F1F7F4` | Primary typography on dark |
| `darkMuted` | `#9CB3A8` | Secondary labels on dark |
| `darkLine` | `#214438` | Subtle hairline borders on dark |
| `darkBorderStrong` | `#325E4E` | Focused dark boundaries |
| `darkPrimary` | `#A7FF00` | Volt Lime primary action color in Dark mode |
| `darkOnPrimary` | `#071A14` | Foreground ink on `darkPrimary` |
| `darkViolet` | `#A78BFA` | Signal Violet AI foreground on dark |
| `darkVioletSoft` | `#251A45` | Signal Violet AI container wash on dark |
| `darkDanger` / `darkSuccess` / `darkWarning` / `darkInfo` | `#F06E6E` / `#5EE094` / `#F3BA52` / `#69B6EC` | Accessible semantic states on dark |

All UI modules resolve colors exclusively via `DarbColors.*Of(context)` / `Theme.of(context)` in Flutter, and semantic CSS custom properties (`--canvas`, `--surface`, `--accent`, `--lime`, `--violet`, `--ink`) with `[data-theme="dark"]` on Web.

---

## 4. Typography, Spacing & Shape

### Web & Admin Font Pairing
- **Arabic Display & Body**: `Cairo` (weights 600–800 for headlines, 400–500 for body)
- **Latin Display & Body**: `Plus Jakarta Sans` (weights 600–800 display, 400–600 body) paired with `IBM Plex Mono` + `tabular-nums` for fares, order IDs, coordinates, and KPI ledgers.

### Spacing & Radius Scales (`darb_design_system.dart`)
- `DarbSpace`: `xxs: 4`, `xs: 8`, `sm: 12`, `md: 16`, `lg: 20`, `xl: 24`, `xxl: 32`, `section: 40`.
- `DarbRadius`: `sm: 12`, `md: 16`, `lg: 22`, `xl: 28`, `hero: 36`, `pill: 999`.
- `DarbElevation`: `none`, `card(isDark)`, `floating(isDark)`, `glow(color, {isDark})`.

---

## 5. Motion, Haptics & Core Components

`DarbMotion`: `press: 120ms`, `fast: 160ms`, `interactive: 220ms`, `tab: 240ms`, `standard: 260ms`, `route: 340ms`, `expressive: 420ms`, `staggerStep: 55ms`.  
Curves: `enter = easeOutCubic`, `exit = easeInCubic`, `emphasis = easeOutBack`.

Key reusable components in `mobile-overrides/lib/core/widgets/`:
- `DarbActionButton`, `DarbInteractiveCard`, `DarbBentoActionCard`, `DarbRouteConnector`
- `DarbActivityLedgerStrip`: 3-cell tabular live backend summary card for Customer/Driver/Vendor/Admin accounts
- `DarbShimmer`, `DarbTypingDots`, `DarbPulseDot`, `DarbOrderTimeline`
- `DarbTabViewStack` (`ValueKey<int>` + `paintOrder` + offscreen `TickerMode` pause), `DarbPageRoute`, `DarbGlassBottomNav`
- `DarbCitySceneCard` & `DarbLoginVectorMap` (abstract vector city geometry, zero bitmap city photos)

Every animated widget checks `DarbMotion.reduceMotion(context)` (and `@media (prefers-reduced-motion: reduce)` on Web) and disables continuous loops / transitions cleanly.

---

## 6. Verification Gates

- **Mobile**: `.github/workflows/validate-mobile-overrides.yml` & `.github/workflows/build-android-release.yml` (`flutter analyze lib` and `flutter test` run in GitHub Actions CI).
- **Public Web**: `python3 scripts/validate_public_site.py` + `.github/workflows/validate-public-web.yml`.
- **Admin Portal**: `.github/workflows/validate-admin-portal.yml` (`node --check` on single inline `<script>` + API contract assertions).
