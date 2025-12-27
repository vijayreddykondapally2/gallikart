// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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
  static const _methodUpi = 'upi';
  static const _methodGateway = 'gateway';
  bool _useWallet = true;
  String _selectedMethod = _methodUpi;
  String _note = '';
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
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

    final upiData =
        'upi://pay?pa=$_upiId&pn=GalliKart&am=${netPayable.toStringAsFixed(2)}&cu=INR&tn=GalliKart%20Order%20${order.id}';
    final qrUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=240x240&data=${Uri.encodeComponent(upiData)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
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
                    _methodSelector(netPayable),
                    const SizedBox(height: 8),
                    if (netPayable > 0 && _selectedMethod == _methodUpi)
                      _upiBlock(qrUrl, upiData),
                    if (netPayable > 0 && _selectedMethod == _methodGateway)
                      _gatewayInfo(),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Payment note (optional)',
                        hintText: 'UPI ref no. or note',
                      ),
                      onChanged: (value) => _note = value.trim(),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: _submitting ? 'Confirming...' : _ctaLabel(netPayable),
                      onPressed: _submitting
                          ? null
                          : () => _confirmPayment(
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

  Widget _methodSelector(double netPayable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select payment method', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        RadioListTile<String>(
          value: _methodUpi,
          groupValue: _selectedMethod,
          onChanged: netPayable > 0 ? (v) => setState(() => _selectedMethod = v!) : null,
          title: const Text('UPI (QR / any UPI app)'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          value: _methodGateway,
          groupValue: _selectedMethod,
          onChanged: netPayable > 0 ? (v) => setState(() => _selectedMethod = v!) : null,
          title: const Text('Card / Netbanking'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        if (netPayable <= 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'No gateway needed. Wallet will settle this payment.',
              style: TextStyle(color: Colors.green.shade700, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _upiBlock(String qrUrl, String upiData) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            qrUrl,
            height: 220,
            width: 220,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 220,
              width: 220,
              color: Colors.grey.shade200,
              child: const Center(child: Text('QR unavailable')),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Scan to pay via UPI', style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('UPI ID: $_upiId', style: const TextStyle(fontWeight: FontWeight.w600)),
            IconButton(
              onPressed: () => Clipboard.setData(const ClipboardData(text: _upiId)),
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Copy UPI ID',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tap below to open your UPI app with amount prefilled.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 10),
        PrimaryButton(
          label: 'Open UPI app',
          onPressed: () async {
            final uri = Uri.parse(upiData);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No UPI app found')),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _gatewayInfo() {
    return Column(
      children: [
        const Icon(Icons.lock, size: 36),
        const SizedBox(height: 8),
        Text(
          'Complete the payment in your preferred gateway. Tap "Payment done" after paying.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ],
    );
  }

  String _ctaLabel(double netPayable) {
    if (netPayable <= 0) return 'Settle with wallet';
    return _selectedMethod == _methodUpi ? 'Payment done (UPI)' : 'Payment done (gateway)';
  }

  Future<void> _confirmPayment(
    BuildContext context,
    Order order,
    double walletPlanned,
    double netPayable,
  ) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final method = netPayable <= 0
          ? 'wallet'
          : _selectedMethod == _methodUpi
              ? 'upi'
              : 'gateway';
      await ref.read(orderControllerProvider.notifier).confirmPayment(
            order: order,
            paymentMethod: method,
            paymentReference: _note.isNotEmpty ? _note : null,
            walletAppliedExtra: walletPlanned,
          );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.orders);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not confirm payment: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
