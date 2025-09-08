import 'package:flutter/material.dart';
import '../models/air_quality_data.dart';
import '../models/forecast_data.dart';
import '../services/air_quality_service.dart';
import '../services/location_service.dart';

class AirQualityProvider extends ChangeNotifier {
  final AirQualityService _airQualityService = AirQualityService();
  final LocationService _locationService = LocationService();

  AirQualityData? _currentAirQuality;
  AirQualityForecast? _forecast;
  List<AirQualityData> _mapData = [];
  bool _isLoading = false;
  String _errorMessage = '';
  double? _currentLatitude;
  double? _currentLongitude;
  String _currentLocationName = 'Unknown Location';

  // Getters
  AirQualityData? get currentAirQuality => _currentAirQuality;
  AirQualityForecast? get forecast => _forecast;
  List<AirQualityData> get mapData => _mapData;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  double? get currentLatitude => _currentLatitude;
  double? get currentLongitude => _currentLongitude;
  String get currentLocationName => _currentLocationName;

  // Initialize with current location
  Future<void> initialize() async {
    await getCurrentLocationAirQuality();
    await loadMapData();
  }

  // Get air quality for current location
  Future<void> getCurrentLocationAirQuality() async {
    _setLoading(true);
    _clearError();

    try {
      // Try to get current location
      final position = await _locationService.getCurrentLocation();
      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;
      _currentLocationName = await _locationService.getLocationName(
        position.latitude,
        position.longitude,
      );

      // Get air quality data
      _currentAirQuality = await _airQualityService.getCurrentAirQuality(
        position.latitude,
        position.longitude,
        _currentLocationName,
      );

      _setLoading(false);
    } catch (e) {
      // Fallback to default location (Delhi)
      _currentLatitude = 28.6139;
      _currentLongitude = 77.2090;
      _currentLocationName = 'Delhi';

      try {
        _currentAirQuality = await _airQualityService.getCurrentAirQuality(
          _currentLatitude!,
          _currentLongitude!,
          _currentLocationName,
        );
      } catch (e2) {
        // Use mock data as final fallback
        _currentAirQuality = AirQualityData.mock(
          _currentLocationName,
          _currentLatitude!,
          _currentLongitude!,
        );
      }

      _setError(
        'Using default location. Enable location services for accurate data.',
      );
      _setLoading(false);
    }
  }

  // Get air quality forecast
  Future<void> getAirQualityForecast() async {
    if (_currentLatitude == null || _currentLongitude == null) {
      await getCurrentLocationAirQuality();
    }

    _setLoading(true);
    _clearError();

    try {
      _forecast = await _airQualityService.getAirQualityForecast(
        _currentLatitude!,
        _currentLongitude!,
        _currentLocationName,
      );
      _setLoading(false);
    } catch (e) {
      // Use mock data as fallback
      _forecast = AirQualityForecast.mock(
        _currentLocationName,
        _currentLatitude!,
        _currentLongitude!,
      );
      _setError('Using sample forecast data');
      _setLoading(false);
    }
  }

  // Load air quality data for map view
  Future<void> loadMapData() async {
    _setLoading(true);
    _clearError();

    try {
      final cities = AirQualityService.getMajorIndianCities();
      _mapData = await _airQualityService.getMultipleLocationsAirQuality(
        cities,
      );
      _setLoading(false);
    } catch (e) {
      // Generate mock data for all cities
      final cities = AirQualityService.getMajorIndianCities();
      _mapData = cities
          .map(
            (city) => AirQualityData.mock(
              city['name'],
              city['latitude'],
              city['longitude'],
            ),
          )
          .toList();

      _setError('Using sample map data');
      _setLoading(false);
    }
  }

  // Get air quality for specific location
  Future<void> getAirQualityForLocation(
    double latitude,
    double longitude,
    String locationName,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      _currentLatitude = latitude;
      _currentLongitude = longitude;
      _currentLocationName = locationName;

      _currentAirQuality = await _airQualityService.getCurrentAirQuality(
        latitude,
        longitude,
        locationName,
      );

      _setLoading(false);
    } catch (e) {
      _currentAirQuality = AirQualityData.mock(
        locationName,
        latitude,
        longitude,
      );
      _setError('Using sample data for this location');
      _setLoading(false);
    }
  }

  // Refresh all data
  Future<void> refreshData() async {
    await getCurrentLocationAirQuality();
    await getAirQualityForecast();
    await loadMapData();
  }

  // Get health recommendations based on current AQI
  List<String> getHealthRecommendations() {
    if (_currentAirQuality != null) {
      return _currentAirQuality!.recommendations;
    }
    return ['Enable location services to get personalized recommendations'];
  }

  // Get AQI category color
  Color getAQIColor() {
    if (_currentAirQuality != null) {
      return _getAQIColor(_currentAirQuality!.aqi);
    }
    return Colors.grey;
  }

  Color _getAQIColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF10B981); // Green
    if (aqi <= 100) return const Color(0xFFF59E0B); // Yellow
    if (aqi <= 150) return const Color(0xFFEF4444); // Red
    if (aqi <= 200) return const Color(0xFF8B5CF6); // Purple
    if (aqi <= 300) return const Color(0xFF991B1B); // Dark red
    return const Color(0xFF450A0A); // Very dark red
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }
}
