# DARB Design System

Version: 2026.2 (Obsidian Emerald Precision & Kinetic Topography)  
Scope: Flutter mobile app (customer, driver, vendor, administration)  
Source of truth: `mobile-overrides/lib/core/theme/darb_design_system.dart`

This document defines the shared visual, motion, and structural system for DARB. It guides UI and motion architecture without altering authentication, package identity, signing, or backend API contracts.

## Product principles

- Arabic-first experience with native RTL layout; English and Turkish remain fully supported (`LTR`).
- Clear primary action on every screen (`DarbActionButton` or themed `FilledButton`). Avoid competing calls to action.
- Real API data only. Never populate screens with fabricated stores, orders, fees, ratings, or driver availability.
- Represent loading, empty, recoverable error, and live state explicitly on network-driven screens.
- Preserve entered form state across recoverable errors and provide haptic + shake validation feedback (`DarbShakeBox` + `DarbHaptics`).
- Maintain accessible contrast, clear touch targets (`>= 48dp`), and responsive layouts across small Android viewports.
- Separate UI widgets from API/session logic cleanly.
- Preserve Google Sign-In, MsgPlus SMS OTP, Firebase/FCM notifications, `com.darb.darb` package identity, release signing, and dual-track APK / Play Store builds.

## Approved visual direction: Obsidian Emerald Precision & Kinetic Topography

DARB feels like a live city logistics command network: deep Obsidian Emerald hero anchors (`#12302A`), asymmetric 6:5 Bento action splits, vertical pickup-to-dropoff route connectors (`DarbRouteConnector`), animated GPU shimmer wireframes (`DarbShimmer`), spatial map HUDs, and responsive motion.

- **Visual hierarchy:** asymmetric Bento grids (`DarbBentoActionCard`), editorial storefront headers, and numbered step pills replace uniform stacked-box layouts; supporting details sit on layered semantic surfaces (`DarbColors.canvasOf`, `surfaceOf`, `surfaceAltOf`).
- **Auth & Global Shell:** expanded `326px` `DarbLoginVectorMap` hero with localized capability pills (`featureStores`, `featureDelivery`, `featureNearby`), `1 / 2 -> 2 / 2` auth step pill, `_ShellActionWell` 38x38 app bar wells, and frosted floating `DarbGlassBottomNav`.
- **Customer experience:** greeting hero, deterministic `DarbCitySceneCard`, asymmetric 6:5 Bento split (`DarbBentoActionCard` Peer Delivery + AI Order Assistant), live active-order banner with `DarbOrderTimeline`, storefront header with `DarbPulseDot` + active-in-cart mint tint, step-numbered checkout, `DarbRouteConnector` peer review/order cards, interactive map HUD legend + camera re-center in `DriverTrackingScreen`, and `DarbTypingDots` + quick-fill chips in AI Order Assistant.
- **Driver experience:** live Neo cockpit (`DarbPulseDot` + lime border glow when online), daily summary, `DarbRouteConnector` pickup/dropoff cards, highlighted earnings strip, and status actions with double-tap protection.
- **Vendor experience:** storefront emblem command header with `DarbPulseDot`, double-tap-locked order progression (`Accept` / `Preparing` / `Ready`), compact `DarbOrderTimeline`, and product inventory rows with category/stock pills and tonal icon wells.
- **Administration:** multi-accent operational KPIs, storefront/vehicle approval cards with tonal icon wells, order feed with `DarbOrderTimeline` + fee/total strips, zone/city/user/audit rows with icon wells, and protected single-flight mutations.
- **Account & AI Role Assistant:** Obsidian Emerald hero profile card, `AccountActionTile` colored icon wells, segmented Glass/Standard & Light/Dark appearance switchers, starter prompt chips, asymmetrical chat bubbles, and live `DarbTypingDots`.
- **Map & tracking use:** animated map camera updates and real-coordinate route polylines (`DriverTrackingScreen`) and active map pickers (`DarbMapPicker`).

## Color system

### Shared brand anchors

| Token | Hex | Usage |
|---|---|---|
| `forest` | `#12302A` | Deep emerald brand anchor and hero dark canvas |
| `primaryGreen` | `#167A5A` | Primary brand interactive green in Light mode |
| `forestSoft` | `#1C4B3F` | Secondary deep emerald containers |
| `mint` | `#B9E4D2` | Supportive highlight, selected states, brand route |
| `lime` | `#C8F169` | High-emphasis live neo beacon (`DarbPulseDot`, badges) |
| `danger` | `#D64545` | Destructive actions and error states |
| `success` | `#2E7D32` | Confirmed and delivered states |
| `warning` | `#C47B19` | Pending and attention states |
| `info` | `#2B6EA3` | Informational alerts and status |

### Light semantic surfaces

| Token | Hex | Usage |
|---|---|---|
| `canvas` | `#F6F6F3` | Main light screen background |
| `surface` | `#FFFFFF` | Primary cards, sheets, and inputs |
| `surfaceAlt` | `#ECEEE9` | Soft secondary containers and icon wells |
| `ink` | `#1A2E29` | Primary text |
| `muted` | `#687A75` | Secondary labels and hints |
| `line` | `#D0D7D4` | Hairline borders and dividers |
| `borderStrong` | `#B8C3BF` | Stronger interactive borders |
| `scrim` | `#990D1C18` | Modal backdrops |

