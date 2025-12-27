// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

class InventoryItem {
  InventoryItem({
    required this.id,
    required this.name,
    required this.stock,
    required this.reorderLevel,
  });

  final String id;
  final String name;
  final int stock;
  final int reorderLevel;

  InventoryItem copyWith({int? stock}) {
    return InventoryItem(
      id: id,
      name: name,
      stock: stock ?? this.stock,
      reorderLevel: reorderLevel,
    );
  }

  bool get isLowStock => stock <= reorderLevel;
}
