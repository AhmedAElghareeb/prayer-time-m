import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String countryCode;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.countryCode,
  });
}

class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    // 1. Check Service & Permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location service disabled');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw Exception('Permission denied');
    }

    // 2. Get Position with Android-specific settings
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
          // In newer geolocator versions, this is how you specify
          // to use the hardware directly if Play Services is slow:
          forceLocationManager: true,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ GPS timeout, trying last known...');
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        position = lastKnown;
      } else {
        throw Exception('Location not found');
      }
    }

    // 3. Get Country Code
    String countryCode = 'EG';
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        countryCode = placemarks.first.isoCountryCode ?? 'EG';
      }
    } catch (_) {}

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      countryCode: countryCode,
    );
  }
}
