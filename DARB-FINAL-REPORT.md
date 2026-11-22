# التقرير الهندسي والتسليم التقني النهائي — تطبيق دَرْب للموبايل (DARB Mobile App)

**المشروع:** إعادة تصميم شاملة وإعادة هيكلة معمارية لتطبيق **دَرْب (DARB)** على **Flutter (Android / iOS)**  
**حزم التسليم الجاهزة:**
- `DARB-MOBILE-READY.zip` — مشروع Flutter الكامل والقابل للبناء والتعديل (`darb-project/mobile/`).
- `DARB-READY-SOURCE.zip` — كامل مساحة العمل (`darb-project/mobile/` + التعديلات المزامنة مع البنية الأصلية).
- `mobile-overrides/` — مجلد التعديلات المزامَن مع مسارات البناء (`build-android-release.yml` و`validate-mobile-overrides.yml`).

---

## 1. الملخص التنفيذي

تم تنفيذ إعادة تصميم وهيكلة كاملة لتطبيق **دَرْب للموبايل (`Flutter`)** المستخرج من `DARB-source.zip` والمحدّث عبر `mobile-overrides/`، مع الحفاظ التام على جميع الوظائف الإنتاجية وتوافقها الصارم مع الخادم الخلفي (`NestJS + ValidationPipe(forbidNonWhitelisted: true)`), وإعدادات **Google Sign-In / OAuth**, وإعدادات **Firebase FCM**, وآلية **التوقيع والبناء التلقائي للأندرويد**.

### أبرز المنجزات:
1. **تصميم زجاجي حقيقي مستوحى من Apple (`Glassmorphism` + `Standard`)**:
   - تطبيق ضبابية فعلية (`BackdropFilter`) وحدود عاكسة ناعمة وخلفيات محيطية متدرجة (`DarbAmbientBackground`).
   - متحكم مظهر فوري (`DarbAppearanceController`) يتيح التبديل بين النمط الزجاجي (`Glass`) والنمط الكلاسيكي عالي التباين (`Standard`)، وبين الوضع النهاري والليلي ونظام الجهاز (`Light / Dark / System`) مع حفظ الاختيار في `FlutterSecureStorage`.
2. **إعادة الهيكلة البرمجية (`lib/core/` + `lib/features/`)**:
   - تفكيك الملفات القديمة المتضخمة إلى **28 ملف Dart معياري** في `lib/` بالإضافة إلى اختبارات `test/widget_test.dart`، مع إزالة التكرار والتوسيم الشخصي القديم (`CRAFTED BY`) وإصلاح شذوذ الألوان.
3. **الالتزام الحرفي بالهوية البصرية المعتمدة**:
   - إزالة اللون الليموني القديم (`#C8F169` / `#d7f36a`) بالكامل واستبداله بلوحة ألوان دَرْب المعتمدة.
4. **إصلاحات التوافق مع الخادم الخلفي الإنتاجي وإصدارات Flutter 3.x**:
   - مطابقة عقود الـ API والمسارات والـ DTOs الصارمة (`tokens` عند الدخول، `PATCH /drivers/location` مع `DriverLocationReporter`, `POST /ai/assistant/ask`, `GET /vendors/:id/products`, وإدارة مرنة للمسارات الاختيارية في العميل والإدارة).
   - استبدال أدوات Flutter 3.35+ الحديثة (`RadioGroup`, `DropdownButtonFormField.initialValue`) بمكونات متوافقة مع جميع إصدارات Flutter 3.x (`DarbRadioOptionTile`, `value:`).

---

## 2. نظام التصميم والهوية البصرية (Modern Design System)

### أ. لوحة الألوان المعتمدة (`DarbColors` في `lib/core/theme/darb_design_system.dart`)
| الدلالة | الوضع النهاري (Light) | الوضع الليلي (Dark) | الاستخدام |
| :--- | :--- | :--- | :--- |
| الأخضر الغابي (`forest`) | `#12302A` | `#12302A` | التدرجات العميقة والشعار والهوية الداكنة |
| الأخضر الأساسي (`primary`) | `#167A5A` | `#28A47C` | الأزرار الأساسية والروابط النشطة والتركيز |
| النعناعي الهادئ (`mint`) | `#B9E4D2` | `#B9E4D2` | التوهجات المحيطية والحدود الزجاجية والتمييز |
| الخلفية العامة (`canvas`) | `#F6F6F3` | `#0A1916` | خلفية الشاشات |
| السطح (`surface`) | `#FFFFFF` | `#112621` | البطاقات والأسطح الصلبة وطبقات الزجاج |
| النص الأساسي (`ink`) | `#1A2E29` | `#F1F5F3` | العناوين والنصوص الرئيسية |
| النص الثانوي (`muted`) | `#687A75` | `#9DB2AC` | الأوصاف والمعلومات الثانوية |
| الخطأ والتحذير (`danger`) | `#D64545` | `#E56868` | الأخطاء وحالات الإلغاء والتنبيهات |

