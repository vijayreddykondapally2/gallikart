// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  const LocationService();

  Future<SimpleLocation> getCurrentLocation() async {
    try {
      final permissionGranted = await _ensurePermission();
      if (!permissionGranted) {
        return _fallbackLocation;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      return SimpleLocation(latitude: position.latitude, longitude: position.longitude);
    } catch (error, stack) {
      debugPrint('LocationService failed: $error');
      debugPrintStack(stackTrace: stack);
      return _fallbackLocation;
    }
  }

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }
}

const SimpleLocation _fallbackLocation = SimpleLocation(
  latitude: 17.3850,
  longitude: 78.4867,
  isFallback: true,
);

class SimpleLocation {
  const SimpleLocation({required this.latitude, required this.longitude, this.isFallback = false});

  final double latitude;
  final double longitude;
  final bool isFallback;
}
