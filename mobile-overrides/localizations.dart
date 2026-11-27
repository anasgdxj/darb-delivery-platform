import 'package:flutter/widgets.dart';

final ValueNotifier<Locale> darbLocale = ValueNotifier(const Locale('ar'));

String dt(String source) =>
    AppLocalizations(darbLocale.value).translateSource(source);

class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static const supportedLocales = [Locale('ar'), Locale('en'), Locale('tr')];

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _DarbLocalizationsDelegate();

  String t(String key) =>
      (_values[locale.languageCode] ?? _values['ar']!)[key] ?? key;

  String translateSource(String source) {
    if (locale.languageCode == 'ar') return source;
    final value = _sourceValues[source];
    if (value != null) {
      final parts = value.split('|');
      return locale.languageCode == 'tr' ? parts.last : parts.first;
    }
    String dynamicValue(String prefix, String en, String tr) {
      final suffix = source.substring(prefix.length);
      return locale.languageCode == 'tr' ? '$tr$suffix' : '$en$suffix';
    }

    if (source.endsWith(' منتج متاح')) {
      final count = source.substring(0, source.length - ' منتج متاح'.length);
      return locale.languageCode == 'tr'
          ? '$count ürün mevcut'
          : '$count products available';
    }
    if (source.startsWith('مسافة التوصيل: ') && source.endsWith(' كم')) {
      final distance = source.substring(
        'مسافة التوصيل: '.length,
        source.length - ' كم'.length,
      );
      return locale.languageCode == 'tr'
          ? 'Teslimat mesafesi: $distance km'
          : 'Delivery distance: $distance km';
    }
    if (source.startsWith('تعذر تحميل العروض: ')) {
      return dynamicValue(
        'تعذر تحميل العروض: ',
        'Could not load offers: ',
        'Teklifler yüklenemedi: ',
      );
    }
    if (source.startsWith('تعذر حفظ التغييرات: ')) {
      return dynamicValue(
        'تعذر حفظ التغييرات: ',
        'Could not save changes: ',
        'Değişiklikler kaydedilemedi: ',
      );
    }
    if (source.startsWith('تعذر إرسال الطلب: ')) {
      return dynamicValue(
        'تعذر إرسال الطلب: ',
        'Could not submit the application: ',
        'Başvuru gönderilemedi: ',
      );
    }
    if (source.startsWith('تعذر تحميل المدن: ')) {
      return dynamicValue(
        'تعذر تحميل المدن: ',
        'Could not load cities: ',
        'Şehirler yüklenemedi: ',
      );
    }
    if (source.startsWith('رمز المدينة: ')) {
      return dynamicValue('رمز المدينة: ', 'City code: ', 'Şehir kodu: ');
    }
    if (source.startsWith('رقم الطلب: ')) {
      return dynamicValue('رقم الطلب: ', 'Order number: ', 'Sipariş numarası: ');
    }
    if (source.startsWith('حالة المتجر: ')) {
      return dynamicValue('حالة المتجر: ', 'Store status: ', 'Mağaza durumu: ');
    }
    if (source.startsWith('تعذر تحميل المناطق: ')) {
      return dynamicValue(
        'تعذر تحميل المناطق: ',
        'Could not load zones: ',
        'Bölgeler yüklenemedi: ',
      );
    }
    if (source.startsWith('الكمية: ')) {
      return dynamicValue('الكمية: ', 'Quantity: ', 'Miktar: ');
    }
    if (source.startsWith('نوع الغرض: ')) {
      return dynamicValue('نوع الغرض: ', 'Item type: ', 'Eşya türü: ');
    }
    if (source.startsWith('وصف الغرض: ')) {
      return dynamicValue('وصف الغرض: ', 'Item description: ', 'Eşya açıklaması: ');
    }
    if (source.startsWith('تعليمات للسائق: ')) {
      return dynamicValue('تعليمات للسائق: ', 'Driver instructions: ', 'Kurye talimatları: ');
    }
    if (source.startsWith('المجموع الفرعي: ')) {
      return dynamicValue('المجموع الفرعي: ', 'Subtotal: ', 'Ara toplam: ');
    }
    if (source.startsWith('السلة (') && source.endsWith(')')) {
      final count = source.substring('السلة ('.length, source.length - 1);
      return locale.languageCode == 'tr' ? 'Sepet ($count)' : 'Cart ($count)';
    }
    if (source.startsWith('الخطوة ') && source.endsWith(' من 3')) {
      final step =
          source.substring('الخطوة '.length, source.length - ' من 3'.length);
      return locale.languageCode == 'tr' ? 'Adım $step / 3' : 'Step $step of 3';
    }
    if (source.startsWith('تم تحديد الموقع بدقة: ')) {
      return dynamicValue(
        'تم تحديد الموقع بدقة: ',
        'Location set precisely: ',
        'Konum hassas şekilde belirlendi: ',
      );
    }
    if (source.startsWith('رسوم المنطقة: ')) {
      return dynamicValue('رسوم المنطقة: ', 'Zone fees: ', 'Bölge ücretleri: ');
    }
    if (source.startsWith('أضيف ') && source.endsWith(' إلى السلة')) {
      final product = source.substring(
        'أضيف '.length,
        source.length - ' إلى السلة'.length,
      );
      return locale.languageCode == 'tr'
          ? '$product sepete eklendi'
          : '$product added to cart';
    }
    if (source.startsWith('متابعة إلى تأكيد الطلب • ')) {
      return dynamicValue(
        'متابعة إلى تأكيد الطلب • ',
        'Continue to checkout • ',
        'Ödemeye geç • ',
      );
    }
    if (source.startsWith('إعادة الإرسال خلال ')) {
      final sec = source.substring('إعادة الإرسال خلال '.length);
      return locale.languageCode == 'tr' ? 'Tekrar gönder ($sec)' : 'Resend in $sec';
    }
    return source;
  }

  static const Map<String, String> _sourceValues = {
    'مظهر التطبيق': 'Appearance|Görünüm',
    'حسب الجهاز': 'System|Sistem',
    'نهاري': 'Light|Açık',
    'ليلي': 'Dark|Koyu',
    'التبديل إلى الوضع النهاري': 'Switch to Light mode|Açık moda geç',
    'التبديل إلى الوضع الليلي': 'Switch to Dark mode|Koyu moda geç',
    'إضافة عنوان توصيل': 'Add delivery address|Teslimat adresi ekle',
    'اسم العنوان طويل جداً': 'Address name is too long|Adres adı çok uzun',
    'أدخل تفاصيل العنوان': 'Enter the address details|Adres ayrıntılarını girin',
    'تفاصيل العنوان طويلة جداً': 'Address details are too long|Adres ayrıntıları çok uzun',
    'الحي، الشارع، البناء، الطابق...': 'District, street, building, floor…|Mahalle, sokak, bina, kat…',
    'فعّل خدمة الموقع في هاتفك أولاً': 'Enable location services on your phone first|Önce telefonunuzda konum hizmetlerini açın',
    'يلزم السماح للتطبيق بالوصول إلى موقعك': 'Allow the app to access your location|Uygulamanın konumunuza erişmesine izin verin',
    'تحديد موقعي على الخريطة': 'Set my location|Konumumu belirle',
    'سيتم حفظ إحداثيات هذا العنوان لحساب مسافة التوصيل': 'This address location will be saved to calculate delivery distance|Teslimat mesafesini hesaplamak için bu adresin konumu kaydedilecek',
    'تعذر قراءة عناوين التوصيل': 'Could not read delivery addresses|Teslimat adresleri okunamadı',
    'لم يتم حفظ العنوان بشكل صحيح': 'The address was not saved correctly|Adres doğru şekilde kaydedilmedi',
    'السلة فارغة أو تحتوي على كمية غير صالحة': 'The cart is empty or contains an invalid quantity|Sepet boş veya geçersiz miktar içeriyor',
    'اختر عنوان توصيل صالحاً أو أضف عنواناً جديداً': 'Choose a valid delivery address or add a new one|Geçerli bir teslimat adresi seçin veya yeni adres ekleyin',
    'هذا الطلب يحتاج إلى إحداثيات عنوان التوصيل لحساب الأجرة. أضف عنواناً جديداً وحدد موقعك بدقة.': 'This order needs a map location to calculate the delivery fee. Add an address and set its location.|Bu siparişin teslimat ücretini hesaplamak için harita konumu gerekiyor. Konum içeren bir adres ekleyin.',
    'التوصيل غير مفعّل لهذه المدينة حالياً. لم يتم إرسال الطلب.': 'Delivery is not configured for this city. The order was not submitted.|Bu şehirde teslimat yapılandırılmamış. Sipariş gönderilmedi.',
    'تغيّرت توفر المنتجات أو الكمية. ارجع إلى المتجر وحدّث سلتك قبل المحاولة.': 'Product availability or quantity changed. Return to the store and update your cart.|Ürün durumu veya miktarı değişti. Mağazaya dönüp sepetinizi güncelleyin.',
    'هذا المتجر غير متاح لاستقبال الطلبات حالياً.': 'This store is currently unavailable for orders.|Bu mağaza şu anda sipariş kabul etmiyor.',
    'مراجعة طلبك': 'Review your order|Siparişinizi gözden geçirin',
    'راجع المنتجات والعنوان قبل إرسال الطلب': 'Review the items and address before submitting|Göndermeden önce ürünleri ve adresi kontrol edin',
    'المجموع الفرعي التقريبي': 'Estimated subtotal|Tahmini ara toplam',
    'السعر النهائي ورسوم التوصيل يؤكدهما الخادم عند إنشاء الطلب': 'Final prices and delivery fees are confirmed by the server when the order is created|Nihai fiyatlar ve teslimat ücretleri sipariş oluşturulurken sunucu tarafından onaylanır',
    'لا توجد إحداثيات لهذا العنوان. قد يطلب النظام تحديد الموقع لحساب رسوم التوصيل.': 'This address has no map location. The system may need it to calculate delivery fees.|Bu adresin harita konumu yok. Teslimat ücretlerini hesaplamak için gerekebilir.',
    'تم استلام طلبك': 'Order received|Sipariş alındı',
    'وصل طلبك إلى النظام، ويمكنك متابعة حالته من قسم طلباتي.': 'Your order has been received. You can follow its status in My Orders.|Siparişiniz alındı. Durumunu Siparişlerim bölümünden takip edebilirsiniz.',
    'الإجمالي عند الاستلام': 'Total due on delivery|Teslimatta ödenecek toplam',
    'طريقة الدفع': 'Payment method|Ödeme yöntemi',
    'الدفع نقداً عند الاستلام': 'Cash on delivery|Kapıda nakit ödeme',
    'حالة الطلب': 'Order status|Sipariş durumu',
    'بانتظار تأكيد المتجر': 'Awaiting store confirmation|Mağaza onayı bekleniyor',
    'العودة إلى الرئيسية': 'Back to home|Ana sayfaya dön',
    'احتفظ برقم الطلب للرجوع إليه عند الحاجة.': 'Keep your order number for reference.|Gerektiğinde kullanmak için sipariş numaranızı saklayın.',
    'تم إرسال الطلب لكن تعذر قراءة تفاصيل التأكيد. تحقق من صفحة طلباتي قبل إعادة المحاولة.': 'The order may have been submitted, but confirmation details could not be read. Check My Orders before trying again.|Sipariş gönderilmiş olabilir ancak onay ayrıntıları okunamadı. Tekrar denemeden önce Siparişlerim bölümünü kontrol edin.',
    'طلب': 'Order|Sipariş',
    'رقم الطلب': 'Order number|Sipariş numarası',
    'الحالة': 'Status|Durum',
    'بانتظار عروض السائقين': 'Waiting for driver offers|Kurye teklifleri bekleniyor',
    'بانتظار التأكيد': 'Awaiting confirmation|Onay bekleniyor',
    'تم قبول الطلب': 'Order accepted|Sipariş kabul edildi',
    'قيد التحضير': 'Preparing|Hazırlanıyor',
    'جاهز للاستلام': 'Ready for pickup|Teslim almaya hazır',
    'تم تعيين سائق': 'Driver assigned|Kurye atandı',
    'تم استلام الطلب': 'Order picked up|Sipariş teslim alındı',
    'تم التسليم': 'Delivered|Teslim edildi',
    'ملغي': 'Cancelled|İptal edildi',
    'كل طريق يبدأ بخطوة': 'Every journey starts with a step|Her yolculuk bir adımla başlar',
    'طلبات المتاجر': 'Store orders|Mağaza siparişleri',
    'طلبات السائقين': 'Driver applications|Kurye başvuruları',
    'رسوم التوصيل': 'Delivery fees|Teslimat ücretleri',
    'حسابي': 'My account|Hesabım',
    'الرئيسية': 'Home|Ana sayfa',
    'طلباتي': 'My orders|Siparişlerim',
    'طلبات المتجر': 'Store orders|Mağaza siparişleri',
    'المنتجات': 'Products|Ürünler',
    'الطلبات المتاحة': 'Available orders|Mevcut siparişler',
    'متجر': 'Store|Mağaza',
    'موقع محدد': 'Location set|Konum belirlendi',
    'الموقع غير محدد': 'Location not set|Konum belirlenmedi',
    'موقع العنوان محفوظ ويمكن حساب المسافة': 'Address location saved for distance calculation|Mesafe hesaplaması için adres konumu kaydedildi',
    'اختر عنوان التوصيل': 'Select delivery address|Teslimat adresini seçin',
    'لا يوجد عنوان محفوظ. أضف عنواناً للمتابعة.': 'No saved address. Add an address to continue.|Kayıtlı adres yok. Devam etmek için adres ekleyin.',
    'تعليمات تساعد المتجر في تجهيز طلبك': 'Instructions to help the store prepare your order|Mağazanın siparişinizi hazırlamasına yardımcı notlar',
    'تأكيد الطلب • الدفع عند الاستلام': 'Confirm order • Cash on delivery|Siparişi onayla • Kapıda ödeme',
    'لن يتم تحصيل أي مبلغ إلكترونياً في هذه الخطوة': 'No online payment is collected at this step|Bu adımda çevrimiçi ödeme alınmaz',
    'اختر الخدمة': 'Choose a service|Hizmet seçin',
    'مساران واضحان لكل احتياجات التوصيل': 'Two clear ways to meet your delivery needs|Teslimat ihtiyaçlarınız için iki net seçenek',
    'إرسال غرض مستقل': 'Send an item|Bağımsız gönderi',
    'أرسل طرداً أو غرضاً من أي عنوان إلى آخر': 'Send a parcel or item from any address to another|Bir paketi veya eşyayı istediğiniz adresten başka bir adrese gönderin',
    'الطلب من المتاجر': 'Order from stores|Mağazalardan sipariş verin',
    'تصفح المتاجر والمنتجات واطلب إلى بابك': 'Browse stores and products, delivered to your door|Mağazalara ve ürünlere göz atın, kapınıza teslim edilsin',
    'المتاجر المتاحة': 'Available stores|Mevcut mağazalar',
    'متاجر مدينتك التي يمكنك الطلب منها': 'Stores in your city you can order from|Şehrinizde sipariş verebileceğiniz mağazalar',
    'متاجر مدينتك': 'Stores in your city|Şehrinizdeki mağazalar',
    'تصفح المتاجر المتاحة وابدأ طلبك': 'Browse available stores and place your order|Mevcut mağazalara göz atın ve sipariş verin',
    'منتجات المتجر': 'Store catalog|Mağaza ürünleri',
    'ابحث عن متجر أو نشاط...': 'Search for a store or business…|Mağaza veya işletme ara…',
    'ابحث عن منتج...': 'Search for a product…|Ürün ara…',
    'لم نعثر على منتجات مطابقة': 'No matching products found|Eşleşen ürün bulunamadı',
    'إضافة إلى السلة': 'Add to cart|Sepete ekle',
    'لا توجد متاجر متاحة في هذه المدينة': 'No stores available in this city|Bu şehirde mağaza yok',
    'يمكنك استخدام خدمة التوصيل المستقل حتى عندما لا تتوفر متاجر في مدينتك.': 'You can still send an item via independent delivery even when stores are unavailable.|Mağaza bulunmasa bile bağımsız teslimat hizmetini kullanabilirsiniz.',
    'إنشاء طلب توصيل مستقل': 'Create independent delivery|Bağımsız teslimat oluştur',
    'لم نعثر على نتائج مطابقة': 'No matching results found|Eşleşen sonuç bulunamadı',
    'طلباتك': 'Your orders|Siparişleriniz',
    'لا توجد طلبات حتى الآن': 'No orders yet|Henüz sipariş yok',
    'لا توجد طلبات واردة': 'No incoming orders|Gelen sipariş yok',
    'الكل': 'All|Tümü',
    'النشطة': 'Active|Aktif',
    'المكتملة': 'Completed|Tamamlanan',
    'الاسم': 'Name|Ad',
    'لغة التطبيق': 'App language|Uygulama dili',
    'إدارة DAZREVO': 'DAZREVO Admin|DAZREVO Yönetimi',
    'حساب سائق': 'Driver account|Kurye hesabı',
    'حساب تاجر': 'Merchant account|Satıcı hesabı',
    'حساب عميل': 'Customer account|Müşteri hesabı',
    'تم إرسال الطلب. ستراجع الإدارة بياناتك قبل تفعيل الصلاحيات.': 'Application submitted. The team will review your details before enabling access.|Başvuru gönderildi. Erişim etkinleştirilmeden önce bilgileriniz incelenecek.',
    'تم تحديد موقع المتجر': 'Store location set|Mağaza konumu belirlendi',
    'طلب انضمام متجر': 'Store application|Mağaza başvurusu',
    'طلب انضمام سائق': 'Driver application|Kurye başvurusu',
    'طلبات انضمام المتاجر': 'Store applications|Mağaza başvuruları',
    'طلبات انضمام السائقين': 'Driver applications|Kurye başvuruları',
    'لا توجد طلبات معلّقة حالياً': 'No pending applications|Bekleyen başvuru yok',
    'قيد المراجعة': 'Pending review|İncelemede',
    'اعتماد الطلب': 'Approve application|Başvuruyu onayla',
    'متجر جديد': 'New store|Yeni mağaza',
    'سائق جديد': 'New driver|Yeni kurye',
    'منطقة': 'Zone|Bölge',
    'DAZREVO': 'DAZREVO|DAZREVO',
    'د': 'D|D',
    'تعذر تحميل حسابك': 'Could not load your account|Hesabınız yüklenemedi',
    'إعادة المحاولة': 'Try again|Tekrar dene',
    'حسابك محفوظ. لن يتم تسجيل خروجك بسبب تعذر الاتصال.': 'Your account is safe. You will not be signed out because the connection failed.|Hesabınız güvende. Bağlantı hatası nedeniyle oturumunuz kapatılmadı.',
    'لا توجد مدينة مفعّلة لخدمة التوصيل حالياً': 'No city currently has delivery service enabled|Şu anda teslimat hizmeti etkin olan şehir yok',
    'موقع التوصيل': 'Delivery city|Teslimat şehri',
    'المدينة غير متاحة': 'City unavailable|Şehir kullanılamıyor',
    'توصيل من الباب إلى الباب': 'Door-to-door delivery|Kapıdan kapıya teslimat',
    'خدمة التوصيل المستقل': 'Independent delivery service|Bağımsız teslimat hizmeti',
    'من بابك إلى وجهتك،\nDAZREVO يتولى الطريق.': 'From your door to your destination,\nDAZREVO leads the route.|Kapınızdan hedefinize,\nDAZREVO yolu yönetir.',
    'أرسل غرضك بسهولة، واستقبل عروض السائقين واختر الأجرة المناسبة لك.': 'Send your parcel easily, receive driver offers, and pick the fare that fits.|Gönderinizi kolayca oluşturun, kurye tekliflerini karşılaştırın ve seçin.',
    'ابدأ طلب توصيل': 'Start a delivery|Teslimat başlat',
    'قارن عروض السائقين قبل اختيار الأجرة': 'Compare driver offers before confirming the fare|Ücreti onaylamadan önce kurye tekliflerini karşılaştırın',
    'كيف تريد استخدام DAZREVO؟': 'How would you like to use DAZREVO?|DAZREVO\'yu nasıl kullanmak istersiniz?',
    'اختر المسار الذي يناسب احتياجك': 'Pick the flow that matches your need|İhtiyacınıza uygun akışı seçin',
    'اطلب بمساعدة الذكاء الاصطناعي': 'Order with AI Assistant|Yapay Zeka ile Sipariş',
    'اكتب طلبك باللهجة التي تستخدمها ودع DAZREVO يحوله إلى مسودة للمراجعة': 'Describe what you need naturally and let DAZREVO draft it for review|İhtiyacınızı doğal dille yazın, DAZREVO taslağa dönüştürsün',
    'مساعد DAZREVO الذكي': 'DAZREVO AI Assistant|DAZREVO Akıllı Asistan',
    'احكِ طلبك بطريقتك': 'Describe your order naturally|Siparişinizi kendi dilinizde anlatın',
    'اكتب باللهجة السورية أو العربية. سيستخرج المساعد نوع الطلب والمنتجات والعنوان، ثم يعرضها عليك للمراجعة.': 'Write naturally in Arabic or Syrian dialect. The assistant extracts order type, items, and address for your review.|Doğal dilde yazın. Asistan sipariş türünü, ürünleri ve adresi incelemeniz için çıkarır.',
    'اكتب طلبك هنا': 'Write your request here|Talebinizi buraya yazın',
    'مثال: بدي كيلو موز وحليب، والتوصيل على عنواني...': 'Example: I need 1kg bananas and milk delivered to my address…|Örnek: Adresime 1 kilo muz ve süt istiyorum…',
    'حلّل الطلب': 'Analyze request|Talebi analiz et',
    'جارٍ تحليل طلبك...': 'Analyzing your request…|Talebiniz analiz ediliyor…',
    'مسودة طلبك': 'Your order draft|Sipariş taslağınız',
    'طلب من متجر': 'Store order|Mağaza siparişi',
    'توصيل غرض مستقل': 'Independent parcel|Bağımsız gönderi',
    'يحتاج إلى توضيح': 'Needs clarification|Açıklama gerekiyor',
    'العناصر المستخرجة': 'Extracted items|Çıkarılan ürünler',
    'عنصر': 'Item|Öğe',
    'يحتاج إلى مراجعتك': 'Needs your review|İncelemeniz gerekiyor',
    'هذه مسودة فقط. لم يتم إنشاء طلب أو حجز منتجات أو تثبيت عنوان.': 'This is a preview draft only. No order or address has been confirmed yet.|Bu yalnızca bir taslaktır. Henüz sipariş veya adres onaylanmadı.',
    'اكتب طلباً بين 5 و3000 محرف': 'Enter between 5 and 3000 characters|5 ile 3000 karakter arasında yazın',
    'تعذر تحليل الطلب حالياً. تحقق من اتصال الإنترنت ثم أعد المحاولة.': 'Could not analyze request right now. Check your connection and try again.|Şu anda analiz edilemedi. Bağlantınızı kontrol edip tekrar deneyin.',
    'جرب مثالاً سريعاً': 'Try a quick example|Hızlı bir örnek deneyin',
    'بدي ٢ كيلو تفاح وعلبة حليب على عنوان البيت': '2kg apples and milk to home|Eve 2 kilo elma ve süt',
    'إرسال ظرف مستندات من الساحة إلى المكتب': 'Send documents envelope from square to office|Meydandan ofise evrak zarfı gönder',
    'متصل لاستلام الطلبات': 'Online for delivery requests|Siparişler için çevrimiçi',
    'فعّل الحالة لتظهر لك الطلبات الجاهزة': 'Turn on availability to view ready orders|Hazır siparişleri görmek için çevrimiçi olun',
    'حساب السائق بانتظار اعتماد الإدارة': 'Your driver account is awaiting admin approval|Kurye hesabınız yönetici onayı bekliyor',
    'طلبات جاهزة للاستلام': 'Orders ready for pickup|Teslim alınmaya hazır siparişler',
    'لا توجد طلبات متاحة حالياً': 'No available orders right now|Şu anda uygun sipariş yok',
    'اتصل لاستقبال الطلبات بعد اعتماد حسابك': 'Go online to receive orders after your account is approved|Hesabınız onaylandıktan sonra sipariş almak için çevrimiçi olun',
    'توصيلاتي': 'My deliveries|Teslimatlarım',
    'لا توجد توصيلات حالياً': 'No deliveries yet|Henüz teslimat yok',
    'قبول': 'Accept|Kabul et',
    'بدء التحضير': 'Start preparing|Hazırlamaya başla',
    'استلام الطلب': 'Pick up order|Siparişi al',
    'موقع السائق': 'Driver location|Kurye konumu',
    'تم الاستلام': 'Picked up|Teslim alındı',
    'طلب توصيل مستقل': 'Independent delivery request|Bağımsız teslimat talebi',
    'بانتظار العروض': 'Waiting for offers|Teklifler bekleniyor',
    'الاستلام': 'Pickup|Alım',
    'التسليم': 'Delivery|Teslimat',
    'قيمة الطلب': 'Order value|Sipariş tutarı',
    'جارٍ تحديث البيانات': 'Refreshing data…|Veriler yenileniyor…',
    'تعذر تحديث القائمة': 'Could not refresh list|Liste yenilenemedi',
    'اسحب للأسفل لتحديث الطلبات': 'Pull down to refresh orders|Siparişleri yenilemek için aşağı çekin',
    'لم يشارك السائق موقعه بعد': 'The driver has not shared their location yet|Kurye henüz konumunu paylaşmadı',
    'تعذر فتح الخرائط': 'Could not open maps|Haritalar açılamadı',
    'تقديم أجرة التوصيل': 'Submit delivery fare|Teslimat ücreti teklif et',
    'الأجرة بالليرة السورية الجديدة': 'Fare in new Syrian pounds|Yeni Suriye lirası cinsinden ücret',
    'أدخل المبلغ': 'Enter amount|Tutarı girin',
    'إلغاء': 'Cancel|İptal',
    'إرسال العرض': 'Send offer|Teklifi gönder',
    'تم إرسال عرضك للعميل': 'Your offer was sent to the customer|Teklifiniz müşteriye gönderildi',
    'تحديد الأجرة': 'Offer fare|Ücret teklif et',
    'تم اختيار السائق وتأكيد الأجرة': 'Driver selected and fare confirmed|Kurye seçildi ve ücret onaylandı',
    'بانتظار عروض السائقين.': 'Waiting for driver offers.|Kurye teklifleri bekleniyor.',
    'تحديث': 'Refresh|Yenile',
    'عروض السائقين': 'Driver offers|Kurye teklifleri',
    'أنسب عرض': 'Best fare|En uygun teklif',
    'تحديث العروض': 'Refresh offers|Teklifleri yenile',
    'سائق': 'Driver|Kurye',
    'سائق معتمد': 'Approved driver|Onaylı kurye',
    'اختيار': 'Select|Seç',
    'عنوان جديد': 'New address|Yeni adres',
    'اسم العنوان (اختياري)': 'Address name (optional)|Adres adı (isteğe bağlı)',
    'العنوان بالتفصيل': 'Full address|Açık adres',
    'فعّل خدمة الموقع أولاً': 'Enable location services first|Önce konum hizmetlerini etkinleştirin',
    'لم يتم منح إذن الموقع': 'Location permission was not granted|Konum izni verilmedi',
    'تم تحديد إحداثيات موقعك': 'Your location coordinates were set|Konum koordinatlarınız belirlendi',
    'استخدام موقعي الحالي': 'Use my current location|Mevcut konumumu kullan',
    'حفظ': 'Save|Kaydet',
    'أضف عنوان توصيل أولاً': 'Add a delivery address first|Önce teslimat adresi ekleyin',
    'تم إرسال طلبك بنجاح': 'Your order was submitted successfully|Siparişiniz başarıyla gönderildi',
    'تأكيد الطلب': 'Confirm order|Siparişi onayla',
    'ملخص السلة': 'Cart summary|Sepet özeti',
    'عنوان التوصيل': 'Delivery address|Teslimat adresi',
    'لا يوجد عنوان محفوظ': 'No saved address|Kayıtlı adres yok',
    'عنوان': 'Address|Adres',
    'إضافة عنوان': 'Add address|Adres ekle',
    'ملاحظات للمتجر (اختياري)': 'Notes for the store (optional)|Mağaza için notlar (isteğe bağlı)',
    'إرسال الطلب — الدفع عند الاستلام': 'Place order — cash on delivery|Siparişi ver — kapıda ödeme',
    'منتج جديد': 'New product|Yeni ürün',
    'اسم المنتج': 'Product name|Ürün adı',
    'السعر': 'Price|Fiyat',
    'الوصف': 'Description|Açıklama',
    'إضافة': 'Add|Ekle',
    'طلب متجرك قيد المراجعة. ستتمكن من إدارة المنتجات بعد اعتماد الإدارة.': 'Your store application is under review. You can manage products after approval.|Mağaza başvurunuz inceleniyor. Onaylandıktan sonra ürünleri yönetebilirsiniz.',
    'لم تضف أي منتجات بعد': 'You have not added any products yet|Henüz ürün eklemediniz',
    'إضافة منتج': 'Add product|Ürün ekle',
    'منتجات متجرك': 'Your store products|Mağaza ürünleriniz',
    'المواقع': 'Locations|Konumlar',
    'تفاصيل الغرض': 'Item details|Gönderi ayrıntıları',
    'مراجعة الطلب': 'Review request|Talebi gözden geçir',
    'فعّل خدمة الموقع على الهاتف': 'Enable location services on your phone|Telefonunuzda konum hizmetlerini etkinleştirin',
    'يلزم السماح بالوصول إلى الموقع': 'Location access is required|Konum erişimine izin verilmelidir',
    'إضافة عنوان تسليم': 'Add delivery address|Teslimat adresi ekle',
    'اسم العنوان': 'Address name|Adres adı',
    'الحي، الشارع، البناء، أقرب نقطة دالة': 'District, street, building, nearest landmark|Mahalle, sokak, bina, en yakın bilinen nokta',
    'جارٍ تحديد الموقع...': 'Locating…|Konum belirleniyor…',
    'تحديد موقع العنوان': 'Set address location|Adres konumunu belirle',
    'تم تحديد الموقع': 'Location set|Konum belirlendi',
    'تم حفظ الإحداثيات لهذا العنوان': 'Coordinates saved for this address|Bu adresin koordinatları kaydedildi',
    'يجب تحديد الموقع وأنت موجود في مكان التسليم نفسه.': 'Set the location while you are at the delivery point.|Konumu teslimat noktasındayken belirlemelisiniz.',
    'حفظ العنوان': 'Save address|Adresi kaydet',
    'أكمل العنوان وحدد موقعه الجغرافي': 'Complete the address and set its location|Adresi tamamlayıp konumunu belirleyin',
    'لم يتم اختيار عنوان': 'No address selected|Adres seçilmedi',
    'عنوان التسليم': 'Delivery address|Teslimat adresi',
    'اكتب وصفاً واضحاً لمكان الاستلام': 'Describe the pickup location clearly|Alım konumunu açıkça açıklayın',
    'حدد موقع الاستلام أولاً': 'Set the pickup location first|Önce alım konumunu belirleyin',
    'اختر عنوان تسليم محفوظاً مع موقع جغرافي أو أضف عنواناً جديداً': 'Choose a saved delivery address with a location or add a new one|Konumu olan kayıtlı bir teslimat adresi seçin veya yeni adres ekleyin',
    'اكتب نوع الغرض الذي تريد إرساله': 'Enter the type of item you want to send|Göndermek istediğiniz eşyanın türünü yazın',
    'أضف وصفاً مختصراً للغرض': 'Add a short description of the item|Eşya için kısa bir açıklama ekleyin',
    'إرشادات للسائق': 'Driver instructions|Kurye talimatları',
    'حسناً': 'OK|Tamam',
    'من أين نستلم؟': 'Where should we pick it up?|Nereden alalım?',
    'حدد مكان وجود الغرض حتى يصل السائق إليك.': 'Set the item location so the driver can reach you.|Kurye size ulaşabilsin diye eşyanın konumunu belirleyin.',
    'وصف مكان الاستلام': 'Pickup location description|Alım konumu açıklaması',
    'مثلاً: أمام صيدلية الشفاء، شارع ...': 'Example: In front of Al-Shifa Pharmacy, ... Street|Örnek: Şifa Eczanesi önü, ... Sokak',
    'تم تحديد موقع الاستلام': 'Pickup location set|Alım konumu belirlendi',
    'إلى أين نوصّل؟': 'Where should we deliver it?|Nereye teslim edelim?',
    'لا يوجد عنوان تسليم محفوظ. أضف عنواناً وحدد موقعه للمتابعة.': 'No saved delivery address. Add an address and set its location to continue.|Kayıtlı teslimat adresi yok. Devam etmek için adres ekleyip konumunu belirleyin.',
    'هذا العنوان لا يحتوي على موقع. أضف عنواناً جديداً وحدد موقعه.': 'This address has no location. Add a new address and set its location.|Bu adresin konumu yok. Yeni adres ekleyip konumunu belirleyin.',
    'ماذا تريد إرسال؟': 'What would you like to send?|Ne göndermek istiyorsunuz?',
    'أخبر السائق بنوع الغرض وحجمه بشكل واضح.': 'Tell the driver clearly what the item is and its size.|Sürücüye eşyanın türünü ve boyutunu açıkça belirtin.',
    'نوع الغرض': 'Item type|Eşya türü',
    'مثلاً: مستندات، حقيبة، قطعة غيار': 'Example: documents, bag, spare part|Örnek: belge, çanta, yedek parça',
    'مستندات': 'Documents|Belgeler',
    'طرد صغير': 'Small parcel|Küçük paket',
    'مشتريات': 'Purchases|Alışveriş',
    'إلكترونيات': 'Electronics|Elektronik',
    'وصف الغرض': 'Item description|Eşya açıklaması',
    'اذكر الحجم أو أي تفاصيل تساعد السائق': 'Include size or details that may help the driver|Boyutu veya sürücüye yardımcı olacak ayrıntıları belirtin',
    'تعليمات إضافية للسائق (اختياري)': 'Additional driver instructions (optional)|Kurye için ek talimatlar (isteğe bağlı)',
    'وقت مناسب، شخص للتواصل عند الوصول...': 'Preferred time, contact person on arrival…|Uygun saat, varışta aranacak kişi…',
    'راجع طلبك': 'Review your request|Talebinizi gözden geçirin',
    'تأكد من التفاصيل قبل إرسال الطلب للسائقين.': 'Check the details before sending your request to drivers.|Talebinizi sürücülere göndermeden önce ayrıntıları kontrol edin.',
    'موقع الاستلام': 'Pickup location|Alım konumu',
    'تعليمات السائق': 'Driver instructions|Kurye talimatları',
    'بعد إرسال الطلب سيحدد السائقون أجورهم وفق مسافة التوصيل، وستختار العرض المناسب قبل تأكيد الطلب.': 'After you submit, drivers will offer fares based on the distance. You can choose an offer before confirming.|Talebi gönderdikten sonra sürücüler mesafeye göre ücret teklif eder. Onaylamadan önce bir teklif seçebilirsiniz.',
    'توصيل مستقل': 'Independent delivery|Bağımsız teslimat',
    'رجوع': 'Back|Geri',
    'السابق': 'Previous|Önceki',
    'تعديل الملف الشخصي': 'Edit profile|Profili düzenle',
    'حفظ التغييرات': 'Save changes|Değişiklikleri kaydet',
    'تم تحديث بيانات حسابك': 'Your account details were updated|Hesap bilgileriniz güncellendi',
    'تعذر قراءة قائمة المدن': 'Could not read the city list|Şehir listesi okunamadı',
    'لا توجد مدن مفعّلة حالياً': 'No active cities at the moment|Şu anda etkin şehir yok',
    'اسم المتجر': 'Store name|Mağaza adı',
    'نوع النشاط': 'Business type|İşletme türü',
    'نوع المركبة (اختياري)': 'Vehicle type (optional)|Araç türü (isteğe bağlı)',
    'المدينة': 'City|Şehir',
    'عنوان المتجر (اختياري)': 'Store address (optional)|Mağaza adresi (isteğe bağlı)',
    'تحديد موقع المتجر': 'Set store location|Mağaza konumunu belirle',
    'إرسال الطلب': 'Submit application|Başvuruyu gönder',
    'تسجيل الخروج؟': 'Sign out?|Oturumu kapat?',
    'ستحتاج إلى تسجيل الدخول مجدداً للوصول إلى حسابك.': 'You will need to sign in again to access your account.|Hesabınıza erişmek için yeniden giriş yapmanız gerekecek.',
    'تسجيل الخروج': 'Sign out|Çıkış yap',
    'قيد مراجعة الإدارة': 'Pending admin review|Yönetici incelemesinde',
    'تمت الموافقة': 'Approved|Onaylandı',
    'لم تتم الموافقة': 'Not approved|Onaylanmadı',
    'معلّق من الإدارة': 'Suspended by admin|Yönetici tarafından askıya alındı',
    'لم يُرسل طلب بعد': 'No application submitted yet|Henüz başvuru gönderilmedi',
    'مرحباً بك في DAZREVO': 'Welcome to DAZREVO|DAZREVO\'ya hoş geldiniz',
    'أكمل بيانات حسابك': 'Complete your account details|Hesap bilgilerinizi tamamlayın',
    'استلمنا طلبك. ستراجع الإدارة بياناتك قبل تفعيل الصلاحيات.': 'We received your application. The team will review it before enabling access.|Başvurunuzu aldık. Erişim etkinleştirilmeden önce incelenecek.',
    'تم اعتماد طلبك. حدّث بيانات الحساب لتظهر صلاحياتك الجديدة.': 'Your application was approved. Update your account details to access your new permissions.|Başvurunuz onaylandı. Yeni yetkilerinizi kullanmak için hesap bilgilerinizi güncelleyin.',
    'يمكنك التواصل مع الدعم لمعرفة تفاصيل القرار.': 'Contact support for details about this decision.|Kararın ayrıntıları için destek ekibiyle iletişime geçin.',
    'ابدأ طلب الانضمام': 'Start your application|Başvurunuzu başlatın',
    'بيانات الحساب': 'Account details|Hesap bilgileri',
    'جارٍ الحفظ': 'Saving…|Kaydediliyor…',
    'تعديل': 'Edit|Düzenle',
    'غير محدد': 'Not specified|Belirtilmedi',
    'البريد الإلكتروني': 'Email|E-posta',
    'غير مرتبط': 'Not linked|Bağlı değil',
    'رقم الهاتف': 'Phone number|Telefon numarası',
    'وسّع دورك مع DAZREVO': 'Grow with DAZREVO|DAZREVO ile büyüyün',
    'انضم إلى شبكة التوصيل أو افتح متجرك على DAZREVO. ستراجع الإدارة طلبك قبل تفعيل الصلاحيات.': 'Join the delivery fleet or launch your store on DAZREVO. Applications are reviewed prior to activation.|Teslimat ağına katılın veya mağazanızı DAZREVO\'da açın. Başvurular onaydan sonra etkinleşir.',
    'كن سائقاً في DAZREVO': 'Become a DAZREVO Driver|DAZREVO Kuryesi Olun',
    'استقبل طلبات التوصيل وقدّم عروض الأجرة للعملاء': 'Receive delivery requests and offer fares to customers|Teslimat talepleri alın ve müşterilere ücret teklif edin',
    'انضم بمتجرك': 'Join with your store|Mağazanızla katılın',
    'اعرض منتجات متجرك واستقبل طلبات العملاء': 'Showcase your products and receive customer orders|Ürünlerinizi sergileyin ve müşteri siparişleri alın',
    'التفضيلات والدعم': 'Preferences & support|Tercihler ve destek',
    'المساعدة والدعم': 'Help & support|Yardım ve destek',
    'تواصل معنا عند الحاجة': 'Contact us whenever you need help|İhtiyaç duyduğunuzda bize ulaşın',
    'DAZREVO • هندسة التوصيل الفاخر': 'DAZREVO • Precision Logistics|DAZREVO • Kusursuz Teslimat',
    'اعتماد': 'Approve|Onayla',
    'رفض': 'Reject|Reddet',
    'تعليق': 'Suspend|Askıya al',
    'لا توجد مدن أخرى تحتاج إلى إعداد رسوم': 'No other cities need fee configuration|Ücret ayarı gereken başka şehir yok',
    'إضافة منطقة توصيل': 'Add delivery zone|Teslimat bölgesi ekle',
    'تعديل رسوم التوصيل': 'Edit delivery fees|Teslimat ücretlerini düzenle',
    'وصف إعداد الرسوم': 'Fee configuration description|Ücret ayarı açıklaması',
    'الرسم الأساسي (ل.س)': 'Base fee (SYP)|Temel ücret (SYP)',
    'الرسم لكل كيلومتر (ل.س)': 'Fee per kilometer (SYP)|Kilometre başına ücret (SYP)',
    'أدخل اسمًا ورسومًا رقمية غير سالبة': 'Enter a name and non-negative numeric fees|Bir ad ve negatif olmayan sayısal ücretler girin',
    'إضافة رسوم لمدينة': 'Add city fees|Şehir ücreti ekle',
    'لم تُضف رسوم توصيل بعد': 'No delivery fees have been added yet|Henüz teslimat ücreti eklenmedi',
    'إعداد رسوم التوصيل': 'Delivery fee settings|Teslimat ücreti ayarları',
    'يُضبط رسم واحد لكل مدينة. احتساب رسم الكيلومتر يتطلب تحديد موقع المتجر وموقع عنوان العميل.': 'One fee is configured per city. Per-kilometer pricing requires the store and customer address locations.|Her şehir için tek ücret ayarlanır. Kilometre başına ücret için mağaza ve müşteri adresinin konumu gerekir.',
    'تأكيد وإرسال الطلب': 'Confirm and send request|Talebi onayla ve gönder',
    'متابعة': 'Continue|Devam et',
    'العربية': 'Arabic|Arapça',
    'منتج': 'Product|Ürün',
    'لا توجد منتجات متاحة': 'No products available|Ürün bulunamadı',
    'تم إرسال طلبك': 'Your request was submitted|Talebiniz gönderildi',
    'سيظهر طلبك للسائقين المتاحين في مدينتك. سيقدم كل سائق أجرته، ويمكنك مقارنة العروض واختيار الأنسب قبل تأكيد التوصيل.': 'Drivers available in your city will see your request and submit fares. Compare the offers and choose the best one before confirming delivery.|Şehrinizdeki kuryeler talebinizi görecek ve ücret teklif edecek. Teslimatı onaylamadan önce teklifleri karşılaştırıp en uygun olanı seçebilirsiniz.',
    'حسابك ضمن شبكة DAZREVO': 'Verified DAZREVO Network Member|Onaylı DAZREVO Ağı Üyesi',
    'تحديث التطبيق': 'Update app|Uygulamayı güncelle',
    'تطبيقك محدّث إلى آخر إصدار': 'Your app is up to date|Uygulamanız güncel',
    'يتوفر تحديث جديد': 'A new update is available|Yeni bir güncelleme var',
    'ما الجديد في هذا التحديث؟': 'What\'s new in this update?|Yenilikler neler?',
    'تحديث الآن': 'Update now|Şimdi güncelle',
    'الإصدار الحالي': 'Current version|Mevcut sürüm',
    'الإصدار الجديد': 'New version|Yeni sürüm',
    'حجم التحديث': 'Update size|Güncelleme boyutu',
    'تنزيل التحديث': 'Download update|Güncellemeyi indir',
    'تثبيت التحديث': 'Install update|Güncellemeyi yükle',
    'جارٍ تنزيل التحديث': 'Downloading update|Güncelleme indiriliyor',
    'جارٍ تجهيز التحديث': 'Preparing update…|Güncelleme hazırlanıyor…',
    'فشل التنزيل': 'Download failed|İndirme başarısız',
    'فشل تنزيل التحديث': 'Update download failed|Güncelleme indirilemedi',
    'فشل فتح مُثبّت أندرويد': 'Could not open Android installer|Android yükleyici açılamadı',
    'سيستمر التنزيل في الخلفية ويمكنك إغلاق التطبيق': 'Download will continue in the background|İndirme arka planda devam edecek',
    'لاحقاً': 'Later|Daha sonra',
    'تعذر التحقق من التحديث': 'Could not check for updates|Güncellemeler kontrol edilemedi',
    'تعذر تنزيل التحديث': 'Could not download the update|Güncelleme indirilemedi',
    'اسمح لـ DAZREVO بتثبيت التحديثات من إعدادات أندرويد ثم ارجع واضغط تثبيت': 'Allow DAZREVO to install updates in Android settings, then return and tap Install|Android ayarlarından DAZREVO\'nun güncelleme yüklemesine izin verin, ardından geri dönüp Yükle\'ye dokunun',
    'التحقق من سلامة الملف فشل. أعد التنزيل': 'File integrity check failed. Download again|Dosya bütünlüğü doğrulanamadı. Yeniden indirin',
    'إعادة إرسال الرمز': 'Resend code|Kodu yeniden gönder',
  };

  static const Map<String, Map<String, String>> _values = {
    'ar': {
      'welcomeTitle': 'أهلاً بك في DAZREVO',
      'welcomeSubtitle': 'طريقك الأرقى لاكتشاف المتاجر وإرسال طلباتك بثقة',
      'featureStores': 'متاجر مختارة',
      'featureDelivery': 'توصيل فوري',
      'featureNearby': 'في مدينتك',
      'tabSignIn': 'تسجيل الدخول',
      'tabSignUp': 'إنشاء حساب',
      'phoneTitle': 'الدخول برقم الهاتف',
      'phoneTitleSignUp': 'انضم إلى DAZREVO',
      'phoneSubtitle': 'سنرسل إليك رمز تحقق لمرة واحدة عبر رسالة نصية',
      'phoneSubtitleSignUp': 'أدخل اسمك ورقم هاتفك السوري للبدء فوراً',
      'phoneLabel': 'رقم الهاتف السوري',
      'fullNameLabel': 'الاسم الكامل',
      'fullNameHint': 'مثلاً: سامر الأحمد',
      'sendOtp': 'إرسال رمز التحقق',
      'or': 'أو المتابعة عبر',
      'google': 'المتابعة باستخدام Google',
      'secure': 'بياناتك مشفّرة ونستخدم رقمك لتأكيد هويتك وحماية طلباتك',
      'invalidPhone': 'أدخل رقمًا سوريًا صحيحًا يبدأ بـ 09 ويتكون من 10 أرقام',
      'networkError': 'تعذر إتمام الطلب. تحقق من اتصالك وحاول مجددًا.',
      'googleUnavailable':
          'تسجيل Google غير مفعّل على الخادم حاليًا. استخدم رقم الهاتف.',
      'googleFailed': 'تعذر تسجيل الدخول باستخدام Google. حاول مجددًا.',
      'otpTitle': 'تحقق من رقمك',
      'otpSubtitle': 'أدخل رمز التحقق المكوّن من 6 أرقام المرسل إلى هاتفك',
      'otpLabel': 'رمز التحقق',
      'nameLabel': 'الاسم (اختياري)',
      'verify': 'تأكيد والمتابعة',
      'changePhone': 'تغيير رقم الهاتف',
      'invalidOtp': 'أدخل رمز التحقق المكوّن من 6 أرقام',
      'languageTitle': 'لغة التطبيق',
      'languageSubtitle': 'اختر اللغة التي تفضل استخدام DAZREVO بها',
      'languageSave': 'حفظ اللغة',
      'languageSaved': 'تم حفظ لغة التطبيق',
      'languageSaving': 'جارٍ حفظ اللغة',
      'languageArabic': 'العربية',
      'languageEnglish': 'الإنجليزية',
      'languageTurkish': 'التركية',
      'languageArabicNative': 'واجهة عربية كاملة واتجاه من اليمين إلى اليسار',
      'languageEnglishNative': 'English interface, left to right',
      'languageTurkishNative': 'Türkçe arayüz, soldan sağa',
    },
    'en': {
      'welcomeTitle': 'Welcome to DAZREVO',
      'welcomeSubtitle':
          'Your refined way to discover curated stores and send deliveries with confidence',
      'featureStores': 'Curated Stores',
      'featureDelivery': 'Express Dispatch',
      'featureNearby': 'In Your City',
      'tabSignIn': 'Sign In',
      'tabSignUp': 'Create Account',
      'phoneTitle': 'Sign in with your phone',
      'phoneTitleSignUp': 'Join DAZREVO',
      'phoneSubtitle': 'We will send you a one-time SMS verification code',
      'phoneSubtitleSignUp': 'Enter your name and Syrian phone number to start',
      'phoneLabel': 'Syrian phone number',
      'fullNameLabel': 'Full name',
      'fullNameHint': 'e.g. Samer Al-Ahmad',
      'sendOtp': 'Send verification code',
      'or': 'Or continue with',
      'google': 'Continue with Google',
      'secure':
          'Your data is encrypted and your number verifies your identity',
      'invalidPhone':
          'Enter a valid Syrian number starting with 09 and containing 10 digits',
      'networkError':
          'Could not complete the request. Check your connection and try again.',
      'googleUnavailable':
          'Google sign-in is not enabled on the server yet. Use your phone number.',
      'googleFailed': 'Google sign-in failed. Please try again.',
      'otpTitle': 'Verify your number',
      'otpSubtitle': 'Enter the 6-digit verification code sent via SMS',
      'otpLabel': 'Verification code',
      'nameLabel': 'Name (optional)',
      'verify': 'Verify & continue',
      'changePhone': 'Change phone number',
      'invalidOtp': 'Enter the 6-digit verification code',
      'languageTitle': 'App language',
      'languageSubtitle': 'Choose your preferred language across DAZREVO',
      'languageSave': 'Save language',
      'languageSaved': 'App language saved',
      'languageSaving': 'Saving language',
      'languageArabic': 'Arabic',
      'languageEnglish': 'English',
      'languageTurkish': 'Turkish',
      'languageArabicNative': 'واجهة عربية كاملة واتجاه من اليمين إلى اليسار',
      'languageEnglishNative': 'English interface, left to right',
      'languageTurkishNative': 'Turkish interface, left to right',
    },
    'tr': {
      'welcomeTitle': "DAZREVO'ya hoş geldiniz",
      'welcomeSubtitle':
          'Seçkin mağazaları keşfetmenin ve güvenle gönderi oluşturmanın en zarif yolu',
      'featureStores': 'Seçkin Mağazalar',
      'featureDelivery': 'Hızlı Teslimat',
      'featureNearby': 'Şehrinizde',
      'tabSignIn': 'Giriş Yap',
      'tabSignUp': 'Hesap Oluştur',
      'phoneTitle': 'Telefon numaranızla giriş yapın',
      'phoneTitleSignUp': "DAZREVO'ya Katılın",
      'phoneSubtitle': 'Size tek kullanımlık SMS doğrulama kodu göndereceğiz',
      'phoneSubtitleSignUp': 'Başlamak için adınızı ve Suriye numaranızı girin',
      'phoneLabel': 'Suriye telefon numarası',
      'fullNameLabel': 'Ad Soyad',
      'fullNameHint': 'Örn: Samer Al-Ahmad',
      'sendOtp': 'Doğrulama kodu gönder',
      'or': 'Veya şununla devam et',
      'google': 'Google ile devam et',
      'secure':
          'Bilgileriniz şifrelenir; numaranız kimliğinizi doğrulamak için kullanılır',
      'invalidPhone':
          '09 ile başlayan ve 10 rakam içeren geçerli bir Suriye numarası girin',
      'networkError':
          'İşlem tamamlanamadı. Bağlantınızı kontrol edip tekrar deneyin.',
      'googleUnavailable':
          'Google ile giriş henüz sunucuda etkin değil. Telefon numaranızı kullanın.',
      'googleFailed': 'Google ile giriş başarısız. Lütfen tekrar deneyin.',
      'otpTitle': 'Numaranızı doğrulayın',
      'otpSubtitle': 'SMS ile gönderilen 6 haneli doğrulama kodunu girin',
      'otpLabel': 'Doğrulama kodu',
      'nameLabel': 'Ad (isteğe bağlı)',
      'verify': 'Doğrula ve devam et',
      'changePhone': 'Telefon numarasını değiştir',
      'invalidOtp': '6 haneli doğrulama kodunu girin',
      'languageTitle': 'Uygulama dili',
      'languageSubtitle': "DAZREVO'da kullanmak istediğiniz dili seçin",
      'languageSave': 'Dili kaydet',
      'languageSaved': 'Uygulama dili kaydedildi',
      'languageSaving': 'Dil kaydediliyor',
      'languageArabic': 'Arapça',
      'languageEnglish': 'İngilizce',
      'languageTurkish': 'Türkçe',
      'languageArabicNative': 'واجهة عربية كاملة واتجاه من اليمين إلى اليسار',
      'languageEnglishNative': 'English interface, left to right',
      'languageTurkishNative': 'Türkçe arayüz, soldan sağa',
    },
  };
}

class _DarbLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _DarbLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ar', 'en', 'tr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_DarbLocalizationsDelegate old) => false;
}
