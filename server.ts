import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import {
  buildOperationalAssistantReply,
  calculateOrderTotals,
  canTransitionOrderStatus,
  clampRating,
  computeAdminStats,
  haversineKm,
  type OrderStatus,
  type PlatformOrder,
  type UserRole,
} from './lib/platform-logic.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
app.use(express.json({ limit: '1mb' }));

// Security headers (never emit X-Frame-Options so iframe preview works cleanly)
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('Referrer-Policy', 'no-referrer');
  const origin = req.headers.origin;
  if (
    origin &&
    (origin.includes('localhost') ||
      origin.includes('127.0.0.1') ||
      origin.endsWith('.run.app') ||
      origin.endsWith('.googleusercontent.com'))
  ) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
    res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type, Accept');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PATCH, PUT, DELETE, OPTIONS');
  }
  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }
  next();
});

interface CityRecord {
  id: string;
  code: string;
  countryCode: string;
  defaultCurrency: string;
  isActive: boolean;
  lat: number;
  lng: number;
  names: Array<{ locale: string; name: string }>;
}

const cities: CityRecord[] = [
  {
    id: 'city-dam',
    code: 'DAM',
    countryCode: 'SY',
    defaultCurrency: 'SYP',
    isActive: true,
    lat: 33.5138,
    lng: 36.2765,
    names: [
      { locale: 'ar', name: 'دمشق' },
      { locale: 'en', name: 'Damascus' },
      { locale: 'tr', name: 'Şam' },
    ],
  },
  {
    id: 'city-ale',
    code: 'ALE',
    countryCode: 'SY',
    defaultCurrency: 'SYP',
    isActive: true,
    lat: 36.2021,
    lng: 37.1343,
    names: [
      { locale: 'ar', name: 'حلب' },
      { locale: 'en', name: 'Aleppo' },
      { locale: 'tr', name: 'Halep' },
    ],
  },
  {
    id: 'city-hms',
    code: 'HMS',
    countryCode: 'SY',
    defaultCurrency: 'SYP',
    isActive: true,
    lat: 34.7324,
    lng: 36.7137,
    names: [
      { locale: 'ar', name: 'حمص' },
      { locale: 'en', name: 'Homs' },
      { locale: 'tr', name: 'Humus' },
    ],
  },
  {
    id: 'city-hma',
    code: 'HMA',
    countryCode: 'SY',
    defaultCurrency: 'SYP',
    isActive: true,
    lat: 35.1318,
    lng: 36.7578,
    names: [
      { locale: 'ar', name: 'حماة' },
      { locale: 'en', name: 'Hama' },
      { locale: 'tr', name: 'Hama' },
    ],
  },
  {
    id: 'city-lat',
    code: 'LAT',
    countryCode: 'SY',
    defaultCurrency: 'SYP',
    isActive: true,
    lat: 35.5317,
    lng: 35.7901,
    names: [
      { locale: 'ar', name: 'اللاذقية' },
      { locale: 'en', name: 'Latakia' },
      { locale: 'tr', name: 'Lazkiye' },
    ],
  },
];

let drivers = [
  {
    id: 'drv-1',
    status: 'PENDING',
    vehicleType: 'MOTORCYCLE',
    isOnline: false,
    createdAt: new Date(Date.now() - 1800000).toISOString(),
    user: { id: 'usr-11', name: 'سامر أحمد', phone: '+963933123456', email: 'samer@dazrevo.sy' },
    city: cities[0],
  },
  {
    id: 'drv-2',
    status: 'PENDING',
    vehicleType: 'CAR',
    isOnline: false,
    createdAt: new Date(Date.now() - 3600000).toISOString(),
    user: { id: 'usr-12', name: 'عمر خالد', phone: '+963944654321', email: 'omar@dazrevo.sy' },
    city: cities[1],
  },
  {
    id: 'drv-3',
    status: 'APPROVED',
    vehicleType: 'MOTORCYCLE',
    isOnline: true,
    createdAt: new Date(Date.now() - 86400000 * 5).toISOString(),
    user: { id: 'usr-13', name: 'حسن محمود', phone: '+963955667788', email: 'hasan@dazrevo.sy' },
    city: cities[0],
  },
];

let vendors = [
  {
    id: 'vnd-3',
    status: 'APPROVED',
    type: 'صيدلية ومستلزمات',
    category: 'pharmacy',
    isOpen: true,
    ratingAvg: 4.9,
    reviewsCount: 128,
    commercialRegNo: '774120',
    location: { address: 'المزة أوتستراد، دمشق', latitude: 33.5021, longitude: 36.2452 },
    translations: [
      { locale: 'ar', name: 'مركز الشفاء', description: 'مستلزمات عناية يومية وصحية وتوصيل سريع' },
      { locale: 'en', name: 'Al-Shifa Care Center', description: 'Daily wellness essentials & express dispatch' },
      { locale: 'tr', name: 'Al-Shifa Bakım Merkezi', description: 'Günlük sağlık ve hızlı teslimat' },
    ],
    cities: [{ city: cities[0] }],
    user: { id: 'usr-23', name: 'سارة العلي', phone: '+963911334455' },
    _count: { products: 4, orders: 64 },
  },
  {
    id: 'vnd-4',
    status: 'APPROVED',
    type: 'مطعم',
    category: 'restaurant',
    isOpen: true,
    ratingAvg: 4.8,
    reviewsCount: 214,
    commercialRegNo: '883210',
    location: { address: 'أبو رمانة، دمشق', latitude: 33.5162, longitude: 36.2715 },
    translations: [
      { locale: 'ar', name: 'دار الياسمين للمأكولات', description: 'أطباق دمشقية طازجة ومشويات مختارة' },
      { locale: 'en', name: 'Dar Al-Yasmin Kitchen', description: 'Fresh Damascene plates & signature grills' },
      { locale: 'tr', name: 'Dar Al-Yasmin Mutfağı', description: 'Taze Şam lezzetleri ve ızgaralar' },
    ],
    cities: [{ city: cities[0] }],
    user: { id: 'usr-24', name: 'طارق الحلبي', phone: '+963944118822' },
    _count: { products: 4, orders: 91 },
  },
  {
    id: 'vnd-5',
    status: 'APPROVED',
    type: 'سوبرماركت',
    category: 'grocery',
    isOpen: true,
    ratingAvg: 4.7,
    reviewsCount: 89,
    commercialRegNo: '519042',
    location: { address: 'الشهباء، حلب', latitude: 36.2151, longitude: 37.1312 },
    translations: [
      { locale: 'ar', name: 'أسواق النخبة', description: 'مواد تموينية وطازجة مع تغليف محكم' },
      { locale: 'en', name: 'Elite Fresh Market', description: 'Curated groceries & chilled pantry staples' },
      { locale: 'tr', name: 'Elite Taze Market', description: 'Günlük market ve taze ürünler' },
    ],
    cities: [{ city: cities[1] }],
    user: { id: 'usr-25', name: 'رامي حلاق', phone: '+963955443322' },
    _count: { products: 3, orders: 47 },
  },
  {
    id: 'vnd-1',
    status: 'PENDING',
    type: 'مطعم',
    category: 'restaurant',
    isOpen: true,
    ratingAvg: 0,
    reviewsCount: 0,
    commercialRegNo: '102938',
    location: { address: 'شارع بغداد، دمشق', latitude: 33.521, longitude: 36.292 },
    translations: [
      { locale: 'ar', name: 'مطعم الشام الأصيل', description: 'أطيب المأكولات الدمشقية التراثية' },
      { locale: 'en', name: 'Al-Sham Heritage', description: 'Traditional Damascene cuisine' },
      { locale: 'tr', name: 'Al-Sham Mutfağı', description: 'Geleneksel Şam yemekleri' },
    ],
    cities: [{ city: cities[0] }],
    user: { id: 'usr-21', name: 'أحمد الدمشقي', phone: '+963932112233' },
    _count: { products: 14, orders: 0 },
  },
  {
    id: 'vnd-2',
    status: 'PENDING',
    type: 'سوبرماركت',
    category: 'grocery',
    isOpen: true,
    ratingAvg: 0,
    reviewsCount: 0,
    commercialRegNo: '564738',
    location: { address: 'الجميلية، حلب', latitude: 36.204, longitude: 37.148 },
    translations: [
      { locale: 'ar', name: 'سوبرماركت البركة', description: 'مواد غذائية واستهلاكية متكاملة' },
      { locale: 'en', name: 'Al-Baraka Market', description: 'Everyday groceries & household essentials' },
      { locale: 'tr', name: 'Al-Baraka Market', description: 'Günlük gıda ve temel ihtiyaçlar' },
    ],
    cities: [{ city: cities[1] }],
    user: { id: 'usr-22', name: 'بلال الحلبي', phone: '+963944778899' },
    _count: { products: 42, orders: 0 },
  },
];

