// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedAddress {
  const SavedAddress({
    required this.label,
    required this.address,
    this.latitude,
    this.longitude,
    this.isPrimary = false,
  });

  final String label;
  final String address;
  final double? latitude;
  final double? longitude;
  final bool isPrimary;

  SavedAddress copyWith({
    String? label,
    String? address,
    double? latitude,
    double? longitude,
    bool? isPrimary,
  }) {
    return SavedAddress(
      label: label ?? this.label,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}

class ProfileState {
  const ProfileState({
    this.loading = false,
    this.name,
    this.phone,
    this.address,
    this.savedAddresses = const <SavedAddress>[],
    this.primaryAddress,
  });

  final bool loading;
  final String? name;
  final String? phone;
  final String? address;
  final List<SavedAddress> savedAddresses;
  final String? primaryAddress;

  ProfileState copyWith({
    bool? loading,
    String? name,
    String? phone,
    String? address,
    List<SavedAddress>? savedAddresses,
    String? primaryAddress,
  }) {
    return ProfileState(
      loading: loading ?? this.loading,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      primaryAddress: primaryAddress ?? this.primaryAddress,
    );
  }
}

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController() : super(const ProfileState()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('profile_name');
    final phone = prefs.getString('profile_phone');
    final address = prefs.getString('profile_address');
    final primaryAddress = prefs.getString('profile_primary_address');
    final savedAddressesJson = prefs.getStringList('profile_saved_addresses') ?? [];
    final savedAddresses = savedAddressesJson.map((json) {
      final parts = json.split('|');
      if (parts.length >= 2) {
        return SavedAddress(
          label: parts[0],
          address: parts[1],
          latitude: parts.length > 2 ? double.tryParse(parts[2]) : null,
          longitude: parts.length > 3 ? double.tryParse(parts[3]) : null,
          isPrimary: parts.length > 4 ? parts[4] == '1' : false,
        );
      }
      return null;
    }).whereType<SavedAddress>().toList();
    final resolvedPrimary = (primaryAddress?.trim().isNotEmpty ?? false)
        ? primaryAddress
        : (savedAddresses.isNotEmpty ? savedAddresses.first.address : null);
    final addressesWithPrimary = savedAddresses.map((sa) {
      final isPrimary = resolvedPrimary != null &&
          sa.address.trim().toLowerCase() == resolvedPrimary.trim().toLowerCase();
      return sa.copyWith(isPrimary: isPrimary);
    }).toList();
    final hasPrimaryInList = addressesWithPrimary.any((sa) => sa.isPrimary);
    if (!hasPrimaryInList && resolvedPrimary != null && resolvedPrimary.isNotEmpty) {
      addressesWithPrimary.insert(
        0,
        SavedAddress(
          label: 'Primary',
          address: resolvedPrimary,
          isPrimary: true,
        ),
      );
    }
    state = ProfileState(
      name: name,
      phone: phone,
      address: address,
      savedAddresses: addressesWithPrimary,
      primaryAddress: resolvedPrimary ??
          (addressesWithPrimary.isNotEmpty ? addressesWithPrimary.first.address : null),
    );
  }

  Future<void> _saveProfileToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', state.name ?? '');
    await prefs.setString('profile_phone', state.phone ?? '');
    await prefs.setString('profile_address', state.address ?? '');
    await prefs.setString('profile_primary_address', state.primaryAddress ?? '');
    final savedAddressesJson = state.savedAddresses.map((sa) =>
      '${sa.label}|${sa.address}|${sa.latitude ?? ''}|${sa.longitude ?? ''}|${sa.isPrimary ? 1 : 0}'
    ).toList();
    await prefs.setStringList('profile_saved_addresses', savedAddressesJson);
  }

  Future<void> refreshProfile() async {
    state = state.copyWith(loading: true);
    await Future.delayed(const Duration(milliseconds: 300));
    await _loadProfile();
    state = state.copyWith(loading: false);
  }

  Future<bool> saveProfile({
    String? name,
    String? phone,
    String? address,
    String addressLabel = 'Home',
    double? latitude,
    double? longitude,
    bool setAsPrimary = false,
  }) async {
    state = state.copyWith(loading: true);
    await Future.delayed(const Duration(milliseconds: 200));
    var updatedList = List<SavedAddress>.from(state.savedAddresses);
    final trimmedAddress = address?.trim() ?? '';
    final label = addressLabel.trim().isEmpty ? 'Home' : addressLabel.trim();
    bool success = true;

    if (trimmedAddress.isNotEmpty) {
      final existingIndex = updatedList.indexWhere(
        (entry) => entry.address.trim().toLowerCase() == trimmedAddress.toLowerCase(),
      );
      final existing = existingIndex >= 0 ? updatedList[existingIndex] : null;
      final bool newIsPrimary = setAsPrimary ||
          (state.primaryAddress?.trim().toLowerCase() == trimmedAddress.toLowerCase());

      if (existingIndex >= 0) {
        updatedList[existingIndex] = existing!.copyWith(
          label: label,
          latitude: latitude ?? existing.latitude,
          longitude: longitude ?? existing.longitude,
          isPrimary: newIsPrimary || existing.isPrimary,
        );
      } else {
        final secondaryCount = updatedList.where((entry) => !entry.isPrimary).length;
        if (!newIsPrimary && secondaryCount >= 10) {
          state = state.copyWith(loading: false);
          return false;
        }
        updatedList.add(
          SavedAddress(
            label: label,
            address: trimmedAddress,
            latitude: latitude,
            longitude: longitude,
            isPrimary: newIsPrimary,
          ),
        );
      }

      if (newIsPrimary) {
        updatedList = updatedList
            .map((sa) => sa.address.trim().toLowerCase() == trimmedAddress.toLowerCase()
                ? sa.copyWith(isPrimary: true)
                : sa.copyWith(isPrimary: false))
            .toList();
      }
    }

    SavedAddress? primaryEntry;
    for (final entry in updatedList) {
      if (entry.isPrimary) {
        primaryEntry = entry;
        break;
      }
    }
    if (primaryEntry == null && updatedList.isNotEmpty) {
      updatedList = [
        updatedList.first.copyWith(isPrimary: true),
        ...updatedList.skip(1).map((e) => e.copyWith(isPrimary: false)),
      ];
      primaryEntry = updatedList.first;
    }

    state = state.copyWith(
      loading: false,
      name: name ?? state.name,
      phone: phone ?? state.phone,
      address: address ?? state.address,
      savedAddresses: updatedList,
      primaryAddress: primaryEntry?.address ?? state.primaryAddress,
    );
    await _saveProfileToPrefs();
    return success;
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>(
      (ref) => ProfileController(),
    );
