// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

class InventoryItem {
  InventoryItem({
    required this.id,
    required this.name,
    required this.price,
    required this.stockQty,
    required this.unit,
    required this.lowStockThreshold,
    required this.isAvailable,
    this.updatedAt,
  });

  final String id;
  final String name;
  final double price;
  final double stockQty;
  final String unit;
  final double lowStockThreshold;
  final bool isAvailable;
  final DateTime? updatedAt;

  InventoryItem copyWith({
    double? price,
    double? stockQty,
    bool? isAvailable,
    double? lowStockThreshold,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id,
      name: name,
      price: price ?? this.price,
      stockQty: stockQty ?? this.stockQty,
      unit: unit,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isAvailable: isAvailable ?? this.isAvailable,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isLowStock => stockQty <= lowStockThreshold;
  bool get isOutOfStock => stockQty <= 0;
}
