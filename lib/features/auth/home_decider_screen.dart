import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/widgets/loader.dart';
import '../../routes/app_routes.dart';
import 'role_select_screen.dart';
import 'route_helpers.dart';

class HomeDeciderScreen extends ConsumerWidget {
  const HomeDeciderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<void>(
      future: _resolve(context, ref),
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Failed to load: ${snapshot.error}'),
            ),
          );
        }
        return const Scaffold(body: Center(child: Loader()));
      },
    );
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(firebaseAuthProvider);
    final firestore = ref.read(firebaseFirestoreProvider);
    final user = auth.currentUser;
    if (user == null || user.phoneNumber == null) {
      await auth.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
      return;
    }
    final docRef = firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();
    if (!context.mounted) return;
    if (!doc.exists || (doc.data()?['role'] as String?) == null) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.roleSelect,
        arguments: RoleSelectArgs(phone: user.phoneNumber ?? ''),
      );
      return;
    }
    final role = (doc.data()?['role'] as String).toLowerCase();
    await docRef.set({'lastLogin': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    routeUser(context, role);
  }
}
