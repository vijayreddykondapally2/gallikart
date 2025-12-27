// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/money_utils.dart';
import 'models/order.dart';
import 'order_controller.dart';

class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key});

  static const _statusFlow = [
    'PLACED',
    'CONFIRMED',
    'PACKING',
    'OUT_FOR_DELIVERY',
    'NEAR_YOU',
    'DELIVERED',
  ];

  static const _statusMessages = {
    'PLACED': 'Order placed',
    'CONFIRMED': 'Order confirmed',
    'PACKING': 'Packing your order',
    'OUT_FOR_DELIVERY': 'Out for delivery',
    'NEAR_YOU': 'Delivery partner is near you',
    'DELIVERED': 'Delivered',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.ordersTitle)),
      body: orders.isEmpty
          ? const Center(child: Text('No orders yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                final statusLabel = _statusMessages[order.status] ?? order.status;
                final shortId = order.id.length > 4
                    ? order.id.substring(order.id.length - 4)
                    : order.id;
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              foregroundColor: AppColors.primary,
                              child: const Icon(Icons.local_shipping_rounded),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Instant Order • #$shortId',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${formatCurrency(order.totalAmount)} • ${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Placed on ${_formatDateTime(order.createdAt)}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _statusChip(order.status, statusLabel),
                                const SizedBox(height: 6),
                                if (_etaLabel(order.status).isNotEmpty)
                                  Text(
                                    _etaLabel(order.status),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _statusTimeline(order),
                        const SizedBox(height: 12),
                        Text(statusLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (_etaLabel(order.status).isNotEmpty)
                          Text(
                            'ETA: ${_etaLabel(order.status)}',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _statusTimeline(Order order) {
    final currentIndex = _statusFlow.indexOf(order.status);
    final idx = currentIndex < 0 ? 0 : currentIndex;
    return Column(
      children: _statusFlow.map((step) {
        final stepIndex = _statusFlow.indexOf(step);
        final isCompleted = idx > stepIndex;
        final isActive = idx == stepIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              _StatusDot(
                color: isCompleted
                    ? Colors.green
                    : isActive
                        ? AppColors.primary
                        : Colors.grey.shade400,
                isActive: isActive,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _statusMessages[step] ?? step,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isCompleted
                        ? Colors.green.shade700
                        : isActive
                            ? AppColors.primary
                            : Colors.grey.shade700,
                  ),
                ),
              ),
              if (isCompleted)
                const Icon(Icons.check_circle, size: 16, color: Colors.green),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _statusChip(String status, String label) {
    Color bg;
    Color fg;
    switch (status) {
      case 'DELIVERED':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        break;
      case 'OUT_FOR_DELIVERY':
      case 'NEAR_YOU':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        break;
      default:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  String _etaLabel(String status) {
    if (status == 'OUT_FOR_DELIVERY' || status == 'NEAR_YOU') {
      return 'Arriving in 10–15 mins';
    }
    return '';
  }

  String _formatDateTime(DateTime dt) {
    final datePart = formatShortDate(dt);
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$datePart, $hour:$minute $period';
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color, required this.isActive});

  final Color color;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isActive ? 14 : 10,
      height: isActive ? 14 : 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
