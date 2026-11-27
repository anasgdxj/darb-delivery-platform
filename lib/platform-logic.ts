export type UserRole = 'CUSTOMER' | 'DRIVER' | 'VENDOR' | 'ADMIN';
export type OrderStatus =
  | 'PENDING'
  | 'ACCEPTED'
  | 'PREPARING'
  | 'READY'
  | 'ASSIGNED'
  | 'PICKED_UP'
  | 'DELIVERED'
  | 'CANCELLED';

export type OrderType = 'VENDOR_ORDER' | 'PEER_DELIVERY';

export interface PlatformOrderItem {
  productId?: string;
  nameSnapshot: string;
  quantity: number;
  unitPrice: number;
}

export interface PlatformOrder {
  id: string;
  orderNumber: string;
  status: OrderStatus;
  type: OrderType;
  subtotal: number;
  deliveryFee: number;
  total: number;
  currency: string;
  createdAt: string;
  pickupAddress: string;
  pickupLatitude: number;
  pickupLongitude: number;
  address: {
    label: string;
    details: string;
    latitude: number;
    longitude: number;
  };
  items: PlatformOrderItem[];
  city: {
    id: string;
    code: string;
    names: Array<{ locale: string; name: string }>;
  };
  vendor: {
    id?: string;
    translations: Array<{ locale: string; name: string }>;
  } | null;
  customer: {
    id?: string;
    name: string;
    phone: string;
  };
  driver: {
    id?: string;
    user: { name: string; phone: string };
  } | null;
  payment: { status: string; method: string };
  notes?: string;
  scheduledFor?: string;
  deliveryProofNote?: string;
  rating?: { stars: number; comment: string; createdAt: string } | null;
}

export interface StatsInput {
  usersCount: number;
  vendors: Array<{ status: string }>;
  drivers: Array<{ status: string; isOnline: boolean }>;
  cities: Array<{ isActive: boolean }>;
  orders: Array<{ status: OrderStatus; total: number; deliveryFee?: number }>;
}

export function computeAdminStats(input: StatsInput) {
  const vendorsApproved = input.vendors.filter((v) => v.status === 'APPROVED').length;
  const vendorsPending = input.vendors.filter((v) => v.status === 'PENDING').length;
  const driversApproved = input.drivers.filter((d) => d.status === 'APPROVED').length;
  const driversPending = input.drivers.filter((d) => d.status === 'PENDING').length;
  const driversOnline = input.drivers.filter((d) => d.status === 'APPROVED' && d.isOnline).length;
  const citiesActive = input.cities.filter((c) => c.isActive).length;
  const ordersTotal = input.orders.length;
  const ordersPending = input.orders.filter((o) => o.status === 'PENDING').length;
  const ordersActive = input.orders.filter((o) => !['DELIVERED', 'CANCELLED'].includes(o.status)).length;
  const ordersDelivered = input.orders.filter((o) => o.status === 'DELIVERED').length;
  const ordersCancelled = input.orders.filter((o) => o.status === 'CANCELLED').length;
  const deliveredGrossTotal = input.orders
    .filter((o) => o.status === 'DELIVERED')
    .reduce((sum, o) => sum + Number(o.total || 0), 0);
  const deliveredDeliveryFees = input.orders
    .filter((o) => o.status === 'DELIVERED')
    .reduce((sum, o) => sum + Number(o.deliveryFee || 0), 0);
  const gmv = input.orders
    .filter((o) => o.status !== 'CANCELLED')
    .reduce((sum, o) => sum + Number(o.total || 0), 0);

  return {
    // Primary NestJS AdminService.stats() fields
    usersTotal: input.usersCount,
    vendorsApproved,
    vendorsPending,
    driversApproved,
    driversPending,
    driversOnline,
    citiesActive,
    ordersTotal,
    ordersPending,
    ordersActive,
    ordersDelivered,
    ordersCancelled,
    deliveredGrossTotal,
    deliveredDeliveryFees,
    // Backwards-compatible aliases
    users: input.usersCount,
    vendors: input.vendors.length,
    pendingVendors: vendorsPending,
    drivers: input.drivers.length,
    pendingDrivers: driversPending,
    orders: ordersTotal,
    activeOrders: ordersActive,
    deliveredOrders: ordersDelivered,
    gmv,
    cities: citiesActive,
  };
}

export function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const R = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Math.round(R * c * 100) / 100;
}

export function calculateOrderTotals(
  items: Array<{ quantity: number; unitPrice: number }>,
  feeBase = 5000,
  feePerKm = 1200,
  distanceKm = 2.5,
) {
  const subtotal = items.reduce((sum, item) => {
    const qty = Math.max(0, Math.floor(Number(item.quantity) || 0));
    const price = Math.max(0, Number(item.unitPrice) || 0);
    return sum + qty * price;
  }, 0);
  const safeDistance = Math.max(0.5, Number(distanceKm) || 0);
  const deliveryFee = Math.round((Math.max(0, feeBase) + safeDistance * Math.max(0, feePerKm)) / 100) * 100;
  return {
    subtotal,
    deliveryFee,
    total: subtotal + deliveryFee,
  };
}

