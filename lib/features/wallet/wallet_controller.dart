// Context:
// Simple wallet with ledger entries to support credits/debits during checkout.
// Keep logic minimal and side-effect free except when updating state.

import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.timestamp,
    required this.amount,
    required this.type, // credit | debit
    required this.orderId,
    required this.note,
    required this.balanceAfter,
  });

  final String id;
  final DateTime timestamp;
  final double amount;
  final String type;
  final String orderId;
  final String note;
  final double balanceAfter;
}

class WalletState {
  const WalletState({
    this.balance = 0,
    this.ledger = const <WalletEntry>[],
  });

  final double balance;
  final List<WalletEntry> ledger;

  WalletState copyWith({double? balance, List<WalletEntry>? ledger}) {
    return WalletState(
      balance: balance ?? this.balance,
      ledger: ledger ?? this.ledger,
    );
  }
}

class WalletApplication {
  const WalletApplication({required this.walletUsed, required this.remaining});

  final double walletUsed;
  final double remaining;
}

class WalletController extends StateNotifier<WalletState> {
  WalletController() : super(const WalletState());

  double get balance => state.balance;
  List<WalletEntry> get ledger => state.ledger;

  WalletApplication preview(double amount) {
    if (amount <= 0) return const WalletApplication(walletUsed: 0, remaining: 0);
    final used = amount <= state.balance ? amount : state.balance;
    final remaining = amount - used;
    return WalletApplication(walletUsed: used, remaining: remaining);
  }

  void credit({
    required double amount,
    required String orderId,
    String note = 'Adjustment',
  }) {
    if (amount <= 0) return;
    final nextBalance = state.balance + amount;
    final entry = WalletEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      amount: amount,
      type: 'credit',
      orderId: orderId,
      note: note,
      balanceAfter: nextBalance,
    );
    state = state.copyWith(
      balance: nextBalance,
      ledger: [...state.ledger, entry],
    );
  }

  void debit({
    required double amount,
    required String orderId,
    String note = 'Checkout',
  }) {
    if (amount <= 0) return;
    final actual = amount > state.balance ? state.balance : amount;
    final nextBalance = state.balance - actual;
    final entry = WalletEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      amount: -actual,
      type: 'debit',
      orderId: orderId,
      note: note,
      balanceAfter: nextBalance,
    );
    state = state.copyWith(
      balance: nextBalance,
      ledger: [...state.ledger, entry],
    );
  }
}

final walletControllerProvider =
    StateNotifierProvider<WalletController, WalletState>(
  (ref) => WalletController(),
);
