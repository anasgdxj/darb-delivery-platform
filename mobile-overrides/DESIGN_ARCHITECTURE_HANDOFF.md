# DAZREVO Mobile UI/UX Redesign & Architecture Handoff

**Product:** DAZREVO (دازريفو)  
**Target Codebase:** `mobile-overrides/` (mirrored cleanly to `darb-workspace/darb-project/mobile/`)  
**Design Language:** Spatial Command-Deck & Editorial 2026 (Obsidian Emerald, Volt Lime & Signal Violet)  
**Compatibility:** `com.darb.darb` package identity, AR (`RTL`) / EN (`LTR`) / TR (`LTR`), Light & Dark themes, Glass & Standard visual modes, Phone & Tablet (`>=720dp`) adaptive breakpoints.

---

## 1. Architectural Overview & Directory Structure

The presentation layer has been refactored away from repetitive stacked Material cards toward modular spatial primitives (`DarbCommandStage`, `DarbSegmentedDock`, `DarbCityOrbStrip`, `DarbTelemetryDeck`, `DarbTicketPass`, `DarbEditorialStoreCard`, `DarbTelemetryProductCard`), while leaving networking, authentication, push notifications, GPS telemetry, offline caches, and backend REST contracts completely intact.

```text
mobile-overrides/
├── DESIGN_ARCHITECTURE_HANDOFF.md         # This technical handoff specification
├── lib/
│   ├── core/
│   │   ├── l10n/
│   │   │   └── app_localizations.dart         # Full AR/EN/TR _sourceValues dictionary (665 keys + dynamic rules)
│   │   ├── theme/
│   │   │   └── darb_design_system.dart        # DarbColors, DarbSpace, DarbRadius, DarbMotion, DarbTheme, DarbAppearanceController
│   │   └── widgets/
│   │       ├── darb_components.dart           # DarbFeedbackBanner, DarbOrderTimeline, DarbBentoActionCard, DarbRouteConnector, DarbActivityLedgerStrip, DarbResponsiveTwoColumn
│   │       ├── darb_copy_order_number_button.dart # Accessible copy-to-clipboard order reference action
│   │       ├── darb_glass.dart                # DarbGlassSurface, DarbGlassBottomNav, DarbGlassSideRail (with pulse beacon & DAZREVO anchor)
│   │       └── darb_spatial_primitives.dart   # NEW: 7 core spatial UI primitives + CustomPainters
│   └── features/
│       ├── auth/
│       │   ├── onboarding_screen.dart         # Full-bleed spatial canvas over CityShowcaseBanner + numbered 01/02/03 step pillars
│       │   └── login_screen.dart              # Continuous DarbLoginVectorMap + floating glass pill bar + tablet split-pane (6:5) + DarbOtpPinPreview
│       ├── shell/
│       │   └── app_shell.dart                 # Role-routed shell (CUSTOMER/DRIVER/VENDOR/ADMIN), DarbFeedbackBanner offline bar, glass nav/rail
│       ├── customer/
│       │   ├── customer_home_screen.dart      # DarbCommandStage + DarbCityOrbStrip + 6:5 Bento split + DarbTicketPass + DarbSegmentedDock + DarbEditorialStoreCard
│       │   ├── customer_orders_screen.dart    # DarbSegmentedDock with live counts + DarbTicketPass order cards + DarbCopyOrderNumberButton
│       │   └── vendor_catalog_screen.dart     # DarbCommandStage + DarbSegmentedDock + DarbTelemetryProductCard + Obsidian-Lime floating cart bar
│       ├── driver/
│       │   ├── driver_dashboard_screen.dart   # DarbCommandStage dispatch console + DarbTelemetryDeck + DarbTicketPass available jobs
│       │   └── driver_orders_screen.dart      # DarbSegmentedDock + DarbTicketPass active/completed courier tickets
│       ├── vendor/
│       │   ├── vendor_orders_screen.dart      # DarbCommandStage store console + DarbTelemetryDeck + DarbSegmentedDock + DarbTicketPass
│       │   └── vendor_products_screen.dart    # DarbCommandStage + DarbSegmentedDock + DarbTelemetryProductCard inventory with stock meters
│       ├── admin/
│       │   ├── admin_dashboard_screen.dart    # DarbCommandStage KPI header + DarbTelemetryDeck + DarbSegmentedDock + DarbTicketPass approval cards
│       │   └── admin_operations_screens.dart  # AdminOrdersScreen & AdminOperationsScreen using DarbSegmentedDock + DarbTicketPass + DarbFeedbackBanner
│       └── account/
│           ├── account_screen.dart            # DarbCommandStage user hero + DarbActivityLedgerStrip + 3 grouped DarbGroupedSection blocks
│           └── settings_screen.dart           # Appearance, accessibility (textScale, reduceMotion, haptics), notifications, privacy & cache controls
└── test/
    └── widget_test.dart                       # All existing 46+ stability/role/theme tests + new Spatial Primitives test suite
```

