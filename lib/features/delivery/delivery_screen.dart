// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_strings.dart';
import '../../core/services/location_service.dart';
import '../../routes/app_routes.dart';
import '../orders/order_controller.dart';
import 'delivery_controller.dart';

final _locationServiceProvider = Provider<LocationService>((ref) => const LocationService());
final _currentLocationProvider = FutureProvider.autoDispose<SimpleLocation>((ref) {
  return ref.watch(_locationServiceProvider).getCurrentLocation();
});

class DeliveryScreen extends ConsumerWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(deliveryControllerProvider);
    final orders = ref.watch(orderControllerProvider);
    final controller = ref.read(deliveryControllerProvider.notifier);
    final locationState = ref.watch(_currentLocationProvider);

    Future<void> openNavigation(double latitude, double longitude) async {
      final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
      );
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open navigation.')),
        );
      }
    }

    Widget buildLocationCard() {
      return locationState.when(
        data: (location) => Card(
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.my_location),
            title: const Text('Current location'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                ),
                if (location.isFallback)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Location fallback – enable GPS/permissions for accuracy.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.directions),
              tooltip: 'Open maps',
              onPressed: () => openNavigation(location.latitude, location.longitude),
            ),
            isThreeLine: location.isFallback,
          ),
        ),
        loading: () => const Card(
          elevation: 1,
          child: ListTile(
            leading: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('Fetching current location'),
          ),
        ),
        error: (error, _) => Card(
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.warning, color: Colors.orange),
            title: const Text('Location unavailable'),
            subtitle: const Text('Enable GPS or permissions from settings.'),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Retry',
              onPressed: () => ref.refresh(_currentLocationProvider),
            ),
          ),
        ),
      );
    }

    final deliveryList = tasks.isEmpty
        ? const Center(child: Text('No delivery assignments yet'))
        : ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                title: Text('Order ${task.orderId}'),
                subtitle: Text('${task.partner} · ${task.status}'),
                trailing: IconButton(
                  icon: const Icon(Icons.navigation),
                  tooltip: 'Navigate to delivery',
                  onPressed: () => openNavigation(task.latitude, task.longitude),
                ),
              );
            },
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.deliveryTitle),
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
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Refresh location',
            onPressed: () => ref.refresh(_currentLocationProvider),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildLocationCard(),
            const SizedBox(height: 12),
            Expanded(child: deliveryList),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => controller.assign(orders),
        icon: const Icon(Icons.local_shipping),
        label: const Text('Assign'),
      ),
    );
  }
}
