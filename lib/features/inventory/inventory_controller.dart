// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../services/vendor_inventory_service.dart';
import 'inventory_item.dart';

class InventoryController extends StateNotifier<List<InventoryItem>> {
  InventoryController(this._service) : super([]) {
    _subscription = _service.inventorySnapshots().listen((docs) {
      state = docs
          .map((doc) {
            final data = doc.data();
            return InventoryItem(
              id: doc.id,
              name: data['name'] as String? ?? 'Unknown',
              price: (data['price'] as num?)?.toDouble() ?? 0,
              stockQty: (data['stockQty'] as num?)?.toDouble() ?? 0,
              unit: data['unit'] as String? ?? 'unit',
              lowStockThreshold: (data['lowStockThreshold'] as num?)?.toDouble() ?? 0,
              isAvailable: data['isAvailable'] as bool? ?? false,
              updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
            );
          })
          .toList(growable: false);
    });
  }

  final VendorInventoryService _service;
  StreamSubscription<List<QueryDocumentSnapshot<Map<String, dynamic>>>>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> updateStock(String productId, double stockQty) async {
    await _service.updateProduct(productId: productId, stockQty: stockQty);
  }

  Future<void> updatePrice(String productId, double price) async {
    await _service.updateProduct(productId: productId, price: price);
  }

  Future<void> updateLowStockThreshold(String productId, double threshold) async {
    await _service.updateProduct(productId: productId, lowStockThreshold: threshold);
  }

  Future<void> toggleAvailability(String productId, bool available) async {
    await _service.toggleAvailability(productId, available);
  }

  Future<void> addProduct({
    required String name,
    required double price,
    required double stockQty,
    required String unit,
    double lowStockThreshold = 0,
  }) {
    return _service.addProduct(
      name: name,
      price: price,
      stockQty: stockQty,
      unit: unit,
      lowStockThreshold: lowStockThreshold,
    );
  }
}

final inventoryControllerProvider = StateNotifierProvider<InventoryController, List<InventoryItem>>(
  (ref) => InventoryController(
    VendorInventoryService(
      ref.read(firebaseFirestoreProvider),
      ref.read(firebaseAuthProvider),
    ),
  ),
);
