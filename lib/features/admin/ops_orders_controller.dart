// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart' as core;
import 'models/ops_order.dart';

final opsOrdersProvider = StreamProvider.autoDispose<List<OpsOrder>>((ref) {
  final firestore = ref.read(core.firebaseFirestoreProvider);
  return firestore
      .collection('opsOrders')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(opsOrderFromOpsDoc).toList());
});

class OpsOrdersService {
  OpsOrdersService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> updateStatus({required OpsOrder order, required String nextStatus}) async {
    final normalized = nextStatus.toUpperCase();
    await order.ref.set(
      {
        'status': normalized,
        'orderStatus': normalized,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}

final opsOrdersServiceProvider = Provider<OpsOrdersService>(
  (ref) => OpsOrdersService(ref.read(core.firebaseFirestoreProvider)),
);
