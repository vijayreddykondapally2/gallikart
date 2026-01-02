// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:cloud_firestore/cloud_firestore.dart';

class OpsOrderItem {
  OpsOrderItem({required this.name, required this.quantity, this.price});

  final String name;
  final num quantity;
  final num? price;
}

class OpsOrder {
  OpsOrder({
    required this.id,
    required this.ref,
    required this.type, // INSTANT | RECURRING
    this.mode, // DAILY | WEEKLY | MONTHLY when recurring
    required this.status,
    required this.createdAt,
    required this.amount,
    this.address,
    this.userId,
    this.sourcePath,
    this.items = const <OpsOrderItem>[],
  });

  final String id;
  final DocumentReference<Map<String, dynamic>> ref;
  final String type;
  final String? mode;
  final String status;
  final DateTime createdAt;
  final double amount;
  final String? address;
  final String? userId;
  final String? sourcePath;
  final List<OpsOrderItem> items;

  bool get isRecurring => type.toUpperCase() == 'RECURRING';

  OpsOrder copyWith({
    String? status,
  }) {
    return OpsOrder(
      id: id,
      ref: ref,
      type: type,
      mode: mode,
      status: status ?? this.status,
      createdAt: createdAt,
      amount: amount,
      address: address,
      userId: userId,
      items: items,
      sourcePath: sourcePath,
    );
  }
}

OpsOrder opsOrderFromInstant(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data() ?? const <String, dynamic>{};
  final created = _toDate(data['createdAt']) ?? DateTime.now();
  final items = (data['items'] as List<dynamic>? ?? const [])
      .map((e) => e as Map<String, dynamic>?)
      .whereType<Map<String, dynamic>>()
      .map((e) => OpsOrderItem(
            name: (e['name'] as String?) ?? 'Item',
            quantity: (e['quantity'] as num?) ?? 0,
            price: (e['price'] as num?),
          ))
      .toList();

  final status = (data['orderStatus'] as String?) ?? (data['status'] as String?) ?? 'PLACED';
  final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;

  return OpsOrder(
    id: doc.id,
    ref: doc.reference,
    type: 'INSTANT',
    status: status,
    createdAt: created,
    amount: amount,
    address: data['deliveryAddress'] as String?,
    userId: data['userId'] as String?,
      sourcePath: data['sourceRef'] as String?,
    items: items,
  );
}

OpsOrder opsOrderFromRecurring(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data() ?? const <String, dynamic>{};
  final created = _toDate(data['createdAt']) ?? DateTime.now();
  final amount = (data['currentAmount'] as num?)?.toDouble() ??
      (data['basePaidAmount'] as num?)?.toDouble() ??
      (data['paidAmount'] as num?)?.toDouble() ?? 0;
  final items = <OpsOrderItem>[];
  final rawItems = data['items'];
  if (rawItems is Map) {
    rawItems.forEach((key, value) {
      if (value is num) {
        items.add(OpsOrderItem(name: key.toString(), quantity: value));
      } else if (value is Map) {
        value.forEach((innerKey, innerVal) {
          items.add(OpsOrderItem(name: '${key.toString()} - ${innerKey.toString()}', quantity: (innerVal as num?) ?? 0));
        });
      }
    });
  }

  return OpsOrder(
    id: doc.id,
    ref: doc.reference,
    type: 'RECURRING',
    mode: (data['frequency'] as String?)?.toUpperCase(),
    status: (data['status'] as String?) ?? 'ACTIVE',
    createdAt: created,
    amount: amount,
    address: data['deliveryAddress'] as String? ?? data['deliveryAddressId'] as String?,
    userId: data['userId'] as String?,
      sourcePath: data['sourceRef'] as String?,
    items: items,
  );
}

OpsOrder opsOrderFromOpsDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data() ?? const <String, dynamic>{};
  final created = _toDate(data['createdAt']) ?? DateTime.now();
  final amount = (data['amount'] as num?)?.toDouble() ?? 0;
  final status = (data['status'] as String?) ?? (data['orderStatus'] as String?) ?? 'PLACED';
  final mode = (data['mode'] as String?) ?? (data['frequency'] as String?);

  final rawItems = data['items'];
  final items = <OpsOrderItem>[];
  if (rawItems is List) {
    for (final entry in rawItems) {
      if (entry is Map) {
        items.add(OpsOrderItem(
          name: (entry['name'] as String?) ?? 'Item',
          quantity: (entry['quantity'] as num?) ?? 0,
          price: entry['price'] as num?,
        ));
      }
    }
  } else if (rawItems is Map) {
    rawItems.forEach((key, value) {
      if (value is num) {
        items.add(OpsOrderItem(name: key.toString(), quantity: value));
      } else if (value is Map) {
        value.forEach((innerKey, innerVal) {
          items.add(OpsOrderItem(name: '${key.toString()} - ${innerKey.toString()}', quantity: (innerVal as num?) ?? 0));
        });
      }
    });
  }

  return OpsOrder(
    id: doc.id,
    ref: doc.reference,
    type: ((data['orderType'] as String?) ?? 'INSTANT').toUpperCase(),
    mode: mode?.toUpperCase(),
    status: status,
    createdAt: created,
    amount: amount,
    address: data['address'] as String? ?? data['deliveryAddress'] as String?,
    userId: data['userId'] as String?,
    sourcePath: data['sourceRef'] as String?,
    items: items,
  );
}

DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
