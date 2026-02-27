import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Result of a location detection attempt.
class LocationResult {
  final Position? position;
  final String? villageName;
  final String? fullAddress;
  final String? error;
  final bool permissionDenied;

  LocationResult({
    this.position,
    this.villageName,
    this.fullAddress,
    this.error,
    this.permissionDenied = false,
  });

  bool get success => position != null;
}

/// Real GPS location + reverse geocoding service.
/// Replaces hardcoded lat/long and village dropdown.
class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  // Cache the last known position
  Position? _lastPosition;
  String? _lastVillage;

  Position? get lastPosition => _lastPosition;
  String? get lastVillage => _lastVillage;

  /// Full location detection flow: check services → request permissions → get GPS → reverse geocode.
  /// Returns a LocationResult with either success data or a user-friendly error message.
  Future<LocationResult> detectLocation({String? localeIdentifier}) async {
    try {
      // Step 1: Check if location services (GPS) are turned on
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          error: 'Location services are turned off. Please enable GPS in your phone settings.',
          permissionDenied: false,
        );
      }

      // Step 2: Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // First time — request permission
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(
            error: 'Location permission was denied. Tap "Auto-detect" again and allow access.',
            permissionDenied: true,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          error: 'Location permission is permanently denied. Go to Settings → Apps → AgroSwap → Permissions → Location → Allow.',
          permissionDenied: true,
        );
      }

      // Step 3: Get actual GPS coordinates
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      _lastPosition = position;

      // Step 4: Reverse geocode to get village name
      String villageName = 'Unknown';
      String fullAddress = 'Unknown location';

      try {
        if (localeIdentifier != null) {
          await setLocaleIdentifier(localeIdentifier);
        }
        
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;

          // Get the most specific locality for rural India
          villageName = _extractVillage(place);
          fullAddress = _buildFullAddress(place);
        }
      } catch (geocodeError) {
        // Geocoding failed but we still have GPS coordinates
        villageName = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }

      _lastVillage = villageName;

      return LocationResult(
        position: position,
        villageName: villageName,
        fullAddress: fullAddress,
      );
    } on LocationServiceDisabledException {
      return LocationResult(
        error: 'GPS is turned off. Please enable Location in your phone settings.',
      );
    } catch (e) {
      return LocationResult(
        error: 'Could not detect location: ${e.toString().split(':').last.trim()}',
      );
    }
  }

  /// Simple position getter (for backward compatibility).
  Future<Position?> getCurrentPosition() async {
    final result = await detectLocation();
    return result.position;
  }

  /// Reverse geocode coordinates to get village/locality name.
  Future<String> getVillageFromCoordinates(
      double latitude, double longitude, {String? localeIdentifier}) async {
    try {
      if (localeIdentifier != null) {
        await setLocaleIdentifier(localeIdentifier);
      }
      final placemarks = await placemarkFromCoordinates(
        latitude, 
        longitude, 
      );
      if (placemarks.isEmpty) return 'Unknown';
      return _extractVillage(placemarks.first);
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get full address string from coordinates.
  Future<String> getFullAddress(
      double latitude, double longitude, {String? localeIdentifier}) async {
    try {
      if (localeIdentifier != null) {
        await setLocaleIdentifier(localeIdentifier);
      }
      final placemarks = await placemarkFromCoordinates(
        latitude, 
        longitude,
      );
      if (placemarks.isEmpty) return 'Unknown location';
      return _buildFullAddress(placemarks.first);
    } catch (e) {
      return 'Unknown location';
    }
  }

  /// Calculate distance between two points in kilometers.
  double getDistanceKm(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Open system location settings (for when permissions are denied).
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (for when permissions are permanently denied).
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  // ─── Private helpers ───────────────────────────────────────

  String _extractVillage(Placemark place) {
    // Priority: subLocality → locality → subAdministrativeArea → administrativeArea
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      return place.subLocality!;
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      return place.locality!;
    }
    if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
      return place.subAdministrativeArea!;
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      return place.administrativeArea!;
    }
    return 'Unknown';
  }

  String _buildFullAddress(Placemark p) {
    final parts = <String>[
      if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
      if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
      if (p.subAdministrativeArea != null && p.subAdministrativeArea!.isNotEmpty)
        p.subAdministrativeArea!,
      if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
        p.administrativeArea!,
      if (p.postalCode != null && p.postalCode!.isNotEmpty) p.postalCode!,
    ];
    return parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
  }
}
