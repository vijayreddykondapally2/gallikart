import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/user_role_provider.dart';
import '../delivery/delivery_tasks_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_today_deliveries_screen.dart';

class RoleGateScreen extends ConsumerWidget {
  const RoleGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);
    return roleAsync.when(
      data: (role) {
        if (role == roleOwner || role == roleStaff) {
          return const _AdminTabs();
        }
        if (role == roleDelivery) {
          return const DeliveryTasksScreen();
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Admin / Delivery')),
          body: const Center(child: Text('No admin or delivery access for this user.')),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Admin / Delivery')),
        body: Center(child: Text('Failed to load role: $error')),
      ),
    );
  }
}

class _AdminTabs extends StatelessWidget {
  const _AdminTabs();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'New Orders'),
              Tab(text: "Today's Deliveries"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminOrdersScreen(),
            AdminTodayDeliveriesScreen(),
          ],
        ),
      ),
    );
  }
}
