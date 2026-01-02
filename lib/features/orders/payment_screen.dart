// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upi_india/upi_india.dart' as upi;

import '../../core/services/upi_service.dart';
import '../../core/utils/money_utils.dart';
import '../../core/widgets/primary_button.dart';
import '../../routes/app_routes.dart';
import '../wallet/wallet_controller.dart';
import 'models/order.dart';
import 'order_controller.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, this.order});

  final Order? order;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  static const _upiId = '8019220628@ybl';
  bool _useWallet = true;
  String _note = '';
  bool _submitting = false;
  String? _lastUpiError;
  List<upi.UpiApp> _upiApps = const [];
  bool _loadingApps = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    if (order == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_outlined),
              tooltip: 'Home',
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              ),
            ),
          ],
        ),
        body: const Center(child: Text('No order found to pay.')),
      );
    }

    final walletState = ref.watch(walletControllerProvider);
    final walletCtrl = ref.read(walletControllerProvider.notifier);
    final due = order.amountDue > 0
        ? order.amountDue.toDouble()
        : (order.totalAmount - order.walletApplied)
            .clamp(0, double.infinity)
            .toDouble();
    final walletPreview = _useWallet && due > 0
        ? walletCtrl.preview(due)
        : const WalletApplication(walletUsed: 0, remaining: 0);
    final walletPlanned = _useWallet ? walletPreview.walletUsed.toDouble() : 0.0;
    final netPayable = _useWallet ? walletPreview.remaining.toDouble() : due;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Home',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (route) => false,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _summaryCard(order, walletState.balance, walletPlanned, netPayable),
                    const SizedBox(height: 12),
                    if (walletState.balance > 0 && due > 0)
                      CheckboxListTile(
                        value: _useWallet,
                        onChanged: (v) => setState(() => _useWallet = v ?? false),
                        title: Text(
                          'Use wallet (available: ${formatCurrency(walletState.balance)})',
                        ),
                        subtitle: Text(
                          _useWallet
                              ? 'Planned wallet: ${formatCurrency(walletPlanned)}'
                              : 'Wallet not applied',
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    const SizedBox(height: 8),
                    _upiInstructions(netPayable),
                    if (_lastUpiError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _lastUpiError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Payment note (optional)',
                        hintText: 'UPI ref no. or note',
                      ),
                      onChanged: (value) => setState(() => _note = value.trim()),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: _submitting
                          ? 'Processing...'
                          : netPayable <= 0
                              ? 'Settle with wallet'
                              : 'Pay via UPI app',
                      onPressed: _submitting
                          ? null
                          : () => _handlePay(
                                context,
                                order,
                                walletPlanned,
                                netPayable,
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(
    Order order,
    double walletBalance,
    double walletPlanned,
    double netPayable,
  ) {
    final paidBefore = order.totalAmount - order.amountDue - order.walletApplied;
    final deltaPlanned = order.recurringDelta ?? order.totalAmount;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ${order.id}', style: const TextStyle(fontWeight: FontWeight.w600)),
            if ((order.deliveryAddress ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Deliver to: ${order.deliveryAddress}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ),
            if ((order.deliveryLabel ?? '').isNotEmpty)
              Text(
                'Label: ${order.deliveryLabel}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            const SizedBox(height: 10),
            _infoRow('Order total', formatCurrency(order.totalAmount)),
            _infoRow('Paid earlier', formatCurrency(paidBefore)),
            _infoRow('Already paid via wallet', formatCurrency(order.walletApplied)),
            _infoRow('New items (delta)', formatCurrency(deltaPlanned)),
            _infoRow('Wallet available', formatCurrency(walletBalance)),
            _infoRow('Wallet planned now', formatCurrency(walletPlanned)),
            const Divider(height: 16),
            _infoRow(
              'To pay now',
              formatCurrency(netPayable),
              valueStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value, style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _upiInstructions(double netPayable) {
    if (netPayable <= 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'No gateway needed. Wallet will settle this payment.',
          style: TextStyle(color: Colors.green.shade700, fontSize: 12),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pay with UPI', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('UPI ID: $_upiId', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          'We will open your UPI chooser with amount ₹${netPayable.toStringAsFixed(2)}.',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _handlePay(
    BuildContext context,
    Order order,
    double walletPlanned,
    double netPayable,
  ) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _lastUpiError = null;
    });
    try {
      if (netPayable <= 0) {
        await _confirmPayment(order, walletPlanned, 'wallet', null);
        return;
      }
      await _ensureUpiApps();
      if (_upiApps.isEmpty) {
        setState(() => _lastUpiError = 'No UPI apps found on this device.');
        return;
      }
      final selectedApp = await _pickUpiApp(context);
      if (selectedApp == null) {
        setState(() => _lastUpiError = 'Payment cancelled. Try again.');
        return;
      }
      final result = await UpiService.startTransaction(
        app: selectedApp,
        receiverUpiId: _upiId,
        receiverName: 'GalliKart',
        amount: netPayable,
        transactionRefId: order.id,
        transactionNote: 'GalliKart order ${order.id}',
      );
      if (result.status == UpiPaymentStatus.success) {
        await _confirmPayment(order, walletPlanned, 'upi', result.transactionId);
        return;
      }
      if (result.status == UpiPaymentStatus.cancelled) {
        setState(() => _lastUpiError = 'Payment cancelled. Try again.');
        return;
      }
      setState(() => _lastUpiError = 'Payment failed. Please retry.');
    } on PlatformException catch (error) {
      setState(() => _lastUpiError = error.message ?? 'Payment could not be started');
    } catch (error) {
      setState(() => _lastUpiError = 'Payment error: $error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _ensureUpiApps() async {
    if (_loadingApps) return;
    setState(() => _loadingApps = true);
    try {
      _upiApps = await UpiService.getAvailableApps();
    } finally {
      if (mounted) setState(() => _loadingApps = false);
    }
  }

  Future<upi.UpiApp?> _pickUpiApp(BuildContext context) async {
    if (_upiApps.isEmpty) return null;
    return showModalBottomSheet<upi.UpiApp>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _upiApps
              .map(
                (app) => ListTile(
                  leading: Image.memory(app.icon, width: 32, height: 32),
                  title: Text(app.name),
                  onTap: () => Navigator.pop(context, app),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _confirmPayment(
    Order? order,
    double walletPlanned,
    String method,
    String? reference,
  ) async {
    if (order == null) return;
    try {
      await ref.read(orderControllerProvider.notifier).confirmPayment(
            order: order,
            paymentMethod: method,
            paymentReference: reference ?? _note,
            walletAppliedExtra: walletPlanned,
          );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.orders);
    } catch (error) {
      if (!mounted) return;
      setState(() => _lastUpiError = 'Could not confirm payment: $error');
    }
  }
}
