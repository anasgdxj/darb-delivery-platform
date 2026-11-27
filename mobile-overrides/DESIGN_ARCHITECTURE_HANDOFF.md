# DAZREVO Mobile UI/UX Redesign & Architecture Handoff

**Product:** DAZREVO (دازريفو)  
**Target Codebase:** `mobile-overrides/` (mirrored cleanly to `darb-workspace/darb-project/mobile/`)  
**Design Language:** Spatial Command-Deck & Architectural 2026 (Obsidian & Champagne Brass + Mineral Teal)  
**Compatibility:** `com.darb.darb` package identity, AR (`RTL`) / EN (`LTR`) / TR (`LTR`), Light & Dark themes, Glass & Standard visual modes, Phone & Tablet (`>=720dp`) adaptive breakpoints.

---

## 1. Architectural Overview & Directory Structure

The presentation layer has been refactored away from repetitive stacked Material cards toward modular spatial primitives (`DarbCommandStage`, `DarbSegmentedDock`, `DarbCityOrbStrip`, `DarbTelemetryDeck`, `DarbTicketPass`, `DarbEditorialStoreCard`, `DarbTelemetryProductCard`), while leaving networking, authentication, push notifications, GPS telemetry, offline caches, and backend REST contracts completely intact.

```text
mobile-overrides/
├── DESIGN_ARCHITECTURE_HANDOFF.md         # This technical handoff specification
├── MainActivity.kt                        # Android 8+ notification channels (dazrevo_high_importance & fallback) + APK updater channel
├── ic_launcher.xml                        # Unified chamfered D + Champagne Brass + Mineral Teal vector icon
├── android-res/                           # Adaptive XMLs, launch splash, notification vector & mipmap PNG icons
├── lib/
│   ├── core/
│   │   ├── l10n/
│   │   │   └── app_localizations.dart         # Full AR/EN/TR _sourceValues dictionary (683 keys + dynamic rules)
│   │   ├── services/
│   │   │   └── notifications_service.dart     # Hardened FCM registration, token refresh, deduplication, retry & sync diagnostics
│   │   ├── theme/
│   │   │   └── darb_design_system.dart        # DarbColors, DarbSpace, DarbRadius, DarbMotion, DarbTheme, DarbAppearanceController
│   │   └── widgets/
│   │       ├── darb_components.dart           # DarbBrandMark (animatePulse), DarbOrderTimeline (glowing active step), DarbFeedbackBanner, DarbBentoActionCard
│   │       ├── darb_copy_order_number_button.dart # Accessible copy-to-clipboard order reference action
│   │       ├── darb_glass.dart                # DarbGlassSurface, DarbGlassBottomNav, DarbGlassSideRail (with pulse beacon & DAZREVO anchor)
│   │       ├── darb_motion_components.dart    # DarbBeaconRing expanding pulse halo, kinetic wrappers & staggered motion
│   │       └── darb_spatial_primitives.dart   # 7 core spatial UI primitives + CustomPainters (including favorite toggle in DarbEditorialStoreCard)
│   └── features/
│       ├── auth/
│       │   ├── onboarding_screen.dart         # Full-bleed spatial canvas over CityShowcaseBanner + numbered 01/02/03 step pillars
│       │   └── login_screen.dart              # Continuous DarbLoginVectorMap + pulsing crest + tablet split-pane (6:5) + DarbOtpPinPreview
│       ├── shell/
│       │   └── app_shell.dart                 # Role-routed shell, tap-to-open notification order/update routing, glass nav/rail
│       ├── notifications/
│       │   └── notifications_screen.dart      # Live FCM sync status bar ("مزامنة الآن") + tap-to-open order/update routing
│       ├── customer/
│       │   ├── customer_home_screen.dart      # DarbCommandStage + persistent Favorite Stores pinning + DarbCityOrbStrip + Bento + DarbEditorialStoreCard
│       │   ├── customer_orders_screen.dart    # DarbSegmentedDock with live counts + DarbTicketPass order cards + DarbCopyOrderNumberButton
│       │   └── vendor_catalog_screen.dart     # DarbCommandStage + DarbSegmentedDock + DarbTelemetryProductCard + Obsidian-Lime floating cart bar
│       ├── driver/
│       │   ├── driver_dashboard_screen.dart   # DarbCommandStage dispatch console + job-type DarbSegmentedDock (ALL/VENDOR/PEER_DELIVERY) + DarbTelemetryDeck
│       │   └── driver_orders_screen.dart      # Job-type & status DarbSegmentedDock + DarbTicketPass active/completed courier tickets
│       ├── vendor/
│       │   ├── vendor_orders_screen.dart      # DarbCommandStage + instant search bar + pending alert banner + DarbTelemetryDeck + DarbTicketPass
│       │   └── vendor_products_screen.dart    # DarbCommandStage + DarbSegmentedDock + DarbTelemetryProductCard inventory with stock meters
│       ├── admin/
│       │   ├── admin_dashboard_screen.dart    # DarbCommandStage KPI header + DarbTelemetryDeck + DarbSegmentedDock + DarbTicketPass approval cards
│       │   └── admin_operations_screens.dart  # AdminOrdersScreen & AdminOperationsScreen using DarbSegmentedDock + DarbTicketPass + DarbFeedbackBanner
│       └── account/
│           ├── account_screen.dart            # DarbCommandStage user hero with pulsing crest + live push sync badge + 3 grouped sections
│           └── settings_screen.dart           # Appearance, accessibility (textScale, reduceMotion, haptics), live FCM force-sync, privacy & cache
└── test/
    └── widget_test.dart                       # Full suite including FCM registration, DarbBeaconRing motion, notification routing & role filter tests
```

