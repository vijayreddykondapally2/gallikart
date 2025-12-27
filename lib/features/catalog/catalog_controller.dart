// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'catalog_repository.dart';
import 'models/product.dart';

class CatalogController extends AsyncNotifier<List<Product>> {
  late final CatalogRepository _repository;

  @override
  Future<List<Product>> build() async {
    _repository = ref.read(catalogRepositoryProvider);
    return _loadActive();
  }

  Future<List<Product>> _loadActive() async {
    final items = await _repository.fetchProducts();
    return items.where((product) => product.isActive && product.stock > 0).toList(growable: false);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadActive);
  }
}

final catalogControllerProvider = AsyncNotifierProvider<CatalogController, List<Product>>(
  CatalogController.new,
);