interface ProductRecord {
  id: string;
  vendorId: string;
  category: string;
  price: number;
  stock: number;
  isAvailable: boolean;
  translations: Array<{ locale: string; name: string; description: string }>;
}

const products: ProductRecord[] = [
  {
    id: 'prd-1',
    vendorId: 'vnd-3',
    category: 'عناية صحية',
    price: 18500,
    stock: 24,
    isAvailable: true,
    translations: [
      { locale: 'ar', name: 'حقيبة إسعافات أولية متكاملة', description: 'مجهزة للاستخدام المنزلي والرحلات' },
      { locale: 'en', name: 'Complete First Aid Kit', description: 'Compact home & travel medical kit' },
      { locale: 'tr', name: 'Tam İlk Yardım Çantası', description: 'Ev ve seyahat için tıbbi set' },
    ],
  },
  {
    id: 'prd-2',
    vendorId: 'vnd-3',
    category: 'عناية يومية',
    price: 12000,
    stock: 40,
    isAvailable: true,
    translations: [
      { locale: 'ar', name: 'فيتامين سي فوار (20 قرص)', description: 'مكمل يومي لدعم المناعة والنشاط' },
      { locale: 'en', name: 'Effervescent Vitamin C (20 Tabs)', description: 'Daily immunity & energy boost' },
      { locale: 'tr', name: 'Efervesan C Vitamini (20 Tablet)', description: 'Günlük bağışıklık desteği' },
    ],
  },
  {
    id: 'prd-3',
    vendorId: 'vnd-3',
    category: 'أجهزة قياس',
    price: 95000,
    stock: 6,
    isAvailable: true,
    translations: [
      { locale: 'ar', name: 'ميزان حرارة رقمي فوري', description: 'قياس دقيق بدون تلامس خلال ثانية' },
      { locale: 'en', name: 'Infrared Digital Thermometer', description: '1-second contactless precision' },
      { locale: 'tr', name: 'Temassız Dijital Termometre', description: '1 saniyede hassas ölçüm' },
    ],
  },
  {
    id: 'prd-4',
    vendorId: 'vnd-4',
    category: 'وجبات رئيسية',
    price: 38000,
    stock: 18,
    isAvailable: true,
    translations: [
      { locale: 'ar', name: 'وجبة مشاوي دمشقية مشكلة', description: 'شقف وكباب وشيش مع مقبلات وخبز ساخن' },
      { locale: 'en', name: 'Signature Damascene Grill Platter', description: 'Mixed skewers, appetizers & warm bread' },
      { locale: 'tr', name: 'Özel Şam Izgara Tabağı', description: 'Karışık kebap, mezeler ve sıcak ekmek' },
    ],
  },
  {
    id: 'prd-5',
    vendorId: 'vnd-4',
    category: 'مقبلات',
    price: 14500,
    stock: 30,
    isAvailable: true,
    translations: [
      { locale: 'ar', name: 'حمص بالطحينة وزيت الزيتون', description: 'محضّر يومياً مع صنوبر محمص' },
      { locale: 'en', name: 'Artisan Hummus & Olive Oil', description: 'Fresh daily with toasted pine nuts' },
      { locale: 'tr', name: 'Zeytinyağlı Özel Humus', description: 'Kavrulmuş çam fıstıklı günlük humus' },
    ],
  },
  {
    id: 'prd-6',
    vendorId: 'vnd-4',
    category: 'عصائر',
    price: 9500,
    stock: 25,
    isAvailable: true,
    translations: [
      { locale: 'ar', name: 'ليموناضة بالنعناع البري', description: 'عصير طبيعي بارد ومنعش' },
      { locale: 'en', name: 'Wild Mint Fresh Lemonade', description: 'Cold-pressed citrus with fresh mint' },
      { locale: 'tr', name: 'Taze Naneli Limonata', description: 'Soğuk sıkım doğal limonata' },
    ],
  },
  {
    id: 'prd-7',
    vendorId: 'vnd-5',
    category: 'مواد غذائية',
    price: 26000,
    stock: 15,
    isAvailable: true,
    translations: [
      { locale: 'ar', name: 'زيت زيتون بكر ممتاز (1 لتر)', description: 'عصرة أولى من بساتين الساحل' },
      { locale: 'en', name: 'Extra Virgin Olive Oil (1L)', description: 'First cold press coastal harvest' },
      { locale: 'tr', name: 'Sızma Zeytinyağı (1L)', description: 'İlk soğuk sıkım hasat' },
    ],
  },
  {
    id: 'prd-8',
    vendorId: 'vnd-5',
    category: 'قهوة ومشروبات',
    price: 22000,
    stock: 22,
    isAvailable: true,
    translations: [
      { locale: 'ar', name: 'بن عربي محمص بالهيل (250غ)', description: 'تحميص متوسط طازج يومياً' },
      { locale: 'en', name: 'Cardamom Arabic Coffee (250g)', description: 'Medium roast ground fresh daily' },
      { locale: 'tr', name: 'Kakuleli Arap Kahvesi (250g)', description: 'Günlük taze orta kavrum' },
    ],
  },
];

