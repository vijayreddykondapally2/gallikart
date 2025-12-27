// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/services/firestore_service.dart';
import 'inventory_item.dart';

class InventoryController extends StateNotifier<List<InventoryItem>> {
  InventoryController(this._service) : super([]) {
    load();
  }

  final FirestoreService _service;

  Future<void> load() async {
    final docs = await _service.fetchCollection('products');
    state = docs
        .map((doc) {
          final data = doc.data();
          return InventoryItem(
            id: doc.id,
            name: data['name'] as String? ?? 'Unknown',
            stock: (data['stock'] as num?)?.toInt() ?? 0,
            reorderLevel: (data['reorderLevel'] as num?)?.toInt() ?? 5,
          );
        })
        .toList(growable: false);
  }

  Future<void> updateStock(String productId, int stock) async {
    await _service.document('products/$productId').update({'stock': stock});
    state = state
        .map((item) => item.id == productId ? item.copyWith(stock: stock) : item)
        .toList(growable: false);
  }
}

final inventoryControllerProvider = StateNotifierProvider<InventoryController, List<InventoryItem>>(
  (ref) => InventoryController(ref.read(firestoreServiceProvider)),
);
