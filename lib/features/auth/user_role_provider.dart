// Role provider for gating admin and delivery flows.
// Uses Firestore users/{uid}.role; defaults to USER when missing.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';

const roleUser = 'USER';
const roleOwner = 'OWNER';
const roleStaff = 'STAFF';
const roleDelivery = 'DELIVERY';

final userRoleProvider = StreamProvider<String>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  final uid = auth.currentUser?.uid;
  if (uid == null) return Stream.value(roleUser);
  return firestore.collection('users').doc(uid).snapshots().map((doc) {
    final data = doc.data();
    final raw = (data?['role'] as String?);
    final role = raw == null ? null : raw.toUpperCase().trim();
    if (role == roleOwner || role == roleStaff || role == roleDelivery) {
      return role!;
    }
    return roleUser;
  }).handleError((_, __) => roleUser);
});
