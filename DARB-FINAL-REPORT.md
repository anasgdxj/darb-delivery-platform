# التقرير الهندسي والتسليم التقني النهائي — منصة دَرْب (DARB Delivery Platform 2026)

**المشروع:** استكمال وإعادة تصميم وهيكلة منصة **دَرْب (`DARB`)** المتكاملة (**تطبيق الموبايل Flutter** + **الخادم الخلفي NestJS/Prisma/PostGIS** + **بوابة الإدارة Admin Web**)
**الفرع النشط في المستودع:** `feat/darb-2026-completion`
**حزم التسليم الجاهزة:**
- `DARB-MOBILE-READY.zip` — مشروع Flutter الكامل والقابل للبناء والتعديل (`darb-project/mobile/`).
- `DARB-READY-SOURCE.zip` — المصدر المتكامل (`darb-project/` شاملاً `mobile/` و`backend/`).
- `mobile-overrides/` و`backend-overrides/` و`backend/` و`admin-web/index.html` — جميعها مزامَنة مع مسارات التحقق والبناء في GitHub Actions.

---

## 1. الملخص التنفيذي

تم تنفيذ استكمال وتحديث شامل لمنصة **دَرْب** دون إنشاء تطبيق جديد أو استبدال أي تقنية أصيلة، مع الحفاظ الكامل على:
- معرف تطبيق Android: **`com.darb.darb`** وتوافق رقم البناء (`versionCode >= 32` في اختبارات التصميم و`1301+` في بناء الإصدار الموقع).
- إعدادات تسجيل الدخول عبر **Google Sign-In (`GOOGLE_SERVER_CLIENT_ID`)** و**SMS OTP (`MsgPlus`)** وإشعارات **Firebase FCM** وتوقيع الإصدار عبر GitHub Secrets.
- العمل على بيانات API حقيقية بالكامل (بدون أي بيانات وهمية أو أسرار في الكود).

### أبرز المنجزات المعمارية والوظيفية:
1. **تطبيق نظام التصميم المعتمد `DESIGN_SYSTEM.md 2.0 (DARB PULSE 2026)`**:
   - تطبيق لوحة الألوان الرسمية في الوضعين النهاري والليلي (`#102B26` Forest، `#1C443B` ForestSoft، `#B9E4D2` Mint، `#C8F169` Lime على الأسطح الداكنة، مع فصل دلالي كامل للوضع الليلي `#0B1512` / `#13221D` / `#1A2D26`).
   - دعم النمط الزجاجي الحقيقي (`Glassmorphism` عبر `BackdropFilter` و`DarbAmbientBackground`) والنمط القياسي (`Standard`)، مع اختيار المظهر (`System / Light / Dark`) وحفظه عبر `FlutterSecureStorage`.
   - احترام إعدادات تقليل الحركة (`Reduce Motion`) ومقياس الحركات القياسي (`DarbMotion`).
2. **إعادة الهيكلة البرمجية للموبايل (`29` ملف Dart في `lib/` + `widget_test.dart`)**:
   - تفكيك الشاشات والمنطق إلى `lib/core/` و`lib/features/` حسب الدور (`auth`, `shell`, `notifications`, `customer`, `driver`, `vendor`, `admin`, `account`).
   - إضافة شاشة الإشعارات (`NotificationsScreen`) المرتبطة بشارات التنبيه الحية في `AppShell`.
   - استكمال مسارات العميل: فلترة المتاجر المفتوحة، نافذة تقييمات المتجر، حالة المخزون، تفاصيل الطلب مع المخطط الزمني والاتصال المباشر، وإرسال تقييم الطلب (1–5 نجوم).
   - استكمال مسارات المندوب والمنشآت والإدارة: مؤشرات اليوم والأرباح، سحب عروض التوصيل، إخفاء الطلبات غير المناسبة، فلترة جميع الحالات للمتجر مع فئات المنتجات، وإدارة المدن والمناطق والمستخدمين والإعدادات وسجل التدقيق في لوحة الإدارة.
