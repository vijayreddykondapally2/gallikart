// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/validators.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loader.dart';
import '../../core/widgets/primary_button.dart';
import '../../routes/app_routes.dart';
import 'auth_controller.dart';
import 'otp_screen.dart';
import 'role_select_screen.dart';
import 'route_helpers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile number'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              if (state.sendingCode)
                const Loader()
              else
                PrimaryButton(
                  label: 'Send OTP',
                  onPressed: isValidPhone(_phoneController.text)
                      ? () => _sendOtp(context)
                      : null,
                ),
              const SizedBox(height: 12),
              const Text('+91 numbers only. We never store OTP.'),
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

  Future<void> _sendOtp(BuildContext context) async {
    FocusScope.of(context).unfocus();
    _localError = null;
    setState(() {});
    await ref.read(authControllerProvider.notifier).sendOtp(
          mobile: _phoneController.text,
          onCodeSent: () {
            final phone = ref.read(authControllerProvider).phone ?? '+91${_phoneController.text}';
            if (!mounted) return;
            Navigator.pushNamed(
              context,
              AppRoutes.otp,
              arguments: OtpScreenArgs(phone: phone),
            );
          },
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
}
