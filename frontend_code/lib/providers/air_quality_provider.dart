import 'package:flutter/material.dart';

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
}

class AirQualityProvider extends ChangeNotifier {
  AirQualityData? _currentAQI;
  List<ForecastData> _forecastData = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdated;

  AirQualityData? get currentAQI => _currentAQI;
  List<ForecastData> get forecastData => _forecastData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Fetch current air quality data
  Future<bool> fetchCurrentAQI(double latitude, double longitude) async {
    try {
      _setLoading(true);
      _setError(null);

      // For now, use mock data since API key is not provided
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      _currentAQI = _generateMockAQIData(latitude, longitude);
      _lastUpdated = DateTime.now();

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to fetch air quality data. Please try again.');
      debugPrint('Error fetching AQI: $e');
      return false;
    }
  }

  // Fetch forecast data
  Future<bool> fetchForecastData(double latitude, double longitude) async {
    try {
      _setLoading(true);
      _setError(null);

      // For now, use mock data
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      _forecastData = _generateMockForecastData();

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to fetch forecast data. Please try again.');
      debugPrint('Error fetching forecast: $e');
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
      location: 'Current Location',
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
    notifyListeners();
  }
}