---

## 2. Reusable Spatial Primitives (`lib/core/widgets/darb_spatial_primitives.dart`)

Developers extending or adding screens should compose from these components instead of creating raw `Card` / `Container` wrappers:

| Component | Purpose | Key Props & Behavior |
|---|---|---|
| `DarbCommandStage` | Signature Smoked Obsidian architectural stage header with `_OrbitalStagePainter` rings | `title`, `eyebrow`, `subtitle`, `leading`, `trailing`, `bottom`, `accentColor`, `livePulse`, `padding` |
| `DarbSegmentedDock<T>` | Horizontally scrollable tactile pill filter bar replacing default `ChoiceChip` rows | `options: List<DarbDockOption<T>>` (`value`, `label`, `count`, `icon`), `selectedValue`, `onSelected`, `accentColor`, `compact` |
| `DarbCityOrbStrip` | Horizontal city selector capsules embedded in `DarbCommandStage` or light canvases | `cities: List<DarbCityOrbOption>`, `selectedCityId`, `onSelect`, `onDarkStage` |
| `DarbTelemetryDeck` | High-density 4-cell (2x2 narrow, 1x4 wide `>=680px`) instrument cluster with `FontFeature.tabularFigures()` | `cells: List<DarbTelemetryCell>` (`label`, `value`, `icon`, `accentColor`, `subtitle`), `title`, `trailing` |
| `DarbTicketPass` | Perforated dispatch ticket (`_TicketPerforationPainter` dashed seam + radial side notches) for orders & approvals | `title`, `status`, `body`, `subtitle`, `leadingIcon`, `accentColor`, `headerActions`, `footer`, `onTap` |
| `DarbEditorialStoreCard` | Asymmetric store card with Obsidian/muted gradient header band, pulse status dot, rating & product count pills | `name`, `category`, `isOpen`, `productsLabel`, `address`, `ratingAvg`, `reviewsCount`, `onTap` |
| `DarbTelemetryProductCard` | Split catalog/inventory row with leading icon badge, category chip, tabular price, stock ratio `LinearProgressIndicator`, and custom `actionDock` | `name`, `priceLabel`, `actionDock`, `description`, `category`, `stockLabel`, `stockRatio`, `outOfStock`, `highlighted`, `leadingIcon`, `onTap` |

### Navigation Chrome & Brand Crest (`lib/core/widgets/darb_glass.dart`, `darb_components.dart`)
- **`DarbBrandMark`**: Chamfered ivory "D" crest intersected by a double-bevel Champagne Brass route chevron (`#D6B46C`) and a Mineral Teal telemetry nexus core (`#3FD1BE`) over Smoked Obsidian. Mirrors native `ic_launcher.xml` and `android-res/`.
- **`DarbGlassBottomNav`**: Floating glass capsule bar with active pill highlight and unread numeric badges.
- **`DarbGlassSideRail`**: Tablet/desktop (`>=720dp`) left/right rail featuring a top `DarbPulseDot` live status header, vertical active rail indicator bar, and bottom `DAZREVO` brand anchor.