let users = [
  { id: 'admin-user-1', name: 'مدير دازريفو', email: 'admin@dazrevo.sy', phone: '+963930000001', role: 'ADMIN' as UserRole, isActive: true, createdAt: new Date(Date.now() - 86400000 * 30).toISOString() },
  { id: 'usr-13', name: 'حسن محمود', email: 'hasan@dazrevo.sy', phone: '+963955667788', role: 'DRIVER' as UserRole, isActive: true, createdAt: new Date(Date.now() - 86400000 * 14).toISOString() },
  { id: 'usr-23', name: 'سارة العلي', email: 'sara@dazrevo.sy', phone: '+963911334455', role: 'VENDOR' as UserRole, isActive: true, createdAt: new Date(Date.now() - 86400000 * 10).toISOString() },
  { id: 'usr-31', name: 'محمد علي', email: 'mohammed@dazrevo.sy', phone: '+963911223344', role: 'CUSTOMER' as UserRole, isActive: true, createdAt: new Date(Date.now() - 86400000 * 4).toISOString() },
  { id: 'usr-32', name: 'فاطمة أحمد', email: null, phone: '+963922334455', role: 'CUSTOMER' as UserRole, isActive: true, createdAt: new Date(Date.now() - 86400000 * 2).toISOString() },
];

let deliveryZones = [
  { id: 'zone-1', cityId: 'city-dam', name: 'دمشق المركزية والمزة', feeBase: 5000, feePerKm: 1200, minOrder: 15000, city: cities[0] },
  { id: 'zone-2', cityId: 'city-ale', name: 'حلب الكبرى والشهباء', feeBase: 4500, feePerKm: 1000, minOrder: 12000, city: cities[1] },
  { id: 'zone-3', cityId: 'city-hms', name: 'حمص الوسطى والوعر', feeBase: 4000, feePerKm: 900, minOrder: 10000, city: cities[2] },
];

const orders: PlatformOrder[] = [
  {
    id: 'ord-101',
    orderNumber: '1001',
    status: 'PENDING',
    type: 'VENDOR_ORDER',
    subtotal: 37000,
    deliveryFee: 5500,
    total: 42500,
    currency: 'SYP',
    createdAt: new Date(Date.now() - 1500000).toISOString(),
    pickupAddress: 'المزة أوتستراد — مركز الشفاء، دمشق',
    pickupLatitude: 33.5021,
    pickupLongitude: 36.2452,
    address: {
      label: 'المنزل · المالكي',
      details: 'شارع عبد المنعم رياض، بناء 14، الطابق الثالث',
      latitude: 33.5194,
      longitude: 36.2718,
    },
    items: [
      { productId: 'prd-1', nameSnapshot: 'حقيبة إسعافات أولية متكاملة', quantity: 1, unitPrice: 18500 },
      { productId: 'prd-2', nameSnapshot: 'فيتامين سي فوار (20 قرص)', quantity: 1, unitPrice: 12000 },
    ],
    city: cities[0],
    vendor: { id: 'vnd-3', translations: [{ locale: 'ar', name: 'مركز الشفاء' }] },
    customer: { id: 'usr-31', name: 'محمد علي', phone: '+963911223344' },
    driver: null,
    payment: { status: 'PENDING', method: 'CASH_ON_DELIVERY' },
  },
  {
    id: 'ord-102',
    orderNumber: '1002',
    status: 'PICKED_UP',
    type: 'PEER_DELIVERY',
    subtotal: 0,
    deliveryFee: 18000,
    total: 18000,
    currency: 'SYP',
    createdAt: new Date(Date.now() - 4800000).toISOString(),
    pickupAddress: 'ساحة سعد الله الجابري، حلب',
    pickupLatitude: 36.2054,
    pickupLongitude: 37.1489,
    address: {
      label: 'المكتب · الموكامبو',
      details: 'شارع النيل، قرب برج الأطباء',
      latitude: 36.2185,
      longitude: 37.1225,
    },
    items: [{ nameSnapshot: 'طرد مستندات رسمية ومفاتيح', quantity: 1, unitPrice: 18000 }],
    city: cities[1],
    vendor: null,
    customer: { id: 'usr-32', name: 'فاطمة أحمد', phone: '+963922334455' },
    driver: { id: 'drv-3', user: { name: 'حسن محمود', phone: '+963955667788' } },
    payment: { status: 'PENDING', method: 'CASH_ON_DELIVERY' },
  },
  {
    id: 'ord-103',
    orderNumber: '1003',
    status: 'DELIVERED',
    type: 'VENDOR_ORDER',
    subtotal: 61500,
    deliveryFee: 5500,
    total: 67000,
    currency: 'SYP',
    createdAt: new Date(Date.now() - 18000000).toISOString(),
    pickupAddress: 'أبو رمانة — دار الياسمين، دمشق',
    pickupLatitude: 33.5162,
    pickupLongitude: 36.2715,
    address: {
      label: 'العمل · البرامكة',
      details: 'مجمع الأعمال، الطابق الثاني',
      latitude: 33.5082,
      longitude: 36.2891,
    },
    items: [
      { productId: 'prd-4', nameSnapshot: 'وجبة مشاوي دمشقية مشكلة', quantity: 1, unitPrice: 38000 },
      { productId: 'prd-5', nameSnapshot: 'حمص بالطحينة وزيت الزيتون', quantity: 1, unitPrice: 14500 },
      { productId: 'prd-6', nameSnapshot: 'ليموناضة بالنعناع البري', quantity: 1, unitPrice: 9500 },
    ],
    city: cities[0],
    vendor: { id: 'vnd-4', translations: [{ locale: 'ar', name: 'دار الياسمين للمأكولات' }] },
    customer: { id: 'usr-31', name: 'ليان كريم', phone: '+963933998877' },
    driver: { id: 'drv-3', user: { name: 'حسن محمود', phone: '+963955667788' } },
    payment: { status: 'PAID', method: 'CASH_ON_DELIVERY' },
  },
];

let notifications = [
  {
    id: 'ntf-1',
    title: 'تم استلام طلبك #1001',
    body: 'الطلب قيد المراجعة من مركز الشفاء وسيتم إشعارك عند بدء التجهيز.',
    isRead: false,
    orderId: 'ord-101',
    createdAt: new Date(Date.now() - 900000).toISOString(),
  },
  {
    id: 'ntf-2',
    title: 'المندوب في الطريق إليك',
    body: 'حسن محمود استلم الطرد #1002 وهو متجه إلى نقطة التسليم.',
    isRead: false,
    orderId: 'ord-102',
    createdAt: new Date(Date.now() - 2400000).toISOString(),
  },
  {
    id: 'ntf-3',
    title: 'تم تسليم الطلب #1003 بنجاح',
    body: 'شكراً لاستخدامك دازريفو. يمكنك تقييم التجربة أو إعادة الطلب بضغطة واحدة.',
    isRead: true,
    orderId: 'ord-103',
    createdAt: new Date(Date.now() - 16000000).toISOString(),
  },
];

