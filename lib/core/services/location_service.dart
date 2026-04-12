import 'package:geolocator/geolocator.dart';
import '../models/trip.dart';

/// LocationService: wraps geolocator to get the device's current GPS position.
/// Returns a TripLatLng so no external map dependency is needed in the model layer.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Request permission and return current position.
  /// Returns null if permission denied or GPS unavailable.
  Future<TripLatLng?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return TripLatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Returns a stream of position updates (for live tracking).
  Stream<TripLatLng> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // update every 50 metres
      ),
    ).map((p) => TripLatLng(p.latitude, p.longitude));
  }
}