---

## 3. Design Tokens (`lib/core/theme/darb_design_system.dart`)

> **Rule:** UI code must resolve semantic colors exclusively via `DarbColors.*Of(context)` / `Theme.of(context)`. Never hardcode `Colors.black` or `Colors.white` for adaptive text or card surfaces outside dark `DarbCommandStage` / Smoked Obsidian anchors.

### Brand & Accent Anchors
| Token | Hex | Usage |
|---|---|---|
| `DarbColors.forest` | `#14171D` | Smoked Obsidian command stages, hero cards, floating cart bar |
| `DarbColors.primaryGreen` | `#8A651F` | Burnished Champagne Bronze light-mode interactive primary (`>=5.3:1` AA) |
| `DarbColors.forestSoft` | `#1E222B` | Elevated Obsidian Slate fills & stage gradient stop |
| `DarbColors.mint` | `#E7D3A3` | Warm Champagne Mist route highlights, subtle dark-stage accents |
| `DarbColors.lime` | `#D6B46C` | Luminous Champagne Gold kinetic CTA, active beacons (`DarbPulseDot`), dark-mode primary |
| `DarbColors.limeInk` | `#6B4F1A` | Accessible Bronze text on light alabaster surfaces |
| `DarbColors.limeTint` | `#F6EFE0` | Soft Champagne badge tint in Light mode |
| `DarbColors.violet` | `#1D7A6E` | Imperial Mineral Teal smart/AI assistant accent (Light); `darkViolet` = `#3FD1BE` |
| `DarbColors.violetSoft` | `#E8F5F3` | Mineral Teal container wash (Light); `darkVioletSoft` = `#112926` |

### Light vs. Dark Semantic Surface Tokens
| Semantic Getter | Light Hex | Dark Hex |
|---|---|---|
| `canvasOf(ctx)` | `#FAF9F6` | `#0C0D0F` |
| `surfaceOf(ctx)` | `#FFFFFF` | `#14161A` |
| `surfaceElevatedOf(ctx)` | `#FFFFFF` | `#1B1E24` |
| `surfaceAltOf(ctx)` | `#F2EFE9` | `#232730` |
| `inkOf(ctx)` | `#141413` | `#F5F3EE` |
| `mutedOf(ctx)` | `#636059` | `#A39E93` |
| `borderOf(ctx)` | `#E5E0D6` | `#262A33` |
| `borderStrongOf(ctx)` | `#CEC7BA` | `#3A404D` |
| `primaryOf(ctx)` | `#8A651F` | `#D6B46C` |
| `onPrimaryOf(ctx)` | `#FFFFFF` | `#0C0D0F` |
| `dangerOf(ctx)` / `successOf(ctx)` / `warningOf(ctx)` / `infoOf(ctx)` | `#C83E3B` / `#1C7C54` / `#B87014` / `#2364AA` | `#F0716E` / `#4CD49A` / `#F0B857` / `#69AEF2` |

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
3. **FCM & Android Notification Channels**:
   - `MainActivity.kt` creates high-importance channels `dazrevo_high_importance` and `fcm_fallback_notification_channel` on Android O+.
   - `AndroidManifest.xml` specifies `com.google.firebase.messaging.default_notification_channel_id = dazrevo_high_importance`.
   - `backend-overrides/notifications.service.ts` attaches `android.notification.channelId = 'dazrevo_high_importance'`, `#8A651F` tint, and `دازريفو` release notification copy.
   - `DarbNotifications` checks `Firebase.apps.isEmpty`, normalizes platform names (`android`, `ios`, `web`), subscribes to `onTokenRefresh` unconditionally, deduplicates identical syncs, retries once on transient errors, and exposes test hooks (`tokenProviderOverride`, `registerDeviceOverride`, `unregisterDeviceOverride`).
4. **Localization Completeness**: All 683 static `dt('...')` UI strings have explicit English and Turkish pairs in `app_localizations.dart` (`_sourceValues`), plus dynamic prefix/suffix handlers for stock counts, distances, and product totals.
5. **Verification Note**: Run `.github/workflows/validate-mobile-overrides.yml` and `.github/workflows/build-android-release.yml` in GitHub Actions to execute `flutter analyze lib`, `flutter test`, and signed `com.darb.darb` release APK/AAB compilation before publishing (`[publish-apk]`).
