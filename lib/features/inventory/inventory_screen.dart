// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../routes/app_routes.dart';
import 'inventory_controller.dart';
import 'inventory_item.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryControllerProvider);
    final controller = ref.read(inventoryControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.inventoryTitle),
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
      body: inventory.isEmpty
          ? const Center(child: Text('No inventory data yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: inventory.length,
              itemBuilder: (context, index) {
                final item = inventory[index];
                final bgColor = item.isOutOfStock
                    ? AppColors.danger.withAlpha(28)
                    : item.isLowStock
                        ? AppColors.warning.withAlpha(20)
                        : null;
                return Card(
                  color: bgColor,
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('₹${item.price.toStringAsFixed(2)} / ${item.unit}'),
                        Text('Stock: ${item.stockQty.toStringAsFixed(1)} • Low stock ≤ ${item.lowStockThreshold.toStringAsFixed(1)}'),
                        Text(
                          item.isAvailable ? 'Available' : 'Unavailable',
                          style: TextStyle(
                            color: item.isAvailable ? AppColors.success : AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: item.isAvailable,
                          onChanged: (value) => controller.toggleAvailability(item.id, value),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditDialog(context, controller, item),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, controller),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
    );
  }

  void _showEditDialog(BuildContext context, InventoryController controller, InventoryItem item) {
    final stockText = TextEditingController(text: item.stockQty.toStringAsFixed(1));
    final priceText = TextEditingController(text: item.price.toStringAsFixed(2));
    final lowStockText = TextEditingController(text: item.lowStockThreshold.toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stockText,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stock quantity'),
            ),
            TextField(
              controller: priceText,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            TextField(
              controller: lowStockText,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Low-stock threshold'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: Navigator.of(context).pop, child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final parsedStock = double.tryParse(stockText.text.trim());
              final parsedPrice = double.tryParse(priceText.text.trim());
              final parsedLow = double.tryParse(lowStockText.text.trim());
              if (parsedStock != null) {
                controller.updateStock(item.id, parsedStock);
              }
              if (parsedPrice != null) {
                controller.updatePrice(item.id, parsedPrice);
              }
              if (parsedLow != null) {
                controller.updateLowStockThreshold(item.id, parsedLow);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, InventoryController controller) {
    final nameText = TextEditingController();
    final priceText = TextEditingController();
    final stockText = TextEditingController();
    final unitText = TextEditingController(text: 'unit');
    final lowStockText = TextEditingController(text: '0');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameText,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: priceText,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            TextField(
              controller: stockText,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stock quantity'),
            ),
            TextField(
              controller: unitText,
              decoration: const InputDecoration(labelText: 'Unit (kg, pcs, etc)'),
            ),
            TextField(
              controller: lowStockText,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Low-stock threshold'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: Navigator.of(context).pop, child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final name = nameText.text.trim();
              final price = double.tryParse(priceText.text.trim());
              final stock = double.tryParse(stockText.text.trim());
              final unit = unitText.text.trim().isEmpty ? 'unit' : unitText.text.trim();
              final lowStock = double.tryParse(lowStockText.text.trim()) ?? 0;
              if (name.isNotEmpty && price != null && stock != null) {
                controller.addProduct(
                  name: name,
                  price: price,
                  stockQty: stock,
                  unit: unit,
                  lowStockThreshold: lowStock,
                );
              }
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
