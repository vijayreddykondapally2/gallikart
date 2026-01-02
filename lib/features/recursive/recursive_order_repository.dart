// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/services/firestore_service.dart';
import 'models/recursive_order.dart';
import 'recursive_order_utils.dart';

class RecursiveOrderRepository {
  RecursiveOrderRepository(this._service);

  final FirestoreService _service;

  static const _collectionName = 'recursiveOrders';

  Future<List<RecursiveOrder>> fetchOrdersForUser(String userId) async {
    final query = await _service
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .get();
    return query.docs.map((doc) => RecursiveOrder.fromMap(doc.data())).toList();
  }

  Future<RecursiveOrder?> fetchById(String id) async {
    if (id.isEmpty) return null;
    final doc = await _service.collection(_collectionName).doc(id).get();
    if (!doc.exists) return null;
    return RecursiveOrder.fromMap(doc.data()!);
  }

  Future<void> saveOrder(RecursiveOrder order) async {
    final docRef = _service.collection(_collectionName).doc(order.id.isEmpty ? null : order.id);
    final orderWithId = order.id.isEmpty ? order.copyWith(id: docRef.id) : order;
    await docRef.set(orderWithId.toMap());
  }

  Future<void> updateOrder(RecursiveOrder order) async {
    if (order.id.isEmpty) return;
    await _service.collection(_collectionName).doc(order.id).set(order.toMap());
  }

  Future<void> deleteOrder(String id) async {
    if (id.isEmpty) return;
    await _service.collection(_collectionName).doc(id).delete();
  }

  Future<RecursiveOrder?> disableWithRefund({
    required RecursiveOrder order,
    required double refundAmount,
    required DateTime disabledAt,
  }) async {
    if (order.id.isEmpty) return order;
    return _service.runTransaction<RecursiveOrder?>((transaction) async {
      final docRef = _service.collection(_collectionName).doc(order.id);
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return order;
      final latest = RecursiveOrder.fromMap(snapshot.data()!);
      if (latest.refundProcessed || latest.status == 'DISABLED_FINAL') {
        return latest;
      }
      final updated = latest.copyWith(
        status: 'DISABLED_FINAL',
        refundProcessed: true,
        refundedAmount: refundAmount,
        disabledAt: disabledAt,
      );
      transaction.set(docRef, updated.toMap());
      return updated;
    });
  }

  Future<RecursiveOrder?> findDuplicate({
    required String userId,
    required DateTime deliveryWeekStart,
    required String addressId,
    required String frequency,
  }) async {
    final normalizedWeek = weekStart(deliveryWeekStart);
    final query = await _service
      .collection(_collectionName)
      .where('userId', isEqualTo: userId)
      .where('frequency', isEqualTo: frequency)
      .where('deliveryAddressId', isEqualTo: addressId)
      .where('status', whereIn: ['ACTIVE', 'ACTIVE_PENDING_PAYMENT', 'UPCOMING', 'active', 'active_pending_payment', 'upcoming'])
      .where('plannedWeekStart', isEqualTo: Timestamp.fromDate(normalizedWeek))
      .limit(1)
      .get();

    if (query.docs.isEmpty) return null;
    return RecursiveOrder.fromMap(query.docs.first.data());
  }
}

final recursiveOrderRepositoryProvider = Provider<RecursiveOrderRepository>(
  (ref) => RecursiveOrderRepository(ref.read(firestoreServiceProvider)),
);
