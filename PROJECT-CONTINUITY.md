# سجل استمرارية مشروع دَرْب

آخر تحديث: 2026-11-19

## المستودع المعتمد
- GitHub: https://github.com/anasgdxj/darb-delivery-platform
- المالك الحالي: `anasgdxj`
- الفرع الأساسي: `main`
- آخر commit تمت مراجعته: `952eda161c2629897398e5f309a18231ddca849e` (Create SECURITY.md)

## ما تم التحقق منه في 2026-11-19
- تم العثور على المستودع الصحيح تحت حساب `anasgdxj`.
- خدمة Render المسماة `darb-api` مرتبطة بالمستودع نفسه وبالفرع `main`، وحالتها غير معلقة، وخطة الاستضافة Free.
- فحص حي لمسار `GET /api/v1/healthz`: HTTP 200 والاستجابة `{"status":"ok"}`.
- فحص حي لمسار `GET /api/v1/readyz`: HTTP 200 وقيمتا قاعدة البيانات وRedis هما `ok`.
- ملف تطبيق Flutter الحالي موجود في `mobile-overrides/login_screen.dart` ويحتوي على OTP وGoogle Sign-In.
- كود الخادم في `backend-overrides/auth.controller.ts` و`backend-overrides/auth.service.ts` يحتوي على `POST /auth/google` والتحقق من Google ID token وربط الحساب.
- يوجد مسار بناء Android موقّع في `.github/workflows/build-android-release.yml`، لكنه يعتمد على GitHub Actions Secrets. وجود workflow لا يثبت أن بناءً حديثاً نجح أو أن APK صالح لتسجيل الدخول من جهاز فعلي.
- لا يوجد ملف `DESIGN_SYSTEM.md` ضمن نتائج البحث في المستودع حتى هذا التحديث.

## نقاط غير مثبتة / تحذيرات
- لم يتم إجراء تسجيل دخول فعلي على جهاز Android في هذه الجلسة.
- لم يتم إثبات أن إعدادات Google OAuth متطابقة في Render وGoogle Cloud/Android (Web Client ID، package name، release SHA-1).
- لم يتم اختبار إرسال SMS حي أو استلام OTP. لا ترسل رسالة ولا تستهلك رصيد MsgPlus دون موافقة صريحة من المالك.
- إعدادات Render السرية لم تُقرأ أو تُعدّل في هذه الجلسة.
- توجد معلومات قديمة/متعارضة في README حول توفر Google Sign-In؛ الكود الحالي يحتوي على endpoint، لذلك يجب تحديث التوثيق بعد التحقق التشغيلي.
- سجل التدقيق السابق يذكر أن حساب رسوم التوصيل كان يتجاهل `feePerKm` في نسخة سابقة؛ يلزم إعادة التحقق من كود المصدر النشط قبل اعتماد أي تسعير تجاري.
- Firebase Push والخرائط والتتبع الحي لم يثبت اكتمالها من طرف إلى طرف.

## قواعد الاستمرار
1. لا تعِد تنفيذ إصلاح تسجيل الدخول من الصفر.
2. لا تبدأ ميزة جديدة قبل إنهاء اختبار المهمة الحالية.
3. لا تُرسل SMS أو تنفذ أي عملية مدفوعة دون موافقة صريحة.
4. لا تعدّل أسرار الإنتاج ولا تستبدلها.
5. اعتمد الملفات الفعلية في المستودع ولا تخترع مكتبات أو مسارات.
6. لا تعتبر نجاح البناء أو health check دليلاً على نجاح تسجيل الدخول أو دورة الطلب على جهاز حقيقي.

## الخطوة التالية
- استكمال التحقق التشغيلي من إعدادات المصادقة وSMS في خدمة Render، دون كشف قيم الأسرار أو تعديلها.
- يتطلب أي وصول إضافي إلى مساحة Render تأكيد المالك لمساحة العمل المقصودة.
- بعد التحقق من إعداد SMS، اطلب موافقة صريحة قبل تنفيذ اختبار إرسال واحد، ثم اختبر استلام OTP وتسجيل الدخول على جهاز فعلي.
- بعد إغلاق المصادقة، انتقل إلى الاختبارات الوظيفية لدورة الطلب والتسعير، ثم الإشعارات والخرائط والتتبع.

## 2026-11-25 — DAZREVO continuation status

- **Repository:** `anasgdxj/darb-delivery-platform`; production branch: `main`.
- **Current main commit:** `f138dac3c7d41da31d4262724d73b11bf2516bee` (website language/script repair merged after the DAZREVO rebrand).
- **Brand:** DAZREVO / دازريفو is the current public identity. Preserve the existing Android application ID `com.darb.darb`, Dart/Kotlin symbols, repository slug, API paths, and existing OAuth/signing configuration.
- **Website:** PR #103 was merged. The Arabic homepage now has an AR/EN/TR language switcher, shared JavaScript safely handles pages without the mobile menu, the updated website validator passed, and the GitHub Pages deployment completed successfully.
- **Website consistency:** PR #104 updates the English/Turkish and help/legal pages to DAZREVO and links them from the homepage footer. Its website validation passed; it remains open for review and has not been merged.
- **Mobile verification:** On main commit `2b6336a4be22279f06d7a5bc06ef6b1d00b2a244`, Flutter analysis, Android debug build, and Flutter tests passed. Signed APK and Play Store AAB builds also passed in run `45582625538`; both artifacts uploaded successfully. The APK passed `apksigner verify` using APK Signature Scheme v2. Release signing SHA-1: `60877b478f9974f36ed8565582f82b3b62089523` (matches the previous signed-release build). APK SHA-256: `93632a94b6060d43043be5d4725ce49d6a49a4cac5f562e16b549540f898b5e9`. The run intentionally skipped publishing `latest` and sending push notifications.
- **FCM blocker:** Render logs previously confirmed that Firebase Admin initialization failed because `FIREBASE_SERVICE_ACCOUNT_JSON` lacked `project_id`, `client_email`, and `private_key`. Do not claim push notifications are operational until corrected and verified on a physical Android device.
- **Release safety:** PR #105 adds a protected readiness endpoint and a GitHub Actions preflight that blocks replacing the public `latest` APK unless the webhook token matches and Firebase Admin Messaging is initialized. CI is pending. The PR does not publish an APK or send a push notification.
- **Secrets:** Do not read, expose, replace, or commit Render/GitHub secrets. The owner must provide the complete Firebase Admin service-account JSON in Render and ensure `DARB_RELEASE_WEBHOOK_TOKEN` matches between Render and GitHub Actions.
- **Next work:** finish PR #105 CI review; wait for the signed artifact build; review PR #104; after the owner corrects Render credentials, deploy the readiness endpoint, verify the protected readiness response, then run a real push test and update test on Android. Do not merge PRs or publish a public APK without the owner's approval.