const customerAddresses = [
  {
    id: 'addr-1',
    label: 'المنزل · المالكي',
    details: 'شارع عبد المنعم رياض، بناء 14، الطابق الثالث',
    cityId: 'city-dam',
    latitude: 33.5194,
    longitude: 36.2718,
    hasLocation: true,
  },
  {
    id: 'addr-2',
    label: 'العمل · البرامكة',
    details: 'مجمع الأعمال، الطابق الثاني',
    cityId: 'city-dam',
    latitude: 33.5082,
    longitude: 36.2891,
    hasLocation: true,
  },
];

let platformSettings = {
  commissionPercent: 10,
  defaultCurrency: 'SYP',
  peerDeliveryEnabled: true,
  aiAssistantEnabled: true,
  maintenanceMode: false,
  supportContact: '+963930000001',
};

const auditLogs = [
  {
    id: 'log-1',
    action: 'VENDOR_STATUS_UPDATED',
    targetType: 'Vendor',
    targetId: 'vnd-3',
    actorRole: 'ADMIN',
    actor: { name: 'مدير دازريفو', email: 'admin@dazrevo.sy' },
    metadata: { status: 'APPROVED' },
    createdAt: new Date(Date.now() - 86400000).toISOString(),
  },
];

function recordAudit(action: string, targetType: string, targetId: string, metadata: Record<string, unknown>) {
  auditLogs.unshift({
    id: `log-${Date.now()}`,
    action,
    targetType,
    targetId,
    actorRole: 'ADMIN',
    actor: { name: 'مدير دازريفو', email: 'admin@dazrevo.sy' },
    metadata,
    createdAt: new Date().toISOString(),
  });
}

function getPreviewRole(req: express.Request): UserRole | null {
  const auth = req.headers.authorization || '';
  if (!auth.startsWith('Bearer darb_preview_')) return null;
  if (auth.includes('_driver')) return 'DRIVER';
  if (auth.includes('_vendor')) return 'VENDOR';
  if (auth.includes('_customer')) return 'CUSTOMER';
  return 'ADMIN';
}

function requirePreviewAuth(req: express.Request, res: express.Response, next: express.NextFunction) {
  const role = getPreviewRole(req);
  if (!role) {
    return res.status(401).json({ message: 'يرجى تسجيل الدخول للمتابعة' });
  }
  (req as any).previewRole = role;
  next();
}

function requirePreviewAdmin(req: express.Request, res: express.Response, next: express.NextFunction) {
  const role = getPreviewRole(req);
  if (role !== 'ADMIN') {
    return res.status(401).json({ message: 'يرجى تسجيل الدخول بحساب الإدارة للمتابعة' });
  }
  next();
}

function getCurrentUserForRole(role: UserRole) {
  if (role === 'DRIVER') return users.find((u) => u.role === 'DRIVER') || users[1];
  if (role === 'VENDOR') return users.find((u) => u.role === 'VENDOR') || users[2];
  if (role === 'CUSTOMER') return users.find((u) => u.role === 'CUSTOMER') || users[3];
  return users[0];
}

// Health endpoints
app.get('/api/v1/health', (_req, res) => {
  res.json({ status: 'ok', service: 'dazrevo-preview', timestamp: new Date().toISOString() });
});
app.get('/api/v1/healthz', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});
app.get('/api/v1/readyz', (_req, res) => {
  res.json({ status: 'ready', mode: 'preview', timestamp: new Date().toISOString() });
});

// Public cities & stores endpoints
app.get('/api/v1/cities', (_req, res) => {
  res.json(cities.filter((c) => c.isActive));
});

app.get('/api/v1/vendors', (req, res) => {
  const cityId = String(req.query.cityId || '');
  const q = String(req.query.q || '').trim().toLowerCase();
  const approved = vendors.filter((v) => v.status === 'APPROVED');
  const filtered = approved.filter((v) => {
    if (cityId && !v.cities.some((c) => c.city.id === cityId)) return false;
    if (q) {
      const text = `${v.type} ${v.translations.map((t) => `${t.name} ${t.description}`).join(' ')}`.toLowerCase();
      if (!text.includes(q)) return false;
    }
    return true;
  });
  res.json(filtered);
});

app.get('/api/v1/vendors/:id/products', (req, res) => {
  const vendor = vendors.find((v) => v.id === req.params.id);
  if (!vendor) return res.status(404).json({ message: 'المتجر غير موجود' });
  res.json({
    vendor,
    products: products.filter((p) => p.vendorId === vendor.id),
  });
});

// Auth endpoints (Google, Admin Preview, Multi-Role OTP & Demo Switch)
app.post('/api/v1/auth/google', (req, res) => {
  const requestedRole = String(req.body?.role || 'ADMIN').toUpperCase() as UserRole;
  const role: UserRole = ['CUSTOMER', 'DRIVER', 'VENDOR', 'ADMIN'].includes(requestedRole) ? requestedRole : 'ADMIN';
  const suffix = role.toLowerCase();
  const user = getCurrentUserForRole(role);
  res.json({
    tokens: {
      accessToken: `darb_preview_access_token_${suffix}`,
      refreshToken: `darb_preview_refresh_token_${suffix}`,
    },
    user,
  });
});

app.post('/api/v1/auth/preview-admin', (_req, res) => {
  res.json({
    tokens: {
      accessToken: 'darb_preview_access_token_admin',
      refreshToken: 'darb_preview_refresh_token_admin',
    },
    user: users[0],
  });
});

app.post('/api/v1/auth/preview-role', (req, res) => {
  const requestedRole = String(req.body?.role || 'CUSTOMER').toUpperCase() as UserRole;
  const role: UserRole = ['CUSTOMER', 'DRIVER', 'VENDOR', 'ADMIN'].includes(requestedRole) ? requestedRole : 'CUSTOMER';
  const suffix = role.toLowerCase();
  res.json({
    tokens: {
      accessToken: `darb_preview_access_token_${suffix}`,
      refreshToken: `darb_preview_refresh_token_${suffix}`,
    },
    user: getCurrentUserForRole(role),
  });
});

app.post('/api/v1/auth/otp/request', (req, res) => {
  const phone = String(req.body?.phone || '').trim();
  if (!phone || phone.length < 8) {
    return res.status(400).json({ message: 'يرجى إدخال رقم هاتف سوري صالح' });
  }
  res.json({ sent: true, phone, previewOtp: '123456' });
});

app.post('/api/v1/auth/otp/verify', (req, res) => {
  const code = String(req.body?.code || '').trim();
  const phone = String(req.body?.phone || '+963911223344').trim();
  const name = String(req.body?.name || '').trim();
  const requestedRole = String(req.body?.role || 'CUSTOMER').toUpperCase() as UserRole;
  const role: UserRole = ['CUSTOMER', 'DRIVER', 'VENDOR', 'ADMIN'].includes(requestedRole) ? requestedRole : 'CUSTOMER';

  if (!/^\d{6}$/.test(code)) {
    return res.status(400).json({ message: 'رمز التحقق يجب أن يتكون من 6 أرقام' });
  }

  const user = getCurrentUserForRole(role);
  if (name) user.name = name;
  if (phone) user.phone = phone;
  const suffix = role.toLowerCase();

  res.json({
    tokens: {
      accessToken: `darb_preview_access_token_${suffix}`,
      refreshToken: `darb_preview_refresh_token_${suffix}`,
    },
    user,
  });
});

