import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoading = false;
  String? _errorMessage;
  bool _serviceEnabled = false;
  LocationPermission _permission = LocationPermission.denied;

  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get serviceEnabled => _serviceEnabled;
  LocationPermission get permission => _permission;

  double? get latitude => _currentPosition?.latitude;
  double? get longitude => _currentPosition?.longitude;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Check location permissions and get current location
  Future<bool> getCurrentLocation() async {
    try {
      _setLoading(true);
      _setError(null);

      // Check if location services are enabled
      _serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_serviceEnabled) {
        _setError(
          'Location services are disabled. Please enable location services.',
        );
        _setLoading(false);
        return false;
      }

      // Check location permissions
      _permission = await Geolocator.checkPermission();
      if (_permission == LocationPermission.denied) {
        _permission = await Geolocator.requestPermission();
        if (_permission == LocationPermission.denied) {
          _setError(
            'Location permissions are denied. Please grant location access.',
          );
          _setLoading(false);
          return false;
        }
      }

      if (_permission == LocationPermission.deniedForever) {
        _setError(
          'Location permissions are permanently denied. Please enable them in settings.',
        );
        _setLoading(false);
        return false;
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Get address from coordinates (simplified - in real app would use geocoding)
      _currentAddress = await _getAddressFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to get current location. Please try again.');
      debugPrint('Error getting location: $e');
      return false;
    }
  }

  // Get location continuously
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  // Calculate distance between two points
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Simplified address resolution (in a real app, use geocoding package)
  Future<String> _getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    // This is a simplified implementation
    // In a real app, you would use a geocoding service
    try {
      // Mock address based on coordinates
      return 'Current Location (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})';
    } catch (e) {
      return 'Unknown Location';
    }
  }

  // Check if location services are available
  Future<bool> checkLocationServices() async {
    _serviceEnabled = await Geolocator.isLocationServiceEnabled();
    _permission = await Geolocator.checkPermission();

    notifyListeners();
    return _serviceEnabled && _permission != LocationPermission.denied;
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      _permission = await Geolocator.requestPermission();
      notifyListeners();

      return _permission == LocationPermission.whileInUse ||
          _permission == LocationPermission.always;
    } catch (e) {
      _setError('Failed to request location permission.');
      return false;
    }
  }

  // Open location settings
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      _setError('Failed to open location settings.');
      return false;
    }
  }

  // Open app settings
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      _setError('Failed to open app settings.');
      return false;
    }
  }

  // Update current position manually
  void updatePosition(Position position) {
    _currentPosition = position;
    notifyListeners();
  }

  // Update current address manually
  void updateAddress(String address) {
    _currentAddress = address;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Reset location data
  void reset() {
    _currentPosition = null;
    _currentAddress = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
