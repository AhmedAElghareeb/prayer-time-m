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
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Location service disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied forever');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    final countryCode =
        placemarks.isNotEmpty && placemarks.first.isoCountryCode != null
            ? placemarks.first.isoCountryCode!
            : 'EG';

    if (kDebugMode) {
      debugPrint('Lat : ${position.latitude}');
      debugPrint('Lng : ${position.longitude}');
      debugPrint('country code : $countryCode');
    }

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      countryCode: countryCode,
    );
  }
}
