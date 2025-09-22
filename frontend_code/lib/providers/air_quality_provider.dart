import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:vayudrishti/core/api_aqi.dart';
import 'package:vayudrishti/models/models.dart';
import 'package:dio/dio.dart';

// Legacy data classes for backward compatibility
class AirQualityData {
  final int aqi;
  final String category;
  final Map<String, double> pollutants;
  final DateTime timestamp;
  final String location;
  final double latitude;
  final double longitude;

  AirQualityData({
    required this.aqi,
    required this.category,
    required this.pollutants,
    required this.timestamp,
    required this.location,
    required this.latitude,
    required this.longitude,
  });

  factory AirQualityData.fromLatestAqi(LatestAqi latestAqi) {
    return AirQualityData(
      aqi: latestAqi.aqi,
      category: latestAqi.aqiCategory,
      pollutants: latestAqi.pollutantsMap,
      timestamp: latestAqi.timestamp,
      location: latestAqi.stationName,
      latitude: latestAqi.lat,
      longitude: latestAqi.lon,
    );
  }

  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    return AirQualityData(
      aqi: json['main']['aqi'] ?? 0,
      category: _getAQICategory(json['main']['aqi'] ?? 0),
      pollutants: {
        'PM2.5': (json['components']['pm2_5'] ?? 0).toDouble(),
        'PM10': (json['components']['pm10'] ?? 0).toDouble(),
        'CO': (json['components']['co'] ?? 0).toDouble(),
        'NO2': (json['components']['no2'] ?? 0).toDouble(),
        'O3': (json['components']['o3'] ?? 0).toDouble(),
        'SO2': (json['components']['so2'] ?? 0).toDouble(),
      },
      timestamp: DateTime.now(),
      location: 'Current Location',
      latitude: 0.0,
      longitude: 0.0,
    );
  }

  static String _getAQICategory(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Fair';
    if (aqi <= 150) return 'Moderate';
    if (aqi <= 200) return 'Poor';
    if (aqi <= 300) return 'Very Poor';
    return 'Hazardous';
  }
}

class ForecastData {
  final DateTime dateTime;
  final int aqi;
  final String category;
  final Map<String, double> pollutants;

  ForecastData({
    required this.dateTime,
    required this.aqi,
    required this.category,
    required this.pollutants,
  });

  factory ForecastData.fromForecastEntry(ForecastEntry entry) {
    final pollutantsMap = <String, double>{};
    for (final pollutant in entry.pollutants) {
      pollutantsMap[pollutant.name] = pollutant.value;
    }

    return ForecastData(
      dateTime: entry.timestamp,
      aqi: entry.aqi,
      category: entry.aqiCategory,
      pollutants: pollutantsMap,
    );
  }
}

class AirQualityProvider extends ChangeNotifier {
  final AqiApiClient _apiClient = AqiApiClient.instance;
  final Logger _logger = Logger();

  AirQualityData? _currentAQI;
  List<ForecastData> _forecastData = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdated;
  LatestAqi? _latestAqiData;
  List<ForecastEntry> _forecast = [];
  HealthRecommendation? _healthRecommendation;

  // Getters
  AirQualityData? get currentAQI => _currentAQI;
  List<ForecastData> get forecastData => _forecastData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;
  LatestAqi? get latestAqiData => _latestAqiData;
  List<ForecastEntry> get forecast => _forecast;
  HealthRecommendation? get healthRecommendation => _healthRecommendation;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Fetch current air quality data from backend
  Future<bool> fetchCurrentAQI(double latitude, double longitude) async {
    try {
      _setLoading(true);
      _setError(null);

      _logger.i('Fetching AQI data for lat: $latitude, lon: $longitude');

      final response = await _apiClient.getLatestByLocation(
        lat: latitude,
        lon: longitude,
        hours: 24,
      );

      if (response.statusCode == 200 && response.data != null) {
        final aqiResponse = AqiResponse.fromJson(response.data);

        // Update new model data
        _latestAqiData = aqiResponse.latest;
        _forecast = aqiResponse.forecast;
        _healthRecommendation = aqiResponse.health;

        // Update legacy model data for backward compatibility
        _currentAQI = AirQualityData.fromLatestAqi(aqiResponse.latest);
        _forecastData = aqiResponse.forecast
            .map((entry) => ForecastData.fromForecastEntry(entry))
            .toList();

        _lastUpdated = DateTime.now();
        _logger.i('Successfully fetched AQI data: ${aqiResponse.latest.aqi}');

        _setLoading(false);
        return true;
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      _setLoading(false);
      String errorMsg = 'Network error occurred';

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMsg = 'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMsg = 'Unable to connect to server. Please try again later.';
      } else if (e.response?.statusCode == 404) {
        errorMsg = 'No air quality data available for this location.';
      } else if (e.response?.statusCode == 500) {
        errorMsg = 'Server error. Please try again later.';
      }

      _setError(errorMsg);
      _logger.e('API Error: ${e.message}', error: e);

      // Fallback to mock data if API fails
      return await _fetchMockData(latitude, longitude);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to fetch air quality data. Please try again.');
      _logger.e('Unexpected error: $e');

      // Fallback to mock data if API fails
      return await _fetchMockData(latitude, longitude);
    }
  }

