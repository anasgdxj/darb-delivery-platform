# دازريفو | DAZREVO

منصة توصيل متعددة الأدوار: عميل، بائع، سائق، وإدارة (الهوية السابقة: دَرْب / DARB؛ المعرّفات التقنية وحزمة `com.darb.darb` محفوظة كما هي).

المصدر الكامل للمشروع موجود ضمن مجلدي `backend/` و`mobile/` داخل الأرشيف `DARB-source.zip`. التعديلات التشغيلية الحالية وملفات Prisma migrations محفوظة كملفات مستقلة في المستودع.

## حالة التحقق

- Backend CI: تثبيت الحزم، توليد Prisma Client، تطبيق Migration على PostgreSQL 16 مع PostGIS، بناء NestJS، وتشغيل الاختبارات. راجع [سجل تشغيل CI](https://github.com/Featuredapps/darb-delivery-platform/actions).
- اختبارات وحدة فحص صحة الخادم تغطي حالات النجاح وتعطل قاعدة البيانات أو Redis.
- تم تطبيق Migration الأولية بنجاح على قاعدة بيانات PostGIS مؤقتة في GitHub Actions.
- نجح بناء APK وAAB موقعين في تشغيل سابق، لكن ذلك البناء استخدم عنوان API افتراضياً للمحاكي، ولذلك لا يصلح لتسجيل دخول فعلي من هاتف المستخدم.
- تم نشر Backend على Render Free بعنوان `https://darb-api-yapv.onrender.com` وفق سجل Render بتاريخ 2026-11-16. سجل الإقلاع أكد نجاح NestJS وتهيئة الوحدات وتطبيق migrations وعدم ظهور أخطاء Redis في آخر تشغيل أرسله المستخدم. يلزم إجراء اختبار HTTP خارجي مستقل لمساري `/api/v1/healthz` و`/api/v1/readyz` قبل اعتبار الجاهزية التشغيلية مؤكدة.

## آخر تحديث تقني

- أضيفت مسارات فحص صحة Backend: `/api/v1/healthz` و`/api/v1/readyz`.
- فحص الجاهزية يتحقق من اتصال Redis ووجود جدول المستخدمين في PostgreSQL.
- أضيفت Migration أولية معتمدة في `backend/prisma/migrations/20261116162000_initial/`.
- Migration تنشئ الجداول والعلاقات والفهارس، وتفعّل PostGIS، وتضيف فهارس مكانية وقيود رقم الهاتف السوري.
- Backend CI يختبر تطبيق Migration على PostgreSQL/PostGIS نظيف قبل البناء والاختبارات.
- Render Blueprint ينشئ API المجاني فقط ويعتمد على Supabase PostgreSQL وUpstash Redis خارجيين. النشر الحالي يستخدم عنوان API: `https://darb-api-yapv.onrender.com`.
- إعداد Blueprint لا ينشئ الاستضافة تلقائياً؛ يتطلب ربط حسابات الخدمات وإدخال عناوين الاتصال.

## النشر المجاني التجريبي

راجع [FREE-DEPLOYMENT.md](FREE-DEPLOYMENT.md) لإعداد Render Free + Supabase Free PostgreSQL/PostGIS + Upstash Redis Free.

هذا المسار مخصص للمعاينة واختبار التكامل فقط. حدود الخطط المجانية والنوم والتوقف المؤقت والحصص تمنع اعتباره استضافة إنتاجية. لا تستخدمه لبيانات عملاء حقيقية أو طلبات مباشرة.

## تنزيل المخرجات

تتوفر مخرجات البناء السابقة من صفحة [GitHub Actions](https://github.com/Featuredapps/darb-delivery-platform/actions):

- `darb-debug-apk`: تطبيق Android Debug للاختبار.
- `darb-source-fixed`: أرشيف المصدر بعد إصلاح Android scaffold وتحديث اعتماد Flutter في بيئة البناء.
- `darb-android-release`: مخرجات APK وAAB موقعة من تشغيل سابق؛ راجع ملاحظات عنوان API أعلاه قبل استخدامها.

Artifacts مؤقتة وتنتهي صلاحيتها وفق مدة الاحتفاظ المضبوطة في GitHub Actions.

## Backend

NestJS + Prisma + PostgreSQL/PostGIS + Redis.

تفاصيل النشر والقيود الحالية: [backend/DEPLOYMENT.md](backend/DEPLOYMENT.md).

## Mobile

Flutter، واجهة عربية RTL.

## تكاملات لم يثبت تفعيلها بعد

- تكامل MsgPlus موجود في Backend ويُضبط عبر `SMS_PROVIDER=msgplus` و`MSGPLUS_API_KEY` و`MSGPLUS_SENDER_NAME` و`MSGPLUS_TEMPLATE_ID=3`. لم يتم تنفيذ اختبار إرسال حي؛ لذلك لا نعتبر OTP جاهزاً تشغيلياً حتى يُجرى اختبار معتمد. لا تُرسل رسائل أو تستهلك رصيداً دون موافقة صريحة.
- Firebase Cloud Messaging وإشعارات الأجهزة الحقيقية.
- الخرائط وGeocoding وتتبع السائق الحي.

لا تعتبر هذه الخدمات متصلة حتى يتم اختبارها بمفاتيح وخدمات فعلية في بيئة آمنة.

## متطلبات ما قبل الإنتاج

- إنشاء حسابات وربط خدمات SMS وFirebase والخرائط واختبارها فعلياً.
- نشر Backend على خطة استضافة مناسبة مع قاعدة بيانات دائمة وRedis دائم.
- اختبار تدفق الطلب كاملاً بين العميل والبائع والسائق والإدارة.
- اختبار صلاحيات الأدوار وعزل البيانات والأمان.
- إعداد HTTPS وإيقاف cleartext traffic.
- حفظ أسرار الخدمات ومفاتيح توقيع Android خارج المستودع.
- بناء APK Release بعنوان API حقيقي، ثم اختباره على أجهزة Android فعلية.

## إعدادات الأمان

لا تضع أسرار الإنتاج في المستودع. استخدم ملفات البيئة المحلية أو GitHub Actions Secrets، وراجع إعدادات HTTPS وسياسات الوصول قبل النشر.

## Mobile login UI update
- The Flutter login override now provides Arabic/English/Turkish language switching, RTL/LTR layout, Syrian phone validation/formatting, OTP request/verification, and Google Sign-In client flow.
- Android builds add `google_sign_in` and may receive `GOOGLE_SERVER_CLIENT_ID` through the GitHub Actions secret of the same name.
- Google sign-in remains unavailable until a Google OAuth client is configured and the NestJS API implements `POST /api/v1/auth/google` with ID-token verification and a user-account linking/creation policy. The mobile client displays a localized message if the endpoint is absent; OTP login remains the working path.
- The deployment migration seeds 12 active Syrian cities with Arabic, English, and Turkish names. It intentionally does not create fake stores, products, drivers, or delivery prices.

Delivery pricing is configured once per city. Per-kilometre charges use PostGIS distance between the vendor GPS point and customer address GPS point; both are required when the per-kilometre rate is non-zero.
