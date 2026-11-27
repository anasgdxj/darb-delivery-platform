import test from 'node:test';
import assert from 'node:assert/strict';
import {
  buildOperationalAssistantReply,
  calculateOrderTotals,
  canTransitionOrderStatus,
  clampRating,
  computeAdminStats,
  estimatePeerFare,
  haversineKm,
} from './platform-logic';

test('computeAdminStats produces both NestJS and compatibility keys accurately', () => {
  const stats = computeAdminStats({
    usersCount: 5,
    vendors: [
      { status: 'PENDING' },
      { status: 'PENDING' },
      { status: 'APPROVED' },
    ],
    drivers: [
      { status: 'PENDING', isOnline: false },
      { status: 'APPROVED', isOnline: true },
    ],
    cities: [
      { isActive: true },
      { isActive: true },
      { isActive: false },
    ],
    orders: [
      { status: 'PENDING', total: 42500, deliveryFee: 5000 },
      { status: 'PICKED_UP', total: 18000, deliveryFee: 4500 },
      { status: 'DELIVERED', total: 67000, deliveryFee: 6000 },
      { status: 'CANCELLED', total: 15000, deliveryFee: 4000 },
    ],
  });

  assert.equal(stats.usersTotal, 5);
  assert.equal(stats.vendorsPending, 2);
  assert.equal(stats.vendorsApproved, 1);
  assert.equal(stats.driversPending, 1);
  assert.equal(stats.driversApproved, 1);
  assert.equal(stats.driversOnline, 1);
  assert.equal(stats.citiesActive, 2);
  assert.equal(stats.ordersTotal, 4);
  assert.equal(stats.ordersActive, 2);
  assert.equal(stats.ordersDelivered, 1);
  assert.equal(stats.ordersCancelled, 1);
  assert.equal(stats.deliveredGrossTotal, 67000);
  assert.equal(stats.deliveredDeliveryFees, 6000);
  assert.equal(stats.gmv, 127500);
});

test('calculateOrderTotals computes rounded delivery fee and total', () => {
  const totals = calculateOrderTotals(
    [
      { quantity: 2, unitPrice: 12000 },
      { quantity: 1, unitPrice: 8500 },
    ],
    5000,
    1200,
    2.5,
  );
  assert.equal(totals.subtotal, 32500);
  assert.equal(totals.deliveryFee, 8000);
  assert.equal(totals.total, 40500);
});

test('canTransitionOrderStatus enforces role state machines', () => {
  assert.equal(canTransitionOrderStatus('VENDOR', 'PENDING', 'ACCEPTED'), true);
  assert.equal(canTransitionOrderStatus('VENDOR', 'ACCEPTED', 'PREPARING'), true);
  assert.equal(canTransitionOrderStatus('VENDOR', 'PREPARING', 'READY'), true);
  assert.equal(canTransitionOrderStatus('VENDOR', 'PICKED_UP', 'DELIVERED'), false);

  assert.equal(canTransitionOrderStatus('DRIVER', 'READY', 'ASSIGNED'), true);
  assert.equal(canTransitionOrderStatus('DRIVER', 'ASSIGNED', 'PICKED_UP'), true);
  assert.equal(canTransitionOrderStatus('DRIVER', 'PICKED_UP', 'DELIVERED'), true);
  assert.equal(canTransitionOrderStatus('DRIVER', 'PENDING', 'DELIVERED'), false);

  assert.equal(canTransitionOrderStatus('CUSTOMER', 'PENDING', 'CANCELLED'), true);
  assert.equal(canTransitionOrderStatus('CUSTOMER', 'PICKED_UP', 'CANCELLED'), false);
});

test('haversineKm calculates Damascus route distance accurately', () => {
  const km = haversineKm(33.5138, 36.2765, 33.505, 36.245);
  assert.ok(km > 2.5 && km < 4.0, `Expected ~3.0km, got ${km}`);
});

test('buildOperationalAssistantReply returns real grounded operational counts', () => {
  const res = buildOperationalAssistantReply('لخص الموافقات المعلقة', 'ADMIN', {
    ordersTotal: 3,
    ordersActive: 2,
    ordersDelivered: 1,
    vendorsPending: 2,
    driversPending: 2,
    driversOnline: 1,
    deliveredGrossTotal: 67000,
    citiesActive: 5,
  });
  assert.ok(res.answer.includes('2 سائقين') && res.answer.includes('2 متاجر'));
});

test('estimatePeerFare and clampRating behave deterministically', () => {
  assert.equal(estimatePeerFare(4, 'STANDARD'), 13000);
  assert.equal(estimatePeerFare(4, 'EXPRESS'), 16500);
  assert.equal(estimatePeerFare(0.2, 'STANDARD', 1000, 500), 5000);
  assert.equal(clampRating(0), 1);
  assert.equal(clampRating(8), 5);
  assert.equal(clampRating(4), 4);
});