app.get('/api/v1/auth/me', requirePreviewAuth, (req, res) => {
  const role = (req as any).previewRole as UserRole;
  res.json(getCurrentUserForRole(role));
});

app.patch('/api/v1/auth/profile', requirePreviewAuth, (req, res) => {
  const role = (req as any).previewRole as UserRole;
  const user = getCurrentUserForRole(role);
  if (req.body?.name) user.name = String(req.body.name).trim();
  if (req.body?.email !== undefined) user.email = String(req.body.email).trim() || null;
  res.json(user);
});

app.post('/api/v1/auth/refresh', (req, res) => {
  const refresh = String(req.body?.refreshToken || '');
  const suffix = refresh.includes('_driver')
    ? 'driver'
    : refresh.includes('_vendor')
      ? 'vendor'
      : refresh.includes('_customer')
        ? 'customer'
        : 'admin';
  res.json({
    accessToken: `darb_preview_access_token_${suffix}`,
    refreshToken: `darb_preview_refresh_token_${suffix}`,
  });
});

app.post('/api/v1/auth/logout', (_req, res) => {
  res.json({ success: true });
});

// AI Role Assistant (shared across Admin, Customer, Driver, Vendor)
app.post('/api/v1/ai/assistant/ask', requirePreviewAuth, (req, res) => {
  const message = String(req.body?.message || '').trim();
  if (message.length < 2) {
    return res.status(400).json({ message: 'يرجى كتابة رسالة واضحة للمساعد الذكي' });
  }
  const role = (req as any).previewRole as UserRole;
  const snapshot = computeAdminStats({
    usersCount: users.length,
    vendors,
    drivers,
    cities,
    orders,
  });
  res.json(buildOperationalAssistantReply(message, role, snapshot));
});

// Customer Addresses, Orders & Peer Delivery
app.get('/api/v1/addresses', requirePreviewAuth, (_req, res) => {
  res.json(customerAddresses);
});

app.post('/api/v1/addresses', requirePreviewAuth, (req, res) => {
  const label = String(req.body?.label || '').trim();
  const details = String(req.body?.details || '').trim();
  if (!label || !details) return res.status(400).json({ message: 'أدخل اسم العنوان والتفاصيل' });
  const created = {
    id: `addr-${Date.now()}`,
    label,
    details,
    cityId: String(req.body?.cityId || 'city-dam'),
    latitude: Number(req.body?.latitude || 33.515),
    longitude: Number(req.body?.longitude || 36.278),
    hasLocation: true,
  };
  customerAddresses.unshift(created);
  res.status(201).json(created);
});

app.delete('/api/v1/addresses/:id', requirePreviewAuth, (req, res) => {
  const before = customerAddresses.length;
  const idx = customerAddresses.findIndex((a) => a.id === req.params.id);
  if (idx === -1) return res.status(404).json({ message: 'العنوان غير موجود' });
  customerAddresses.splice(idx, 1);
  res.json({ deleted: before !== customerAddresses.length });
});

app.get('/api/v1/orders/mine', requirePreviewAuth, (_req, res) => {
  res.json(orders);
});

app.post('/api/v1/orders', requirePreviewAuth, (req, res) => {
  const vendor = vendors.find((v) => v.id === req.body?.vendorId);
  if (!vendor) return res.status(400).json({ message: 'اختر متجراً صالحاً' });
  const reqItems = Array.isArray(req.body?.items) ? req.body.items : [];
  if (!reqItems.length) return res.status(400).json({ message: 'السلة فارغة' });

  const resolvedItems = reqItems
    .map((entry: any) => {
      const p = products.find((pr) => pr.id === entry.productId);
      if (!p) return null;
      return {
        productId: p.id,
        nameSnapshot: p.translations[0]?.name || 'منتج',
        quantity: Math.max(1, Number(entry.quantity || 1)),
        unitPrice: p.price,
      };
    })
    .filter(Boolean) as Array<{ productId: string; nameSnapshot: string; quantity: number; unitPrice: number }>;

  if (!resolvedItems.length) return res.status(400).json({ message: 'لا توجد منتجات صالحة في الطلب' });

  const addr = customerAddresses.find((a) => a.id === req.body?.addressId) || customerAddresses[0];
  const city = vendor.cities[0]?.city || cities[0];
  const zone = deliveryZones.find((z) => z.cityId === city.id) || deliveryZones[0];
  const distKm = haversineKm(vendor.location.latitude, vendor.location.longitude, addr.latitude, addr.longitude);
  const totals = calculateOrderTotals(resolvedItems, zone.feeBase, zone.feePerKm, distKm);
  const customer = getCurrentUserForRole('CUSTOMER');

  const created: PlatformOrder = {
    id: `ord-${Date.now()}`,
    orderNumber: String(1001 + orders.length),
    status: 'PENDING',
    type: 'VENDOR_ORDER',
    subtotal: totals.subtotal,
    deliveryFee: totals.deliveryFee,
    total: totals.total,
    currency: city.defaultCurrency,
    createdAt: new Date().toISOString(),
    pickupAddress: vendor.location.address,
    pickupLatitude: vendor.location.latitude,
    pickupLongitude: vendor.location.longitude,
    address: {
      label: addr.label,
      details: addr.details,
      latitude: addr.latitude,
      longitude: addr.longitude,
    },
    items: resolvedItems,
    city,
    vendor: { id: vendor.id, translations: vendor.translations },
    customer: { id: customer.id, name: customer.name, phone: customer.phone },
    driver: null,
    payment: { status: 'PENDING', method: 'CASH_ON_DELIVERY' },
    notes: req.body?.notes ? String(req.body.notes).trim() : undefined,
    scheduledFor: req.body?.scheduledFor ? String(req.body.scheduledFor).trim() : undefined,
    rating: null,
  };

  orders.unshift(created);
  notifications.unshift({
    id: `ntf-${Date.now()}`,
    title: `تم إنشاء الطلب #${created.orderNumber}`,
    body: `طلبك من ${vendor.translations[0].name} بقيمة ${created.total.toLocaleString('en-US')} ل.س قيد المراجعة.`,
    isRead: false,
    orderId: created.id,
    createdAt: new Date().toISOString(),
  });
  res.status(201).json(created);
});

