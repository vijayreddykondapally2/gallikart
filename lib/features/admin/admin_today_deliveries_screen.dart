import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/money_utils.dart';
import '../orders/models/order.dart';
import '../orders/order_repository.dart';

final todayDeliveriesProvider = StreamProvider.autoDispose<List<Order>>(
  (ref) => ref.read(orderRepositoryProvider).watchTodayDeliveries(DateTime.now()),
);

class AdminTodayDeliveriesScreen extends ConsumerWidget {
  const AdminTodayDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(todayDeliveriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Deliveries")),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No deliveries scheduled today'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final order = orders[index];
              final shortId = order.id.length > 6 ? order.id.substring(order.id.length - 6) : order.id;
              final next = _nextStatus(order.status);
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('#$shortId', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          _pill(order.orderType ?? 'INSTANT'),
                          const Spacer(),
                          Text(order.status, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${formatCurrency(order.totalAmount)} • ${order.items.length} item(s)'),
                      if (order.deliveryAddress != null) ...[
                        const SizedBox(height: 4),
                        Text(order.deliveryAddress!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showDetails(context, order),
                              child: const Text('View'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: next == null ? null : () => _updateStatus(context, ref, order, next),
                              child: Text(next == null ? 'No action' : 'Mark $next'),
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
        error: (error, _) => Center(child: Text('Failed to load deliveries: $error')),
      ),
    );
  }

  String? _nextStatus(String current) {
    switch (current) {
      case 'CONFIRMED':
        return 'PACKING';
      case 'PACKING':
        return 'OUT_FOR_DELIVERY';
      default:
        return null;
    }
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, Order order, String next) async {
    await ref.read(orderRepositoryProvider).updateStatus(orderId: order.id, status: next);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order ${order.id} moved to $next')),
      );
    }
  }

  void _showDetails(BuildContext context, Order order) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Order ${order.id}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Status: ${order.status}'),
            Text('Type: ${order.orderType ?? 'INSTANT'}'),
            if (order.deliveryAddress != null) Text('Address: ${order.deliveryAddress}'),
            const SizedBox(height: 12),
            ...order.items.map((item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(item.product.name),
                  trailing: Text('x${item.quantity} • ${formatCurrency(item.product.price)}'),
                )),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.teal)),
    );
  }
}
