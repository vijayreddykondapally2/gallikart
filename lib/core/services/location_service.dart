// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

class LocationService {
  const LocationService();

  /// Returns a fixed fallback location for Hyderabad outskirts until GPS is wired.
  Future<SimpleLocation> getCurrentLocation() async {
    return const SimpleLocation(latitude: 17.3850, longitude: 78.4867);
  }
}

class SimpleLocation {
  const SimpleLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}
