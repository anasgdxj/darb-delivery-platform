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