app.post('/api/v1/orders/peer', requirePreviewAuth, (req, res) => {
  const pickupAddress = String(req.body?.pickupAddress || '').trim();
  const dropoffDetails = String(req.body?.dropoffAddress || '').trim();
  const itemDescription = String(req.body?.description || '').trim();
  const fare = Math.max(5000, Number(req.body?.offeredFare || 15000));
  if (!pickupAddress || !dropoffDetails || !itemDescription) {
    return res.status(400).json({ message: 'أدخل وصف الغرض ونقطتي الاستلام والتسليم' });
  }
  const city = cities.find((c) => c.id === req.body?.cityId) || cities[0];
  const customer = getCurrentUserForRole('CUSTOMER');
  const created: PlatformOrder = {
    id: `ord-${Date.now()}`,
    orderNumber: String(1001 + orders.length),
    status: 'PENDING',
    type: 'PEER_DELIVERY',
    subtotal: 0,
    deliveryFee: fare,
    total: fare,
    currency: city.defaultCurrency,
    createdAt: new Date().toISOString(),
    pickupAddress,
    pickupLatitude: Number(req.body?.pickupLatitude || city.lat - 0.009),
    pickupLongitude: Number(req.body?.pickupLongitude || city.lng - 0.012),
    address: {
      label: 'تسليم مستقل',
      details: dropoffDetails,
      latitude: Number(req.body?.dropoffLatitude || city.lat + 0.011),
      longitude: Number(req.body?.dropoffLongitude || city.lng + 0.015),
    },
    items: [{ nameSnapshot: itemDescription, quantity: 1, unitPrice: fare }],
    city,
    vendor: null,
    customer: { id: customer.id, name: customer.name, phone: customer.phone },
    driver: null,
    payment: { status: 'PENDING', method: 'CASH_ON_DELIVERY' },
    notes: req.body?.notes ? String(req.body.notes).trim() : undefined,
    scheduledFor: req.body?.scheduledFor ? String(req.body.scheduledFor).trim() : undefined,
    rating: null,
  };
  orders.unshift(created);
  notifications.unshift({
    id: `ntf-${Date.now()}`,
    title: `تم بث طلب التوصيل المستقل #${created.orderNumber}`,
    body: `تم إرسال الطلب إلى المناديب المتاحين في ${city.names[0].name} بأجرة ${fare.toLocaleString('en-US')} ل.س.`,
    isRead: false,
    orderId: created.id,
    createdAt: new Date().toISOString(),
  });
  res.status(201).json(created);
});

app.patch('/api/v1/orders/:id/cancel', requirePreviewAuth, (req, res) => {
  const order = orders.find((o) => o.id === req.params.id);
  if (!order) return res.status(404).json({ message: 'الطلب غير موجود' });
  if (!canTransitionOrderStatus('CUSTOMER', order.status, 'CANCELLED')) {
    return res.status(400).json({ message: 'لا يمكن إلغاء الطلب في هذه المرحلة' });
  }
  order.status = 'CANCELLED';
  res.json(order);
});

app.post('/api/v1/orders/:id/rating', requirePreviewAuth, (req, res) => {
  const order = orders.find((o) => o.id === req.params.id);
  if (!order) return res.status(404).json({ message: 'الطلب غير موجود' });
  if (order.status !== 'DELIVERED') {
    return res.status(400).json({ message: 'يمكن التقييم فقط بعد اكتمال التسليم' });
  }
  const stars = clampRating(Number(req.body?.stars || 5));
  const comment = String(req.body?.comment || '').trim();
  order.rating = { stars, comment, createdAt: new Date().toISOString() };
  notifications.unshift({
    id: `ntf-${Date.now()}`,
    title: `تم استلام تقييم الطلب #${order.orderNumber}`,
    body: `تقييم ${stars}/5 نجوم${comment ? ' — ' + comment : ''}`,
    isRead: false,
    orderId: order.id,
    createdAt: new Date().toISOString(),
  });
  res.json(order);
});

// Notifications
app.get('/api/v1/notifications', requirePreviewAuth, (_req, res) => {
  res.json(notifications);
});
app.post('/api/v1/notifications/read-all', requirePreviewAuth, (_req, res) => {
  notifications = notifications.map((n) => ({ ...n, isRead: true }));
  res.json({ success: true });
});

// Driver Dashboard & Dispatch
app.get('/api/v1/driver/dashboard', requirePreviewAuth, (_req, res) => {
  const activeDriver = drivers.find((d) => d.id === 'drv-3') || drivers[2];
  const availableOrders = orders.filter(
    (o) => !o.driver && (o.status === 'READY' || (o.type === 'PEER_DELIVERY' && o.status === 'PENDING')),
  );
  const myOrders = orders.filter((o) => o.driver?.id === activeDriver.id);
  const earnings = myOrders
    .filter((o) => o.status === 'DELIVERED')
    .reduce((sum, o) => sum + o.deliveryFee, 0);
  res.json({
    driver: activeDriver,
    stats: {
      earnings,
      completedTrips: myOrders.filter((o) => o.status === 'DELIVERED').length,
      activeTrips: myOrders.filter((o) => !['DELIVERED', 'CANCELLED'].includes(o.status)).length,
      acceptanceRate: 96,
    },
    availableOrders,
    myOrders,
  });
});

app.patch('/api/v1/driver/availability', requirePreviewAuth, (req, res) => {
  const activeDriver = drivers.find((d) => d.id === 'drv-3') || drivers[2];
  activeDriver.isOnline = Boolean(req.body?.isOnline);
  res.json(activeDriver);
});

app.post('/api/v1/driver/orders/:id/accept', requirePreviewAuth, (req, res) => {
  const order = orders.find((o) => o.id === req.params.id);
  if (!order) return res.status(404).json({ message: 'الطلب غير موجود' });
  if (order.driver) return res.status(409).json({ message: 'تم قبول الطلب مسبقاً من سائق آخر' });
  const activeDriver = drivers.find((d) => d.id === 'drv-3') || drivers[2];
  order.driver = { id: activeDriver.id, user: { name: activeDriver.user.name, phone: activeDriver.user.phone } };
  order.status = 'ASSIGNED';
  notifications.unshift({
    id: `ntf-${Date.now()}`,
    title: `تم تعيين المندوب للطلب #${order.orderNumber}`,
    body: `${activeDriver.user.name} قبل توصيل طلبك وسيتوجه للاستلام.`,
    isRead: false,
    orderId: order.id,
    createdAt: new Date().toISOString(),
  });
  res.json(order);
});

app.patch('/api/v1/driver/orders/:id/status', requirePreviewAuth, (req, res) => {
  const order = orders.find((o) => o.id === req.params.id);
  if (!order) return res.status(404).json({ message: 'الطلب غير موجود' });
  const next = String(req.body?.status || '') as OrderStatus;
  if (!canTransitionOrderStatus('DRIVER', order.status, next)) {
    return res.status(400).json({ message: 'انتقال الحالة غير مسموح للسائق' });
  }
  order.status = next;
  if (next === 'DELIVERED') {
    order.payment.status = 'PAID';
    if (req.body?.deliveryProofNote) {
      order.deliveryProofNote = String(req.body.deliveryProofNote).trim();
    }
  }
  res.json(order);
});

