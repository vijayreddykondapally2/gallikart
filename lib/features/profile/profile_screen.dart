// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/loader.dart';
import '../../core/widgets/primary_button.dart';
import 'profile_controller.dart';
import '../wallet/wallet_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  double? _pickedLat;
  double? _pickedLng;
  bool _locating = false;
  String _selectedLabel = 'Home';
  bool _setAsPrimary = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileControllerProvider.notifier).refreshProfile();
    });
  }

  void _syncControllers(ProfileState state) {
    if (state.name != null && _nameController.text != state.name) {
      _nameController.text = state.name!;
    }
    if (state.phone != null && _phoneController.text != state.phone) {
      _phoneController.text = state.phone!;
    }
    if (state.address != null && _addressController.text != state.address) {
      _addressController.text = state.address!;
    }
    _setAsPrimary = state.primaryAddress != null &&
        _addressController.text.trim() == state.primaryAddress!.trim();
    if (_pickedLat == null && _pickedLng == null && state.savedAddresses.isNotEmpty) {
      final primary = state.savedAddresses.first;
      _pickedLat = primary.latitude;
      _pickedLng = primary.longitude;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);
    final wallet = ref.watch(walletControllerProvider);
    final secondaryCount = state.savedAddresses.where((a) => !a.isPrimary).length;
    _syncControllers(state);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileTitle)),
      body: state.loading
          ? const Loader()
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          hintText: 'Enter your name',
                        ),
                        enabled: !state.loading,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter a name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          hintText: 'Enter your phone number',
                        ),
                        keyboardType: TextInputType.phone,
                        enabled: !state.loading,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter a phone number'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Delivery address',
                          hintText: 'Enter your delivery location',
                        ),
                        minLines: 2,
                        maxLines: 3,
                        enabled: !state.loading,
                        onChanged: (_) {
                          _pickedLat = null;
                          _pickedLng = null;
                        },
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _setAsPrimary,
                        onChanged: state.loading
                            ? null
                            : (val) => setState(() => _setAsPrimary = val ?? false),
                        title: const Text('Make this primary'),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 4),
                      if (secondaryCount >= 10)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Maximum 10 secondary addresses reached. Remove one to add another.',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ElevatedButton.icon(
                        icon: _locating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(_locating ? 'Fetching location...' : 'Use current location'),
                        onPressed: state.loading || _locating
                            ? null
                            : () async {
                                setState(() => _locating = true);
                                try {
                                  final position = await _determinePosition();
                                  setState(() {
                                    _pickedLat = position.latitude;
                                    _pickedLng = position.longitude;
                                    if (_addressController.text.trim().isEmpty) {
                                      _addressController.text = 'Current location';
                                    }
                                  });
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Location captured for address.'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Unable to fetch location: $e'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => _locating = false);
                                }
                              },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final label in ['Home', 'Office', 'Other'])
                            ChoiceChip(
                              label: Text(label),
                              selected: _selectedLabel == label,
                              onSelected: (selected) {
                                if (selected)
                                  setState(() => _selectedLabel = label);
                              },
                            ),
                        ],
                      ),
                      CheckboxListTile(
                        value: _setAsPrimary,
                        onChanged: (val) {
                          setState(() => _setAsPrimary = val ?? false);
                        },
                        title: const Text('Set as primary delivery address'),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 12),
                      if (state.savedAddresses.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Saved addresses'),
                            const SizedBox(height: 8),
                            ...state.savedAddresses.map(
                              (entry) => Card(
                                child: ListTile(
                                  title: Text('${entry.label}: ${entry.address}'),
                                  subtitle: entry.isPrimary
                                      ? const Text('Primary address')
                                      : null,
                                  trailing: entry.isPrimary
                                      ? const Chip(label: Text('Primary'))
                                      : TextButton(
                                          onPressed: state.loading
                                              ? null
                                              : () async {
                                                  final ok = await controller.saveProfile(
                                                    address: entry.address,
                                                    addressLabel: entry.label,
                                                    latitude: entry.latitude,
                                                    longitude: entry.longitude,
                                                    setAsPrimary: true,
                                                  );
                                                  if (!mounted) return;
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(ok
                                                          ? 'Set as primary'
                                                          : 'Cannot set primary right now'),
                                                    ),
                                                  );
                                                },
                                          child: const Text('Make primary'),
                                        ),
                                  onTap: () {
                                    _addressController.text = entry.address;
                                    setState(() {
                                      _selectedLabel = entry.label;
                                      _setAsPrimary = entry.isPrimary;
                                    });
                                    _pickedLat = entry.latitude;
                                    _pickedLng = entry.longitude;
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Galli Car Wallet',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Balance: ₹${wallet.balance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (wallet.ledger.isNotEmpty)
                                SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    itemCount: wallet.ledger.length,
                                    itemBuilder: (context, index) {
                                      final entry = wallet.ledger.reversed.toList()[index];
                                      final sign = entry.type == 'credit' ? '+' : '-';
                                      final color = entry.type == 'credit'
                                          ? Colors.green
                                          : Colors.red;
                                      return ListTile(
                                        dense: true,
                                        title: Text('${entry.note} • ${entry.orderId}'),
                                        subtitle: Text(
                                          '${entry.timestamp.toLocal()}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        trailing: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '$sign₹${entry.amount.abs().toStringAsFixed(2)}',
                                              style: TextStyle(color: color),
                                            ),
                                            Text(
                                              'Bal: ₹${entry.balanceAfter.toStringAsFixed(2)}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                )
                              else
                                const Text('No wallet activity yet.'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit profile'),
                            onPressed: () => _formKey.currentState?.reset(),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_location_alt),
                            label: const Text('Add new address'),
                            onPressed: secondaryCount >= 10 && !_setAsPrimary
                                ? null
                                : () {
                                    _addressController.clear();
                                    setState(() {
                                      _selectedLabel = 'Other';
                                      _setAsPrimary = false;
                                    });
                                  },
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.chat),
                            label: const Text('Order via WhatsApp'),
                            onPressed: _launchWhatsApp,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: secondaryCount >= 10 && !_setAsPrimary
                              ? null
                              : () {
                                  _addressController.clear();
                                  setState(() {
                                    _selectedLabel = 'Other';
                                    _setAsPrimary = false;
                                  });
                                },
                          child: const Text('Add another address'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Save details',
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            if (secondaryCount >= 10 && !_setAsPrimary && state.savedAddresses.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Maximum 10 secondary addresses reached. Remove one to add another.'),
                                ),
                              );
                              return;
                            }
                            controller.saveProfile(
                              name: _nameController.text.trim(),
                              phone: _phoneController.text.trim(),
                              address: _addressController.text.trim(),
                              addressLabel: _selectedLabel,
                              latitude: _pickedLat,
                              longitude: _pickedLng,
                              setAsPrimary: _setAsPrimary || state.savedAddresses.isEmpty,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _launchWhatsApp() async {
    final uri = Uri.parse('https://wa.me/918019220628?text=Hi%20GalliKart');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<Position> _determinePosition() async {
    final servicesEnabled = await Geolocator.isLocationServiceEnabled();
    if (!servicesEnabled) {
      throw Exception('Enable location services to continue');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission denied. Please enable location access in app settings.',
      );
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    );
  }
}