3. **استكمال الخادم الخلفي (`NestJS + Prisma + PostGIS`)**:
   - إضافة نموذج `UserNotification` و`DriverDismissedOrder` وقيد التفرد وفهارس `Review` في `schema.prisma` مع ترحيل `20261122090000_notifications_reviews_dismissals/migration.sql` متضمناً سياسات RLS.
   - توسيع `NotificationsController/Service` و`DriversService` و`OrdersController/Service` و`VendorsController/Service` مع التحقق الصارم بالـ `ValidationPipe(whitelist: true, forbidNonWhitelisted: true)` و`ParseUUIDPipe`.
4. **تحديث بوابة الإدارة (`admin-web/index.html`)**:
   - مواءمة البوابة مع هوية `DESIGN_SYSTEM.md 2.0` وإصلاح استهلاك استجابات الخادم (`/admin/stats`, `/admin/users`, `/admin/cities`, `/admin/settings`, `/admin/audit-logs`) مع إبقاء رموز الدخول في ذاكرة الجلسة (`accessToken` في الذاكرة فقط).

---

## 2. نظام التصميم والهوية البصرية (`DESIGN_SYSTEM.md 2.0`)

### أ. الألوان الأساسية والدلالية (`DarbColors` في `lib/core/theme/darb_design_system.dart`)
| الدلالة | الوضع النهاري (`Light`) | الوضع الليلي (`Dark`) | الاستخدام |
| :--- | :--- | :--- | :--- |
| الأخضر الغابي (`forest`) | `#102B26` | `#102B26` | الهوية الأساسية وبطاقة البطل والشارات الداكنة |
| الغابي الناعم (`forestSoft`) | `#1C443B` | `#1C443B` | الأسطح الثانوية للعنصر الرئيسي |
| النعناعي (`mint`) | `#B9E4D2` | `#B9E4D2` | اللون التفاعلي الرئيسي في الوضع الليلي والحالات النشطة |
| الليموني (`lime`) | `#C8F169` | `#C8F169` | تمييز عالي التباين فوق الأسطح الداكنة (`forest`) |
| الخلفية (`canvas`) | `#F5F6F2` | `#0B1512` | الخلفية العامة للشاشات |
| السطح (`surface` / `elevated`) | `#FFFFFF` | `#13221D` / `#1A2D26` | البطاقات والأوراق المنبثقة |
| النص الرئيسي (`ink`) | `#17231F` | `#F1F5F1` | العناوين والنصوص الأساسية |
| النص الثانوي (`muted`) | `#77837D` | `#A4B2AA` | الأوصاف والتلميحات |
| الخطوط والفواصل (`line` / `borderStrong`) | `#E4E9E3` / `#CBD5CE` | `#2A3B33` / `#40564A` | الحدود والفواصل |
| الحالات (`danger` / `success` / `warning` / `info`) | `#B94747` / `#287A50` / `#B7791F` / `#356D9A` | `#E56868` / `#4FB982` / `#E2A84B` / `#63A6DC` | الحالات والتنبيهات |

### ب. الخطوط والمقاييس والحركة
- **الخطوط:** دعم العربية أولاً (`Cairo` في الويب مع `Plus Jakarta Sans` و`IBM Plex Mono` للأرقام الجدولية `tabular-nums`) وتناسق الأرقام الجدولية في Flutter (`FontFeature.tabularFigures()`).
- **المسافات (`DarbSpace`):** `xxs=4`, `xs=8`, `sm=12`, `md=16`, `lg=20`, `xl=24`, `xxl=32`, `section=40`.
- **الحواف (`DarbRadius`):** `sm=12`, `md=16`, `lg=22`, `xl=28`, `hero=36`, `pill=999`.
- **الحركة (`DarbMotion`):** `press=120ms`, `fast=160ms`, `standard=260ms`, `route=340ms`, `expressive=420ms`, `staggerStep=55ms` مع `Curves.easeOutCubic` / `Curves.easeInCubic` / `Curves.easeOutBack`.

---

## 3. هيكل الملفات المحدّثة والجديدة