  // Fetch forecast data (already included in the main API call)
  Future<bool> fetchForecastData(double latitude, double longitude) async {
    // Forecast data is already fetched with the main AQI call
    if (_forecast.isNotEmpty) {
      return true;
    }
    // If no forecast data, refetch everything
    return await fetchCurrentAQI(latitude, longitude);
  }

  // Fetch historical data for a specific station
  Future<List<HistoricalAqiEntry>> fetchHistoricalData({
    required String stationId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      _logger.i('Fetching historical data for station: $stationId');

      final response = await _apiClient.getHistorical(
        stationId: stationId,
        from: from,
        to: to,
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'] as List<dynamic>;
        return data
            .map(
              (entry) =>
                  HistoricalAqiEntry.fromJson(entry as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      _logger.e('Error fetching historical data: ${e.message}');
      throw Exception('Failed to fetch historical data');
    }
  }

  // Fetch data for a specific station
  Future<bool> fetchStationData(String stationId) async {
    try {
      _setLoading(true);
      _setError(null);

      _logger.i('Fetching data for station: $stationId');

      final response = await _apiClient.getByStation(stationId);

      if (response.statusCode == 200 && response.data != null) {
        final aqiResponse = AqiResponse.fromJson(response.data);

        // Update new model data
        _latestAqiData = aqiResponse.latest;
        _forecast = aqiResponse.forecast;
        _healthRecommendation = aqiResponse.health;

        // Update legacy model data for backward compatibility
        _currentAQI = AirQualityData.fromLatestAqi(aqiResponse.latest);
        _forecastData = aqiResponse.forecast
            .map((entry) => ForecastData.fromForecastEntry(entry))
            .toList();

        _lastUpdated = DateTime.now();
        _logger.i('Successfully fetched station data');

        _setLoading(false);
        return true;
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      _setLoading(false);
      _setError('Failed to fetch station data. Please try again.');
      _logger.e('Error fetching station data: ${e.message}');
      return false;
    }
  }

  // Fallback method for mock data when API is unavailable
  Future<bool> _fetchMockData(double latitude, double longitude) async {
    try {
      _logger.w('Using mock data as fallback');
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      _currentAQI = _generateMockAQIData(latitude, longitude);
      _forecastData = _generateMockForecastData();
      _lastUpdated = DateTime.now();

      return true;
    } catch (e) {
      _logger.e('Error generating mock data: $e');
      return false;
    }
  }

  // Generate mock AQI data for demonstration
  AirQualityData _generateMockAQIData(double latitude, double longitude) {
    final random = DateTime.now().millisecond;
    final aqi = 50 + (random % 150); // AQI between 50-200

    return AirQualityData(
      aqi: aqi,
      category: _getAQICategory(aqi),
      pollutants: {
        'PM2.5': 15.0 + (random % 40), // 15-55 μg/m³
        'PM10': 25.0 + (random % 60), // 25-85 μg/m³
        'CO': 0.8 + (random % 20) / 10, // 0.8-2.8 mg/m³
        'NO2': 20.0 + (random % 80), // 20-100 μg/m³
        'O3': 60.0 + (random % 120), // 60-180 μg/m³
        'SO2': 5.0 + (random % 30), // 5-35 μg/m³
      },
      timestamp: DateTime.now(),
      location: 'Mock Station (Offline)',
      latitude: latitude,
      longitude: longitude,
    );
  }

  // Generate mock forecast data
  List<ForecastData> _generateMockForecastData() {
    final List<ForecastData> forecast = [];
    final now = DateTime.now();

    for (int i = 0; i < 24; i++) {
      final dateTime = now.add(Duration(hours: i));
      final random = (now.millisecond + i) % 100;
      final aqi = 40 + random; // AQI between 40-140

      forecast.add(
        ForecastData(
          dateTime: dateTime,
          aqi: aqi,
          category: _getAQICategory(aqi),
          pollutants: {
            'PM2.5': 10.0 + random / 2,
            'PM10': 20.0 + random,
            'CO': 0.5 + random / 50,
            'NO2': 15.0 + random / 2,
            'O3': 50.0 + random,
            'SO2': 3.0 + random / 5,
          },
        ),
      );
    }

    return forecast;
  }

  // Get AQI category from numeric value
  String _getAQICategory(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Fair';
    if (aqi <= 150) return 'Moderate';
    if (aqi <= 200) return 'Poor';
    if (aqi <= 300) return 'Very Poor';
    return 'Hazardous';
  }

  // Get health advisory based on AQI
  String getHealthAdvisory(int aqi) {
    if (_healthRecommendation != null) {
      return _healthRecommendation!.description;
    }

    // Fallback logic
    if (aqi <= 50) {
      return 'Air quality is considered satisfactory. Ideal for all outdoor activities.';
    } else if (aqi <= 100) {
      return 'Air quality is acceptable. Unusually sensitive people should consider limiting prolonged outdoor exertion.';
    } else if (aqi <= 150) {
      return 'Members of sensitive groups may experience health effects. Limit prolonged outdoor exertion.';
    } else if (aqi <= 200) {
      return 'Health warnings of emergency conditions. Everyone may experience more serious health effects.';
    } else if (aqi <= 300) {
      return 'Health alert: everyone may experience serious health effects. Avoid outdoor activities.';
    } else {
      return 'Emergency conditions: the entire population is at risk. Stay indoors and avoid all physical activities.';
    }
  }

  // Get recommendations based on AQI
  List<String> getRecommendations(int aqi) {
    if (_healthRecommendation != null) {
      return _healthRecommendation!.recommendations;
    }

    // Fallback logic
    if (aqi <= 50) {
      return [
        'Perfect for outdoor exercise',
        'Open windows for fresh air',
        'Great day for outdoor activities',
      ];
    } else if (aqi <= 100) {
      return [
        'Good for most outdoor activities',
        'Sensitive individuals should limit outdoor exposure',
        'Consider wearing a mask if you\'re sensitive',
      ];
    } else if (aqi <= 150) {
      return [
        'Limit outdoor exercise',
        'Close windows',
        'Wear a mask when outdoors',
        'Consider using air purifiers indoors',
      ];
    } else if (aqi <= 200) {
      return [
        'Avoid outdoor exercise',
        'Stay indoors with windows closed',
        'Use air purifiers',
        'Wear N95 mask when going outside',
      ];
    } else {
      return [
        'Stay indoors',
        'Avoid all outdoor activities',
        'Use air purifiers continuously',
        'Wear N95/N99 mask if must go outside',
        'Consider relocating temporarily',
      ];
    }
  }

  // Check if backend is available
  Future<bool> checkBackendHealth() async {
    try {
      return await _apiClient.checkHealth();
    } catch (e) {
      _logger.e('Backend health check failed: $e');
      return false;
    }
  }

  // Refresh data
  Future<bool> refreshData(double latitude, double longitude) async {
    final success = await fetchCurrentAQI(latitude, longitude);
    if (success) {
      await fetchForecastData(latitude, longitude);
    }
    return success;
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Reset all data
  void reset() {
    _currentAQI = null;
    _forecastData = [];
    _errorMessage = null;
    _isLoading = false;
    _lastUpdated = null;
    _latestAqiData = null;
    _forecast = [];
    _healthRecommendation = null;
    notifyListeners();
  }
}
