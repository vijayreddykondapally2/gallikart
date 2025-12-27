// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/loader.dart';
import '../../core/widgets/primary_button.dart';
import '../../routes/app_routes.dart';
import '../wallet/wallet_controller.dart';
import 'profile_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileControllerProvider.notifier).refreshProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _sync(ProfileState state) {
    if (state.name != null) _nameController.text = state.name!;
    if (state.phone != null) _phoneController.text = state.phone!;
    if (state.primaryAddress != null) {
      _addressController.text = state.primaryAddress!;
    } else if (state.address != null) {
      _addressController.text = state.address!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final wallet = ref.watch(walletControllerProvider);
    _sync(state);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileTitle)),
      body: state.loading
          ? const Loader()
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _readOnlyField('Name', _nameController.text),
                    _readOnlyField('Phone', _phoneController.text),
                    _readOnlyField('Primary address', _addressController.text),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Add New Address',
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.delivery),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: ListTile(
                        title: const Text('Wallet'),
                        subtitle: Text('Balance: ₹${wallet.balance.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => ref.read(walletControllerProvider.notifier).credit(
                                    amount: 100,
                                    orderId: 'manual-topup',
                                    note: 'Manual wallet top-up',
                                  ),
                              child: const Text('Add money'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.account_balance_wallet_outlined),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Customer Support'),
                      subtitle: const Text('Call or WhatsApp for help'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.call),
                            onPressed: () => _launchUri(Uri.parse('tel:+911234567890')),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chat),
                            onPressed: () => _launchUri(Uri.parse('https://wa.me/911234567890')),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value.isEmpty ? '-' : value,
            style: const TextStyle(fontSize: 16, color: Colors.black87)),
        const Divider(),
      ],
    );
  }

  Future<void> _launchUri(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
