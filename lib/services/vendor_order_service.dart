import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VendorOrderService {
  VendorOrderService(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _vendorId {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Vendor must be signed in');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('vendors').doc(_vendorId).collection('orders');

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllOrders() {
    return _orders.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> updateItems({
    required String orderId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
  }) async {
    await _orders.doc(orderId).update({
      'items': items,
      'totalAmount': totalAmount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStatus({
    required String orderId,
    required String status,
  }) async {
    await _orders.doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