### ب. المكونات والحركة والتعريب
- **مكونات الزجاج (`lib/core/widgets/darb_glass.dart`):** `DarbAmbientBackground`, `DarbGlassSurface`, `DarbGlassAppBar`, `DarbGlassBottomNav`, `showDarbGlassModalSheet`.
- **المكونات المشتركة (`lib/core/widgets/darb_components.dart`):** `DarbBrandMark`, `DarbSectionHeader`, `DarbMetricCard`, `DarbStatusBadge`, `DarbStateView`, `DarbRadioOptionTile`.
- **الحركات (`DarbMotion`, `DarbFadeSlide`, `DarbPressScale`, `DarbPageTransitionsBuilder`):** انتقالات سلسة (`160ms` / `300ms` / `480ms`) تحترم تلقائياً `MediaQuery.disableAnimations` و`accessibleNavigation` (`Reduce Motion`)، مع أرقام جدولية (`FontFeature.tabularFigures()`).
- **التعريب والتحقق (`lib/core/l10n/app_localizations.dart`):** دعم كامل للغات العربية (`ar` RTL) والإنجليزية (`en` LTR) والتركية (`tr` LTR)، وتنسيق العملة السورية (`formatDarbMoney`) والأرقام السورية (`SyrianPhoneFormatter`, `isValidSyrianPhone`, `normalizeSyrianPhone`).
- **صور المدن المدمجة محلياً (`assets/cities/`):** `damascus.jpg`, `aleppo.jpg`, `homs.jpg`, `hama.jpg`, `latakia.jpg` + `ATTRIBUTION.txt` مع عرض بديل أنيق عند تعذر التحميل.

---

## 3. الهيكلية الجديدة وأسماء الملفات

### أ. تطبيق الموبايل (`darb-workspace/darb-project/mobile/` ومزامَن في `mobile-overrides/`)
- **نقطة الدخول:** `lib/main.dart`
- **النواة المشتركة (`lib/core/`):**
  - `theme/darb_design_system.dart`
  - `widgets/darb_glass.dart`
  - `widgets/darb_components.dart`
  - `l10n/app_localizations.dart`
  - `network/api_client.dart` (إدارة التوكن، التدوير التلقائي `refreshToken`، وإعادة المحاولة للطلبات الآمنة)
  - `storage/local_cache.dart` (`DarbLocalCache` لدعم العمل عند ضعف/انقطاع الاتصال)
  - `services/location_service.dart` (خدمة الموقع + `DriverLocationReporter` لتحديث موقع المندوب دورياً كل 30 ثانية عبر `PATCH /drivers/location`)
  - `services/notifications_service.dart` (إشعارات Firebase FCM وتسجيل التوكن مع الخادم)
  - `services/app_update_service.dart` (التحقق من التحديثات عبر GitHub Releases والتحقق من بصمة `SHA-256` والتثبيت عبر Android DownloadManager)
- **شاشات الميزات (`lib/features/`):**
  - `auth/`: `city_carousel.dart`, `login_screen.dart` (تسجيل الدخول عبر Google وOTP سوري)
  - `shell/`: `app_shell.dart` (التنقل المعتمد على الدور، استعادة الجلسة، تفعيل مراسل موقع المندوب، شارة التحديث)
  - `customer/`: `customer_home_screen.dart`, `vendor_catalog_screen.dart`, `checkout_screen.dart`, `customer_orders_screen.dart`, `peer_delivery_screen.dart`, `addresses_screen.dart`, `ai_order_assistant_screen.dart`
  - `driver/`: `driver_dashboard_screen.dart`, `driver_orders_screen.dart`
  - `vendor/`: `vendor_orders_screen.dart`, `vendor_products_screen.dart`
  - `admin/`: `admin_dashboard_screen.dart`, `admin_operations_screens.dart`
  - `account/`: `account_screen.dart`, `ai_role_assistant_screen.dart`
- **ملفات الأندرويد الأصيلة (`android/`):**
  - `android/app/src/main/AndroidManifest.xml`
  - `android/app/src/main/kotlin/com/darb/darb/MainActivity.kt`
  - `android/app/src/main/kotlin/com/darb/darb/DarbUpdateDownloadReceiver.kt`
  - `android/app/src/main/res/xml/darb_file_paths.xml`
  - `android/app/src/main/res/drawable/ic_launcher.xml`
- **الاختبارات (`test/`):**
  - `test/widget_test.dart` (اختبارات لوحة الألوان، التبديل بين Glass/Standard وThemeMode، تنسيق وتحقق الأرقام السورية، التعريب الثلاثي، واختبارات Widget وReduce Motion)

