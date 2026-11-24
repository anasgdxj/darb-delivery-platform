import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

final ValueNotifier<Locale> darbLocale = ValueNotifier(const Locale('ar'));

String dt(String source) =>
    AppLocalizations(darbLocale.value).translateSource(source);

String formatDarbMoney(num amount, [String currency = 'SYP']) {
  final formatted = intl.NumberFormat('#,##0.##', 'en_US').format(amount);
  if (currency.toUpperCase() == 'SYP') {
    final unit = switch (darbLocale.value.languageCode) {
      'en' => 'SYP',
      'tr' => 'SYP',
      _ => 'ل.س',
    };
    return '$formatted $unit';
  }
  return '$formatted $currency';
}

String normalizeSyrianPhone(String input) {
  var digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('00963')) digits = digits.substring(2);
  if (digits.startsWith('09') && digits.length == 10) {
    digits = '963${digits.substring(1)}';
  } else if (digits.startsWith('9') && digits.length == 9) {
    digits = '963$digits';
  }
  return '+$digits';
}

bool isValidSyrianPhone(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (RegExp(r'^09\d{8}$').hasMatch(digits)) return true;
  if (RegExp(r'^9639\d{8}$').hasMatch(digits)) return true;
  if (RegExp(r'^009639\d{8}$').hasMatch(digits)) return true;
  return false;
}

class SyrianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    var trimmed = digits;
    if (trimmed.length > 12) trimmed = trimmed.substring(0, 12);
    final buffer = StringBuffer();
    if (trimmed.startsWith('963')) {
      buffer.write('+963');
      final rest = trimmed.substring(3);
      if (rest.isNotEmpty) buffer.write(' ');
      for (var i = 0; i < rest.length; i++) {
        if (i == 3 || i == 6) buffer.write(' ');
        buffer.write(rest[i]);
      }
    } else {
      for (var i = 0; i < trimmed.length; i++) {
        if (i == 4 || i == 7) buffer.write(' ');
        buffer.write(trimmed[i]);
      }
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

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
    if (source.startsWith('المتبقي: ')) {
      return dynamicValue('المتبقي: ', 'In stock: ', 'Stok: ');
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
      return dynamicValue('تعذر تحميل العروض: ', 'Could not load offers: ', 'Teklifler yüklenemedi: ');
    }
    if (source.startsWith('تعذر حفظ التغييرات: ')) {
      return dynamicValue('تعذر حفظ التغييرات: ', 'Could not save changes: ', 'Değişiklikler kaydedilemedi: ');
    }
    if (source.startsWith('تعذر إرسال الطلب: ')) {
      return dynamicValue('تعذر إرسال الطلب: ', 'Could not submit the application: ', 'Başvuru gönderilemedi: ');
    }
    if (source.startsWith('تعذر تحميل المدن: ')) {
      return dynamicValue('تعذر تحميل المدن: ', 'Could not load cities: ', 'Şehirler yüklenemedi: ');
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
      return dynamicValue('تعذر تحميل المناطق: ', 'Could not load zones: ', 'Bölgeler yüklenemedi: ');
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
      final step = source.substring(
        'الخطوة '.length,
        source.length - ' من 3'.length,
      );
      return locale.languageCode == 'tr' ? 'Adım $step / 3' : 'Step $step of 3';
    }
    if (source.startsWith('تم تحديد الموقع بدقة: ')) {
      return dynamicValue('تم تحديد الموقع بدقة: ', 'Location set precisely: ', 'Konum hassas şekilde belirlendi: ');
    }
    if (source.startsWith('حدد الموقع على خريطة ')) {
      return dynamicValue('حدد الموقع على خريطة ', 'Pin location on the map for ', 'Haritada konumu işaretleyin: ');
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
    return source;
  }

  static const Map<String, String> _sourceValues = {
    'مظهر التطبيق': 'Appearance|Görünüm',
    'نمط الواجهة': 'Interface style|Arayüz stili',
    'زجاجي حديث (Glass)': 'Frosted Glass|Buzlu Cam (Glass)',
    'كلاسيكي (Standard)': 'Standard|Klasik (Standard)',
    'حسب الجهاز': 'System default|Sistem varsayılanı',
    'نهاري': 'Light|Açık',
    'ليلي': 'Dark|Koyu',
    'تم الحفظ': 'Saved|Kaydedildi',
    'الإشعارات': 'Notifications|Bildirimler',
    'تحديد الكل كمقروء': 'Mark all read|Tümünü okundu say',
    'لا توجد إشعارات حتى الآن': 'No notifications yet|Henüz bildirim yok',
    'إشعارات غير مقروءة': 'Unread notifications|Okunmamış bildirimler',
    'إضافة عنوان توصيل': 'Add delivery address|Teslimat adresi ekle',
    'تعديل العنوان': 'Edit address|Adresi düzenle',
    'حذف العنوان': 'Delete address|Adresi sil',
    'اسم العنوان طويل جداً': 'Address name is too long|Adres adı çok uzun',
    'أدخل تفاصيل العنوان': 'Enter the address details|Adres ayrıntılarını girin',
    'تفاصيل العنوان طويلة جداً': 'Address details are too long|Adres ayrıntıları çok uzun',
    'الحي، الشارع، البناء، الطابق...': 'District, street, building, floor…|Mahalle, sokak, bina, kat…',
    'فعّل خدمة الموقع في هاتفك أولاً': 'Enable location services on your phone first|Önce telefonunuzda konum hizmetlerini açın',
    'يلزم السماح للتطبيق بالوصول إلى موقعك': 'Allow the app to access your location|Uygulamanın konumunuza erişmesine izin verin',
    'تحديد موقعي على الخريطة': 'Set my location|Konumumu belirle',
    'اضغط على الخريطة لتحديد الموقع': 'Tap the map to choose a location|Konum seçmek için haritaya dokunun',
    'حرّك العلامة بالضغط على الخريطة': 'Move the pin by tapping the map|İşareti haritaya dokunarak taşıyın',
    'سيتم حفظ إحداثيات هذا العنوان لحساب مسافة التوصيل': 'This address location will be saved to calculate delivery distance|Teslimat mesafesini hesaplamak için bu adresin konumu kaydedilecek',
    'تعذر قراءة عناوين التوصيل': 'Could not read delivery addresses|Teslimat adresleri okunamadı',
    'لم يتم حفظ العنوان بشكل صحيح': 'The address was not saved correctly|Adres doğru şekilde kaydedilmedi',
    'السلة فارغة أو تحتوي على كمية غير صالحة': 'The cart is empty or contains an invalid quantity|Sepet boş veya geçersiz miktar içeriyor',
    'اختر عنوان توصيل صالحاً أو أضف عنواناً جديداً': 'Choose a valid delivery address or add a new one|Geçerli bir teslimat adresi seçin veya yeni adres ekleyin',
    'مراجعة طلبك': 'Review your order|Siparişinizi gözden geçirin',
    'راجع المنتجات والعنوان قبل إرسال الطلب': 'Review the items and address before submitting|Göndermeden önce ürünleri ve adresi kontrol edin',
    'المجموع الفرعي التقريبي': 'Estimated subtotal|Tahmini ara toplam',
    'أجرة التوصيل المتوقعة': 'Estimated delivery fee|Tahmini teslimat ücreti',
    'الإجمالي التقديري': 'Estimated total|Tahmini toplam',
    'حساب التكلفة قبل الإرسال': 'Estimate fee before ordering|Sipariş öncesi ücreti hesapla',
    'تم استلام طلبك': 'Order received|Sipariş alındı',
    'وصل طلبك إلى النظام، ويمكنك متابعة حالته من قسم طلباتي.': 'Your order has been received. You can follow its status in My Orders.|Siparişiniz alındı. Durumunu Siparişlerim bölümünden takip edebilirsiniz.',
    'الإجمالي عند الاستلام': 'Total due on delivery|Teslimatta ödenecek toplam',
    'طريقة الدفع': 'Payment method|Ödeme yöntemi',
    'الدفع نقداً عند الاستلام': 'Cash on delivery|Kapıda nakit ödeme',
    'حالة الطلب': 'Order status|Sipariş durumu',
    'تفاصيل الطلب': 'Order details|Sipariş ayrıntıları',
    'مسار حالات الطلب': 'Status timeline|Durum geçmişi',
    'إلغاء الطلب': 'Cancel order|Siparişi iptal et',
    'تأكيد إلغاء الطلب؟': 'Confirm order cancellation?|Sipariş iptali onaylansın mı?',
    'تقييم الطلب': 'Rate order|Siparişi değerlendir',
    'تقييم المتجر': 'Store reviews|Mağaza değerlendirmeleri',
    'تقييمات العملاء': 'Customer reviews|Müşteri yorumları',
    'لا توجد تقييمات بعد': 'No reviews yet|Henüz değerlendirme yok',
    'أضف تعليقك (اختياري)': 'Add a comment (optional)|Yorum ekle (isteğe bağlı)',
    'إرسال التقييم': 'Submit review|Değerlendirmeyi gönder',
    'تم إرسال تقييمك بنجاح': 'Thank you! Review submitted|Değerlendirmeniz gönderildi',
    'تقييمك': 'Your rating|Puanınız',
    'المفتوحة فقط': 'Open only|Sadece açıklar',
    'متوفر': 'In stock|Mevcut',
    'نفد المخزون': 'Out of stock|Tükendi',
    'بانتظار تأكيد المتجر': 'Awaiting store confirmation|Mağaza onayı bekleniyor',
    'العودة إلى الرئيسية': 'Back to home|Ana sayfaya dön',
    'طلب': 'Order|Sipariş',
    'رقم الطلب': 'Order number|Sipariş numarası',
    'الحالة': 'Status|Durum',
    'قيد الانتظار': 'Pending|Beklemede',
    'مقبول': 'Accepted|Kabul edildi',
    'قيد التحضير': 'Preparing|Hazırlanıyor',
    'جاهز للاستلام': 'Ready for pickup|Teslime hazır',
    'تم تعيين مندوب': 'Driver assigned|Kurye atandı',
    'في الطريق إليك': 'Picked up / On the way|Yolda',
    'تم التسليم': 'Delivered|Teslim edildi',
    'ملغى': 'Cancelled|İptal edildi',
    'ملغي': 'Cancelled|İptal edildi',
    'معتمد': 'Approved|Onaylandı',
    'مرفوض': 'Rejected|Reddet',
    'موقوف': 'Suspended|Askıda',
    'مسحوب': 'Withdrawn|Geri çekildi',
    'مفتوح': 'Open|Açık',
    'مغلق': 'Closed|Kapalı',
    'متصل': 'Online|Çevrimiçi',
    'غير متصل': 'Offline|Çevrimdışı',
    'دراجة هوائية': 'Bicycle|Bisiklet',
    'دراجة نارية': 'Motorcycle|Motosiklet',
    'سيارة': 'Car|Araba',
    'نوع المركبة': 'Vehicle type|Araç türü',
    'تحديث المركبة': 'Update vehicle|Aracı güncelle',
    'رحلات اليوم': "Today's trips|Bugünkü teslimatlar",
    'أرباح اليوم': "Today's earnings|Bugünkü kazanç",
    'الرحلات المكتملة': 'Completed trips|Tamamlanan teslimatlar',
    'الأرباح المحققة': 'Total earnings|Toplam kazanç',
    'الرحلات النشطة': 'Active trips|Aktif teslimatlar',
    'توصيلاتي': 'My deliveries|Teslimatlarım',
    'طلبات اليوم': "Today's orders|Bugünkü siparişler",
    'مبيعات اليوم': "Today's sales|Bugünkü satışlar",
    'قيد التنفيذ': 'Active orders|Aktif siparişler',
    'التقييم': 'Rating|Puan',
    'نشطة': 'Active|Aktif',
    'مكتملة': 'Completed|Tamamlanan',
    'استبعاد': 'Dismiss|Gizle',
    'تم استبعاد الطلب': 'Order dismissed|Sipariş gizlendi',
    'سحب العرض': 'Withdraw offer|Teklifi geri çek',
    'تم سحب العرض': 'Offer withdrawn|Teklif geri çekildi',
    'عرضك الحالي': 'Your current offer|Mevcut teklifiniz',
    'اتصال بالعميل': 'Call customer|Müşteriyi ara',
    'اتصال بالسائق': 'Call driver|Kuryeyi ara',
    'موقع التسليم': 'Delivery location|Teslimat konumu',
    'عروض معلّقة': 'Pending offers|Bekleyen teklifler',
    'بانتظار عروض السائقين': 'Waiting for driver offers|Kurye teklifleri bekleniyor',
    'بانتظار التأكيد': 'Awaiting confirmation|Onay bekleniyor',
    'تم قبول الطلب': 'Order accepted|Sipariş kabul edildi',
    'تم تعيين سائق': 'Driver assigned|Kurye atandı',
    'تم استلام الطلب': 'Order picked up|Sipariş teslim alındı',
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
    'المساعد الذكي': 'AI Assistant|Yapay Zeka Asistanı',
    'مساعد الطلبات الذكي': 'AI Order Assistant|Akıllı Sipariş Asistanı',
    'مساعد دَرْب الشخصي': 'DARB Role Assistant|DARB Kişisel Asistan',
    'متجر': 'Store|Mağaza',
    'موقع محدد': 'Location set|Konum belirlendi',
    'الموقع غير محدد': 'Location not set|Konum belirlenmedi',
    'اختر الخدمة': 'Choose a service|Hizmet seçin',
    'مساران واضحان لكل احتياجات التوصيل': 'Two clear ways to meet your delivery needs|Teslimat ihtiyaçlarınız için iki net seçenek',
    'إرسال غرض مستقل': 'Send an item|Bağımsız gönderi',
    'أرسل طرداً أو غرضاً من أي عنوان إلى آخر': 'Send a parcel or item from any address to another|Bir paketi veya eşyayı başka adrese gönderin',
    'الطلب من المتاجر': 'Order from stores|Mağazalardan sipariş',
    'تصفح المتاجر والمنتجات واطلب إلى بابك': 'Browse stores and products, delivered to your door|Mağazalara ve ürünlere göz atın',
    'المتاجر المتاحة': 'Available stores|Mevcut mağazalar',
    'ابحث عن متجر أو نشاط...': 'Search for a store or business…|Mağaza veya işletme ara…',
    'ابحث عن منتج...': 'Search products…|Ürün ara…',
    'الكل': 'All|Tümü',
    'لا توجد متاجر متاحة في هذه المدينة': 'No stores available in this city|Bu şehirde mağaza yok',
    'لم نعثر على نتائج مطابقة': 'No matching results found|Eşleşen sonuç bulunamadı',
    'طلباتك': 'Your orders|Siparişleriniz',
    'لا توجد طلبات حتى الآن': 'No orders yet|Henüz sipariş yok',
    'لا توجد طلبات واردة': 'No incoming orders|Gelen sipariş yok',
    'الاسم': 'Name|Ad',
    'لغة التطبيق': 'App language|Uygulama dili',
    'إدارة دَرْب': 'DARB Administration|DARB Yönetimi',
    'لوحة المؤشرات': 'Dashboard KPIs|Özet Göstergeler',
    'المستخدمون والمدن': 'Users & Cities|Kullanıcılar ve Şehirler',
    'الإعدادات والسجلات': 'Settings & Audit|Ayarlar ve Kayıtlar',
    'نسبة العمولة (%)': 'Commission rate (%)|Komisyon oranı (%)',
    'تواصل الدعم': 'Support contact|Destek iletişimi',
    'وضع الصيانة': 'Maintenance mode|Bakım modu',
    'سجل التدقيق': 'Audit log|Denetim kaydı',
    'إضافة مدينة': 'Add city|Şehir ekle',
    'اسم المدينة بالعربية': 'City name (Arabic)|Şehir adı (Arapça)',
    'اسم المدينة بالإنجليزية': 'City name (English)|Şehir adı (İngilizce)',
    'العملة الافتراضية': 'Default currency|Varsayılan para birimi',
    'تغيير الصلاحية': 'Change role|Rolü değiştir',
    'ابحث بالاسم أو الهاتف...': 'Search by name or phone…|Ad veya telefon ile ara…',
    'إجمالي المبيعات': 'Gross GMV|Toplam hacim',
    'سائقون متصلون': 'Drivers online|Çevrimiçi kuryeler',
    'سجل المتاجر': 'All stores|Tüm mağazalar',
    'سجل السائقين': 'All drivers|Tüm kuryeler',
    'حذف المنطقة': 'Delete zone|Bölgeyi sil',
    'تأكيد حذف منطقة التوصيل؟': 'Delete this delivery zone?|Bu teslimat bölgesi silinsin mi?',
    'حساب سائق': 'Driver account|Kurye hesabı',
    'حساب تاجر': 'Merchant account|Satıcı hesabı',
    'حساب عميل': 'Customer account|Müşteri hesabı',
    'دَرْب': 'DARB|DARB',
    'د': 'D|D',
    'تعذر تحميل حسابك': 'Could not load your account|Hesabınız yüklenemedi',
    'إعادة المحاولة': 'Try again|Tekrar dene',
    'موقع التوصيل': 'Delivery location|Teslimat konumu',
    'متصل لاستلام الطلبات': 'Online to receive orders|Sipariş almak için çevrimiçi',
    'فعّل الحالة لتظهر لك الطلبات الجاهزة': 'Go online to see available orders|Mevcut siparişleri görmek için çevrimiçi olun',
    'قبول': 'Accept|Kabul et',
    'بدء التحضير': 'Start preparing|Hazırlamaya başla',
    'استلام الطلب': 'Pick up order|Siparişi al',
    'موقع السائق': 'Driver location|Kurye konumu',
    'تتبع المندوب': 'Track courier|Kurye takibi',
    'يتحدث الموقع تلقائياً كل 30 ثانية': 'Location refreshes automatically every 30 seconds|Konum her 30 saniyede otomatik yenilenir',
    'تحديث الموقع': 'Refresh location|Konumu yenile',
    'آخر تحديث': 'Last update|Son güncelleme',
    'بانتظار أول تحديث للموقع': 'Waiting for the first location update|İlk konum güncellemesi bekleniyor',
    'إحداثيات موقع المندوب غير صالحة': 'Courier location coordinates are invalid|Kurye konum koordinatları geçersiz',
    'آخر موقع للمندوب قديم، ننتظر تحديثه': 'The courier location is stale; waiting for an update|Kurye konumu eski; güncelleme bekleniyor',
    'لم يشارك السائق موقعه بعد': 'The courier has not shared a location yet|Kurye henüz konum paylaşmadı',
    'تعذر تحديث موقع المندوب': 'Could not refresh the courier location|Kurye konumu yenilenemedi',
    'توسيط على المندوب': 'Center on courier|Kuryeye ortala',
    'المندوب': 'Courier|Kurye',
    'تم الاستلام': 'Picked up|Teslim alındı',
    'تقديم أجرة التوصيل': 'Submit delivery fare|Teslimat ücreti teklif et',
    'إلغاء': 'Cancel|İptal',
    'إرسال العرض': 'Send offer|Teklifi gönder',
    'تحديث': 'Refresh|Yenile',
    'عروض السائقين': 'Driver offers|Kurye teklifleri',
    'اختيار': 'Select|Seç',
    'عنوان جديد': 'New address|Yeni adres',
    'استخدام موقعي الحالي': 'Use my current location|Mevcut konumumu kullan',
    'حفظ': 'Save|Kaydet',
    'تأكيد الطلب': 'Confirm order|Siparişi onayla',
    'عنوان التوصيل': 'Delivery address|Teslimat adresi',
    'إضافة عنوان': 'Add address|Adres ekle',
    'منتج جديد': 'New product|Yeni ürün',
    'تعديل المنتج': 'Edit product|Ürünü düzenle',
    'حذف المنتج': 'Delete product|Ürünü sil',
    'متاح للبيع': 'Available for order|Satışa açık',
    'التصنيف (اختياري)': 'Category (optional)|Kategori (isteğe bağlı)',
    'المخزون (اختياري)': 'Stock quantity (optional)|Stok miktarı (isteğe bağlı)',
    'اسم المنتج': 'Product name|Ürün adı',
    'السعر': 'Price|Fiyat',
    'الوصف': 'Description|Açıklama',
    'إضافة': 'Add|Ekle',
    'إضافة منتج': 'Add product|Ürün ekle',
    'المواقع': 'Locations|Konumlar',
    'تفاصيل الغرض': 'Item details|Gönderi ayrıntıları',
    'مراجعة الطلب': 'Review request|Talebi gözden geçir',
    'توصيل مستقل': 'Independent delivery|Bağımsız teslimat',
    'رجوع': 'Back|Geri',
    'السابق': 'Previous|Önceki',
    'تعديل الملف الشخصي': 'Edit profile|Profili düzenle',
    'حفظ التغييرات': 'Save changes|Değişiklikleri kaydet',
    'تسجيل الخروج؟': 'Sign out?|Oturumu kapat?',
    'تسجيل الخروج': 'Sign out|Çıkış yap',
    'تعديل': 'Edit|Düzenle',
    'غير محدد': 'Not specified|Belirtilmedi',
    'البريد الإلكتروني': 'Email|E-posta',
    'رقم الهاتف': 'Phone number|Telefon numarası',
    'المساعدة والدعم': 'Help & support|Yardım ve destek',
    'اعتماد': 'Approve|Onayla',
    'رفض': 'Reject|Reddet',
    'تعليق': 'Suspend|Askıya al',
    'إضافة منطقة توصيل': 'Add delivery zone|Teslimat bölgesi ekle',
    'تعديل رسوم التوصيل': 'Edit delivery fees|Teslimat ücretlerini düzenle',
    'متابعة': 'Continue|Devam et',
    'العربية': 'Arabic|Arapça',
    'منتج': 'Product|Ürün',
    'لا توجد منتجات متاحة': 'No products available|Ürün bulunamadı',
    'تحديث التطبيق': 'Update app|Uygulamayı güncelle',
    'تطبيقك محدّث إلى آخر إصدار': 'Your app is up to date|Uygulamanız güncel',
    'يتوفر تحديث جديد': 'A new update is available|Yeni bir güncelleme var',
    'ما الجديد في هذا التحديث؟': "What's new in this update?|Yenilikler neler?",
    'تنزيل التحديث': 'Download update|Güncellemeyi indir',
    'تثبيت التحديث': 'Install update|Güncellemeyi yükle',
    'لاحقاً': 'Later|Daha sonra',
    'بيانات مخزنة محلياً لضعف الاتصال': 'Showing cached data while offline|Çevrimdışı önbellek gösteriliyor',
    'أجرة التوصيل': 'Delivery fee|Teslimat ücreti',
    'أدخل اسم المتجر ونوع النشاط': 'Enter the store name and business type|Mağaza adını ve işletme türünü girin',
    'أدخل اسم المنتج وسعراً صحيحاً': 'Enter a valid product name and price|Geçerli bir ürün adı ve fiyat girin',
    'أدخل اسمًا ورسومًا رقمية غير سالبة': 'Enter a name and non-negative numeric fees|Bir ad ve negatif olmayan sayısal ücretler girin',
    'أدخل المبلغ': 'Enter amount|Tutarı girin',
    'أدخل رمز المدينة واسمها العربي': 'Enter the city code and Arabic name|Şehir kodunu ve Arapça adını girin',
    'أضف وصفاً مختصراً للغرض': 'Add a brief description of the item|Eşya için kısa bir açıklama ekleyin',
    'أكمل العنوان وحدد موقعه الجغرافي': 'Complete the address and set its map location|Adresi tamamlayın ve harita konumunu belirleyin',
    'إجمالي الطلبات': 'Total orders|Toplam sipariş',
    'إرسال الطلب': 'Submit request|Talebi gönder',
    'إرسال الطلب — الدفع عند الاستلام': 'Place order — Cash on delivery|Siparişi gönder — Kapıda ödeme',
    'إشعار جديد': 'New notification|Yeni bildirim',
    'إعادة حساب التكلفة': 'Recalculate fee|Ücreti yeniden hesapla',
    'إعداد رسوم التوصيل': 'Configure delivery fees|Teslimat ücretlerini ayarla',
    'إغلاق': 'Close|Kapat',
    'إلى أين نوصّل؟': 'Where are we delivering?|Nereye teslim edelim?',
    'اختر المتجر من القائمة الرئيسية لإكمال المنتجات المقترحة': 'Choose a store from Home to complete suggested items|Önerilen ürünleri tamamlamak için Ana Sayfadan bir mağaza seçin',
    'اختر عنوان تسليم محفوظاً مع موقع جغرافي أو أضف عنواناً جديداً': 'Select a saved delivery address with GPS or add a new one|Konumu olan kayıtlı bir teslimat adresi seçin veya yeni ekleyin',
    'اذكر الحجم أو أي تفاصيل تساعد السائق': 'Mention size or helpful details for the courier|Boyutu veya kuryeye yardımcı olacak ayrıntıları belirtin',
    'اسأل مساعد دَرْب عن طلباتك أو مهامك الحالية وفق صلاحية حسابك': 'Ask DARB Assistant about your current orders or tasks|DARB Asistanına mevcut siparişleriniz veya görevleriniz hakkında sorun',
    'استقبل طلبات التوصيل وقدّم عروض الأجرة للعملاء': 'Receive delivery requests and submit fare offers to customers|Teslimat talepleri alın ve müşterilere ücret teklifi gönderin',
    'اسم العنوان (اختياري)': 'Address label (optional)|Adres adı (isteğe bağlı)',
    'اسم المتجر': 'Store name|Mağaza adı',
    'اسمح لدَرْب بتثبيت التحديثات من إعدادات أندرويد ثم ارجع واضغط تثبيت': 'Allow DARB to install updates in Android settings, then return and tap Install|Android ayarlarından DARB için güncelleme yüklemeye izin verip geri dönün ve Yükle’ye dokunun',
    'اعرض منتجات متجرك واستقبل طلبات العملاء': 'Showcase your store products and receive customer orders|Mağaza ürünlerinizi sergileyin ve müşteri siparişleri alın',
    'اكتب تفاصيل طلبك بشكل أوضح (5 أحرف على الأقل)': 'Describe your order clearly (at least 5 characters)|Siparişinizi net şekilde yazın (en az 5 karakter)',
    'اكتب سؤالك هنا...': 'Type your question here…|Sorunuzu buraya yazın…',
    'اكتب طلبك هنا': 'Type your request here|Talebinizi buraya yazın',
    'اكتب نوع الغرض الذي تريد إرساله': 'Specify the type of item you want to send|Göndermek istediğiniz eşya türünü yazın',
    'اكتب وصفاً واضحاً لمكان الاستلام': 'Write a clear description of the pickup location|Alım noktası için net bir açıklama yazın',
    'الإصدار الجديد': 'New version|Yeni sürüm',
    'الإعدادات المتقدمة تُدار من الخادم مباشرة.': 'Advanced settings are managed directly from the server.|Gelişmiş ayarlar doğrudan sunucudan yönetilir.',
    'الاستلام': 'Pickup|Alım',
    'التسليم': 'Dropoff|Teslimat',
    'الرسم الأساسي (ل.س)': 'Base fee (SYP)|Temel ücret (SYP)',
    'الرسم لكل كيلومتر (ل.س)': 'Fee per km (SYP)|Kilometre başı ücret (SYP)',
    'السلة فارغة': 'Cart is empty|Sepet boş',
    'العنوان بالتفصيل': 'Detailed address|Detaylı adres',
    'المتجر مغلق حالياً ولا يستقبل طلبات جديدة': 'This store is currently closed and not accepting orders|Bu mağaza şu anda kapalı ve yeni sipariş almıyor',
    'المدن المدعومة': 'Supported cities|Desteklenen şehirler',
    'المدينة': 'City|Şehir',
    'المنزل، العمل...': 'Home, Work…|Ev, İş…',
    'النوع': 'Type|Tür',
    'انضم بمتجرك': 'Join with your store|Mağazanla katıl',
    'بانتظار العروض': 'Awaiting offers|Teklifler bekleniyor',
    'بانتظار عروض السائقين.': 'Waiting for driver offers.|Kurye teklifleri bekleniyor.',
    'بعد إرسال الطلب سيحدد السائقون أجورهم وفق مسافة التوصيل، وستختار العرض المناسب قبل تأكيد الطلب.': 'After submitting, drivers will propose delivery fares based on distance so you can pick the best one.|Talep gönderildikten sonra kuryeler mesafeye göre ücret teklif eder, siz de uygun olanı seçersiniz.',
    'تأكيد وإرسال الطلب': 'Confirm & submit request|Onayla ve talebi gönder',
    'تحليل الطلب': 'Analyze request|Talebi analiz et',
    'تصغير الخريطة': 'Zoom out|Uzaklaştır',
    'تعديل بيانات المتجر': 'Edit store profile|Mağaza bilgilerini düzenle',
    'تعذر التحقق من التحديث': 'Could not check for updates|Güncelleme kontrol edilemedi',
    'تعذر تحديث الإشعار': 'Could not update notification|Bildirim güncellenemedi',
    'تعذر تحديد الموقع الحالي': 'Could not determine current location|Mevcut konum alınamadı',
    'تعذر تحديد موقعك الحالي. تحقق من إعدادات الموقع وحاول مجدداً.': 'Could not get your current location. Check location settings and try again.|Mevcut konumunuz alınamadı. Konum ayarlarını kontrol edip tekrar deneyin.',
    'تعذر تحميل الطلبات المتاحة حالياً': 'Could not load available orders right now|Mevcut siparişler şu anda yüklenemedi',
    'تعذر تحميل بلاطات الخريطة. احتفظنا بآخر موقع معروف ويمكنك فتحه خارج التطبيق عند توفر الإنترنت.': 'Map tiles failed to load. Last known location is preserved and can be opened externally when online.|Harita kareleri yüklenemedi. Son bilinen konum korundu ve çevrimiçi olduğunuzda harici olarak açılabilir.',
    'تعذر تنزيل التحديث': 'Could not download update|Güncelleme indirilemedi',
    'تعذر حساب تكلفة التوصيل. تحقق من الاتصال وحاول مجدداً.': 'Could not estimate delivery cost. Check connection and try again.|Teslimat ücreti hesaplanamadı. Bağlantıyı kontrol edip tekrar deneyin.',
    'تعليمات إضافية للسائق (اختياري)': 'Extra driver instructions (optional)|Kurye için ek talimatlar (isteğe bağlı)',
    'تعليمات السائق': 'Driver instructions|Kurye talimatları',
    'تعليمات للسائق: ': 'Driver instructions: |Kurye talimatları: ',
    'تكبير الخريطة': 'Zoom in|Yakınlaştır',
    'تم إرسال طلبك': 'Your request has been submitted|Talebiniz gönderildi',
    'تم إرسال عرضك للعميل': 'Your offer was sent to the customer|Teklifiniz müşteriye gönderildi',
    'تم إلغاء الطلب بنجاح': 'Order cancelled successfully|Sipariş başarıyla iptal edildi',
    'تم اختيار السائق وتأكيد الأجرة': 'Driver selected and fare confirmed|Kurye seçildi ve ücret onaylandı',
    'تم بلوغ الكمية المتوفرة من هذا المنتج': 'Maximum available stock reached for this item|Bu ürün için mevcut maksimum stoka ulaşıldı',
    'تم تحديث بيانات حسابك': 'Your account has been updated|Hesap bilgileriniz güncellendi',
    'تم تحديد إحداثيات موقعك': 'Your location coordinates were updated|Konum koordinatlarınız güncellendi',
    'تم تحديد الموقع': 'Location selected|Konum seçildi',
    'تم تحديد موقع الاستلام': 'Pickup location set|Alım konumu belirlendi',
    'تم حفظ الإحداثيات لهذا العنوان': 'Coordinates saved for this address|Bu adres için koordinatlar kaydedildi',
    'توصيل من الباب إلى الباب': 'Door-to-door delivery|Kapıdan kapıya teslimat',
    'جارٍ التحديد': 'Locating…|Belirleniyor…',
    'جارٍ التحليل...': 'Analyzing…|Analiz ediliyor…',
    'جارٍ الحفظ': 'Saving…|Kaydediliyor…',
    'جارٍ تجهيز التحديث': 'Preparing update…|Güncelleme hazırlanıyor…',
    'جارٍ تحديد الموقع...': 'Getting location…|Konum alınıyor…',
    'حدث خطأ غير متوقع، حاول مجدداً': 'An unexpected error occurred. Please try again.|Beklenmeyen bir hata oluştu, lütfen tekrar deneyin.',
    'حدد مكان وجود الغرض حتى يصل السائق إليك.': 'Pin where the item is located so the courier can reach you.|Kuryenin size ulaşabilmesi için eşyanın bulunduğu yeri işaretleyin.',
    'حدد موقع الاستلام أولاً': 'Select the pickup location first|Önce alım konumunu seçin',
    'حرّك الخريطة واضغط لتحديد النقطة بدقة': 'Pan the map and tap to place the pin accurately|Noktayı hassas seçmek için haritayı kaydırıp dokunun',
    'حساب السائق بانتظار اعتماد الإدارة': 'Your driver account is awaiting admin approval|Kurye hesabınız yönetici onayı bekliyor',
    'حسناً': 'OK|Tamam',
    'حفظ العنوان': 'Save address|Adresi kaydet',
    'راجع طلبك': 'Review your request|Talebinizi gözden geçirin',
    'رقم الطلب: ': 'Order number: |Sipariş numarası: ',
    'رمز المدينة: ': 'City code: |Şehir kodu: ',
    'سائق جديد': 'New driver|Yeni kurye',
    'سائق معتمد': 'Verified courier|Onaylı kurye',
    'ستحتاج إلى تسجيل الدخول مجدداً للوصول إلى حسابك.': 'You will need to sign in again to access your account.|Hesabınıza erişmek için tekrar giriş yapmanız gerekecek.',
    'سيتم إلغاء الطلب فوراً وإعادة الكمية إلى المتجر إذا لم يبدأ تحضيره.': 'The order will be cancelled immediately and items restocked if preparation has not started.|Hazırlık başlamadıysa sipariş hemen iptal edilir ve stok iade edilir.',
    'سيتم حذف المنتج أو إخفاؤه تلقائياً إذا ارتبط بطلبات سابقة.': 'The product will be deleted or archived automatically if linked to past orders.|Ürün geçmiş siparişlerle ilişkiliyse otomatik olarak silinir veya gizlenir.',
    'سيستمر التنزيل في الخلفية ويمكنك إغلاق التطبيق': 'Download will continue in the background|İndirme arka planda devam edecek',
    'سيظهر طلبك للسائقين المتاحين في مدينتك. سيقدم كل سائق أجرته، ويمكنك مقارنة العروض واختيار الأنسب قبل تأكيد التوصيل.': 'Your request will be shown to available drivers in your city. Compare fare offers before confirming.|Talebiniz şehrinizdeki müsait kuryelere gösterilir. Onaylamadan önce ücret tekliflerini karşılaştırabilirsiniz.',
    'صف طلبك أو الغرض المطلوب توصيله بالعربية وسنجهزه لك للمراجعة': 'Describe your order or delivery item and we will prepare a draft for review|Siparişinizi veya gönderinizi yazın, incelemeniz için taslak hazırlayalım',
    'طلب انضمام سائق': 'Driver application|Kurye başvurusu',
    'طلب انضمام متجر': 'Store application|Mağaza başvurusu',
    'طلب توصيل مستقل': 'Peer delivery request|Bağımsız teslimat talebi',
    'طلب متجرك قيد المراجعة. ستتمكن من إدارة المنتجات بعد اعتماد الإدارة.': 'Your store application is under review. You can manage products once approved.|Mağaza başvurunuz inceleniyor. Onaylandıktan sonra ürünleri yönetebilirsiniz.',
    'طلبات جاهزة للاستلام': 'Orders ready for pickup|Teslime hazır siparişler',
    'عميل': 'Customer|Müşteri',
    'عناوين التوصيل': 'Delivery addresses|Teslimat adresleri',
    'عنوان': 'Title|Başlık',
    'عنوان التسليم': 'Delivery address|Teslimat adresi',
    'عنوان المتجر (اختياري)': 'Store address (optional)|Mağaza adresi (isteğe bağlı)',
    'غرضك بأي مكان…\nودَرْب يوصّله.': 'Your parcel anywhere…\nand DARB delivers.|Eşyanız her yerden…\nDARB ile kapınızda.',
    'فتح موقع المندوب خارج التطبيق': 'Open courier location externally|Kurye konumunu dışarıda aç',
    'فشل التنزيل': 'Download failed|İndirme başarısız',
    'فشل فتح مُثبّت أندرويد': 'Failed to launch Android installer|Android yükleyici açılamadı',
    'قيد مراجعة الإدارة': 'Under admin review|Yönetici incelemesinde',
    'كن سائقاً في دَرْب': 'Drive with DARB|DARB kuryesi ol',
    'لا توجد بيانات متاحة حالياً': 'No data available right now|Şu anda görüntülenecek veri yok',
    'لا توجد توصيلات حالياً': 'No deliveries right now|Şu anda teslimat yok',
    'لا توجد طلبات متاحة حالياً': 'No available orders right now|Şu anda uygun sipariş yok',
    'لا توجد طلبات معلّقة حالياً': 'No pending applications right now|Şu anda bekleyen başvuru yok',
    'لا توجد مدن أخرى تحتاج إلى إعداد رسوم': 'No other cities need fee setup|Ücret ayarı gereken başka şehir yok',
    'لا يوجد عنوان تسليم محفوظ. أضف عنواناً وحدد موقعه للمتابعة.': 'No saved delivery address. Add one with a map location to continue.|Kayıtlı teslimat adresi yok. Devam etmek için konumlu bir adres ekleyin.',
    'لا يوجد عنوان محفوظ': 'No saved address|Kayıtlı adres yok',
    'لم تضف أي منتجات بعد': 'No products added yet|Henüz ürün eklenmedi',
    'لم تُضف رسوم توصيل بعد': 'No delivery zones configured yet|Henüz teslimat ücreti eklenmedi',
    'لم يتم اختيار عنوان': 'No address selected|Adres seçilmedi',
    'لم يتم تحديد نقطة بعد': 'No point selected yet|Henüz konum seçilmedi',
    'ماذا تريد إرسال؟': 'What are you sending?|Ne göndermek istiyorsunuz?',
    'متابعة لمراجعة وإرسال الطلب': 'Continue to review & submit|İnceleme ve gönderime devam et',
    'مثال: أريد عبوتين زيت وخبز إلى حي الشهباء، أو إرسال مفاتيح من المزة إلى المالكي': 'Example: 2 bottles of oil and bread to Al-Shahba, or send keys from Mazzeh to Malki|Örnek: Al-Shahba mahallesine yağ ve ekmek veya Mazzeh’den Malki’ye anahtar',
    'مثلاً: أمام صيدلية الشفاء، شارع ...': 'e.g. In front of Al-Shifa Pharmacy, St…|Örn: Al-Shifa Eczanesi önü, Cad…',
    'مثلاً: مستندات، حقيبة، قطعة غيار': 'e.g. Documents, bag, spare part|Örn: Belgeler, çanta, yedek parça',
    'مرحباً بك في دَرْب': 'Welcome to DARB|DARB’a hoş geldiniz',
    'مستخدم': 'User|Kullanıcı',
    'مسودة الطلب المستخرجة': 'Extracted order draft|Çıkarılan sipariş taslağı',
    'ملاحظات للمتجر (اختياري)': 'Notes for store (optional)|Mağaza notları (isteğe bağlı)',
    'ملخص السلة': 'Cart summary|Sepet özeti',
    'من أين نستلم؟': 'Where should we pick up?|Nereden teslim alalım?',
    'موقع الاستلام': 'Pickup location|Alım konumu',
    'موقعي الحالي': 'My location|Mevcut konumum',
    'نوع الغرض': 'Item type|Eşya türü',
    'نوع الغرض: ': 'Item type: |Eşya türü: ',
    'نوع النشاط': 'Business type|İşletme türü',
    'هذا المتجر غير متاح لاستقبال الطلبات حالياً.': 'This store is not accepting orders right now.|Bu mağaza şu anda sipariş kabul etmiyor.',
    'هل تريد حذف هذا العنوان المحفوظ؟': 'Delete this saved address?|Bu kayıtlı adres silinsin mi?',
    'وصف إعداد الرسوم': 'Zone fee description|Ücret bölgesi açıklaması',
    'وصف الغرض': 'Item description|Eşya açıklaması',
    'وصف الغرض: ': 'Item description: |Eşya açıklaması: ',
    'وصف مكان الاستلام': 'Pickup point description|Alım noktası açıklaması',
    'وضع عدم الاتصال — يتم عرض البيانات المحفوظة مؤقتاً': 'Offline mode — showing cached data|Çevrimdışı mod — önbellekteki veriler gösteriliyor',
    'وقت مناسب، شخص للتواصل عند الوصول...': 'Preferred time, contact person on arrival…|Uygun saat, varışta iletişim kişisi…',
    'يتحدث الموقع تلقائياً كل 25 ثانية': 'Location refreshes automatically every 25 seconds|Konum her 25 saniyede otomatik yenilenir',
    'يجب حساب تكلفة الطلب بنجاح قبل الإرسال': 'Delivery fee must be calculated before placing the order|Sipariş göndermeden önce teslimat ücreti hesaplanmalıdır',
    'أرباح اليوم': "Today's earnings|Bugünkü kazanç",
    'أهلاً بك': 'Welcome back|Hoş geldiniz',
    'اختر متجرك أو أرسل غرضاً سريعاً داخل مدينتك': 'Choose a store or send an item across your city|Şehrinizde bir mağaza seçin veya hızlıca bir paket gönderin',
    'التحضير': 'Preparing|Hazırlanıyor',
    'التفاصيل': 'Details|Detaylar',
    'العناوين': 'Addresses|Adresler',
    'تم إلغاء هذا الطلب': 'This order has been cancelled|Bu sipariş iptal edildi',
    'تم التعيين': 'Assigned|Atandı',
    'جاهز لتوصيل طلبك أو غرضك بأسرع مسار': 'Ready to deliver your order or parcel on the fastest route|Siparişinizi veya paketinizi en hızlı rotayla teslim etmeye hazır',
    'جديد': 'New|Yeni',
    'رحلات اليوم': "Today's trips|Bugünkü teslimatlar",
    'شبكة التوصيل المباشر': 'Live Delivery Network|Canlı Teslimat Ağı',
    'طلبات اليوم': "Today's orders|Bugünkü siparişler",
    'طلبك الحالي': 'Your active order|Aktif siparişiniz',
    'عرض الكل': 'View all|Tümünü gör',
    'في الطريق': 'On the way|Yolda',
    'لا توجد طلبات مطابقة للتصفية الحالية': 'No orders match the current filter|Mevcut filtreyle eşleşen sipariş yok',
    'ما الجديد في هذا التحديث؟': "What's new in this update?|Bu güncellemede neler yeni?",
    'مبيعات اليوم': "Today's revenue|Bugünkü ciro",
    'أريد عبوتين زيت وخبز إلى حي الشهباء': '2 bottles of oil and bread to Al-Shahba|Al-Shahba mahallesine 2 şişe yağ ve ekmek',
    'إرسال مفاتيح من المزة إلى المالكي': 'Send keys from Mazzeh to Malki|Mazzeh’den Malki’ye anahtar gönder',
    'اكتب طلبك وسيتم تجهيزه تلقائياً': 'Describe your order and it will be prepared automatically|Siparişinizi yazın, otomatik olarak hazırlansın',
    'المتجر': 'Store|Mağaza',
    'سريع': 'Fast|Hızlı',
    'طلب متجر': 'Store order|Mağaza siparişi',
    'كيف أتابع التوصيل المباشر؟': 'How do I track live delivery?|Canlı teslimatı nasıl takip edebilirim?',
    'لخّص مهامي الحالية': 'Summarize my current tasks|Mevcut görevlerimi özetle',
    'ما حالة طلباتي اليوم؟': "What is today's order status?|Bugünkü siparişlerimin durumu nedir?",
  };

  static const Map<String, Map<String, String>> _values = {
    'ar': {
      'welcomeTitle': 'أهلاً بك في دَرْب',
      'welcomeSubtitle': 'طريقك الأسهل لاكتشاف المتاجر وطلب ما تحتاجه',
      'featureStores': 'متاجر',
      'featureDelivery': 'توصيل',
      'featureNearby': 'على دربك',
      'phoneTitle': 'سجّل الدخول برقم هاتفك',
      'phoneSubtitle': 'سنرسل إليك رمز تحقق لمرة واحدة',
      'phoneLabel': 'رقم الهاتف السوري',
      'sendOtp': 'إرسال رمز التحقق',
      'or': 'أو المتابعة عبر',
      'google': 'المتابعة باستخدام Google',
      'secure': 'بياناتك محمية ونستخدم رقمك لتأكيد هويتك',
      'invalidPhone': 'أدخل رقمًا سوريًا صحيحًا يبدأ بـ 09 ويتكون من 10 أرقام',
      'networkError': 'تعذر إتمام الطلب. تحقق من اتصالك وحاول مجددًا.',
      'googleUnavailable': 'تسجيل Google غير مفعّل على الخادم حاليًا. استخدم رقم الهاتف.',
      'googleFailed': 'تعذر تسجيل الدخول باستخدام Google. حاول مجددًا.',
      'otpTitle': 'تحقق من رقمك',
      'otpSubtitle': 'أدخل رمز التحقق الذي وصلك برسالة نصية',
      'otpLabel': 'رمز التحقق',
      'nameLabel': 'الاسم (اختياري)',
      'verify': 'تأكيد الدخول',
      'changePhone': 'تغيير رقم الهاتف',
      'invalidOtp': 'أدخل رمز التحقق المكوّن من 6 أرقام',
      'languageTitle': 'لغة التطبيق',
      'languageSubtitle': 'اختر اللغة التي تريد استخدام دَرْب بها',
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
      'welcomeTitle': 'Welcome to DARB',
      'welcomeSubtitle': 'Your easier way to discover stores and order what you need',
      'featureStores': 'Stores',
      'featureDelivery': 'Delivery',
      'featureNearby': 'Nearby',
      'phoneTitle': 'Sign in with your phone',
      'phoneSubtitle': 'We will send you a one-time verification code',
      'phoneLabel': 'Syrian phone number',
      'sendOtp': 'Send verification code',
      'or': 'Or continue with',
      'google': 'Continue with Google',
      'secure': 'Your information is protected and your number verifies your identity',
      'invalidPhone': 'Enter a valid Syrian number starting with 09 and containing 10 digits',
      'networkError': 'Could not complete the request. Check your connection and try again.',
      'googleUnavailable': 'Google sign-in is not enabled on the server yet. Use your phone number.',
      'googleFailed': 'Google sign-in failed. Please try again.',
      'otpTitle': 'Verify your number',
      'otpSubtitle': 'Enter the verification code sent by SMS',
      'otpLabel': 'Verification code',
      'nameLabel': 'Name (optional)',
      'verify': 'Verify and continue',
      'changePhone': 'Change phone number',
      'invalidOtp': 'Enter the 6-digit verification code',
      'languageTitle': 'App language',
      'languageSubtitle': 'Choose the language you want to use in DARB',
      'languageSave': 'Save language',
      'languageSaved': 'App language saved',
      'languageSaving': 'Saving language',
      'languageArabic': 'Arabic',
      'languageEnglish': 'English',
      'languageTurkish': 'Turkish',
      'languageArabicNative': 'واجهة عربية كاملة واتجاه من اليمين إلى اليسار',
      'languageEnglishNative': 'English interface, left to right',
      'languageTurkishNative': 'Türkçe arayüz, soldan sağa',
    },
    'tr': {
      'welcomeTitle': "DARB'a hoş geldiniz",
      'welcomeSubtitle': 'İhtiyacınız olanı keşfetmenin ve sipariş etmenin kolay yolu',
      'featureStores': 'Mağazalar',
      'featureDelivery': 'Teslimat',
      'featureNearby': 'Yakınında',
      'phoneTitle': 'Telefon numaranızla giriş yapın',
      'phoneSubtitle': 'Size tek kullanımlık doğrulama kodu göndereceğiz',
      'phoneLabel': 'Suriye telefon numarası',
      'sendOtp': 'Doğrulama kodu gönder',
      'or': 'Veya şununla devam et',
      'google': 'Google ile devam et',
      'secure': 'Bilgileriniz korunur; numaranız kimliğinizi doğrulamak için kullanılır',
      'invalidPhone': '09 ile başlayan ve 10 rakam içeren geçerli bir Suriye numarası girin',
      'networkError': 'İşlem tamamlanamadı. Bağlantınızı kontrol edip tekrar deneyin.',
      'googleUnavailable': 'Google ile giriş henüz sunucuda etkin değil. Telefon numaranızı kullanın.',
      'googleFailed': 'Google ile giriş başarısız. Lütfen tekrar deneyin.',
      'otpTitle': 'Numaranızı doğrulayın',
      'otpSubtitle': 'SMS ile gönderilen doğrulama kodunu girin',
      'otpLabel': 'Doğrulama kodu',
      'nameLabel': 'Ad (isteğe bağlı)',
      'verify': 'Doğrula ve devam et',
      'changePhone': 'Telefon numarasını değiştir',
      'invalidOtp': '6 haneli doğrulama kodunu girin',
      'languageTitle': 'Uygulama dili',
      'languageSubtitle': 'DARB uygulamasında kullanmak istediğiniz dili seçin',
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

class _DarbLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _DarbLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en', 'tr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_DarbLocalizationsDelegate old) => false;
}
