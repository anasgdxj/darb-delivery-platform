import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
app.use(express.json({ limit: '1mb' }));

// Security headers (never emit X-Frame-Options so iframe preview works cleanly)
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('Referrer-Policy', 'no-referrer');
  const origin = req.headers.origin;
  if (origin && (origin.includes('localhost') || origin.includes('127.0.0.1') || origin.endsWith('.run.app') || origin.endsWith('.googleusercontent.com'))) {
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

// In-memory preview stores matching production NestJS + Prisma schema
interface CityRecord {
  id: string;
  code: string;
  countryCode: string;
  isActive: boolean;
  names: Array<{ locale: string; name: string }>;
}

let cities: CityRecord[] = [
  { id: 'city-dam', code: 'DAM', countryCode: 'SY', isActive: true, names: [{ locale: 'ar', name: 'دمشق' }, { locale: 'en', name: 'Damascus' }, { locale: 'tr', name: 'Şam' }] },
  { id: 'city-ale', code: 'ALE', countryCode: 'SY', isActive: true, names: [{ locale: 'ar', name: 'حلب' }, { locale: 'en', name: 'Aleppo' }, { locale: 'tr', name: 'Halep' }] },
  { id: 'city-hms', code: 'HMS', countryCode: 'SY', isActive: true, names: [{ locale: 'ar', name: 'حمص' }, { locale: 'en', name: 'Homs' }, { locale: 'tr', name: 'Humus' }] },
  { id: 'city-hma', code: 'HMA', countryCode: 'SY', isActive: true, names: [{ locale: 'ar', name: 'حماة' }, { locale: 'en', name: 'Hama' }, { locale: 'tr', name: 'Hama' }] },
  { id: 'city-lat', code: 'LAT', countryCode: 'SY', isActive: true, names: [{ locale: 'ar', name: 'اللاذقية' }, { locale: 'en', name: 'Latakia' }, { locale: 'tr', name: 'Lazkiye' }] },
];

let drivers = [
  {
    id: 'drv-1',
    status: 'PENDING',
    vehicleType: 'MOTORCYCLE',
    isOnline: false,
    createdAt: new Date(Date.now() - 1800000).toISOString(),
    user: { id: 'usr-11', name: 'سامر أحمد', phone: '+963933123456', email: 'samer@darb.sy' },
    city: { id: 'city-dam', code: 'DAM', names: [{ locale: 'ar', name: 'دمشق' }] },
  },
  {
    id: 'drv-2',
    status: 'PENDING',
    vehicleType: 'CAR',
    isOnline: false,
    createdAt: new Date(Date.now() - 3600000).toISOString(),
    user: { id: 'usr-12', name: 'عمر خالد', phone: '+963944654321', email: 'omar@darb.sy' },
    city: { id: 'city-ale', code: 'ALE', names: [{ locale: 'ar', name: 'حلب' }] },
  },
  {
    id: 'drv-3',
    status: 'APPROVED',
    vehicleType: 'BICYCLE',
    isOnline: true,
    createdAt: new Date(Date.now() - 86400000 * 5).toISOString(),
    user: { id: 'usr-13', name: 'حسن محمود', phone: '+963955667788', email: 'hasan@darb.sy' },
    city: { id: 'city-dam', code: 'DAM', names: [{ locale: 'ar', name: 'دمشق' }] },
  },
];

let vendors = [
  {
    id: 'vnd-1',
    status: 'PENDING',
    type: 'مطعم',
    isOpen: true,
    commercialRegNo: '102938',
    location: { address: 'شارع بغداد، دمشق' },
    translations: [{ locale: 'ar', name: 'مطعم الشام الأصيل', description: 'أطيب المأكولات الدمشقية التراثية' }],
    cities: [{ city: { id: 'city-dam', code: 'DAM', names: [{ locale: 'ar', name: 'دمشق' }] } }],
    user: { id: 'usr-21', name: 'أحمد الدمشقي', phone: '+963932112233' },
    _count: { products: 14, orders: 0 },
  },
  {
    id: 'vnd-2',
    status: 'PENDING',
    type: 'سوبرماركت',
    isOpen: true,
    commercialRegNo: '564738',
    location: { address: 'الجميلية، حلب' },
    translations: [{ locale: 'ar', name: 'سوبرماركت البركة', description: 'مواد غذائية واستهلاكية متكاملة' }],
    cities: [{ city: { id: 'city-ale', code: 'ALE', names: [{ locale: 'ar', name: 'حلب' }] } }],
    user: { id: 'usr-22', name: 'بلال الحلبي', phone: '+963944778899' },
    _count: { products: 42, orders: 0 },
  },
  {
    id: 'vnd-3',
    status: 'APPROVED',
    type: 'صيدلية ومستلزمات',
    isOpen: true,
    commercialRegNo: '774120',
    location: { address: 'المزة أوتستراد، دمشق' },
    translations: [{ locale: 'ar', name: 'مركز الشفاء', description: 'مستلزمات عناية يومية وصحية' }],
    cities: [{ city: { id: 'city-dam', code: 'DAM', names: [{ locale: 'ar', name: 'دمشق' }] } }],
    user: { id: 'usr-23', name: 'سارة العلي', phone: '+963911334455' },
    _count: { products: 28, orders: 64 },
  },
];

let users = [
  { id: 'admin-user-1', name: 'مدير دَرْب', email: 'admin@darb.sy', phone: '+963930000001', role: 'ADMIN', isActive: true, createdAt: new Date(Date.now() - 86400000 * 30).toISOString() },
  { id: 'usr-13', name: 'حسن محمود', email: 'hasan@darb.sy', phone: '+963955667788', role: 'DRIVER', isActive: true, createdAt: new Date(Date.now() - 86400000 * 14).toISOString() },
  { id: 'usr-23', name: 'سارة العلي', email: 'sara@darb.sy', phone: '+963911334455', role: 'VENDOR', isActive: true, createdAt: new Date(Date.now() - 86400000 * 10).toISOString() },
  { id: 'usr-31', name: 'محمد علي', email: null, phone: '+963911223344', role: 'CUSTOMER', isActive: true, createdAt: new Date(Date.now() - 86400000 * 4).toISOString() },
  { id: 'usr-32', name: 'فاطمة أحمد', email: null, phone: '+963922334455', role: 'CUSTOMER', isActive: true, createdAt: new Date(Date.now() - 86400000 * 2).toISOString() },
];

let deliveryZones = [
  { id: 'zone-1', cityId: 'city-dam', name: 'دمشق المركزية والمزة', feeBase: 5000, feePerKm: 1200, minOrder: 15000, city: cities[0] },
  { id: 'zone-2', cityId: 'city-ale', name: 'حلب الكبرى والشهباء', feeBase: 4500, feePerKm: 1000, minOrder: 12000, city: cities[1] },
  { id: 'zone-3', cityId: 'city-hms', name: 'حمص الوسطى والوعر', feeBase: 4000, feePerKm: 900, minOrder: 10000, city: cities[2] },
];

const orders = [
  {
    id: 'ord-101',
    orderNumber: '1001',
    status: 'PENDING',
    type: 'VENDOR_ORDER',
    total: 42500,
    currency: 'SYP',
    createdAt: new Date(Date.now() - 1500000).toISOString(),
    city: cities[0],
    vendor: { translations: [{ locale: 'ar', name: 'مركز الشفاء' }] },
    customer: { name: 'محمد علي', phone: '+963911223344' },
    driver: null,
    payment: { status: 'PENDING', method: 'CASH_ON_DELIVERY' },
  },
  {
    id: 'ord-102',
    orderNumber: '1002',
    status: 'PICKED_UP',
    type: 'PEER_DELIVERY',
    total: 18000,
    currency: 'SYP',
    createdAt: new Date(Date.now() - 4800000).toISOString(),
    city: cities[1],
    vendor: null,
    customer: { name: 'فاطمة أحمد', phone: '+963922334455' },
    driver: { user: { name: 'حسن محمود', phone: '+963955667788' } },
    payment: { status: 'PENDING', method: 'CASH_ON_DELIVERY' },
  },
  {
    id: 'ord-103',
    orderNumber: '1003',
    status: 'DELIVERED',
    type: 'VENDOR_ORDER',
    total: 67000,
    currency: 'SYP',
    createdAt: new Date(Date.now() - 18000000).toISOString(),
    city: cities[0],
    vendor: { translations: [{ locale: 'ar', name: 'مركز الشفاء' }] },
    customer: { name: 'ليان كريم', phone: '+963933998877' },
    driver: { user: { name: 'حسن محمود', phone: '+963955667788' } },
    payment: { status: 'PAID', method: 'CASH_ON_DELIVERY' },
  },
];

let platformSettings = {
  commissionPercent: '10',
  maintenanceMode: 'false',
  supportPhone: '+963930000001',
};

let auditLogs = [
  {
    id: 'log-1',
    action: 'VENDOR_STATUS_UPDATED',
    entityType: 'VENDOR',
    entityId: 'vnd-3',
    actor: { name: 'مدير دَرْب', email: 'admin@darb.sy' },
    payload: { status: 'APPROVED' },
    createdAt: new Date(Date.now() - 86400000).toISOString(),
  },
];

function recordAudit(action: string, entityType: string, entityId: string, payload: Record<string, unknown>) {
  auditLogs.unshift({
    id: `log-${Date.now()}`,
    action,
    entityType,
    entityId,
    actor: { name: 'مدير دَرْب', email: 'admin@darb.sy' },
    payload: payload as any,
    createdAt: new Date().toISOString(),
  });
}

function requirePreviewAdmin(req: express.Request, res: express.Response, next: express.NextFunction) {
  const auth = req.headers.authorization || '';
  if (!auth.startsWith('Bearer darb_preview_')) {
    return res.status(401).json({ message: 'يرجى تسجيل الدخول بحساب الإدارة للمتابعة' });
  }
  next();
}

// Health endpoints
app.get('/api/v1/health', (_req, res) => {
  res.json({ status: 'ok', service: 'darb-preview', timestamp: new Date().toISOString() });
});
app.get('/api/v1/healthz', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});
app.get('/api/v1/readyz', (_req, res) => {
  res.json({ status: 'ready', mode: 'preview', timestamp: new Date().toISOString() });
});

