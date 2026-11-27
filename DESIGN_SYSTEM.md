# DAZREVO Design System — Mineral Atelier

- **Version:** 3.1
- **Scope:** Flutter mobile app (`mobile-overrides/`), public web portal (`index.html`), and admin operations console (`admin-web/index.html`).
- **Flutter source of truth:** `mobile-overrides/lib/core/theme/darb_design_system.dart`.
- **Brand change:** Mineral Teal + Champagne Brass over Smoked Obsidian and Warm Porcelain.

This system defines DAZREVO's visual language while preserving existing API contracts, authentication, secure-storage keys, role-based workflows, and navigation behavior.

---

## 1. Visual Direction

DAZREVO uses a restrained spatial interface: architectural surfaces, layered depth, precise typography, expressive but short motion, and clear action hierarchy. Glass treatments are selective rather than universal; text contrast and performance take priority.

- **Dark anchor:** Smoked Obsidian `#171C20`.
- **Primary interaction:** Mineral Teal `#1D7A6E` in light mode and bright Mineral Teal `#36B6A0` in dark mode.
- **Secondary accent:** Champagne Brass `#C6A875`.
- **Light canvas:** Warm Porcelain `#FAF9F6`.
- **Motion:** honor `MediaQuery.disableAnimations`, accessible navigation, and the user's Reduce Motion setting.
- **Responsive behavior:** support compact phones, tablets, and wide layouts without horizontal overflow.
- **Content integrity:** network-driven screens must retain loading, empty, recoverable-error, and success states.

## 2. Color System

### Brand anchors

| Token | Hex | Usage |
|---|---|---|
| `forest` | `#171C20` | Smoked Obsidian brand anchor |
| `primaryGreen` | `#1D7A6E` | Light-mode primary action |
| `forestSoft` | `#222A2E` | Elevated dark structural surface |
| `mint` | `#E8D9B8` | Soft Champagne highlight |
| `lime` | `#C6A875` | Champagne Brass accent |
| `limeInk` | `#725629` | Accessible brass text on light surfaces |
| `limeTint` | `#F5F0E6` | Champagne wash |
| `violet` | `#1D7A6E` | Compatibility alias for Mineral Teal |
| `violetSoft` | `#E8F4F1` | Mineral Teal wash |

### Light semantic tokens

| Token | Hex |
|---|---|
| `canvas` | `#FAF9F6` |
| `surface` | `#FFFFFF` |
| `surfaceAlt` | `#F2EFE9` |
| `ink` | `#141413` |
| `muted` | `#636059` |
| `line` | `#E5E0D6` |
| `borderStrong` | `#CEC7BA` |

### Dark semantic tokens

| Token | Hex |
|---|---|
| `darkCanvas` | `#0C0D0F` |
| `darkSurface` | `#14161A` |
| `darkSurfaceElevated` | `#1B1E24` |
| `darkSurfaceAlt` | `#232730` |
| `darkInk` | `#F5F3EE` |
| `darkMuted` | `#A39E93` |
| `darkLine` | `#262A33` |
| `darkBorderStrong` | `#3A404D` |
| `darkPrimary` | `#36B6A0` |
| `darkOnPrimary` | `#071B18` |
| `darkAccent` | `#C6A875` |
| `darkViolet` | `#36B6A0` |

### Status colors

| State | Light | Dark |
|---|---|---|
| Danger | `#C83E3B` | `#F0716E` |
| Success | `#1C7C54` | `#4CD49A` |
| Warning | `#B87014` | `#F0B857` |
| Info | `#2364AA` | `#69AEF2` |

## 3. Typography and localization

- Arabic (`ar`) is the primary RTL locale.
- English (`en`) and Turkish (`tr`) use LTR layout.
- Phone numbers, OTP digits, coordinates, order references, and Latin brand marks remain directionally LTR.
- Amounts, distances, and order identifiers should use tabular figures where supported.

## 4. Layout, components, and motion

- Use the shared `DarbSpace`, `DarbRadius`, and `DarbMotion` scales.
- Use Spatial and Glass components to establish hierarchy, not as decoration on every surface.
- Keep touch targets accessible and preserve responsive behavior at narrow phone widths.
- Respect reduced-motion preferences in every animated component.
- Keep existing resource names, Android package ID, navigation routes, and backend payload contracts stable.

## 5. Quality gates

The release source must pass Flutter analysis, all widget tests, Android APK build, and signed release packaging before it is merged or published. A successful compile alone is not a release approval.
