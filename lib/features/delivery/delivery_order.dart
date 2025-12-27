// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

class DeliveryTask {
  DeliveryTask({
    required this.id,
    required this.orderId,
    required this.partner,
    required this.status,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String orderId;
  final String partner;
  final String status;
  final double latitude;
  final double longitude;
}
