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

  firestore.CollectionReference<Map<String, dynamic>> get _productCollection =>
      _service.collection('products');
  firestore.CollectionReference<Map<String, dynamic>> get _orderCollection =>
      _service.collection('orders');

  Future<void> placeOrder(Order order) async {
    final orderDoc = _orderCollection.doc(order.id);
    await orderDoc.set(order.toMap());
  }
}

final orderRepositoryProvider = Provider(
  (ref) => OrderRepository(ref.read(firestoreServiceProvider)),
);