export function canTransitionOrderStatus(
  role: UserRole,
  current: OrderStatus,
  next: OrderStatus,
): boolean {
  if (role === 'ADMIN') return current !== next;
  if (role === 'CUSTOMER') {
    return current === 'PENDING' && next === 'CANCELLED';
  }
  if (role === 'VENDOR') {
    const allowed: Partial<Record<OrderStatus, OrderStatus[]>> = {
      PENDING: ['ACCEPTED', 'CANCELLED'],
      ACCEPTED: ['PREPARING'],
      PREPARING: ['READY'],
    };
    return Boolean(allowed[current]?.includes(next));
  }
  if (role === 'DRIVER') {
    const allowed: Partial<Record<OrderStatus, OrderStatus[]>> = {
      PENDING: ['ASSIGNED'],
      READY: ['ASSIGNED'],
      ASSIGNED: ['PICKED_UP'],
      PICKED_UP: ['DELIVERED'],
    };
    return Boolean(allowed[current]?.includes(next));
  }
  return false;
}

export function buildOperationalAssistantReply(
  message: string,
  role: UserRole,
  snapshot: {
    ordersTotal: number;
    ordersActive: number;
    ordersDelivered: number;
    vendorsPending: number;
    driversPending: number;
    driversOnline: number;
    deliveredGrossTotal: number;
    citiesActive: number;
  },
): { answer: string; reply: string } {
  const q = message.trim().toLowerCase();
  const isEnglish = /^[a-z0-9\s.,?!'-]+$/i.test(message.trim());

  if (role === 'ADMIN') {
    if (q.includes('موافق') || q.includes('pending') || q.includes('approval')) {
      const answer = isEnglish
        ? `Pending review queue: ${snapshot.driversPending} drivers and ${snapshot.vendorsPending} merchants awaiting approval. Active orders currently stand at ${snapshot.ordersActive}.`
        : `ملخص الموافقات المعلقة: يوجد حالياً ${snapshot.driversPending} سائقين و${snapshot.vendorsPending} متاجر بانتظار المراجعة والاعتماد، إلى جانب ${snapshot.ordersActive} طلبات نشطة قيد التنفيذ.`;
      return { answer, reply: answer };
    }
    if (q.includes('سائق') || q.includes('متاجر') || q.includes('driver') || q.includes('vendor')) {
      const answer = isEnglish
        ? `Network readiness: ${snapshot.driversOnline} approved drivers are currently online across ${snapshot.citiesActive} active cities. Completed GMV stands at ${snapshot.deliveredGrossTotal.toLocaleString('en-US')} SYP.`
        : `جاهزية الشبكة: يتوفر حالياً ${snapshot.driversOnline} سائق متصل فعلياً عبر ${snapshot.citiesActive} مدن مفعّلة، مع إجمالي مبيعات مكتملة قدره ${snapshot.deliveredGrossTotal.toLocaleString('en-US')} ل.س.`;
      return { answer, reply: answer };
    }
    const answer = isEnglish
      ? `Operations Snapshot: ${snapshot.ordersTotal} total orders (${snapshot.ordersActive} active, ${snapshot.ordersDelivered} delivered), ${snapshot.driversOnline} online drivers, and ${snapshot.vendorsPending + snapshot.driversPending} pending onboarding approvals.`
      : `نظرة تشغيلية مباشرة: إجمالي الطلبات ${snapshot.ordersTotal} (${snapshot.ordersActive} نشط، ${snapshot.ordersDelivered} مكتمل)، و${snapshot.driversOnline} سائق متصل في ${snapshot.citiesActive} مدن مفعّلة. هناك ${snapshot.vendorsPending + snapshot.driversPending} طلبات انضمام بانتظار القرار.`;
    return { answer, reply: answer };
  }

  if (role === 'DRIVER') {
    const answer = isEnglish
      ? `Courier Dispatch Brief: ${snapshot.ordersActive} active city orders are moving across ${snapshot.citiesActive} zones. Keep availability toggled on to receive instant pickup dispatches.`
      : `ملخص المندوب: يوجد ${snapshot.ordersActive} طلبات نشطة عبر ${snapshot.citiesActive} مدن. تأكد من تفعيل حالة التوفر لاستقبال عروض التوصيل القريبة فوراً.`;
    return { answer, reply: answer };
  }

  if (role === 'VENDOR') {
    const answer = isEnglish
      ? `Merchant Operations Brief: ${snapshot.ordersActive} orders are active network-wide with ${snapshot.driversOnline} online couriers ready for pickup once orders reach READY status.`
      : `ملخص المتجر: هناك ${snapshot.ordersActive} طلبات نشطة حالياً و${snapshot.driversOnline} سائق متصل جاهز لاستلام الطلبات فور تحويل حالتها إلى جاهز.`;
    return { answer, reply: answer };
  }

  const answer = isEnglish
    ? `DAZREVO Smart Assistant: ${snapshot.citiesActive} cities are active with ${snapshot.driversOnline} couriers online. Tell me the items or pickup/dropoff points you need and I will structure your order.`
    : `مساعد دازريفو الذكي: الخدمة مفعّلة حالياً في ${snapshot.citiesActive} مدن مع توفر ${snapshot.driversOnline} سائق متصل. اكتب تفاصيل طلبك أو نقطة الاستلام والتسليم لتجهيز ملخص واضح قبل التأكيد.`;
  return { answer, reply: answer };
}

export function estimatePeerFare(
  distanceKm: number,
  priority: 'STANDARD' | 'EXPRESS' = 'STANDARD',
  feeBase = 6000,
  feePerKm = 1800,
): number {
  const safeDist = Math.max(0.5, Math.min(100, Number(distanceKm) || 1));
  const multiplier = priority === 'EXPRESS' ? 1.25 : 1;
  const raw = (Math.max(0, feeBase) + safeDist * Math.max(0, feePerKm)) * multiplier;
  return Math.max(5000, Math.round(raw / 500) * 500);
}

export function clampRating(stars: number): number {
  const n = Math.round(Number(stars) || 0);
  return Math.max(1, Math.min(5, n));
}