// Vendor Dashboard, Orders & Inventory
app.get('/api/v1/vendor/dashboard', requirePreviewAuth, (_req, res) => {
  const activeVendor = vendors.find((v) => v.id === 'vnd-3') || vendors[0];
  const vendorOrders = orders.filter((o) => o.type === 'VENDOR_ORDER' && o.vendor?.id === activeVendor.id);
  const vendorProducts = products.filter((p) => p.vendorId === activeVendor.id);
  res.json({
    vendor: activeVendor,
    stats: {
      activeOrders: vendorOrders.filter((o) => !['DELIVERED', 'CANCELLED'].includes(o.status)).length,
      deliveredOrders: vendorOrders.filter((o) => o.status === 'DELIVERED').length,
      revenue: vendorOrders.filter((o) => o.status !== 'CANCELLED').reduce((s, o) => s + o.subtotal, 0),
      productCount: vendorProducts.length,
    },
    orders: vendorOrders,
    products: vendorProducts,
  });
});

app.patch('/api/v1/vendor/toggle-open', requirePreviewAuth, (req, res) => {
  const activeVendor = vendors.find((v) => v.id === 'vnd-3') || vendors[0];
  activeVendor.isOpen = Boolean(req.body?.isOpen);
  res.json(activeVendor);
});

app.patch('/api/v1/vendor/orders/:id/status', requirePreviewAuth, (req, res) => {
  const order = orders.find((o) => o.id === req.params.id);
  if (!order) return res.status(404).json({ message: 'الطلب غير موجود' });
  const next = String(req.body?.status || '') as OrderStatus;
  if (!canTransitionOrderStatus('VENDOR', order.status, next)) {
    return res.status(400).json({ message: 'انتقال الحالة غير مسموح للمتجر' });
  }
  order.status = next;
  res.json(order);
});

app.post('/api/v1/vendor/products', requirePreviewAuth, (req, res) => {
  const nameAr = String(req.body?.name || '').trim();
  const price = Math.max(500, Number(req.body?.price || 0));
  const stock = Math.max(0, Number(req.body?.stock || 10));
  const category = String(req.body?.category || 'عام').trim();
  if (!nameAr) return res.status(400).json({ message: 'أدخل اسم المنتج' });
  const created: ProductRecord = {
    id: `prd-${Date.now()}`,
    vendorId: 'vnd-3',
    category,
    price,
    stock,
    isAvailable: true,
    translations: [
      { locale: 'ar', name: nameAr, description: String(req.body?.description || 'منتج متجر محلي') },
      { locale: 'en', name: nameAr, description: 'Local merchant catalog item' },
      { locale: 'tr', name: nameAr, description: 'Yerel mağaza ürünü' },
    ],
  };
  products.unshift(created);
  res.status(201).json(created);
});

app.patch('/api/v1/vendor/products/:id', requirePreviewAuth, (req, res) => {
  const prd = products.find((p) => p.id === req.params.id);
  if (!prd) return res.status(404).json({ message: 'المنتج غير موجود' });
  if (req.body?.isAvailable !== undefined) prd.isAvailable = Boolean(req.body.isAvailable);
  if (req.body?.stock !== undefined) prd.stock = Math.max(0, Number(req.body.stock));
  if (req.body?.price !== undefined) prd.price = Math.max(500, Number(req.body.price));
  res.json(prd);
});

// Admin Stats
app.get('/api/v1/admin/stats', requirePreviewAdmin, (_req, res) => {
  res.json(
    computeAdminStats({
      usersCount: users.length,
      vendors,
      drivers,
      cities,
      orders,
    }),
  );
});

// Drivers
app.get('/api/v1/admin/drivers/pending', requirePreviewAdmin, (_req, res) => {
  res.json(drivers.filter((d) => d.status === 'PENDING'));
});
app.get('/api/v1/admin/drivers', requirePreviewAdmin, (req, res) => {
  const status = String(req.query.status || '');
  res.json(status ? drivers.filter((d) => d.status === status) : drivers);
});
app.patch('/api/v1/admin/drivers/:id/status', requirePreviewAdmin, (req, res) => {
  const target = drivers.find((d) => d.id === req.params.id);
  if (!target) return res.status(404).json({ message: 'السائق غير موجود' });
  target.status = String(req.body?.status || target.status);
  if (target.status !== 'APPROVED') target.isOnline = false;
  recordAudit('DRIVER_STATUS_UPDATED', 'Driver', target.id, { status: target.status });
  res.json(target);
});

// Vendors
app.get('/api/v1/admin/vendors/pending', requirePreviewAdmin, (_req, res) => {
  res.json(vendors.filter((v) => v.status === 'PENDING'));
});
app.get('/api/v1/admin/vendors', requirePreviewAdmin, (req, res) => {
  const status = String(req.query.status || '');
  res.json(status ? vendors.filter((v) => v.status === status) : vendors);
});
app.patch('/api/v1/admin/vendors/:id/status', requirePreviewAdmin, (req, res) => {
  const target = vendors.find((v) => v.id === req.params.id);
  if (!target) return res.status(404).json({ message: 'المتجر غير موجود' });
  target.status = String(req.body?.status || target.status);
  recordAudit('VENDOR_STATUS_UPDATED', 'Vendor', target.id, { status: target.status });
  res.json(target);
});

// Users & Roles
app.get('/api/v1/admin/users', requirePreviewAdmin, (req, res) => {
  const role = String(req.query.role || '');
  const q = String(req.query.q || '').trim().toLowerCase();
  const filtered = users.filter((u) => {
    if (role && u.role !== role) return false;
    if (q && !(u.name?.toLowerCase().includes(q) || u.phone?.includes(q) || u.email?.toLowerCase().includes(q))) {
      return false;
    }
    return true;
  });
  res.json({ items: filtered, total: filtered.length, page: 1, pages: 1 });
});
app.patch('/api/v1/admin/users/:id/role', requirePreviewAdmin, (req, res) => {
  const target = users.find((u) => u.id === req.params.id);
  if (!target) return res.status(404).json({ message: 'المستخدم غير موجود' });
  target.role = String(req.body?.role || target.role) as UserRole;
  recordAudit('USER_ROLE_UPDATED', 'User', target.id, { role: target.role });
  res.json(target);
});

// Cities
app.get('/api/v1/admin/cities', requirePreviewAdmin, (_req, res) => {
  res.json(cities);
});
app.post('/api/v1/admin/cities', requirePreviewAdmin, (req, res) => {
  const code = String(req.body?.code || '').trim().toUpperCase();
  const nameAr = String(req.body?.nameAr || '').trim();
  const nameEn = String(req.body?.nameEn || nameAr).trim();
  const nameTr = String(req.body?.nameTr || nameEn).trim();
  if (!code || !nameAr) return res.status(400).json({ message: 'أدخل رمز المدينة والاسم بالعربية' });
  if (cities.some((c) => c.code === code)) return res.status(409).json({ message: 'رمز المدينة مستخدم مسبقاً' });
  const created: CityRecord = {
    id: `city-${Date.now()}`,
    code,
    countryCode: String(req.body?.countryCode || 'SY').toUpperCase(),
    defaultCurrency: String(req.body?.defaultCurrency || 'SYP').toUpperCase(),
    isActive: true,
    lat: 34.889,
    lng: 35.886,
    names: [
      { locale: 'ar', name: nameAr },
      { locale: 'en', name: nameEn },
      { locale: 'tr', name: nameTr },
    ],
  };
  cities.push(created);
  recordAudit('CITY_CREATED', 'City', created.id, { code, nameAr });
  res.status(201).json(created);
});
app.patch('/api/v1/admin/cities/:id', requirePreviewAdmin, (req, res) => {
  const city = cities.find((c) => c.id === req.params.id);
  if (!city) return res.status(404).json({ message: 'المدينة غير موجودة' });
  if (typeof req.body?.isActive === 'boolean') city.isActive = req.body.isActive;
  recordAudit('CITY_UPDATED', 'City', city.id, { isActive: city.isActive });
  res.json(city);
});