// Public cities endpoint
app.get('/api/v1/cities', (_req, res) => {
  res.json(cities.filter((c) => c.isActive));
});

// Auth endpoints for admin portal preview
app.post('/api/v1/auth/google', (_req, res) => {
  res.json({
    tokens: {
      accessToken: 'darb_preview_access_token_admin',
      refreshToken: 'darb_preview_refresh_token_admin',
    },
    user: {
      id: 'admin-user-1',
      email: 'admin@darb.sy',
      name: 'مدير دَرْب',
      role: 'ADMIN',
    },
  });
});

app.post('/api/v1/auth/preview-admin', (_req, res) => {
  res.json({
    tokens: {
      accessToken: 'darb_preview_access_token_admin',
      refreshToken: 'darb_preview_refresh_token_admin',
    },
    user: {
      id: 'admin-user-1',
      email: 'admin@darb.sy',
      name: 'مدير دَرْب',
      role: 'ADMIN',
    },
  });
});

app.get('/api/v1/auth/me', requirePreviewAdmin, (_req, res) => {
  res.json({
    id: 'admin-user-1',
    email: 'admin@darb.sy',
    name: 'مدير دَرْب',
    role: 'ADMIN',
  });
});

app.post('/api/v1/auth/refresh', (_req, res) => {
  res.json({
    accessToken: 'darb_preview_access_token_admin',
    refreshToken: 'darb_preview_refresh_token_admin',
  });
});

