import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/money_utils.dart';
import 'models/ops_order.dart';
import 'ops_orders_controller.dart';

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(opsOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ops Orders')),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final order = orders[index];
              final shortId = order.id.length > 6 ? order.id.substring(order.id.length - 6) : order.id;
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
                          _pill(order.type),
                          if (order.isRecurring && order.mode != null) ...[
                            const SizedBox(width: 6),
                            _pill(order.mode!),
                          ],
                          const Spacer(),
                          Text(formatCurrency(order.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${order.items.length} item(s) • ${order.status}'),
                      if (order.address != null && order.address!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(order.address!, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _statusButton(context, ref, order, 'CONFIRMED', 'Accept'),
                          _statusButton(context, ref, order, 'PACKING', 'Picked at store'),
                          _statusButton(context, ref, order, 'OUT_FOR_DELIVERY', 'On the way'),
                          _statusButton(context, ref, order, 'DELIVERED', 'Delivered'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _showDetails(context, order),
                        child: const Text('View details'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load orders: $error')),
      ),
    );
  }

  Widget _statusButton(BuildContext context, WidgetRef ref, OpsOrder order, String target, String label) {
    final isCurrent = order.status.toUpperCase() == target;
    return ElevatedButton(
      onPressed: isCurrent ? null : () => _updateStatus(context, ref, order, target),
      child: Text(label),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, OpsOrder order, String next) async {
    await ref.read(opsOrdersServiceProvider).updateStatus(order: order, nextStatus: next);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order ${order.id} → $next')),
      );
    }
  }

  void _showDetails(BuildContext context, OpsOrder order) {
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
            Text('Type: ${order.type}${order.mode != null ? ' • ${order.mode}' : ''}'),
            if (order.address != null) Text('Address: ${order.address}'),
            const SizedBox(height: 12),
            ...order.items.map((item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(item.name),
                  trailing: Text('x${item.quantity}'),
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
