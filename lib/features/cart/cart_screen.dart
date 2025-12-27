// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/money_utils.dart';
import '../../core/widgets/primary_button.dart';
import '../../routes/app_routes.dart';
import '../orders/order_controller.dart';
import '../profile/profile_controller.dart';
import 'cart_controller.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartControllerProvider);
    final orderController = ref.read(orderControllerProvider.notifier);
    final cartController = ref.read(cartControllerProvider.notifier);
    final profile = ref.watch(profileControllerProvider);
    final profileCtrl = ref.read(profileControllerProvider.notifier);
    final total = cartItems.fold(0.0, (sum, item) => sum + item.total);

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(title: const Text(AppStrings.cartTitle)),
      body: cartItems.isEmpty
          ? const Center(child: Text('Cart is empty'))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.shade100,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart_outlined, color: Colors.teal, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${cartItems.length} item${cartItems.length == 1 ? '' : 's'} in cart',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.teal),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final cartItem = cartItems[index];
                      return Container(
                        margin: EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.shade50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.shade100,
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: cartItem.product.imageUrl.isNotEmpty
                                        ? Image.network(
                                            cartItem.product.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Center(
                                                child: Text(
                                                  cartItem.product.name.isNotEmpty
                                                      ? cartItem.product.name[0].toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              );
                                            },
                                          )
                                        : Center(
                                            child: Text(
                                              cartItem.product.name.isNotEmpty
                                                  ? cartItem.product.name[0].toUpperCase()
                                                  : '?',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.local_grocery_store, size: 14, color: Colors.teal),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              cartItem.product.name,
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          _quantityButton(
                                            onTap: () => cartController.decrement(cartItem.product.id),
                                            icon: Icons.remove,
                                          ),
                                          Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 6),
                                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${cartItem.quantity}',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          _quantityButton(
                                            onTap: () => cartController.add(cartItem.product),
                                            icon: Icons.add,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      formatCurrency(cartItem.product.price),
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatCurrency(cartItem.total),
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.teal),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            formatCurrency(total),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Proceed to payment',
                        onPressed: cartItems.isEmpty
                            ? null
                            : () async {
                                final selection = await _selectAddress(
                                  context,
                                  profileCtrl,
                                  profile,
                                );
                                if (selection == null) return;
                                final pending = orderController.createPending(
                                  cartItems,
                                  applyWallet: false,
                                  deliveryAddress: selection.address,
                                  deliveryLatitude: selection.latitude,
                                  deliveryLongitude: selection.longitude,
                                  deliveryLabel: selection.label,
                                );
                                if (pending == null) return;
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.payment,
                                  arguments: pending,
                                );
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _quantityButton({required VoidCallback onTap, required IconData icon}) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Icon(icon, size: 16, color: Colors.teal.shade800),
        ),
      ),
    );
  }

  Future<_AddressPick?> _selectAddress(
    BuildContext context,
    ProfileController profileCtrl,
    ProfileState profile,
  ) async {
    final secondaryCount = profile.savedAddresses.where((a) => !a.isPrimary).length;
    String choice = profile.savedAddresses.isNotEmpty ? 'existing' : 'new';
    int selectedIndex = 0;
    final newAddressController = TextEditingController();
    String newLabel = 'Home';

    final media = MediaQuery.of(context);
    final result = await showDialog<_AddressPick>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final canSubmit = choice == 'existing'
                ? profile.savedAddresses.isNotEmpty
                : newAddressController.text.trim().isNotEmpty;
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: media.size.width * 0.9,
                  maxHeight: media.size.height * 0.8,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Delivery address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RadioListTile<String>(
                                value: 'existing',
                                groupValue: choice,
                                onChanged: (val) => setState(() => choice = val ?? 'existing'),
                                title: const Text('Use saved address'),
                                subtitle: profile.savedAddresses.isEmpty
                                    ? const Text('No saved addresses')
                                    : Text('Selected: ${profile.savedAddresses[selectedIndex].label}'),
                              ),
                              if (choice == 'existing' && profile.savedAddresses.isNotEmpty)
                                SizedBox(
                                  height: 180,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: profile.savedAddresses.length,
                                    itemBuilder: (context, index) {
                                      final entry = profile.savedAddresses[index];
                                      return RadioListTile<int>(
                                        value: index,
                                        groupValue: selectedIndex,
                                        onChanged: (val) => setState(() => selectedIndex = val ?? 0),
                                        title: Text('${entry.label}: ${entry.address}'),
                                        subtitle: entry.isPrimary ? const Text('Primary') : null,
                                      );
                                    },
                                  ),
                                ),
                              RadioListTile<String>(
                                value: 'new',
                                groupValue: choice,
                                onChanged: (val) => setState(() => choice = val ?? 'new'),
                                title: const Text('Add new address'),
                              ),
                              if (choice == 'new') ...[
                                if (secondaryCount >= 10 && profile.savedAddresses.isNotEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      'You have reached the limit of 10 secondary addresses. Remove one in profile to add another.',
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                  ),
                                TextField(
                                  controller: newAddressController,
                                  minLines: 2,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Delivery address',
                                    hintText: 'Type the delivery address',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: ['Home', 'Office', 'Other']
                                      .map(
                                        (label) => ChoiceChip(
                                          label: Text(label),
                                          selected: newLabel == label,
                                          onSelected: (v) {
                                            if (v) setState(() => newLabel = label);
                                          },
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(null),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: !canSubmit
                                ? null
                                : () async {
                                    if (choice == 'existing' && profile.savedAddresses.isNotEmpty) {
                                      final entry = profile.savedAddresses[selectedIndex];
                                      Navigator.of(dialogContext).pop(
                                        _AddressPick(
                                          address: entry.address,
                                          label: entry.label,
                                          latitude: null,
                                          longitude: null,
                                        ),
                                      );
                                    } else {
                                      if (secondaryCount >= 10 && profile.savedAddresses.isNotEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Maximum 10 secondary addresses reached. Remove one in profile to add another.'),
                                          ),
                                        );
                                        return;
                                      }
                                      final addr = newAddressController.text.trim();
                                      if (addr.isEmpty) return;
                                      final ok = await profileCtrl.saveProfile(
                                        address: addr,
                                        addressLabel: newLabel,
                                        setAsPrimary: profile.savedAddresses.isEmpty,
                                      );
                                      if (!ok) return;
                                      Navigator.of(dialogContext).pop(
                                        _AddressPick(
                                          address: addr,
                                          label: newLabel,
                                          latitude: null,
                                          longitude: null,
                                        ),
                                      );
                                    }
                                  },
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    return result;
  }
}

class _AddressPick {
  const _AddressPick({
    required this.address,
    required this.label,
    this.latitude,
    this.longitude,
  });

  final String address;
  final String label;
  final double? latitude;
  final double? longitude;
}
