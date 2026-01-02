// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/core_providers.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/money_utils.dart';
import '../../routes/app_routes.dart';
import 'models/order.dart';
import 'order_controller.dart';
import 'order_repository.dart';

final userOrdersProvider = StreamProvider.autoDispose<List<Order>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.read(orderRepositoryProvider).watchUserOrders(uid);
});

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
    final ordersAsync = ref.watch(userOrdersProvider);
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text(AppStrings.ordersTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Home',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (route) => false,
            ),
          ),
        ],
      ),
        body: ordersAsync.when(
        data: (orders) => orders.isEmpty
          ? const Center(child: Text('No orders yet'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final order = orders[index];
                final statusLabel = _statusMessages[order.status] ?? order.status;
                final shortId = order.id.length > 4
                    ? order.id.substring(order.id.length - 4)
                    : order.id;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.shade100,
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.teal.shade50,
                                foregroundColor: Colors.teal.shade700,
                                child: const Icon(Icons.delivery_dining, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _modeChip('INSTANT'),
                                        const SizedBox(width: 6),
                                        _statusChip(order.status, statusLabel),
                                        const Spacer(),
                                        Text(
                                          '#$shortId',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${formatCurrency(order.totalAmount)} • ${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Placed on ${_formatDateTime(order.createdAt)}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _statusTimeline(order),
                          if (_etaLabel(order.status).isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.schedule, size: 14, color: Colors.teal),
                                const SizedBox(width: 4),
                                Text(
                                  'ETA: ${_etaLabel(order.status)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load orders: $error')),
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
                    ? Colors.teal.shade400
                    : isActive
                        ? Colors.teal
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
                        ? Colors.teal.shade700
                        : isActive
                            ? Colors.teal.shade800
                            : Colors.grey.shade700,
                  ),
                ),
              ),
              if (isCompleted)
                const Icon(Icons.check_circle, size: 16, color: Colors.teal),
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
        fg = Colors.green.shade800;
        break;
      case 'OUT_FOR_DELIVERY':
      case 'NEAR_YOU':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade800;
        break;
      case 'DISABLED':
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
        break;
      default:
        bg = AppColors.primary.withOpacity(0.12);
        fg = AppColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }

  Widget _modeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.teal),
      ),
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
