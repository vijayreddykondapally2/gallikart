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
    DateTime? placedAt,
    this.confirmedAt,
    this.packedAt,
    this.outForDeliveryAt,
    this.nearYouAt,
    this.deliveredAt,
  }) : placedAt = placedAt ?? createdAt;

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
  final DateTime placedAt;
  final DateTime? confirmedAt;
  final DateTime? packedAt;
  final DateTime? outForDeliveryAt;
  final DateTime? nearYouAt;
  final DateTime? deliveredAt;

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
      'placedAt': placedAt.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'packedAt': packedAt?.toIso8601String(),
      'outForDeliveryAt': outForDeliveryAt?.toIso8601String(),
      'nearYouAt': nearYouAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
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

  Order copyWith({
    String? id,
    List<CartItem>? items,
    double? totalAmount,
    double? walletApplied,
    double? amountDue,
    String? status,
    DateTime? createdAt,
    String? paymentMethod,
    String? paymentReference,
    String? recurringOrderId,
    double? recurringDelta,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? deliveryLabel,
    DateTime? placedAt,
    DateTime? confirmedAt,
    DateTime? packedAt,
    DateTime? outForDeliveryAt,
    DateTime? nearYouAt,
    DateTime? deliveredAt,
  }) {
    return Order(
      id: id ?? this.id,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      walletApplied: walletApplied ?? this.walletApplied,
      amountDue: amountDue ?? this.amountDue,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      recurringOrderId: recurringOrderId ?? this.recurringOrderId,
      recurringDelta: recurringDelta ?? this.recurringDelta,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      deliveryLabel: deliveryLabel ?? this.deliveryLabel,
      placedAt: placedAt ?? this.placedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      packedAt: packedAt ?? this.packedAt,
      outForDeliveryAt: outForDeliveryAt ?? this.outForDeliveryAt,
      nearYouAt: nearYouAt ?? this.nearYouAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}
