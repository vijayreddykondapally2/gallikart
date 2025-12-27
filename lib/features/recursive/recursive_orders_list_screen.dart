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
              final editable = order.frequency != 'instant' && order.status != 'DISABLED_FINAL';
              final disableAllowed = order.status != 'DISABLED_FINAL' && !order.refundProcessed;
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
                          Row(
                            children: [
                              Chip(
                                label: Text(order.status),
                                backgroundColor: order.status == 'DISABLED_FINAL'
                                    ? Colors.red.shade50
                                    : Colors.blue.shade50,
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: order.status == 'DISABLED_FINAL'
                                      ? Colors.red.shade700
                                      : Colors.blue.shade700,
                                ),
                                visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Saved ${order.createdAt.toLocal().toString().split(' ').first}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
                            child: OutlinedButton(
                              onPressed: () => _showOrderView(context, order),
                              child: const Text('View'),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: disableAllowed
                                  ? () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      await ref
                                          .read(
                                            recursiveOrderControllerProvider.notifier,
                                          )
                                          .disableOrder(order);
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Recurring order disabled, refund sent to wallet'),
                                        ),
                                      );
                                    }
                                  : null,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                              ),
                              child: Text(disableAllowed ? 'Disable' : 'Disabled'),
                            ),
                          ),
                        ],
                      ),
                      if (order.status == 'DISABLED_FINAL') ...[
                        const SizedBox(height: 8),
                        Text(
                          'Order Disabled • Refund processed for remaining days',
                          style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
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

void _showOrderView(BuildContext context, RecursiveOrder order) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      final delivered = order.deliveredDays.toSet();
      final isWeekly = order.items.containsKey('weekly') || order.frequency == 'weekly';
      final weeklyMap = isWeekly
          ? Map<String, dynamic>.from(order.items.containsKey('weekly')
              ? order.items['weekly'] as Map
              : order.items)
          : <String, dynamic>{'Schedule': order.items};
      final dayKeys = weeklyMap.keys.toList()..sort();
      if (dayKeys.isEmpty && order.dayTotals.isNotEmpty) {
        dayKeys.addAll(order.dayTotals.keys);
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Order ${order.frequency.toUpperCase()} - Breakdown',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...dayKeys.map((day) {
              final dayItemsRaw = weeklyMap[day];
              final entries = <String>[];
              if (dayItemsRaw is Map) {
                dayItemsRaw.forEach((key, qty) {
                  if (qty is num && qty > 0) {
                    entries.add('$key x${qty.toInt()}');
                  }
                });
              }
              final isDelivered = delivered.contains(day);
              final isDisabled = order.status == 'DISABLED_FINAL' && !isDelivered;
              final statusLabel = isDelivered
                  ? 'Delivered'
                  : isDisabled
                      ? 'Disabled'
                      : 'Upcoming';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDelivered
                            ? Colors.green.shade50
                            : isDisabled
                                ? Colors.red.shade50
                                : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDelivered
                              ? Colors.green.shade700
                              : isDisabled
                                  ? Colors.red.shade700
                                  : Colors.blue.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(day, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          if (entries.isEmpty)
                            const Text('No items for this day', style: TextStyle(color: Colors.grey)),
                          if (entries.isNotEmpty)
                            Text(entries.join(', ')),
                          if (order.status == 'DISABLED_FINAL' && isDisabled)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Disabled and refunded for remaining days',
                                style: TextStyle(fontSize: 12, color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            Text(
              order.status == 'DISABLED_FINAL'
                  ? 'Order Disabled · Refund processed for remaining days'
                  : 'Read-only view',
              style: TextStyle(
                color: order.status == 'DISABLED_FINAL' ? Colors.red.shade700 : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    },
  );
}
