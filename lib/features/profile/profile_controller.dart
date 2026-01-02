// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';

class SavedAddress {
  const SavedAddress({
    this.id,
    required this.label,
    required this.address,
    this.latitude,
    this.longitude,
    this.isPrimary = false,
    this.contactName,
    this.contactPhone,
  });

  final String? id;
  final String label;
  final String address;
  final double? latitude;
  final double? longitude;
  final bool isPrimary;
  final String? contactName;
  final String? contactPhone;

  SavedAddress copyWith({
    String? id,
    String? label,
    String? address,
    double? latitude,
    double? longitude,
    bool? isPrimary,
    String? contactName,
    String? contactPhone,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPrimary: isPrimary ?? this.isPrimary,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'isPrimary': isPrimary,
      'name': contactName,
      'phone': contactPhone,
    };
  }

  factory SavedAddress.fromMap(Map<String, dynamic> map, {String? id}) {
    return SavedAddress(
      id: id ?? map['id'] as String?,
      label: (map['label'] ?? map['name'] ?? 'Home') as String,
      address: (map['address'] ?? map['addressLine'] ?? '') as String,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isPrimary: (map['isPrimary'] as bool?) ?? false,
      contactName: map['name'] as String?,
      contactPhone: map['phone'] as String?,
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
  ProfileController(this._firestore, this._userId) : super(const ProfileState()) {
    _bindProfileStream();
    _loadProfile();
  }

  final FirebaseFirestore _firestore;
  final String? _userId;
  StreamSubscription<ProfileState>? _profileSub;

  void _bindProfileStream() {
    if (_userId == null) return;
    final docRef = _firestore.collection('users').doc(_userId);
    _profileSub = docRef.snapshots().asyncMap((snapshot) async {
      if (!snapshot.exists) return const ProfileState();
      final addresses = await _fetchAddresses(docRef);
      return _mapProfile(snapshot.data() ?? {}, addresses);
    }).listen((profile) {
      state = profile;
    });
  }

  Future<List<SavedAddress>> _fetchAddresses(DocumentReference<Map<String, dynamic>> docRef) async {
    final snapshot = await docRef.collection('addresses').get();
    return snapshot.docs
        .map((doc) => SavedAddress.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  ProfileState _mapProfile(Map<String, dynamic> data, List<SavedAddress> addresses) {
    var resolvedAddresses = addresses;
    SavedAddress? primaryEntry;
    for (final entry in resolvedAddresses) {
      if (entry.isPrimary) {
        primaryEntry = entry;
        break;
      }
    }
    if (primaryEntry == null && resolvedAddresses.isNotEmpty) {
      primaryEntry = resolvedAddresses.first;
      resolvedAddresses = [
        resolvedAddresses.first.copyWith(isPrimary: true),
        ...resolvedAddresses.skip(1).map((e) => e.copyWith(isPrimary: false)),
      ];
    }

    return ProfileState(
      name: data['name'] as String?,
      phone: data['phone'] as String?,
      savedAddresses: resolvedAddresses,
      primaryAddress: primaryEntry?.address,
    );
  }

  Future<void> _loadProfile() async {
    if (_userId == null) return;
    final docRef = _firestore.collection('users').doc(_userId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) return;
    final addresses = await _fetchAddresses(docRef);
    state = _mapProfile(snapshot.data() ?? {}, addresses);
  }

  Stream<ProfileState> watchProfile() {
    if (_userId == null) return Stream.value(const ProfileState());
    final docRef = _firestore.collection('users').doc(_userId);
    return docRef.snapshots().asyncMap((snapshot) async {
      if (!snapshot.exists) return const ProfileState();
      final addresses = await _fetchAddresses(docRef);
      return _mapProfile(snapshot.data() ?? {}, addresses);
    });
  }

  Future<void> refreshProfile() async {
    state = state.copyWith(loading: true);
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
    String? contactName,
    String? contactPhone,
  }) async {
    if (_userId == null) return false;
    state = state.copyWith(loading: true);
    try {
      final docRef = _firestore.collection('users').doc(_userId);
      final trimmedAddress = address?.trim() ?? '';
      final label = addressLabel.trim().isEmpty ? 'Home' : addressLabel.trim();

      await docRef.set(
        {
          'name': name ?? state.name ?? '',
          'phone': phone ?? state.phone ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (trimmedAddress.isNotEmpty) {
        final addressesRef = docRef.collection('addresses');
        final existing = await addressesRef.where('address', isEqualTo: trimmedAddress).limit(1).get();
        final addrRef = existing.docs.isNotEmpty ? existing.docs.first.reference : addressesRef.doc();

        await addrRef.set(
          {
            'label': label,
            'address': trimmedAddress,
            'latitude': latitude,
            'longitude': longitude,
            'isPrimary': setAsPrimary,
            'name': contactName ?? name ?? state.name ?? '',
            'phone': contactPhone ?? phone ?? state.phone ?? '',
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': existing.docs.isNotEmpty
                ? existing.docs.first.data()['createdAt'] ?? FieldValue.serverTimestamp()
                : FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        if (setAsPrimary) {
          final others = await addressesRef.get();
          for (final doc in others.docs) {
            if (doc.id != addrRef.id && (doc.data()['isPrimary'] as bool? ?? false)) {
              await doc.reference.set({'isPrimary': false}, SetOptions(merge: true));
            }
          }
        }
      }

      await _loadProfile();
      state = state.copyWith(loading: false);
      return true;
    } catch (_) {
      state = state.copyWith(loading: false);
      return false;
    }
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
      final user = ref.watch(firebaseAuthProvider).currentUser;
      return ProfileController(
        ref.read(firebaseFirestoreProvider),
        user?.uid,
      );
    });

final userProfileProvider = StreamProvider<ProfileState>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value(const ProfileState());
  final controller = ref.watch(profileControllerProvider.notifier);
  return controller.watchProfile();
});