// Delivery Zones
app.get('/api/v1/admin/delivery-zones', requirePreviewAdmin, (_req, res) => {
  res.json(deliveryZones);
});
app.post('/api/v1/admin/delivery-zones', requirePreviewAdmin, (req, res) => {
  const city = cities.find((c) => c.id === req.body?.cityId);
  if (!city) return res.status(400).json({ message: 'اختر مدينة صالحة' });
  if (deliveryZones.some((z) => z.cityId === city.id)) {
    return res.status(409).json({ message: 'توجد منطقة توصيل مفعلة لهذه المدينة مسبقاً' });
  }
  const created = {
    id: `zone-${Date.now()}`,
    cityId: city.id,
    name: String(req.body?.name || 'منطقة التوصيل الرئيسية'),
    feeBase: Number(req.body?.feeBase || 0),
    feePerKm: Number(req.body?.feePerKm || 0),
    minOrder: Number(req.body?.minOrder || 0),
    city,
  };
  deliveryZones.push(created);
  recordAudit('DELIVERY_ZONE_CREATED', 'DeliveryZone', created.id, { cityId: city.id });
  res.status(201).json(created);
});
app.patch('/api/v1/admin/delivery-zones/:id', requirePreviewAdmin, (req, res) => {
  const zone = deliveryZones.find((z) => z.id === req.params.id);
  if (!zone) return res.status(404).json({ message: 'منطقة التوصيل غير موجودة' });
  if (req.body?.name !== undefined) zone.name = String(req.body.name);
  if (req.body?.feeBase !== undefined) zone.feeBase = Number(req.body.feeBase);
  if (req.body?.feePerKm !== undefined) zone.feePerKm = Number(req.body.feePerKm);
  if (req.body?.minOrder !== undefined) zone.minOrder = Number(req.body.minOrder);
  recordAudit('DELIVERY_ZONE_UPDATED', 'DeliveryZone', zone.id, { feeBase: zone.feeBase, feePerKm: zone.feePerKm });
  res.json(zone);
});
app.delete('/api/v1/admin/delivery-zones/:id', requirePreviewAdmin, (req, res) => {
  const before = deliveryZones.length;
  deliveryZones = deliveryZones.filter((z) => z.id !== req.params.id);
  if (deliveryZones.length === before) return res.status(404).json({ message: 'منطقة التوصيل غير موجودة' });
  recordAudit('DELIVERY_ZONE_DELETED', 'DeliveryZone', req.params.id, {});
  res.json({ deleted: true });
});

// Orders Monitor
app.get('/api/v1/admin/orders', requirePreviewAdmin, (req, res) => {
  const page = Math.max(1, parseInt(String(req.query.page || '1'), 10) || 1);
  const limit = Math.min(50, Math.max(1, parseInt(String(req.query.limit || '20'), 10) || 20));
  const status = String(req.query.status || '');
  const type = String(req.query.type || '');
  const filtered = orders.filter((o) => (!status || o.status === status) && (!type || o.type === type));
  const total = filtered.length;
  const pages = Math.max(1, Math.ceil(total / limit));
  const items = filtered.slice((page - 1) * limit, page * limit);
  res.json({ items, total, page, pages });
});
app.patch('/api/v1/admin/orders/:id/status', requirePreviewAdmin, (req, res) => {
  const order = orders.find((o) => o.id === req.params.id);
  if (!order) return res.status(404).json({ message: 'الطلب غير موجود' });
  const next = String(req.body?.status || '').trim() as OrderStatus;
  if (!next || !canTransitionOrderStatus('ADMIN', order.status, next)) {
    return res.status(400).json({ message: 'حدد حالة جديدة صالحة للطلب' });
  }
  order.status = next;
  if (next === 'DELIVERED') order.payment.status = 'PAID';
  recordAudit('ORDER_STATUS_OVERRIDDEN', 'Order', order.id, { orderNumber: order.orderNumber, status: next });
  res.json(order);
});

// Platform Settings & Audit Logs
app.get('/api/v1/admin/settings', requirePreviewAdmin, (_req, res) => {
  res.json(platformSettings);
});
app.patch('/api/v1/admin/settings', requirePreviewAdmin, (req, res) => {
  const body = req.body && typeof req.body === 'object' ? req.body : {};
  if (body.commissionPercent !== undefined) platformSettings.commissionPercent = Number(body.commissionPercent);
  if (body.maintenanceMode !== undefined) platformSettings.maintenanceMode = Boolean(body.maintenanceMode);
  if (body.peerDeliveryEnabled !== undefined) platformSettings.peerDeliveryEnabled = Boolean(body.peerDeliveryEnabled);
  if (body.aiAssistantEnabled !== undefined) platformSettings.aiAssistantEnabled = Boolean(body.aiAssistantEnabled);
  if (body.supportContact !== undefined) platformSettings.supportContact = String(body.supportContact);
  if (body.supportPhone !== undefined) platformSettings.supportContact = String(body.supportPhone);
  recordAudit('PLATFORM_SETTINGS_UPDATED', 'PlatformSetting', 'global', platformSettings);
  res.json(platformSettings);
});
app.get('/api/v1/admin/audit-logs', requirePreviewAdmin, (_req, res) => {
  res.json(auditLogs.slice(0, 50));
});

// Serve Static Assets, Public Pages, Interactive Web App, and Admin Portal
app.use('/assets', express.static(path.join(__dirname, 'assets')));
app.get('/site.webmanifest', (_req, res) => res.sendFile(path.join(__dirname, 'site.webmanifest')));
app.get('/robots.txt', (_req, res) => res.sendFile(path.join(__dirname, 'robots.txt')));
app.get('/sitemap.xml', (_req, res) => res.sendFile(path.join(__dirname, 'sitemap.xml')));

app.get(['/app', '/app/'], (_req, res) => {
  res.sendFile(path.join(__dirname, 'app', 'index.html'));
});
app.get(['/admin', '/admin/'], (_req, res) => {
  res.sendFile(path.join(__dirname, 'admin-web', 'index.html'));
});
for (const sub of ['en', 'tr', 'drivers', 'merchants', 'faq', 'privacy', 'terms']) {
  app.get([`/${sub}`, `/${sub}/`], (_req, res) => {
    res.sendFile(path.join(__dirname, sub, 'index.html'));
  });
}
app.get('/', (_req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

const PORT = Number(process.env.PORT || 3000);
app.listen(PORT, '0.0.0.0', () => {
  console.log(`DAZREVO web preview server listening on http://0.0.0.0:${PORT}`);
});
