// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  Query<Map<String, dynamic>> collectionGroup(String collectionId) {
    return _firestore.collectionGroup(collectionId);
  }

  DocumentReference<Map<String, dynamic>> document(String path) {
    return _firestore.doc(path);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchCollection(String path) async {
    final result = await collection(path).get();
    return result.docs;
  }

  Future<T> runTransaction<T>(Future<T> Function(Transaction transaction) handler) {
    return _firestore.runTransaction(handler);
  }
}
