// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import '../../cart/cart_item.dart';

class Order {
  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    this.walletApplied = 0,
    this.amountDue = 0,
    required this.status,
    required this.createdAt,
    this.paymentMethod,
    this.paymentReference,
    this.recurringOrderId,
    this.recurringDelta,
    this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.deliveryLabel,
  });

  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final double walletApplied;
  final double amountDue;
  final String status;
  final DateTime createdAt;
  final String? paymentMethod;
  final String? paymentReference;
  final String? recurringOrderId;
  final double? recurringDelta;
  final String? deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? deliveryLabel;

  Map<String, dynamic> toMap() {
    return {
      'totalAmount': totalAmount,
      'walletApplied': walletApplied,
      'amountDue': amountDue,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'recurringOrderId': recurringOrderId,
      'recurringDelta': recurringDelta,
      'deliveryAddress': deliveryAddress,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'deliveryLabel': deliveryLabel,
      'items': items
          .map((item) => {
                'productId': item.product.id,
                'name': item.product.name,
                'quantity': item.quantity,
                'price': item.product.price,
              })
          .toList(),
    };
  }
}
