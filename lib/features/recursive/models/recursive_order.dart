// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:cloud_firestore/cloud_firestore.dart';

class RecursiveOrder {
  const RecursiveOrder({
    required this.id,
    required this.frequency,
    required this.items,
    required this.createdAt,
    this.userId,
    this.paidAmount = 0,
    this.basePaidAmount = 0,
    this.deltaPendingAmount = 0,
    this.walletAdjustmentAmount = 0,
    this.currentAmount = 0,
    this.monthlyDay,
    this.deliveryTime,
    this.deliveryAddress,
    this.deliveryAddressId,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.plannedWeekStart,
    this.status = 'ACTIVE',
    this.disabledAt,
    this.deliveredDays = const <String>[],
    this.refundedAmount = 0,
    this.refundProcessed = false,
    this.dayTotals = const <String, double>{},
  });

  final String id;
  final String? userId;
  final String frequency; // daily | weekly | monthly
  final Map<String, dynamic> items; // daily/monthly: {item: qty}, weekly: {day: {item: qty}}
  final DateTime createdAt;
  final double paidAmount;
  final double basePaidAmount;
  final double deltaPendingAmount;
  final double walletAdjustmentAmount;
  final double currentAmount;
  final int? monthlyDay; // 1-31
  final String? deliveryTime; // HH:mm
  final String? deliveryAddress;
  final String? deliveryAddressId;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final DateTime? plannedWeekStart;
  final String status; // ACTIVE | DISABLED_FINAL | COMPLETED
  final DateTime? disabledAt;
  final List<String> deliveredDays;
  final double refundedAmount;
  final bool refundProcessed;
  final Map<String, double> dayTotals; // per-day totals for refund logic

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'frequency': frequency,
      'items': items,
      'createdAt': Timestamp.fromDate(createdAt),
      'paidAmount': paidAmount,
      'basePaidAmount': basePaidAmount,
      'deltaPendingAmount': deltaPendingAmount,
      'walletAdjustmentAmount': walletAdjustmentAmount,
      'currentAmount': currentAmount,
      'monthlyDay': monthlyDay,
      'deliveryTime': deliveryTime,
      'deliveryAddress': deliveryAddress,
      'deliveryAddressId': deliveryAddressId,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'plannedWeekStart': plannedWeekStart != null
          ? Timestamp.fromDate(plannedWeekStart!)
          : null,
      'status': status,
      'disabledAt': disabledAt != null ? Timestamp.fromDate(disabledAt!) : null,
      'deliveredDays': deliveredDays,
      'refundedAmount': refundedAmount,
      'refundProcessed': refundProcessed,
      'dayTotals': dayTotals,
    };
  }

  factory RecursiveOrder.fromMap(Map<String, dynamic> map) {
    return RecursiveOrder(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String?,
      frequency: map['frequency'] as String? ?? 'daily',
      items: Map<String, dynamic>.from(map['items'] as Map? ?? {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
      basePaidAmount: (map['basePaidAmount'] as num?)?.toDouble() ??
          (map['paidAmount'] as num?)?.toDouble() ??
          0,
      deltaPendingAmount: (map['deltaPendingAmount'] as num?)?.toDouble() ?? 0,
      walletAdjustmentAmount:
          (map['walletAdjustmentAmount'] as num?)?.toDouble() ?? 0,
      currentAmount: (map['currentAmount'] as num?)?.toDouble() ?? 0,
      monthlyDay: (map['monthlyDay'] as num?)?.toInt(),
      deliveryTime: map['deliveryTime'] as String?,
      deliveryAddress: map['deliveryAddress'] as String?,
      deliveryAddressId: map['deliveryAddressId'] as String?,
      deliveryLatitude: (map['deliveryLatitude'] as num?)?.toDouble(),
      deliveryLongitude: (map['deliveryLongitude'] as num?)?.toDouble(),
      plannedWeekStart: (map['plannedWeekStart'] as Timestamp?)?.toDate(),
      status: (map['status'] as String? ?? 'ACTIVE').toUpperCase(),
      disabledAt: (map['disabledAt'] as Timestamp?)?.toDate(),
      deliveredDays: List<String>.from(map['deliveredDays'] as List? ?? const <String>[]),
      refundedAmount: (map['refundedAmount'] as num?)?.toDouble() ?? 0,
      refundProcessed: map['refundProcessed'] as bool? ?? false,
      dayTotals: Map<String, double>.from(
        (map['dayTotals'] as Map? ?? const <String, double>{}).map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        ),
      ),
    );
  }

  RecursiveOrder copyWith({
    String? id,
    String? userId,
    String? frequency,
    Map<String, dynamic>? items,
    DateTime? createdAt,
    double? paidAmount,
    double? basePaidAmount,
    double? deltaPendingAmount,
    double? walletAdjustmentAmount,
    double? currentAmount,
    int? monthlyDay,
    String? deliveryTime,
    String? deliveryAddress,
    String? deliveryAddressId,
    double? deliveryLatitude,
    double? deliveryLongitude,
    DateTime? plannedWeekStart,
    String? status,
    DateTime? disabledAt,
    List<String>? deliveredDays,
    double? refundedAmount,
    bool? refundProcessed,
    Map<String, double>? dayTotals,
  }) {
    return RecursiveOrder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      frequency: frequency ?? this.frequency,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      paidAmount: paidAmount ?? this.paidAmount,
      basePaidAmount: basePaidAmount ?? this.basePaidAmount,
      deltaPendingAmount: deltaPendingAmount ?? this.deltaPendingAmount,
      walletAdjustmentAmount:
          walletAdjustmentAmount ?? this.walletAdjustmentAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      monthlyDay: monthlyDay ?? this.monthlyDay,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryAddressId: deliveryAddressId ?? this.deliveryAddressId,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      plannedWeekStart: plannedWeekStart ?? this.plannedWeekStart,
      status: status ?? this.status,
      disabledAt: disabledAt ?? this.disabledAt,
      deliveredDays: deliveredDays ?? this.deliveredDays,
      refundedAmount: refundedAmount ?? this.refundedAmount,
      refundProcessed: refundProcessed ?? this.refundProcessed,
      dayTotals: dayTotals ?? this.dayTotals,
    );
  }
}