---

## 2. Reusable Spatial Primitives (`lib/core/widgets/darb_spatial_primitives.dart`)

Developers extending or adding screens should compose from these components instead of creating raw `Card` / `Container` wrappers:

| Component | Purpose | Key Props & Behavior |
|---|---|---|
| `DarbCommandStage` | Signature dark Obsidian Emerald architectural stage header with `_OrbitalStagePainter` rings | `title`, `eyebrow`, `subtitle`, `leading`, `trailing`, `bottom`, `accentColor`, `livePulse`, `padding` |
| `DarbSegmentedDock<T>` | Horizontally scrollable tactile pill filter bar replacing default `ChoiceChip` rows | `options: List<DarbDockOption<T>>` (`value`, `label`, `count`, `icon`), `selectedValue`, `onSelected`, `accentColor`, `compact` |
| `DarbCityOrbStrip` | Horizontal city selector capsules embedded in `DarbCommandStage` or light canvases | `cities: List<DarbCityOrbOption>`, `selectedCityId`, `onSelect`, `onDarkStage` |
| `DarbTelemetryDeck` | High-density 4-cell (2x2 narrow, 1x4 wide `>=680px`) instrument cluster with `FontFeature.tabularFigures()` | `cells: List<DarbTelemetryCell>` (`label`, `value`, `icon`, `accentColor`, `subtitle`), `title`, `trailing` |
| `DarbTicketPass` | Perforated dispatch ticket (`_TicketPerforationPainter` dashed seam + radial side notches) for orders & approvals | `title`, `status`, `body`, `subtitle`, `leadingIcon`, `accentColor`, `headerActions`, `footer`, `onTap` |
| `DarbEditorialStoreCard` | Asymmetric store card with forest/muted gradient header band, pulse status dot, rating & product count pills | `name`, `category`, `isOpen`, `productsLabel`, `address`, `ratingAvg`, `reviewsCount`, `onTap` |
| `DarbTelemetryProductCard` | Split catalog/inventory row with leading icon badge, category chip, tabular price, stock ratio `LinearProgressIndicator`, and custom `actionDock` | `name`, `priceLabel`, `actionDock`, `description`, `category`, `stockLabel`, `stockRatio`, `outOfStock`, `highlighted`, `leadingIcon`, `onTap` |

### Navigation Chrome Upgrades (`lib/core/widgets/darb_glass.dart`)
- **`DarbGlassBottomNav`**: Floating glass capsule bar with active pill highlight and unread numeric badges.
- **`DarbGlassSideRail`**: Tablet/desktop (`>=720dp`) left/right rail featuring a top `DarbPulseDot` live status header, vertical active rail indicator bar, and bottom `DAZREVO` brand anchor.

---

## 3. Design Tokens (`lib/core/theme/darb_design_system.dart`)

> **Rule:** UI code must resolve semantic colors exclusively via `DarbColors.*Of(context)` / `Theme.of(context)`. Never hardcode `Colors.black` or `Colors.white` for adaptive text or card surfaces outside dark `DarbCommandStage` / Obsidian anchors.

### Brand & Accent Anchors
| Token | Hex | Usage |
|---|---|---|
| `DarbColors.forest` | `#0B2F24` | Obsidian Emerald command stages, hero cards, floating cart bar |
| `DarbColors.primaryGreen` | `#0D6E4E` | Light-mode interactive primary |
| `DarbColors.forestSoft` | `#144435` | Secondary emerald fills & stage gradient stop |
| `DarbColors.mint` | `#A8EBC8` | Route highlights, subtle dark-stage accents |
| `DarbColors.lime` | `#A7FF00` | Volt Lime kinetic CTA, active beacons (`DarbPulseDot`), dark-mode primary |
| `DarbColors.limeInk` | `#3E6800` | Accessible lime text on light surfaces |
| `DarbColors.limeTint` | `#E7FFAD` | Soft lime badge tint in Light mode |
| `DarbColors.violet` | `#8A5CF6` | Signal Violet AI assistant accent (Light); `darkViolet` = `#A78BFA` |
| `DarbColors.violetSoft` | `#F1EBFF` | Signal Violet container wash (Light); `darkVioletSoft` = `#251A45` |

