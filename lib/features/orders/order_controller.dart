// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cart/cart_controller.dart';
import '../cart/cart_item.dart';
import '../recursive/recursive_order_controller.dart';
import 'models/order.dart';
import 'order_repository.dart';
import '../wallet/wallet_controller.dart';

class OrderController extends StateNotifier<List<Order>> {
  OrderController(
    this._repository,
    this._cartController,
    this._walletController,
    this._ref,
  ) : super([]);

  final OrderRepository _repository;
  final CartController _cartController;
  final WalletController _walletController;
  final Ref _ref;

  Order? createPending(
    List<CartItem> cartItems, {
    bool applyWallet = false,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? deliveryLabel,
  }) {
    if (cartItems.isEmpty) return null;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final snapshot = cartItems
        .map((item) => CartItem(product: item.product, quantity: item.quantity))
        .toList(growable: false);
    final total = snapshot.fold(0.0, (sum, item) => sum + item.total);
    final walletUse = applyWallet
        ? _walletController.preview(total)
        : const WalletApplication(walletUsed: 0, remaining: 0);
    if (applyWallet && walletUse.walletUsed > 0) {
      _walletController.debit(
        amount: walletUse.walletUsed,
        orderId: id,
        note: 'Applied to order',
      );
    }
    final netDue = applyWallet ? walletUse.remaining : total;
    const status = 'PLACED';
    final order = Order(
      id: id,
      items: snapshot,
      totalAmount: total,
      walletApplied: walletUse.walletUsed,
      amountDue: netDue,
      status: status,
      createdAt: DateTime.now(),
      paymentMethod: netDue <= 0 ? 'wallet' : null,
      deliveryAddress: deliveryAddress,
      deliveryLatitude: deliveryLatitude,
      deliveryLongitude: deliveryLongitude,
      deliveryLabel: deliveryLabel,
    );
    state = [...state, order];
    if (netDue <= 0) {
      _repository.placeOrder(order);
    }
    _cartController.clear();
    return order;
  }

  Order createPendingAmount({
    required double amount,
    List<CartItem> items = const [],
    String note = 'Plan update',
    bool applyWallet = false,
    String? recurringOrderId,
    double? recurringDelta,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? deliveryLabel,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final walletUse = applyWallet
        ? _walletController.preview(amount)
        : const WalletApplication(walletUsed: 0, remaining: 0);
    if (applyWallet && walletUse.walletUsed > 0) {
      _walletController.debit(
        amount: walletUse.walletUsed,
        orderId: id,
        note: 'Applied to order update',
      );
    }
    final netDue = applyWallet ? walletUse.remaining : amount;
    const status = 'PLACED';
    final order = Order(
      id: id,
      items: items,
      totalAmount: amount,
      walletApplied: walletUse.walletUsed,
      amountDue: netDue,
      status: status,
      createdAt: DateTime.now(),
      paymentMethod: netDue <= 0 ? 'wallet' : null,
      paymentReference: note,
      recurringOrderId: recurringOrderId,
      recurringDelta: recurringDelta,
      deliveryAddress: deliveryAddress,
      deliveryLatitude: deliveryLatitude,
      deliveryLongitude: deliveryLongitude,
      deliveryLabel: deliveryLabel,
    );
    state = [...state, order];
    if (netDue <= 0) {
      _repository.placeOrder(order);
    }
    return order;
  }

  Future<Order> confirmPayment({
    required Order order,
    required String paymentMethod,
    String? paymentReference,
    double walletAppliedExtra = 0,
  }) async {
    if (order.status == 'DELIVERED') {
      return order;
    }

    if (order.amountDue <= 0) {
      final confirmed = Order(
        id: order.id,
        items: order.items,
        totalAmount: order.totalAmount,
        walletApplied: order.walletApplied,
        amountDue: 0,
        status: 'PLACED',
        createdAt: order.createdAt,
        paymentMethod: order.paymentMethod ?? paymentMethod,
        paymentReference: paymentReference ?? order.paymentReference,
        recurringOrderId: order.recurringOrderId,
        recurringDelta: order.recurringDelta,
        deliveryAddress: order.deliveryAddress,
        deliveryLatitude: order.deliveryLatitude,
        deliveryLongitude: order.deliveryLongitude,
        deliveryLabel: order.deliveryLabel,
      );
      await _repository.placeOrder(confirmed);
      state = [...state.where((o) => o.id != confirmed.id), confirmed];
      _cartController.clear();
      return confirmed;
    }

    final availableWallet = _walletController.balance;
    final dueBefore = order.amountDue;
    final cappedWalletRequested = walletAppliedExtra.clamp(0, dueBefore);
    final walletToUse = cappedWalletRequested > availableWallet
        ? availableWallet
        : cappedWalletRequested;
    if (walletToUse > 0) {
      _walletController.debit(
        amount: walletToUse.toDouble(),
        orderId: order.id,
        note: 'Applied at confirmation',
      );
    }
    final netDue = (dueBefore - walletToUse).clamp(0, double.infinity).toDouble();
    final paidDelta = (walletToUse + netDue).toDouble();
    final confirmed = Order(
      id: order.id,
      items: order.items,
      totalAmount: order.totalAmount,
      walletApplied: order.walletApplied + walletToUse,
      amountDue: 0,
      status: 'PLACED',
      createdAt: order.createdAt,
      paymentMethod: netDue <= 0 ? 'wallet' : paymentMethod,
      paymentReference: paymentReference,
      recurringOrderId: order.recurringOrderId,
      recurringDelta: order.recurringDelta,
    );
    await _repository.placeOrder(confirmed);
    state = [...state.where((o) => o.id != confirmed.id), confirmed];
    _cartController.clear();

    if (order.recurringOrderId != null && paidDelta > 0) {
      await _ref
          .read(recursiveOrderControllerProvider.notifier)
          .markDeltaPaid(
            recurringOrderId: order.recurringOrderId!,
            paidDelta: paidDelta,
          );
    }
    return confirmed;
  }

  Future<Order?> updateStatus({
    required Order order,
    required String status,
  }) async {
    if (order.status == status) return order;
    final updated = _applyStatus(order, status);
    state = [...state.where((o) => o.id != order.id), updated];
    await _repository.placeOrder(updated);
    return updated;
  }

  Order _applyStatus(Order order, String status) {
    final now = DateTime.now();
    switch (status) {
      case 'CONFIRMED':
        return order.copyWith(
          status: status,
          confirmedAt: order.confirmedAt ?? now,
        );
      case 'PACKING':
        return order.copyWith(
          status: status,
          packedAt: order.packedAt ?? now,
        );
      case 'OUT_FOR_DELIVERY':
        return order.copyWith(
          status: status,
          outForDeliveryAt: order.outForDeliveryAt ?? now,
        );
      case 'NEAR_YOU':
        return order.copyWith(
          status: status,
          nearYouAt: order.nearYouAt ?? now,
        );
      case 'DELIVERED':
        return order.copyWith(
          status: status,
          deliveredAt: order.deliveredAt ?? now,
        );
      case 'PLACED':
      default:
        return order.copyWith(status: 'PLACED');
    }
  }
}

final orderControllerProvider =
    StateNotifierProvider<OrderController, List<Order>>(
      (ref) => OrderController(
        ref.read(orderRepositoryProvider),
        ref.read(cartControllerProvider.notifier),
        ref.read(walletControllerProvider.notifier),
        ref,
      ),
    );
