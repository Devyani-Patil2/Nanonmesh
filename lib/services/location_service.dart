import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Real GPS location + reverse geocoding service.
/// Replaces hardcoded lat/long and village dropdown.
class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  /// Get real device GPS coordinates.
  /// Returns [latitude, longitude] or null if unavailable.
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      // Get actual position
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Reverse geocode coordinates to get village/locality name.
  /// Returns the most specific locality found (subLocality > locality > subAdministrativeArea).
  Future<String> getVillageFromCoordinates(
      double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return 'Unknown';

      final place = placemarks.first;

      // Try to get the most specific rural locality
      // Priority: subLocality → locality → subAdministrativeArea → administrativeArea
      final village = place.subLocality?.isNotEmpty == true
          ? place.subLocality!
          : place.locality?.isNotEmpty == true
              ? place.locality!
              : place.subAdministrativeArea?.isNotEmpty == true
                  ? place.subAdministrativeArea!
                  : place.administrativeArea ?? 'Unknown';

      return village;
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get full address string from coordinates.
  Future<String> getFullAddress(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return 'Unknown location';

      final p = placemarks.first;
      final parts = <String>[
        if (p.subLocality?.isNotEmpty == true) p.subLocality!,
        if (p.locality?.isNotEmpty == true) p.locality!,
        if (p.subAdministrativeArea?.isNotEmpty == true)
          p.subAdministrativeArea!,
        if (p.administrativeArea?.isNotEmpty == true) p.administrativeArea!,
      ];
      return parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
    } catch (e) {
      return 'Unknown location';
    }
  }

  /// Calculate distance between two points in kilometers.
  double getDistanceKm(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
}