### ب. تكامل البناء التلقائي (`CI Workflows`)
تم تحديث قسم نسخ التعديلات فقط في:
- `.github/workflows/build-android-release.yml`
- `.github/workflows/validate-mobile-overrides.yml`
ليقرأ البناء مباشرة من البنية الجديدة في `mobile-overrides/lib/` و`mobile-overrides/test/widget_test.dart` مع **الإبقاء التام دون أي تعديل** على خطوات التوقيع (`DARB_KEYSTORE_*`), وإعدادات Google OAuth (`GOOGLE_SERVER_CLIENT_ID`), وFirebase (`--dart-define`), و`versionCode 1301+`, ونشر الإصدار.

---

## 4. إصلاحات التوافق مع الخادم الخلفي وإصدارات Flutter

1. **استخراج التوكن عند الدخول (`login_screen.dart`):** فك غلاف `data['tokens']` عند نجاح `/auth/otp/verify` و`/auth/google` مع إرسال `locale`.
2. **مسار موقع المندوب (`location_service.dart`, `driver_dashboard_screen.dart`, `app_shell.dart`):** استبدال `PUT /drivers/location` بـ **`PATCH /drivers/location`** وإعادة ربط `DriverLocationReporter` بدورة حياة التطبيق ودور المندوب.
3. **مساعد الأدوار الذكي (`ai_role_assistant_screen.dart`):** تصحيح المسار إلى **`POST /ai/assistant/ask`** بحمولة `{'message': text}` وقراءة `res['answer']`.
4. **منتجات المتجر (`vendor_products_screen.dart`):** الجلب عبر `/vendors/mine` ثم **`GET /vendors/:id/products?locale=...`** بدلاً من `/vendor/products` غير الموجود، وحصر حقول `POST /vendor/products` في الحقول المصرح بها في DTO (`name`, `description`, `price`, `stockQty`) حتى لا يرفضها `forbidNonWhitelisted: true`.
5. **المسارات الاختيارية في الشراء والإدارة (`checkout_screen.dart`, `admin_dashboard_screen.dart`, `admin_operations_screens.dart`):** عزل الطلبات الاختيارية (`/orders/estimate`, `/admin/stats`, `/admin/cities`, `/admin/users`, `/admin/settings`) داخل كتل `try/catch` مستقلة حتى لا تتعطل الشاشات عند غياب أي مسار اختياري، مع فرض قاعدة منطقة توصيل واحدة لكل مدينة وتمرير التحقق من توفر إحداثيات المندوب قبل فتح الخرائط.
6. **التوافق مع Flutter 3.x (`darb_components.dart`, `checkout_screen.dart`, `peer_delivery_screen.dart`, `account_screen.dart`, `admin_operations_screens.dart`):** استبدال `RadioGroup<T>` و`DropdownButtonFormField.initialValue` بمكون `DarbRadioOptionTile<T>` وخاصية `value:`.

---

## 5. حالة الفحوصات والاختبارات (تقريراً صادقاً للواقع الفعلي)

### الفحوصات المنفذة والتحقق المكتمل في هذه البيئة:
1. **التدقيق البرمجي والثابت عبر كامل شجرة Flutter (`29` ملف `.dart` في `lib/` و`test/` ومزامنتها في `mobile-overrides/`):**
   - **0** أخطاء في الاستيرادات النسبية أو استيرادات `package:darb/...`.
   - **0** استخدامات للألوان الممنوعة (`#C8F169` / `#d7f36a`) أو التوسيم القديم (`CRAFTED BY`) أو القيمة المعيبة `0x334FFFFF`.
   - **0** استدعاءات `RadioGroup<` أو `initialValue:` في قوائم الاختيار.
2. **فحص سلامة الأرشيفات (`DARB-MOBILE-READY.zip` و`DARB-READY-SOURCE.zip`):**
   - التحقق الفعلي من سلامة الضغط والأصول المحلية (`testzip() == None`، والتحقق من حجم صور المدن الخمس).

### الفحوصات التي تتطلب بيئة Flutter / Android SDK (غير مثبتة في هذه الحاوية):
- أدوات `flutter` و`dart` و`Android SDK` و`gradle` غير متوفرة داخل بيئة الحاوية الحالية؛ لذلك **لم يُشغَّل** `flutter analyze` أو `flutter test` أو `flutter build apk --release` محلياً هنا.
- لتشغيلها فوراً على جهاز التطوير أو عبر GitHub Actions (`.github/workflows/build-android-release.yml`):
  ```bash
  cd darb-project/mobile
  # (اختياري إذا لم يكن مجلد gradle/wrapper مولداً بعد)
  flutter create --platforms=android --org com.darb --project-name darb --no-pub .
  flutter pub get
  flutter analyze lib
  flutter test
  flutter build apk --release \
    --dart-define=API_BASE_URL=https://darb-api-yapv.onrender.com/api/v1 \
    --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_CLIENT_ID
  ```