app.post('/api/v1/auth/logout', (_req, res) => {
  res.json({ success: true });
});

// Admin Stats
app.get('/api/v1/admin/stats', requirePreviewAdmin, (_req, res) => {
  const gmv = orders.filter((o) => o.status !== 'CANCELLED').reduce((acc, o) => acc + o.total, 0);
  res.json({
    users: users.length,
    vendors: vendors.length,
    pendingVendors: vendors.filter((v) => v.status === 'PENDING').length,
    drivers: drivers.length,
    pendingDrivers: drivers.filter((d) => d.status === 'PENDING').length,
    orders: orders.length,
    activeOrders: orders.filter((o) => !['DELIVERED', 'CANCELLED'].includes(o.status)).length,
    deliveredOrders: orders.filter((o) => o.status === 'DELIVERED').length,
    gmv,
    cities: cities.filter((c) => c.isActive).length,
  });
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
  recordAudit('DRIVER_STATUS_UPDATED', 'DRIVER', target.id, { status: target.status });
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
  recordAudit('VENDOR_STATUS_UPDATED', 'VENDOR', target.id, { status: target.status });
  res.json(target);
});

// Users & Roles
app.get('/api/v1/admin/users', requirePreviewAdmin, (req, res) => {
  const role = String(req.query.role || '');
  const q = String(req.query.q || '').trim().toLowerCase();
  const filtered = users.filter((u) => {
    if (role && u.role !== role) return false;
    if (q && !(u.name?.toLowerCase().includes(q) || u.phone?.includes(q) || u.email?.toLowerCase().includes(q))) return false;
    return true;
  });
  res.json(filtered);
});
app.patch('/api/v1/admin/users/:id/role', requirePreviewAdmin, (req, res) => {
  const target = users.find((u) => u.id === req.params.id);
  if (!target) return res.status(404).json({ message: 'المستخدم غير موجود' });
  target.role = String(req.body?.role || target.role);
  recordAudit('USER_ROLE_UPDATED', 'USER', target.id, { role: target.role });
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
    isActive: true,
    names: [{ locale: 'ar', name: nameAr }, { locale: 'en', name: nameEn }, { locale: 'tr', name: nameTr }],
  };
  cities.push(created);
  recordAudit('CITY_CREATED', 'CITY', created.id, { code, nameAr });
  res.status(201).json(created);
});
app.patch('/api/v1/admin/cities/:id', requirePreviewAdmin, (req, res) => {
  const city = cities.find((c) => c.id === req.params.id);
  if (!city) return res.status(404).json({ message: 'المدينة غير موجودة' });
  if (typeof req.body?.isActive === 'boolean') city.isActive = req.body.isActive;
  recordAudit('CITY_UPDATED', 'CITY', city.id, { isActive: city.isActive });
  res.json(city);
});

