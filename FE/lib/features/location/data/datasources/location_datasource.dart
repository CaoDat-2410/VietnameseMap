import '../../domain/entities/location.dart';

abstract interface class LocationDataSource {
  Future<Location> getCurrentLocation();
}

// Stub implementation — replace with geolocator / permission_handler when added.
// Using a fixed centroid of Vietnam (Hanoi) as fallback for dev/testing.
class StubLocationDataSource implements LocationDataSource {
  @override
  Future<Location> getCurrentLocation() async {
    return const Location(latitude: 21.0285, longitude: 105.8542);
  }
}
