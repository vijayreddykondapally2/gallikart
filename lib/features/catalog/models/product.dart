// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

class Product {
  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.isActive,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final bool isActive;
  final String imageUrl;

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] as String? ?? 'Unknown',
      category: map['category'] as String? ?? 'General',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      imageUrl: map['imageUrl'] as String? ?? '',
    );
  }
}
