class AirQualityData {
  final double latitude;
  final double longitude;
  final String locationName;
  final int aqi;
  final Map<String, double> pollutants;
  final DateTime timestamp;
  final String category;
  final String message;
  final List<String> recommendations;

  AirQualityData({
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.aqi,
    required this.pollutants,
    required this.timestamp,
    required this.category,
    required this.message,
    required this.recommendations,
  });

  factory AirQualityData.fromOpenWeatherMap(
    Map<String, dynamic> json,
    String locationName,
  ) {
    final list = json['list'][0];
    final components = list['components'];

    final pollutants = <String, double>{
      'pm2_5': (components['pm2_5'] ?? 0).toDouble(),
      'pm10': (components['pm10'] ?? 0).toDouble(),
      'o3': (components['o3'] ?? 0).toDouble(),
      'no2': (components['no2'] ?? 0).toDouble(),
      'so2': (components['so2'] ?? 0).toDouble(),
      'co': (components['co'] ?? 0).toDouble(),
    };

    final aqiValue = _calculateAQI(pollutants);
    final category = _getAQICategory(aqiValue);
    final message = _getAQIMessage(aqiValue);
    final recommendations = _getRecommendations(aqiValue);

    return AirQualityData(
      latitude: json['coord']['lat'].toDouble(),
      longitude: json['coord']['lon'].toDouble(),
      locationName: locationName,
      aqi: aqiValue,
      pollutants: pollutants,
      timestamp: DateTime.fromMillisecondsSinceEpoch(list['dt'] * 1000),
      category: category,
      message: message,
      recommendations: recommendations,
    );
  }

  factory AirQualityData.fromGoogleAirQuality(
    Map<String, dynamic> json,
    String locationName,
  ) {
    try {
      // Extract AQI from Google's response
      final aqiValue = json['indexes']?[0]?['aqi'] ?? 75;
      final category = json['indexes']?[0]?['category'] ?? 'Moderate';

      // Extract pollutant concentrations
      final pollutants = <String, double>{};
      final pollutantData = json['pollutants'] as List? ?? [];

      for (final pollutant in pollutantData) {
        final code = pollutant['code'] as String?;
        final concentration = pollutant['concentration']?['value'] as num?;

        if (code != null && concentration != null) {
          // Map Google's pollutant codes to our format
          String mappedCode = code.toLowerCase();
          if (code == 'pm25') mappedCode = 'pm2_5';
          pollutants[mappedCode] = concentration.toDouble();
        }
      }

      // Fill in missing pollutants with reasonable defaults
      pollutants.putIfAbsent('pm2_5', () => (aqiValue * 0.4));
      pollutants.putIfAbsent('pm10', () => (aqiValue * 0.6));
      pollutants.putIfAbsent('o3', () => (aqiValue * 0.8));
      pollutants.putIfAbsent('no2', () => (aqiValue * 0.3));
      pollutants.putIfAbsent('so2', () => (aqiValue * 0.2));
      pollutants.putIfAbsent('co', () => (aqiValue * 0.1));

      // Extract recommendations from health recommendations
      final healthRecs = json['healthRecommendations'] ?? {};
      final generalPopulation = healthRecs['generalPopulation'] ?? '';
      final recommendations = _parseGoogleRecommendations(
        generalPopulation,
        aqiValue,
      );

      final message = _getAQIMessage(aqiValue);

      // Extract coordinates from the request location (using defaults for now)
      const requestLocation = {'lat': 28.6139, 'lon': 77.2090};

      return AirQualityData(
        latitude: requestLocation['lat']!,
        longitude: requestLocation['lon']!,
        locationName: locationName,
        aqi: aqiValue,
        pollutants: pollutants,
        timestamp: DateTime.now(),
        category: _formatGoogleCategory(category),
        message: message,
        recommendations: recommendations,
      );
    } catch (e) {
      // Fallback to mock data if parsing fails
      return AirQualityData.mock(locationName, 28.6139, 77.2090);
    }
  }

  factory AirQualityData.mock(String locationName, double lat, double lon) {
    final pollutants = <String, double>{
      'pm2_5': 25.0 + (DateTime.now().millisecond % 50),
      'pm10': 40.0 + (DateTime.now().millisecond % 60),
      'o3': 80.0 + (DateTime.now().millisecond % 40),
      'no2': 30.0 + (DateTime.now().millisecond % 30),
      'so2': 15.0 + (DateTime.now().millisecond % 20),
      'co': 8.0 + (DateTime.now().millisecond % 10),
    };

    final aqiValue = _calculateAQI(pollutants);
    final category = _getAQICategory(aqiValue);
    final message = _getAQIMessage(aqiValue);
    final recommendations = _getRecommendations(aqiValue);

    return AirQualityData(
      latitude: lat,
      longitude: lon,
      locationName: locationName,
      aqi: aqiValue,
      pollutants: pollutants,
      timestamp: DateTime.now(),
      category: category,
      message: message,
      recommendations: recommendations,
    );
  }

