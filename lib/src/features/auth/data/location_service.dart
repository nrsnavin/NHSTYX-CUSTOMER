import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Detects the device's city via GPS + reverse geocoding, for pre-selecting
/// the registration city. Throws a user-friendly String message on failure.
class LocationService {
  /// Returns candidate city/area names (most specific first) for the current
  /// location, so the caller can match them against serviceable cities.
  Future<List<String>> detectCityCandidates() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw 'Location is turned off. Turn on GPS / location and try again.';
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw 'Location permission denied. Allow it to auto-detect your city.';
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission is blocked — enable it in Settings to use this.';
    }

    // Get a fix, but never hang: time out and fall back to the last known
    // position so a slow GPS lock can't leave the button spinning forever.
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } on TimeoutException {
      position = await Geolocator.getLastKnownPosition();
    } catch (_) {
      position = await Geolocator.getLastKnownPosition();
    }
    if (position == null) {
      throw 'Couldn’t get a location fix. Move to an open area and try again.';
    }

    final List<Placemark> placemarks;
    try {
      placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    } catch (_) {
      throw 'Couldn’t look up your city (needs internet). Please pick it from the list.';
    }

    final candidates = <String>[];
    void add(String? name) {
      final trimmed = name?.trim() ?? '';
      if (trimmed.isNotEmpty && !candidates.contains(trimmed)) candidates.add(trimmed);
    }

    for (final p in placemarks.take(3)) {
      add(p.locality);
      add(p.subAdministrativeArea);
      add(p.subLocality);
      add(p.administrativeArea);
    }
    if (candidates.isEmpty) {
      throw 'Couldn’t determine your city from your location. Please pick it from the list.';
    }
    return candidates;
  }
}

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());
