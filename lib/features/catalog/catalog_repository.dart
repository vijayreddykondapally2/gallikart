// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/services/firestore_service.dart';
import 'models/product.dart';

class CatalogRepository {
  CatalogRepository(this._service);

  final FirestoreService _service;

  Future<List<Product>> fetchProducts() async {
    final docs = await _service.fetchCollection('products');
    return docs.map((doc) => Product.fromMap(doc.id, doc.data())).toList();
  }
}

final catalogRepositoryProvider = Provider((ref) => CatalogRepository(ref.read(firestoreServiceProvider)));