### أ. تطبيق الموبايل (`darb-workspace/darb-project/mobile/` ومزامَن في `mobile-overrides/`)
- **نقطة الدخول:** `lib/main.dart`
- **النواة (`lib/core/`):**
  - `theme/darb_design_system.dart`
  - `widgets/darb_glass.dart`, `widgets/darb_components.dart`
  - `l10n/app_localizations.dart`
  - `network/api_client.dart`, `storage/local_cache.dart`
  - `services/location_service.dart`, `services/notifications_service.dart`, `services/app_update_service.dart`
- **الميزات (`lib/features/`):**
  - `auth/`: `city_carousel.dart`, `login_screen.dart`
  - `shell/`: `app_shell.dart`
  - `notifications/`: `notifications_screen.dart` (**جديد**)
  - `customer/`: `customer_home_screen.dart`, `vendor_catalog_screen.dart`, `checkout_screen.dart`, `customer_orders_screen.dart`, `peer_delivery_screen.dart`, `addresses_screen.dart`, `ai_order_assistant_screen.dart`
  - `driver/`: `driver_dashboard_screen.dart`, `driver_orders_screen.dart`
  - `vendor/`: `vendor_orders_screen.dart`, `vendor_products_screen.dart`
  - `admin/`: `admin_dashboard_screen.dart`, `admin_operations_screens.dart`
  - `account/`: `account_screen.dart`, `ai_role_assistant_screen.dart`
- **الاختبارات:** `test/widget_test.dart`

### ب. الخادم الخلفي (`darb-workspace/darb-project/backend/` ومزامَن في `backend/` و`backend-overrides/`)
- `prisma/schema.prisma` + `prisma/migrations/20261122090000_notifications_reviews_dismissals/migration.sql`
- `src/modules/notifications/{notifications.controller.ts,notifications.service.ts,notifications.service.spec.ts}`
- `src/modules/drivers/{drivers.service.ts,drivers.service.spec.ts}`
- `src/modules/orders/{orders.controller.ts,orders.service.ts,orders.service.spec.ts}`
- `src/modules/vendors/{vendors.controller.ts,vendors.service.ts,vendors.service.spec.ts}`

### ج. بوابة الإدارة (`admin-web/`)
- `admin-web/index.html`

---

## 4. حالة التحقق والاختبارات (تقريراً صادقاً للواقع الفعلي)

### الفحوصات المنفذة والناجحة محلياً:
1. **الخادم الخلفي (`NestJS + Prisma`):**
   - نجاح `prisma validate` على `schema.prisma`.
   - نجاح البناء `npm run build` (`nest build`).
   - نجاح اختبارات الوحدة: **18 ملف اختبار / 95 اختباراً ناجحاً** (`--testPathIgnorePatterns=integration.spec.ts`).
   - مطابقة `diff -qr` بين `darb-workspace/darb-project/backend/` و`backend/` و`backend-overrides/`.
2. **تطبيق الموبايل (`Dart`):**
   - فحص ثابت لـ **30 ملف Dart**: التحقق من سلامة كافة الاستيرادات النسبية و`package:darb/...`، والتحقق من هوية `com.darb.darb`، ومطابقة `diff -qr` بين `mobile/` و`mobile-overrides/`.
3. **بوابة الإدارة (`admin-web/index.html`):**
   - نجاح فحوصات `validate-admin-portal.yml` و`validate-admin-web.yml` وفحص بناء الجافاسكريبت عبر `node --check`.
4. **صحة التعديلات وتنظيف الفروقات:**
   - نجاح `git diff --check` دون أي مسافات زائدة أو تعارضات.

### الفحوصات التي تتطلب بيئة CI (غير متوفرة في الحاوية الحالية):
- أدوات `flutter` و`dart` و`Android SDK / Gradle` وخادم `PostGIS` غير مثبتة في هذه الحاوية؛ لذا يتم تنفيذ الأوامر التالية فعلياً عبر GitHub Actions (`.github/workflows/validate-mobile-overrides.yml` و`build-android-release.yml` و`backend-ci.yml`):
  - `flutter analyze lib --no-pub` و`flutter test` و`flutter build apk --release`
  - `prisma migrate deploy` واختبار التكامل `orders.service.integration.spec.ts` على `postgis/postgis:16-3.4`.
