// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/error_view.dart';
import '../../core/widgets/loader.dart';
import '../../core/widgets/primary_button.dart';
import '../../routes/app_routes.dart';
import 'auth_controller.dart';
import 'role_select_screen.dart';
import 'route_helpers.dart';

class OtpScreenArgs {
  const OtpScreenArgs({required this.phone});
  final String phone;
}

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, this.args});

  final OtpScreenArgs? args;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 60;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final phone = widget.args?.phone ?? state.phone ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Center(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('OTP sent to $phone'),
              const SizedBox(height: 12),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: '6-digit OTP'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              if (state.verifying)
                const Loader()
              else
                PrimaryButton(
                  label: 'Verify',
                  onPressed: _otpController.text.trim().length == 6
                      ? () => _verifyOtp(context)
                      : null,
                ),
              const SizedBox(height: 12),
              Text(
                _secondsLeft > 0
                    ? 'Resend available in $_secondsLeft s'
                    : 'Did not receive? Resend OTP',
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Resend OTP',
                onPressed: _secondsLeft == 0
                    ? () => _resendOtp(context)
                    : null,
              ),
              if (_localError != null || state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ErrorView(
                    message: _localError ?? state.error ?? 'Something went wrong',
                    onRetry: () => setState(() => _localError = null),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verifyOtp(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final result = await ref.read(authControllerProvider.notifier).verifyOtp(
          smsCode: _otpController.text.trim(),
        );
    if (result == null || !mounted) return;
    _handleOutcome(context, result);
  }

  Future<void> _resendOtp(BuildContext context) async {
    setState(() {
      _localError = null;
      _secondsLeft = 60;
    });
    _startTimer();
    final fallbackPhone = widget.args?.phone ?? ref.read(authControllerProvider).phone ?? '';
    await ref.read(authControllerProvider.notifier).sendOtp(
          mobile: fallbackPhone,
          forceResendToken: ref.read(authControllerProvider).resendToken,
          onCodeSent: () {},
          onAutoVerified: (result) {
            if (!mounted) return;
            _handleOutcome(context, result);
          },
        );
  }

  void _handleOutcome(BuildContext context, AuthResult result) {
    if (result.needsRoleSelection) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.roleSelect,
        arguments: RoleSelectArgs(phone: result.phone),
      );
      return;
    }
    routeUser(context, result.role ?? 'customer');
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }
}