### Dark semantic surfaces

Dark mode uses a dedicated Deep Emerald Neo palette (not mechanically inverted):

| Semantic role | Hex | Usage |
|---|---|---|
| `darkCanvas` | `#0B1512` | App dark canvas background |
| `darkSurface` | `#12201B` | Cards and navigation containers |
| `darkSurfaceElevated` | `#182A24` | Dialogs, sheets, and elevated surfaces |
| `darkSurfaceAlt` | `#1D322B` | Soft containers and inactive pills |
| `darkInk` | `#EEF5F1` | Primary text on dark |
| `darkMuted` | `#9CB0A7` | Secondary text on dark |
| `darkLine` | `#263B33` | Subtle dark borders |
| `darkBorderStrong` | `#3A544A` | Stronger boundaries on dark |
| `darkPrimary` | `#6FE0B7` | Primary interactive emerald-mint on dark |
| `darkOnPrimary` | `#0B1F1A` | Foreground text/icons on `darkPrimary` |
| `darkAccent` | `#C8F169` | High-priority neo live indicator (`lime`) |
| `darkDanger` | `#EB6B6B` | Destructive/error foreground on dark |
| `darkSuccess` | `#54C977` | Confirmed/delivered foreground on dark |
| `darkWarning` | `#E8B04A` | Attention/warning foreground on dark |
| `darkInfo` | `#64ADE8` | Informational foreground on dark |
| `darkScrim` | `#B8000000` | Modal backdrop on dark |

All screen colors resolve through `DarbColors.*Of(context)` and `Theme.of(context)`. Hard-coded screen colors are forbidden outside brand emblems (`DarbBrandMark`) and dedicated city/login hero vector artwork.

## Spacing & Shape

`DarbSpace`: `xxs: 4`, `xs: 8`, `sm: 12`, `md: 16`, `lg: 20`, `xl: 24`, `xxl: 32`, `section: 40`.  
`DarbRadius`: `sm: 12`, `md: 16`, `lg: 22`, `xl: 28`, `hero: 36`, `pill: 999`.  
`DarbElevation`: `none`, `card(isDark)`, `floating(isDark)`, `glow(color, {isDark})`.

## Motion & Haptics (`DarbMotion` + `DarbHaptics`)

| Token | Value | Curve / Purpose |
|---|---|---|
| `press` | `120 ms` | Tactile scale-down (`DarbPressScale`, `DarbInteractiveCard`) |
| `fast` | `160 ms` | Micro-state & border highlight (`AnimatedContainer`) |
| `interactive` | `220 ms` | Release spring-back & button state swap |
| `tab` | `240 ms` | Bottom navigation tab crossfade + directional slide (`DarbTabViewStack`) |
| `standard` | `260 ms` | Content reveal (`DarbFadeSlide`) and timeline progress |
| `route` | `340 ms` | Push navigation (`DarbPageRoute` / `DarbPageTransitionsBuilder`) |
| `expressive` | `420 ms` | City hero transitions & badge celebrations |
| `staggerStep` | `55 ms` | Bounded stagger delay (`DarbMotion.staggerDelay`) |
| `enter` / `exit` / `emphasis` | `easeOutCubic` / `easeInCubic` / `easeOutBack` | Standard motion curves |

Core components in `darb_motion_components.dart`, `darb_components.dart`, and `darb_city_scene.dart`:
- `DarbActionButton`: animated state machine (`idle -> loading -> success -> error`), press scale, shake on validation/API failure, haptics.
- `DarbInteractiveCard`: press shrink, highlighted border feedback, selection haptic.
- `DarbBentoActionCard`: asymmetric Bento surface supporting Obsidian Emerald dark hero or Frosted Glass highlight modes with optional pill badge.
- `DarbRouteConnector`: spatial pickup-to-dropoff logistics track with emerald origin pin, vertical gradient connector, and optional distance/fee pills.
- `DarbShimmer`: GPU `ShaderMask` sweep animation (`1400ms`) powering multi-block skeleton loading wireframes (`DarbStateView.loading`).
- `DarbTypingDots`: 3-dot staggered sine-wave AI thinking indicator.
- `DarbPulseDot`: live ambient halo pulse on online/active indicators; stops cleanly when inactive or `reduceMotion` is enabled.
- `DarbTabViewStack`: keyed `ValueKey<int>(i)` stack preserving child state, scroll positions, offscreen `TickerMode` pause, and `paintOrder` layering.
- `DarbPageRoute`: unified fade + slide + micro-scale push transition across all feature navigation.
- `DarbOrderTimeline`: step-by-step live order progression (store & peer tracks + cancelled banner).
- `DarbCitySceneCard`: deterministic city photo hero + Ken Burns loop with Neo vector skyline fallback.
- `DarbSearchBar`: consistent themed search input with instant clear action.

Every animated widget checks `DarbMotion.reduceMotion(context)` and collapses durations to `Duration.zero` / stops continuous loops automatically.

## RTL, Localization & Security

- Locale switcher (`ar` / `en` / `tr`) wired to `app_localizations.dart` (`dt(...)` and `t(...)`).
- Phone numbers, OTP inputs, coordinates, and technical identifiers stay wrapped in `Directionality(textDirection: TextDirection.ltr)`.
- Release verification gates: run `flutter analyze lib` and `flutter test` via CI (`.github/workflows/build-android-release.yml`) before merging or publishing.
