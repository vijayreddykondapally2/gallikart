// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/services/firestore_service.dart';
import 'models/order.dart';

class OrderRepository {
  OrderRepository(this._service);

  final FirestoreService _service;

  firestore.CollectionReference<Map<String, dynamic>> _userOrderCollection(String userId) {
    return _service.collection('users').doc(userId).collection('orders');
  }

  firestore.Query<Map<String, dynamic>> get _ordersGroup =>
      _service.collectionGroup('orders');

  Future<void> placeOrder(Order order) async {
    if (order.userId == null || order.userId!.isEmpty) {
      throw ArgumentError('userId is required on Order');
    }
    final data = order.toMap();
    // Ensure server-side timestamp for ordering
    data['createdAt'] = firestore.FieldValue.serverTimestamp();
    await _userOrderCollection(order.userId!).doc(order.id).set(data);
  }

  Stream<List<Order>> watchPlacedOrders() {
    return _ordersGroup
        .where('orderStatus', isEqualTo: 'PLACED')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _fromDoc(doc.id, doc.data())).toList());
  }

  Stream<List<Order>> watchUserOrders(String userId) {
    return _userOrderCollection(userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => _fromDoc(doc.id, doc.data())).toList());
  }

  Stream<List<Order>> watchTodayDeliveries(DateTime now) {
    final todayKey = _dateKey(now);
    final dayLabel = _weekdayLabel(now.weekday);
    return _ordersGroup
        .where('orderStatus', whereIn: ['CONFIRMED', 'PACKING', 'OUT_FOR_DELIVERY'])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => _fromDoc(doc.id, doc.data()))
              .where((order) {
                final matchesDate = order.deliveryDate == todayKey || order.deliveryDate == null;
                final activeMatches = order.activeDays.contains(dayLabel);
                final createdToday = _dateKey(order.createdAt) == todayKey;
                return (matchesDate && createdToday) || activeMatches;
              })
              .toList();
        });
  }

  Stream<List<Order>> watchDeliveryQueue() {
    return _ordersGroup
        .where('orderStatus', whereIn: ['OUT_FOR_DELIVERY', 'NEAR_YOU'])
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _fromDoc(doc.id, doc.data())).toList());
  }

  Future<void> updateStatus({required String orderId, required String status}) async {
    final updatePayload = {
      'orderStatus': status,
      'status': status,
      ..._statusTimestamps(status),
    };
    final snapshot = await _ordersGroup
        .where(firestore.FieldPath.documentId, isEqualTo: orderId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return;
    await snapshot.docs.first.reference.update(updatePayload);
  }

  Map<String, dynamic> _statusTimestamps(String status) {
    final now = DateTime.now().toIso8601String();
    switch (status) {
      case 'CONFIRMED':
        return {'confirmedAt': now};
      case 'PACKING':
        return {'packedAt': now};
      case 'OUT_FOR_DELIVERY':
        return {'outForDeliveryAt': now};
      case 'NEAR_YOU':
        return {'nearYouAt': now};
      case 'DELIVERED':
        return {'deliveredAt': now};
      default:
        return {};
    }
  }

  Order _fromDoc(String id, Map<String, dynamic> data) {
    return Order.fromMap(id, data);
  }

  String _dateKey(DateTime dt) {
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$mm-$dd';
  }

  String _weekdayLabel(int weekday) {
    const labels = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    return labels[weekday] ?? 'Monday';
  }
}

final orderRepositoryProvider = Provider(
  (ref) => OrderRepository(ref.read(firestoreServiceProvider)),
);
