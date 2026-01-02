// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import '../catalog/models/product.dart';

class CartItem {
  CartItem({required this.product, this.quantity = 1});

  final Product product;
  int quantity;

  double get total => product.price * quantity;

  static Product productFromMap(Map<String, dynamic> data) {
    return Product(
      id: data['productId'] as String? ?? data['id'] as String? ?? 'unknown',
      name: data['name'] as String? ?? 'Unknown',
      category: data['category'] as String? ?? 'General',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      imageUrl: data['imageUrl'] as String? ?? '',
    );
  }
}
