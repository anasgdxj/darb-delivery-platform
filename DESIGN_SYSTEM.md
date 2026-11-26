# DAZREVO Design System

Version: 2026.4 (Obsidian & Champagne Brass + Mineral Teal)  
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

## 2. Visual Direction: Obsidian & Champagne Brass + Mineral Teal

DAZREVO feels like a flagship luxury urban mobility & commerce platform: Smoked Obsidian architectural stages (`#14171D`), Burnished Bronze light primary (`#8A651F`) paired with Luminous Champagne Gold CTAs and active beacons (`#D6B46C`), Alabaster Stone daylight cards (`#FAF9F6` / `#FFFFFF`), layered Smoked Obsidian dark surfaces (`#0C0D0F` -> `#14161A` -> `#1B1E24`), and Mineral Teal smart telemetry accents (`#1D7A6E` / `#3FD1BE`).

- **Brand Crest & App Icon (`DarbBrandMark`, `ic_launcher.xml`, `android-res/`)**: Chamfered ivory "D" crest intersected by a double-bevel Champagne Brass route chevron (`#D6B46C` / `#E7D3A3`) and a Mineral Teal telemetry nexus core (`#3FD1BE`), set over a Smoked Obsidian surface.
- **Splash & Interactive Onboarding (`main.dart`, `onboarding_screen.dart`)**: Smoked Obsidian splash gate + 3-slide interactive `OnboardingScreen` persisted via `kDazrevoOnboardingSeenKey` (`onboarding_seen_v1`) and replayable from `LoginScreen` and `AccountScreen`.
- **Authentication & Global Shell (`login_screen.dart`, `app_shell.dart`)**: Geometric vector network map (`DarbLoginVectorMap`, zero city photos), `DarbBrandMark`, `1 / 2 -> 2 / 2` auth step pill, LTR Syrian phone formatting + OTP countdown, custom Google emblem CTA, and Mineral Teal AI command button in the shell app bar.
- **Customer Experience (`customer_home_screen.dart`, `vendor_catalog_screen.dart`, `checkout_screen.dart`, `ai_order_assistant_screen.dart`)**: Abstract `DarbCitySceneCard` (zero city photos), 6:5 asymmetric Bento action split (`DarbBentoActionCard`), Mineral Teal AI order assistant, Smoked Obsidian + Champagne Brass floating cart dock, live `DarbOrderTimeline`, and spatial courier GPS tracking (`DriverTrackingScreen`).
- **Account & Live Activity Ledger (`account_screen.dart`)**: Smoked Obsidian header card, live role-aware `DarbActivityLedgerStrip` (fetching `/orders/mine`, `/drivers/stats`, `/vendors/mine/stats`, or `/admin/stats`), dedicated `EditProfileScreen`, 5-step Driver & Vendor onboarding wizards (`DriverApplicationScreen`, `VendorApplicationScreen`), Mineral Teal `AiRoleAssistantScreen`, and Glass/Standard + System/Light/Dark appearance controls.
- **Driver, Vendor & Administration**: Unified token resolution across driver cockpit (`DarbPulseDot` + Champagne Brass border when online), merchant order progression + product inventory, and multi-tab admin operations portal (`admin-web/index.html`) including an Admin AI Copilot (`POST /ai/assistant/ask`).

---

## 3. Unified Color System

### Brand & Accent Anchors

| Token | Hex | Usage |
|---|---|---|
| `forest` | `#14171D` | Smoked Obsidian brand anchor, dark hero containers & floating cart dock |
| `primaryGreen` | `#8A651F` | Burnished Champagne Bronze interactive primary in Light mode (`>=5.3:1` AA with white) |
| `forestSoft` | `#1E222B` | Elevated Obsidian Slate containers and dark accent washes |
| `mint` | `#E7D3A3` | Warm Champagne Mist highlights, selected states, map route accents |
| `lime` | `#D6B46C` | Luminous Champagne Gold CTA, active beacons (`DarbPulseDot`), dark primary |
| `limeInk` | `#6B4F1A` | High-contrast Bronze ink on light alabaster surfaces |
| `limeTint` | `#F6EFE0` | Soft Champagne wash background in Light mode |
| `violet` | `#1D7A6E` | Imperial Mineral Teal smart/AI assistant accent (Light mode) |
| `violetSoft` | `#E8F5F3` | Mineral Teal tinted containers (Light mode) |
| `danger` | `#C83E3B` | Destructive actions and error states |
| `success` | `#1C7C54` | Confirmed and delivered states |
| `warning` | `#B87014` | Pending and review alerts |
| `info` | `#2364AA` | Informational notices |

### Light Semantic Surfaces (Alabaster Stone Canvas)

| Token | Hex | Usage |
|---|---|---|
| `canvas` | `#FAF9F6` | Main light background canvas |
| `surface` | `#FFFFFF` | Cards, inputs, bottom sheets |
| `surfaceAlt` | `#F2EFE9` | Secondary containers, pills, icon wells |
| `ink` | `#141413` | Primary high-contrast typography |
| `muted` | `#636059` | Secondary metadata and hints |
| `line` | `#E5E0D6` | Hairline dividers and card outlines |
| `borderStrong` | `#CEC7BA` | Interactive focus/selected borders |
| `scrim` | `#990C0D0F` | Modal overlay scrim |

### Dark Semantic Surfaces (Smoked Obsidian Dark)

| Semantic Role | Hex | Usage |
|---|---|---|
| `darkCanvas` | `#0C0D0F` | App dark canvas background |
| `darkSurface` | `#14161A` | Primary dark cards and navigation bars |
| `darkSurfaceElevated` | `#1B1E24` | Dialogs, sheets, elevated panels |
| `darkSurfaceAlt` | `#232730` | Soft secondary containers and chips |
| `darkInk` | `#F5F3EE` | Primary typography on dark |
| `darkMuted` | `#A39E93` | Secondary labels on dark |
| `darkLine` | `#262A33` | Subtle hairline borders on dark |
| `darkBorderStrong` | `#3A404D` | Focused dark boundaries |
| `darkPrimary` | `#D6B46C` | Luminous Champagne Gold primary action color in Dark mode |
| `darkOnPrimary` | `#0C0D0F` | Foreground ink on `darkPrimary` |
| `darkViolet` | `#3FD1BE` | Mineral Teal smart/AI foreground on dark |
| `darkVioletSoft` | `#112926` | Mineral Teal container wash on dark |
| `darkDanger` / `darkSuccess` / `darkWarning` / `darkInfo` | `#F0716E` / `#4CD49A` / `#F0B857` / `#69AEF2` | Accessible semantic states on dark |

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
