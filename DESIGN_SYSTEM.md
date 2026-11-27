# DAZREVO Design System — Nocturne Atelier

- **Version:** 3.0
- **Scope:** Flutter mobile app (`mobile-overrides/`), Public Web Portal (`index.html`), Admin Operations Console (`admin-web/index.html`)
- **Source of truth:** `mobile-overrides/design_system.dart`

This document defines the unified **Nocturne Atelier** design language and component architecture for **DAZREVO** across mobile and web surfaces while preserving all backend API contracts, release signing, and role-based workflows.

---

## 1. Visual Direction: Nocturne Atelier (2026)

DAZREVO embodies architectural luxury logistics: high-contrast Deep Obsidian (`#090B0E`) paired with Burnished Champagne Gold (`#DFBE7D` / `#C6A15B`) in Dark mode, and crisp Warm Alabaster (`#F7F6F2`) anchored by Midnight Charcoal (`#11151B`) and Matte Gold in Light mode.

- **60–30–10 Balance:** 60% neutral canvas (`#090B0E` dark / `#F7F6F2` light), 30% elevated structural cards (`#11151B` / `#FFFFFF`), 10% restrained Champagne Gold accent (`#DFBE7D` / `#C6A15B`).
- **Architectural Geometry:** Sharp 8–10px status tags (zero candy pills), crisp 1px borders (`#222934` / `#E4DFD4`), and floating capsule navigation (`DazrevoFloatingDock`).
- **Tabular Precision:** All currency amounts, distances, order numbers, and zone fees render with tabular figures (`tabular-nums`).
- **Content Integrity:** Real API data only; complete Loading (shimmer skeletons), Empty, and Recoverable Error states on every network view.

---

## 2. Color System

### Core Brand Anchors

| Token | Hex | Usage |
|---|---|---|
| `obsidian` | `#090B0E` | Primary dark canvas & dark-mode surfaces |
| `charcoal` (`forest`) | `#11151B` | Primary dark anchor & light-mode primary CTA |
| `charcoalSoft` (`forestSoft`) | `#181E27` | Elevated dark surfaces & input fills |
| `champagne` (`lime`) | `#DFBE7D` | Primary emphasis on dark surfaces & dark-mode CTA |
| `gold` | `#C6A15B` | Light-mode metallic accent & active states |
| `goldMuted` (`mint`) | `#EAD9B4` | Soft champagne tint for supportive containers |
| `ivory` (`onForest`) | `#F5F2EB` | High-contrast text/icons on dark obsidian surfaces |

### Light Mode Semantic Tokens

| Token | Hex | Usage |
|---|---|---|
| `canvas` | `#F7F6F2` | Warm Alabaster main backdrop |
| `surface` | `#FFFFFF` | Cards, dialogs, sheets |
| `surfaceAlt` | `#EFECE4` | Icon wells, segmented track, secondary panels |
| `ink` | `#11151B` | Primary headings and body text |
| `muted` | `#646B76` | Secondary copy and metadata |
| `line` | `#E4DFD4` | Hairline borders and dividers |
| `borderStrong` | `#CCC4B4` | Active borders and outlined controls |

### Dark Mode Semantic Tokens

| Token | Hex | Usage |
|---|---|---|
| `canvas` | `#090B0E` | Deep Obsidian backdrop |
| `surface` | `#11151B` | Cards, dialogs, navigation dock |
| `surfaceAlt` | `#181E27` | Icon wells, input fills, segmented tracks |
| `ink` | `#F5F2EB` | Warm Ivory primary text |
| `muted` | `#969DA8` | Subordinate labels and hints |
| `line` | `#222934` | Hairline dark borders and dividers |
| `borderStrong` | `#343F4F` | Focused & strong borders |

### Semantic Status Colors (Light / Dark)

- **Success:** `#1E8E64` / `#4CD49E`
- **Warning:** `#B87A1E` / `#E6B86A`
- **Danger:** `#B93D45` / `#EB7A82`
- **Info:** `#2B6CB0` / `#7DB4EE`

---

## 3. Typography & Localization

- **Supported Locales:** Arabic (`ar`, RTL primary), English (`en`, LTR), Turkish (`tr`, LTR).
- **Web Fonts:** `Cairo` (Arabic) + `Plus Jakarta Sans` (Latin) + `JetBrains Mono` (code/IDs) via Google Fonts with system fallbacks.
- **Mobile Font:** `Arial` fallback with directional `TextDirection` enforcement (LTR strictly for `+963` phone fields, OTP digits, coordinates, and `DAZREVO` wordmarks).

---

## 4. Reusable Mobile Component Library (`mobile-overrides/design_system.dart`)

- `DazrevoLogoMark` & `DazrevoWordmark`: Custom geometric kinetic "D" emblem synchronized with `mobile-overrides/ic_launcher.xml` and web SVG marks.
- `DazrevoFloatingDock`: Floating capsule bottom bar on mobile (`< 840px`) paired with `NavigationRail` on tablet/wide viewports.
- `DazrevoHeroSurface`: Obsidian architectural hero container with champagne edge accent.
- `DazrevoSectionHeader`, `DazrevoIconWell`, `DazrevoStatusTag`: Standardized structural hierarchy primitives.
- `DazrevoRouteTimeline`: Vertical pickup-to-dropoff route visualization.
- `DazrevoChoiceSegment<T>`: Segmented control used for Auth (`Sign In` / `Create Account`), Order Filters (`All` / `Active` / `Completed`), and Appearance (`System` / `Light` / `Dark`).
- `DazrevoShimmerTile`, `DazrevoEmptyState`, `DazrevoErrorState`: Shared async state primitives.
- Motion Primitives: `DarbMotion`, `DarbFadeSlide`, `DarbPressScale`, `DarbPageTransitionsBuilder` (all honor `MediaQuery.disableAnimations`).
