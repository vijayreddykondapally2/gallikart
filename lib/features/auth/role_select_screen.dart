import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/loader.dart';
import '../../core/widgets/primary_button.dart';
import 'auth_controller.dart';
import 'route_helpers.dart';

class RoleSelectArgs {
  const RoleSelectArgs({required this.phone});
  final String phone;
}

class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key, this.args});

  final RoleSelectArgs? args;

  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final phone = widget.args?.phone ?? ref.read(authControllerProvider).phone ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: Center(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Signed in as $phone'),
              const SizedBox(height: 16),
              _saving
                  ? const Loader()
                  : Column(
                      children: [
                        PrimaryButton(
                          label: 'I am a Customer',
                          onPressed: () => _persistRole(context, 'customer', phone),
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: 'I am a Vendor',
                          onPressed: () => _persistRole(context, 'vendor', phone),
                        ),
                      ],
                    ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _persistRole(BuildContext context, String role, String phone) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).saveUserRole(role: role, phone: phone);
      if (!mounted) return;
      routeUser(context, role);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