  static int _calculateAQI(Map<String, double> pollutants) {
    // Simplified AQI calculation based on PM2.5
    final pm25 = pollutants['pm2_5'] ?? 0;
    if (pm25 <= 12) return 50;
    if (pm25 <= 35.4) return 100;
    if (pm25 <= 55.4) return 150;
    if (pm25 <= 150.4) return 200;
    if (pm25 <= 250.4) return 300;
    return 400;
  }

  static String _getAQICategory(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Fair';
    if (aqi <= 150) return 'Moderate';
    if (aqi <= 200) return 'Poor';
    if (aqi <= 300) return 'Very Poor';
    return 'Hazardous';
  }

  static String _getAQIMessage(int aqi) {
    if (aqi <= 50) {
      return 'Air quality is good. Perfect for outdoor activities!';
    }
    if (aqi <= 100) {
      return 'Air quality is fair. Moderate outdoor activities are fine.';
    }
    if (aqi <= 150) {
      return 'Air quality is moderate. Limit outdoor activities for sensitive groups.';
    }
    if (aqi <= 200) return 'Air quality is poor. Avoid outdoor activities.';
    if (aqi <= 300) return 'Air quality is very poor. Stay indoors.';
    return 'Air quality is hazardous. Emergency conditions!';
  }

  static List<String> _getRecommendations(int aqi) {
    if (aqi <= 50) {
      return [
        'Enjoy outdoor activities',
        'Open windows for fresh air',
        'Perfect time for exercise',
      ];
    }
    if (aqi <= 100) {
      return [
        'Outdoor activities are acceptable',
        'Sensitive individuals should limit prolonged outdoor exertion',
        'Good time for light exercise',
      ];
    }
    if (aqi <= 150) {
      return [
        'Limit prolonged outdoor activities',
        'Children and elderly should be cautious',
        'Consider wearing a mask outdoors',
      ];
    }
    if (aqi <= 200) {
      return [
        'Avoid outdoor activities',
        'Wear N95 mask when going out',
        'Keep windows closed',
        'Use air purifier indoors',
      ];
    }
    if (aqi <= 300) {
      return [
        'Stay indoors as much as possible',
        'Avoid all outdoor physical activities',
        'Wear N95 mask if you must go out',
        'Use air purifier and keep windows closed',
      ];
    }
    return [
      'Stay indoors at all times',
      'Avoid all outdoor activities',
      'Emergency conditions for all',
      'Use air purifier and seal windows',
      'Consider leaving the area',
    ];
  }

  static List<String> _parseGoogleRecommendations(
    String generalPopulation,
    int aqiValue,
  ) {
    if (generalPopulation.isNotEmpty) {
      // Try to extract meaningful recommendations from Google's text
      final recommendations = <String>[];
      if (generalPopulation.toLowerCase().contains('outdoor')) {
        if (generalPopulation.toLowerCase().contains('avoid')) {
          recommendations.add('Avoid outdoor activities');
        } else {
          recommendations.add('Outdoor activities are acceptable');
        }
      }
      if (generalPopulation.toLowerCase().contains('mask')) {
        recommendations.add('Consider wearing a mask');
      }
      if (generalPopulation.toLowerCase().contains('indoors')) {
        recommendations.add('Stay indoors when possible');
      }

      if (recommendations.isNotEmpty) {
        return recommendations;
      }
    }

    // Fallback to our standard recommendations
    return _getRecommendations(aqiValue);
  }

  static String _formatGoogleCategory(String googleCategory) {
    // Convert Google's category format to our format
    switch (googleCategory.toLowerCase()) {
      case 'excellent':
      case 'good':
        return 'Good';
      case 'fair':
      case 'moderate':
        return 'Fair';
      case 'poor':
        return 'Poor';
      case 'very poor':
      case 'verypoor':
        return 'Very Poor';
      case 'extremely poor':
      case 'hazardous':
        return 'Hazardous';
      default:
        return 'Moderate';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'aqi': aqi,
      'pollutants': pollutants,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
      'message': message,
      'recommendations': recommendations,
    };
  }

  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    return AirQualityData(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      locationName: json['locationName'] ?? '',
      aqi: json['aqi'] ?? 0,
      pollutants: Map<String, double>.from(json['pollutants'] ?? {}),
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      category: json['category'] ?? '',
      message: json['message'] ?? '',
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }
}
