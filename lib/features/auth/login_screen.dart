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
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();

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
              if (state.loading)
                const Loader()
              else
                PrimaryButton(
                  label: 'Continue',
                  onPressed: isValidPhone(_phoneController.text)
                      ? () => ref.read(authControllerProvider.notifier).loginAnonymously()
                      : null,
                ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ErrorView(
                    message: state.error ?? 'Something went wrong',
                    onRetry: () => ref.read(authControllerProvider.notifier).loginAnonymously(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
