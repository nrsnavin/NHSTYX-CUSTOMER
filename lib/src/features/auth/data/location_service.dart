import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Detects the device's city via GPS + reverse geocoding, for pre-selecting
/// the registration city. Throws a user-friendly message on failure.
class LocationService {
  /// Returns candidate city/area names (most specific first) for the current
  /// location, so the caller can match them against serviceable cities.
  Future<List<String>> detectCityCandidates() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw 'Location is turned off. Enable it and try again.';
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw 'Location permission denied.';
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission is blocked — enable it in Settings.';
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );
    final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

    final candidates = <String>[];
    for (final p in placemarks.take(3)) {
      for (final name in [p.locality, p.subAdministrativeArea, p.subLocality, p.administrativeArea]) {
        final trimmed = name?.trim() ?? '';
        if (trimmed.isNotEmpty && !candidates.contains(trimmed)) candidates.add(trimmed);
      }
    }
    if (candidates.isEmpty) throw 'Could not determine your city from your location.';
    return candidates;
  }
}

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());
