// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../orders/order_controller.dart';
import 'delivery_controller.dart';

class DeliveryScreen extends ConsumerWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(deliveryControllerProvider);
    final orders = ref.watch(orderControllerProvider);
    final controller = ref.read(deliveryControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.deliveryTitle)),
      body: tasks.isEmpty
          ? const Center(child: Text('No delivery assignments yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ListTile(
                  title: Text('Order ${task.orderId}'),
                  subtitle: Text('${task.partner} · ${task.status}'),
                  trailing: Text('${task.latitude.toStringAsFixed(2)}, ${task.longitude.toStringAsFixed(2)}'),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => controller.assign(orders),
        icon: const Icon(Icons.local_shipping),
        label: const Text('Assign'),
      ),
    );
  }
}
