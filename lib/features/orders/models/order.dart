// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:cloud_firestore/cloud_firestore.dart';

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
    this.orderType,
    this.deliveryDate,
    this.activeDays = const <String>[],
    this.userId,
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
  final String? orderType; // INSTANT | RECURRING | OTHER
  final String? deliveryDate; // yyyy-MM-dd
  final List<String> activeDays; // e.g., ['Mon','Tue']
  final String? userId;
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
      'createdAt': createdAt,
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'recurringOrderId': recurringOrderId,
      'recurringDelta': recurringDelta,
      'deliveryAddress': deliveryAddress,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'deliveryLabel': deliveryLabel,
      'orderType': orderType ?? 'INSTANT',
      'orderStatus': status,
      'deliveryDate': deliveryDate,
      'activeDays': activeDays,
      'userId': userId,
      'placedAt': placedAt,
      'confirmedAt': confirmedAt,
      'packedAt': packedAt,
      'outForDeliveryAt': outForDeliveryAt,
      'nearYouAt': nearYouAt,
      'deliveredAt': deliveredAt,
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
      orderType: orderType ?? this.orderType,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      activeDays: activeDays ?? this.activeDays,
      userId: userId ?? this.userId,
    );
  }

  factory Order.fromMap(String id, Map<String, dynamic> map) {
    DateTime? _parse(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
      return null;
    }

    final items = (map['items'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .map((e) => CartItem(
              product: CartItem.productFromMap(e),
              quantity: (e['quantity'] as num?)?.toInt() ?? 0,
            ))
        .toList();

    return Order(
      id: id,
      items: items,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      walletApplied: (map['walletApplied'] as num?)?.toDouble() ?? 0,
      amountDue: (map['amountDue'] as num?)?.toDouble() ?? 0,
      status: (map['orderStatus'] as String?) ?? (map['status'] as String?) ?? 'PLACED',
      createdAt: _parse(map['createdAt']) ?? DateTime.now(),
      paymentMethod: map['paymentMethod'] as String?,
      paymentReference: map['paymentReference'] as String?,
      recurringOrderId: map['recurringOrderId'] as String?,
      recurringDelta: (map['recurringDelta'] as num?)?.toDouble(),
      deliveryAddress: map['deliveryAddress'] as String?,
      deliveryLatitude: (map['deliveryLatitude'] as num?)?.toDouble(),
      deliveryLongitude: (map['deliveryLongitude'] as num?)?.toDouble(),
      deliveryLabel: map['deliveryLabel'] as String?,
      orderType: map['orderType'] as String?,
      deliveryDate: map['deliveryDate'] as String?,
      activeDays: List<String>.from((map['activeDays'] as List?)?.whereType<String>() ?? const <String>[]),
      userId: map['userId'] as String?,
      placedAt: _parse(map['placedAt']) ?? DateTime.now(),
      confirmedAt: _parse(map['confirmedAt']),
      packedAt: _parse(map['packedAt']),
      outForDeliveryAt: _parse(map['outForDeliveryAt']),
      nearYouAt: _parse(map['nearYouAt']),
      deliveredAt: _parse(map['deliveredAt']),
    );
  }
}
