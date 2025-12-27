// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/models/product.dart';
import 'cart_item.dart';

class CartController extends StateNotifier<List<CartItem>> {
  CartController() : super([]);

  void add(Product product) {
    final existing = state.where((item) => item.product.id == product.id).toList();
    if (existing.isNotEmpty) {
      existing.first.quantity += 1;
      state = [...state];
    } else {
      state = [...state, CartItem(product: product)];
    }
  }

  void remove(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void updateQuantity(String productId, int quantity) {
    final items = state.map((item) {
      if (item.product.id == productId) {
        item.quantity = quantity;
      }
      return item;
    }).toList();
    state = items;
  }

  void changeQuantity(String productId, int delta) {
    final items = state.map((item) {
      if (item.product.id == productId) {
        final nextQuantity = item.quantity + delta;
        item.quantity = nextQuantity < 0 ? 0 : nextQuantity;
      }
      return item;
    }).where((item) => item.quantity > 0).toList();
    state = items;
  }

  void decrement(String productId) => changeQuantity(productId, -1);

  void clear() {
    state = [];
  }

  double get total => state.fold(0, (sum, item) => sum + item.total);
}

final cartControllerProvider = StateNotifierProvider<CartController, List<CartItem>>(
  (ref) => CartController(),
);
