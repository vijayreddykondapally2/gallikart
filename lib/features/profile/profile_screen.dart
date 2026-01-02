// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upi_india/upi_india.dart' as upi;
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_strings.dart';
import '../../core/services/location_service.dart';
import '../../core/providers/core_providers.dart';
import '../../core/widgets/loader.dart';
import '../../core/widgets/primary_button.dart';
import '../../routes/app_routes.dart';
import '../../core/services/upi_service.dart';
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
  bool _walletLoading = false;
  String? _walletError;
  List<upi.UpiApp> _upiApps = const [];
  final LocationService _locationService = const LocationService();

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
    final profileAsync = ref.watch(userProfileProvider);
    final wallet = ref.watch(walletControllerProvider);

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text(AppStrings.profileTitle),
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
      body: profileAsync.when(
        loading: () => const Loader(),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (state) {
          _sync(state);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionCard(
                    title: 'Profile',
                    icon: Icons.person_outline,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _readOnlyField('Name', _nameController.text),
                        _readOnlyField('Phone', _phoneController.text),
                        _readOnlyField('Primary address', _addressController.text),
                        const SizedBox(height: 8),
                        PrimaryButton(
                          label: 'Add New Address',
                          onPressed: () => _openAddressSheet(context, state),
                        ),
                      ],
                    ),
                  ),
                  if (state.savedAddresses.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _sectionCard(
                      title: 'Saved addresses',
                      icon: Icons.location_on_outlined,
                      child: Column(
                        children: state.savedAddresses
                            .map(
                              (addr) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text('${addr.label}: ${addr.address}'),
                                subtitle: addr.isPrimary ? const Text('Primary') : null,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Wallet',
                    icon: Icons.account_balance_wallet,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Balance', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                '₹${wallet.balance.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.teal),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _walletLoading ? null : () => _promptAddMoney(context),
                          icon: _walletLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.add_circle_outline, color: Colors.teal),
                          label: const Text('Add Money'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Support',
                    icon: Icons.support_agent,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Customer Support'),
                      subtitle: const Text('Call or WhatsApp for help'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.call, color: Colors.teal),
                            onPressed: () => _launchUri(Uri.parse('tel:+911234567890')),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chat, color: Colors.teal),
                            onPressed: () => _launchUri(Uri.parse('https://wa.me/911234567890')),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_walletError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _walletError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Logout',
                    onPressed: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (!mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openAddressSheet(BuildContext context, ProfileState state) async {
    final nameController = TextEditingController(text: state.name ?? '');
    final phoneController = TextEditingController(text: state.phone ?? '');
    final addressController = TextEditingController();
    String label = 'Home';
    bool setPrimary = state.savedAddresses.isEmpty;
    double? latitude;
    double? longitude;
    bool saving = false;
    String? errorText;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              Future<void> fillLocation() async {
                final loc = await _locationService.getCurrentLocation();
                setModal(() {
                  latitude = loc.latitude;
                  longitude = loc.longitude;
                });
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Add new address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: addressController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Address line'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Home', 'Office', 'Other']
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(entry),
                              selected: label == entry,
                              onSelected: (_) => setModal(() => label = entry),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Set as primary'),
                    value: setPrimary,
                    onChanged: (val) => setModal(() => setPrimary = val ?? false),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          latitude == null
                              ? 'No location attached'
                              : 'Lat: ${latitude!.toStringAsFixed(4)}, Lng: ${longitude!.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: saving ? null : fillLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Use current'),
                      ),
                    ],
                  ),
                  if (errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(errorText!, style: const TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: saving ? null : () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (addressController.text.trim().isEmpty) {
                                  setModal(() => errorText = 'Enter address');
                                  return;
                                }
                                setModal(() {
                                  saving = true;
                                  errorText = null;
                                });
                                final success = await ref.read(profileControllerProvider.notifier).saveProfile(
                                      name: nameController.text.trim().isEmpty ? state.name : nameController.text.trim(),
                                      phone: phoneController.text.trim().isEmpty ? state.phone : phoneController.text.trim(),
                                      address: addressController.text.trim(),
                                      addressLabel: label,
                                      latitude: latitude,
                                      longitude: longitude,
                                      setAsPrimary: setPrimary,
                                      contactName: nameController.text.trim(),
                                      contactPhone: phoneController.text.trim(),
                                    );
                                if (!success) {
                                  setModal(() {
                                    saving = false;
                                    errorText = 'Could not save address. Please try again.';
                                  });
                                  return;
                                }
                                if (mounted) Navigator.pop(ctx);
                              },
                        child: saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 16, color: Colors.black87)),
          const Divider(height: 14),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child, IconData? icon}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade100,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: Colors.teal),
                    const SizedBox(width: 6),
                  ],
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUri(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _promptAddMoney(BuildContext context) async {
    setState(() {
      _walletError = null;
    });
    final amountController = TextEditingController(text: '200');
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add money to wallet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (₹)'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [100, 200, 500]
                  .map((preset) => ActionChip(
                        label: Text('₹$preset'),
                        onPressed: () => amountController.text = preset.toString(),
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final amt = double.tryParse(amountController.text.trim()) ?? 0;
              if (amt <= 0) {
                setState(() => _walletError = 'Enter a valid amount');
                return;
              }
              Navigator.pop(context);
                _processWalletTopUp(context, amt);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _processWalletTopUp(BuildContext context, double amount) async {
    setState(() {
      _walletLoading = true;
      _walletError = null;
    });
    try {
      await _ensureUpiApps();
      if (_upiApps.isEmpty) {
        setState(() => _walletError = 'No UPI apps found on this device.');
        return;
      }
      final app = await _pickUpiApp(context);
      if (app == null) {
        setState(() => _walletError = 'Payment cancelled.');
        return;
      }
      final txn = await UpiService.startTransaction(
        app: app,
        receiverUpiId: '8019220628@ybl',
        receiverName: 'GalliKart Wallet',
        amount: amount,
        transactionRefId: 'wallet-${DateTime.now().millisecondsSinceEpoch}',
        transactionNote: 'Wallet top-up',
      );
      if (!mounted) return;
      if (txn.status == UpiPaymentStatus.success) {
        ref.read(walletControllerProvider.notifier).credit(
              amount: amount,
              orderId: 'wallet-topup',
              note: 'UPI top-up ${txn.transactionId ?? ''}',
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallet updated after successful payment.')),
        );
      } else {
        setState(() => _walletError = 'Payment was not successful. No wallet credit made.');
      }
    } catch (error) {
      setState(() => _walletError = 'UPI error: $error');
    } finally {
      if (mounted) setState(() => _walletLoading = false);
    }
  }

  Future<void> _ensureUpiApps() async {
    if (_upiApps.isNotEmpty) return;
    _upiApps = await UpiService.getAvailableApps();
  }

  Future<upi.UpiApp?> _pickUpiApp(BuildContext context) async {
    return showModalBottomSheet<upi.UpiApp>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _upiApps
              .map(
                (app) => ListTile(
                  leading: Image.memory(app.icon, width: 32, height: 32),
                  title: Text(app.name),
                  onTap: () => Navigator.pop(context, app),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