### Light vs. Dark Semantic Surface Tokens
| Semantic Getter | Light Hex | Dark Hex |
|---|---|---|
| `canvasOf(ctx)` | `#F8FAF7` | `#071A14` |
| `surfaceOf(ctx)` | `#FFFFFF` | `#0E281F` |
| `surfaceElevatedOf(ctx)` | `#FFFFFF` | `#14352A` |
| `surfaceAltOf(ctx)` | `#EDF2EC` | `#194033` |
| `inkOf(ctx)` | `#0E221B` | `#F1F7F4` |
| `mutedOf(ctx)` | `#586E65` | `#9CB3A8` |
| `borderOf(ctx)` | `#D5DFD9` | `#214438` |
| `borderStrongOf(ctx)` | `#B9C7BF` | `#325E4E` |
| `primaryOf(ctx)` | `#0D6E4E` | `#A7FF00` |
| `onPrimaryOf(ctx)` | `#FFFFFF` | `#071A14` |
| `dangerOf(ctx)` / `successOf(ctx)` / `warningOf(ctx)` / `infoOf(ctx)` | `#CF3B3B` / `#17804B` / `#C67A12` / `#1E6FA8` | `#F06E6E` / `#5EE094` / `#F3BA52` / `#69B6EC` |

---

## 4. Typography, Spacing, Radii & Motion

### Mobile Typography Scale (`DarbTheme._buildTheme`)
Uses the platform font stack (system Arabic/Latin sans) scaled dynamically by `DarbAppearanceController.textScale` (`0.90x`–`1.25x`), paired with `FontFeature.tabularFigures()` on prices, metrics, order numbers, and OTP previews:
- **`headlineMedium`**: `24sp`, `FontWeight.w900`, `letterSpacing: -0.4`
- **`titleLarge`**: `19sp`, `FontWeight.w900`, `letterSpacing: -0.2`
- **`titleMedium`**: `16sp`, `FontWeight.w800`
- **`bodyLarge`**: `15sp`, `FontWeight.w600`, `height: 1.45`
- **`bodyMedium`**: `13.5sp`, `FontWeight.w600`, `height: 1.42`
- **`bodySmall`**: `12sp`, `FontWeight.w600`, `color: muted`

*(Web & Admin surfaces use `Cairo` 600–800/400–500 for Arabic, `Plus Jakarta Sans` for Latin, and `IBM Plex Mono` for tabular numeric readouts.)*

### Spacing, Corner Radii & Motion Scales
- **`DarbSpace`**: `xxs: 4`, `xs: 8`, `sm: 12`, `md: 16`, `lg: 20`, `xl: 24`, `xxl: 32`, `section: 40`
- **`DarbRadius`**: `sm: 12`, `md: 16`, `lg: 22`, `xl: 28`, `hero: 36`, `pill: 999`
- **`DarbMotion`**: `press: 120ms`, `fast: 160ms`, `interactive: 220ms`, `tab: 240ms`, `standard: 260ms`, `route: 340ms`, `expressive: 420ms`, `staggerStep: 55ms` (`enter: easeOutCubic`, `exit: easeInCubic`, `emphasis: easeOutBack`). All animations respect `DarbMotion.reduceMotion(context)`.

---

## 5. Preserved Functional & Engineering Contracts

1. **Zero City Photographs**: Onboarding, Login hero (`DarbLoginVectorMap`), and City banners (`DarbCitySceneCard`) use pure procedural vector painters (`CustomPaint`). Zero `Image.*` calls or `assets/cities/` assets exist in `lib/`.
2. **Backend Endpoints & Auth**:
   - Auth recovery (`Api.restore`), token refresh, MsgPlus OTP, Google Sign-In, `/auth/me`, `/notifications`, `/cities`, `/vendors`, `/drivers/me`, `/drivers/stats`, `/orders/driver/available`, `/vendors/mine`, `/vendors/mine/stats`, `/orders/vendor`, `/admin/stats`, `/admin/vendors/pending`, `/admin/drivers/pending`, `/admin/orders` remain unmodified.
   - `VendorOrdersScreen` preserves exact `MISSING`/`PENDING` empty states; `DriverDashboardScreen` preserves `REJECTED` review messages and non-fatal `statsError` banner recovery; `AccountScreen` preserves `ListView` + 3 `DarbGroupedSection` blocks and `SettingsScreen` navigation.
3. **Localization Completeness**: All 619+ static `dt('...')` UI strings have explicit English and Turkish pairs in `app_localizations.dart` (`_sourceValues`), plus dynamic prefix/suffix handlers for stock counts, distances, and product totals.
4. **Verification Note**: CI workflows (`.github/workflows/validate-mobile-overrides.yml` and `.github/workflows/build-android-release.yml`) should be executed via `flutter analyze lib` and `flutter test` in an environment with Flutter SDK installed to verify runtime widget tests (`widget_test.dart`).
