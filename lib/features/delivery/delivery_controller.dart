// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../orders/models/order.dart';
import 'delivery_order.dart';

class DeliveryController extends StateNotifier<List<DeliveryTask>> {
  DeliveryController() : super([]);

  final List<_Partner> _partners = const [
    _Partner('Sai', 17.4500, 78.3800),
    _Partner('Suma', 17.4000, 78.5000),
    _Partner('Ravi', 17.3500, 78.5300),
  ];

  void assign(List<Order> pendingOrders) {
    final sorted = List<Order>.from(pendingOrders)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final tasks = <DeliveryTask>[];
    for (var i = 0; i < sorted.length; i++) {
      final order = sorted[i];
      final partner = _partners[i % _partners.length];
      tasks.add(DeliveryTask(
        id: 'task-${order.id}',
        orderId: order.id,
        partner: partner.name,
        status: order.status,
        latitude: partner.latitude,
        longitude: partner.longitude,
      ));
    }

    state = tasks;
  }
}

final deliveryControllerProvider = StateNotifierProvider<DeliveryController, List<DeliveryTask>>(
  (ref) => DeliveryController(),
);

class _Partner {
  const _Partner(this.name, this.latitude, this.longitude);

  final String name;
  final double latitude;
  final double longitude;
}
