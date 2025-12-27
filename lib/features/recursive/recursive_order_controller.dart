// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/recursive_order.dart';
import 'recursive_order_repository.dart';

class RecursiveOrderController extends StateNotifier<AsyncValue<List<RecursiveOrder>>> {
  RecursiveOrderController(this._repository) : super(const AsyncValue.data([]));

  final RecursiveOrderRepository _repository;

  Future<void> markDeltaPaid({
    required String recurringOrderId,
    required double paidDelta,
  }) async {
    final currentList = state.value ?? [];
    final existingIndex = currentList.indexWhere((o) => o.id == recurringOrderId);
    if (existingIndex < 0) return;
    final existing = currentList[existingIndex];
    final updated = existing.copyWith(
      paidAmount: existing.paidAmount + paidDelta,
      deltaPendingAmount: 0,
      status: 'active',
    );
    await _repository.updateOrder(updated);
    await loadOrders();
  }

  Future<void> loadOrders() async {
    state = const AsyncLoading();
    try {
      final orders = await _repository.fetchOrders();
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveOrder(RecursiveOrder order) async {
    try {
      await _repository.saveOrder(order);
      await loadOrders();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateOrder(RecursiveOrder order) async {
    if (order.id.isEmpty) return;
    try {
      await _repository.updateOrder(order);
      await loadOrders();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteOrder(String id) async {
    try {
      await _repository.deleteOrder(id);
      await loadOrders();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final recursiveOrderControllerProvider =
    StateNotifierProvider<RecursiveOrderController, AsyncValue<List<RecursiveOrder>>>(
  (ref) => RecursiveOrderController(ref.read(recursiveOrderRepositoryProvider))..loadOrders(),
);