// Delivery Zones
app.get('/api/v1/admin/delivery-zones', requirePreviewAdmin, (_req, res) => {
  res.json(deliveryZones);
});
app.post('/api/v1/admin/delivery-zones', requirePreviewAdmin, (req, res) => {
  const city = cities.find((c) => c.id === req.body?.cityId);
  if (!city) return res.status(400).json({ message: 'اختر مدينة صالحة' });
  if (deliveryZones.some((z) => z.cityId === city.id)) return res.status(409).json({ message: 'توجد منطقة توصيل مفعلة لهذه المدينة مسبقاً' });
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
  recordAudit('DELIVERY_ZONE_CREATED', 'DELIVERY_ZONE', created.id, { cityId: city.id });
  res.status(201).json(created);
});
app.patch('/api/v1/admin/delivery-zones/:id', requirePreviewAdmin, (req, res) => {
  const zone = deliveryZones.find((z) => z.id === req.params.id);
  if (!zone) return res.status(404).json({ message: 'منطقة التوصيل غير موجودة' });
  if (req.body?.name !== undefined) zone.name = String(req.body.name);
  if (req.body?.feeBase !== undefined) zone.feeBase = Number(req.body.feeBase);
  if (req.body?.feePerKm !== undefined) zone.feePerKm = Number(req.body.feePerKm);
  if (req.body?.minOrder !== undefined) zone.minOrder = Number(req.body.minOrder);
  recordAudit('DELIVERY_ZONE_UPDATED', 'DELIVERY_ZONE', zone.id, { feeBase: zone.feeBase, feePerKm: zone.feePerKm });
  res.json(zone);
});
app.delete('/api/v1/admin/delivery-zones/:id', requirePreviewAdmin, (req, res) => {
  const before = deliveryZones.length;
  deliveryZones = deliveryZones.filter((z) => z.id !== req.params.id);
  if (deliveryZones.length === before) return res.status(404).json({ message: 'منطقة التوصيل غير موجودة' });
  recordAudit('DELIVERY_ZONE_DELETED', 'DELIVERY_ZONE', req.params.id, {});
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

// Platform Settings & Audit Logs
app.get('/api/v1/admin/settings', requirePreviewAdmin, (_req, res) => {
  res.json(platformSettings);
});
app.patch('/api/v1/admin/settings', requirePreviewAdmin, (req, res) => {
  const body = req.body && typeof req.body === 'object' ? req.body : {};
  if (body.commissionPercent !== undefined) platformSettings.commissionPercent = String(body.commissionPercent);
  if (body.maintenanceMode !== undefined) platformSettings.maintenanceMode = String(body.maintenanceMode);
  if (body.supportPhone !== undefined) platformSettings.supportPhone = String(body.supportPhone);
  recordAudit('PLATFORM_SETTINGS_UPDATED', 'SETTINGS', 'global', platformSettings);
  res.json(platformSettings);
});
app.get('/api/v1/admin/audit-logs', requirePreviewAdmin, (_req, res) => {
  res.json(auditLogs.slice(0, 50));
});

// Serve Admin Portal & Landing Showcase
app.use('/assets', express.static(path.join(__dirname, 'assets')));
app.get(['/admin', '/admin/'], (_req, res) => {
  res.sendFile(path.join(__dirname, 'admin-web', 'index.html'));
});
app.get('/', (_req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

const PORT = Number(process.env.PORT || 3000);
app.listen(PORT, '0.0.0.0', () => {
  console.log(`DARB web preview server listening on http://0.0.0.0:${PORT}`);
});
