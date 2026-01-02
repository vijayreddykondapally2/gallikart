import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VendorInventoryService {
  VendorInventoryService(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _vendorId {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Vendor must be signed in');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _inventoryRef =>
      _firestore.collection('vendors').doc(_vendorId).collection('inventory');

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> inventorySnapshots() {
    return _inventoryRef.orderBy('name').snapshots().map((snap) => snap.docs);
  }

  Future<void> addProduct({
    required String name,
    required double price,
    required double stockQty,
    required String unit,
    double lowStockThreshold = 0,
  }) async {
    await _inventoryRef.add({
      'name': name,
      'price': price,
      'stockQty': stockQty,
      'unit': unit,
      'isAvailable': stockQty > 0,
      'lowStockThreshold': lowStockThreshold,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProduct({
    required String productId,
    double? price,
    double? stockQty,
    double? lowStockThreshold,
    bool? isAvailable,
  }) async {
    final payload = <String, dynamic>{
      if (price != null) 'price': price,
      if (stockQty != null) 'stockQty': stockQty,
      if (lowStockThreshold != null) 'lowStockThreshold': lowStockThreshold,
      if (isAvailable != null) 'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (payload.length == 1) return; // only timestamp would be written
    await _inventoryRef.doc(productId).update(payload);
  }

  Future<void> toggleAvailability(String productId, bool available) {
    return updateProduct(productId: productId, isAvailable: available);
  }

  Future<void> reduceStock({
    required String productId,
    required double orderedQty,
  }) async {
    final ref = _inventoryRef.doc(productId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      final data = snap.data();
      if (data == null) return;
      final current = (data['stockQty'] as num?)?.toDouble() ?? 0;
      final next = current - orderedQty;
      txn.update(ref, {
        'stockQty': next,
        'isAvailable': next > 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
