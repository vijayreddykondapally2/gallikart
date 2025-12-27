// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/primary_button.dart';
import 'models/recursive_order.dart';
import 'recursive_order_controller.dart';
import 'recursive_order_utils.dart';
import 'recursive_orders_screen.dart';

class RecursiveOrdersListScreen extends ConsumerWidget {
  const RecursiveOrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(recursiveOrderControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Recursive Orders')),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No saved recursive orders yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              final editable = order.frequency != 'instant';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: Text(order.frequency.toUpperCase()),
                            backgroundColor: Colors.green.shade50,
                            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          Text(
                            'Saved ${order.createdAt.toLocal().toString().split(' ').first}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _buildSummary(order),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Edit',
                              onPressed: editable
                                  ? () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Editing subscription order (${order.frequency} → keep or change plan)',
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => RecursiveOrdersScreen(
                                            initialOrder: order,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await ref
                                    .read(
                                      recursiveOrderControllerProvider.notifier,
                                    )
                                    .deleteOrder(order.id);
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Order deleted'),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Failed to load orders: $error'),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Retry',
                onPressed: () => ref
                    .read(recursiveOrderControllerProvider.notifier)
                    .loadOrders(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSummary(RecursiveOrder order) {
    final timePart = order.deliveryTime == null
        ? ''
        : ' @ ${order.deliveryTime}';
    final addressPart = order.deliveryAddress?.isNotEmpty == true
        ? ' • ${order.deliveryAddress!}'
        : '';
    if (order.frequency == 'weekly') {
      final weekLabel = order.plannedWeekStart != null
          ? formatWeekStartLabel(order.plannedWeekStart!)
          : 'Weekly plan';
      final dayDetails = <String>[];
      final weeklyItems = Map<String, dynamic>.from(order.items);
      weeklyItems.forEach((day, data) {
        final details = <String>[];
        final dayMap = Map<String, dynamic>.from((data as Map?) ?? {});
        for (final entry in dayMap.entries) {
          final qtyVal = entry.value;
          final quantity = qtyVal is num ? qtyVal.toInt() : 0;
          if (quantity > 0) {
            details.add('${entry.key} ($quantity)');
          }
        }
        if (details.isNotEmpty) {
          dayDetails.add('$day: ${details.join(', ')}');
        }
      });
      final detailPart = dayDetails.isNotEmpty
          ? ' • ${dayDetails.join(' | ')}'
          : '';
      return '$weekLabel$timePart$addressPart$detailPart';
    }
    final itemCount = Map<String, dynamic>.from(order.items)
        .values
        .where((value) {
          if (value is num) return value.toInt() > 0;
          return false;
        })
        .length;
    if (order.frequency == 'monthly') {
      final day = order.monthlyDay ?? 1;
      return 'Monthly on day $day$timePart$addressPart • $itemCount items';
    }
    return 'Items: $itemCount$timePart$addressPart';
  }
}
