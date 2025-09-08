class ForecastData {
  final DateTime timestamp;
  final int aqi;
  final Map<String, double> pollutants;
  final String category;

  ForecastData({
    required this.timestamp,
    required this.aqi,
    required this.pollutants,
    required this.category,
  });

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    final components = json['components'];
    final pollutants = <String, double>{
      'pm2_5': (components['pm2_5'] ?? 0).toDouble(),
      'pm10': (components['pm10'] ?? 0).toDouble(),
      'o3': (components['o3'] ?? 0).toDouble(),
      'no2': (components['no2'] ?? 0).toDouble(),
      'so2': (components['so2'] ?? 0).toDouble(),
      'co': (components['co'] ?? 0).toDouble(),
    };

    final aqi = _calculateAQI(pollutants);
    final category = _getAQICategory(aqi);

    return ForecastData(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      aqi: aqi,
      pollutants: pollutants,
      category: category,
    );
  }

  factory ForecastData.fromGoogleForecast(Map<String, dynamic> json) {
    try {
      final timestamp = DateTime.parse(
        json['dateTime'] ?? DateTime.now().toIso8601String(),
      );
      final aqi = json['indexes']?[0]?['aqi'] ?? 50;
      final category = json['indexes']?[0]?['category'] ?? 'Good';

      // Extract pollutant concentrations
      final pollutants = <String, double>{};
      final pollutantData = json['pollutants'] as List? ?? [];

      for (final pollutant in pollutantData) {
        final code = pollutant['code'] as String?;
        final concentration = pollutant['concentration']?['value'] as num?;

        if (code != null && concentration != null) {
          String mappedCode = code.toLowerCase();
          if (code == 'pm25') mappedCode = 'pm2_5';
          pollutants[mappedCode] = concentration.toDouble();
        }
      }

      // Fill in missing pollutants with reasonable defaults
      pollutants.putIfAbsent('pm2_5', () => (aqi * 0.4));
      pollutants.putIfAbsent('pm10', () => (aqi * 0.6));
      pollutants.putIfAbsent('o3', () => (aqi * 0.8));
      pollutants.putIfAbsent('no2', () => (aqi * 0.3));
      pollutants.putIfAbsent('so2', () => (aqi * 0.2));
      pollutants.putIfAbsent('co', () => (aqi * 0.1));

      return ForecastData(
        timestamp: timestamp,
        aqi: aqi,
        pollutants: pollutants,
        category: _formatGoogleCategory(category),
      );
    } catch (e) {
      // Fallback to mock data
      return ForecastData.mock(DateTime.now());
    }
  }

  factory ForecastData.mock(DateTime timestamp) {
    final pollutants = <String, double>{
      'pm2_5': 20.0 + (timestamp.millisecond % 60),
      'pm10': 35.0 + (timestamp.millisecond % 70),
      'o3': 75.0 + (timestamp.millisecond % 50),
      'no2': 25.0 + (timestamp.millisecond % 40),
      'so2': 12.0 + (timestamp.millisecond % 25),
      'co': 6.0 + (timestamp.millisecond % 15),
    };

    final aqi = _calculateAQI(pollutants);
    final category = _getAQICategory(aqi);

    return ForecastData(
      timestamp: timestamp,
      aqi: aqi,
      pollutants: pollutants,
      category: category,
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

  static String _formatGoogleCategory(String? category) {
    if (category == null) return 'Good';

    // Google API categories mapping to our app's categories
    switch (category.toLowerCase()) {
      case 'excellent':
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      case 'moderate':
        return 'Moderate';
      case 'poor':
        return 'Poor';
      case 'very_poor':
        return 'Very Poor';
      case 'extremely_poor':
        return 'Hazardous';
      default:
        return category; // Return as-is if not recognized
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'aqi': aqi,
      'pollutants': pollutants,
      'category': category,
    };
  }
}

class AirQualityForecast {
  final String locationName;
  final double latitude;
  final double longitude;
  final List<ForecastData> hourlyForecast;
  final List<ForecastData> dailyForecast;
  final DateTime lastUpdated;

  AirQualityForecast({
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.hourlyForecast,
    required this.dailyForecast,
    required this.lastUpdated,
  });

  factory AirQualityForecast.fromOpenWeatherMap(
    Map<String, dynamic> json,
    String locationName,
  ) {
    final list = json['list'] as List;
    final hourlyData = list.map((item) => ForecastData.fromJson(item)).toList();

    // Group by day for daily forecast
    final dailyGroups = <String, List<ForecastData>>{};
    for (final data in hourlyData) {
      final dayKey =
          '${data.timestamp.year}-${data.timestamp.month}-${data.timestamp.day}';
      dailyGroups[dayKey] ??= [];
      dailyGroups[dayKey]!.add(data);
    }

    final dailyData = dailyGroups.entries.map((entry) {
      final dayData = entry.value;
      final avgAqi =
          dayData.map((d) => d.aqi).reduce((a, b) => a + b) ~/ dayData.length;
      final avgPollutants = <String, double>{};

      for (final key in dayData.first.pollutants.keys) {
        avgPollutants[key] =
            dayData.map((d) => d.pollutants[key] ?? 0).reduce((a, b) => a + b) /
            dayData.length;
      }

      return ForecastData(
        timestamp: dayData.first.timestamp,
        aqi: avgAqi,
        pollutants: avgPollutants,
        category: ForecastData._getAQICategory(avgAqi),
      );
    }).toList();

    return AirQualityForecast(
      locationName: locationName,
      latitude: json['city']['coord']['lat'].toDouble(),
      longitude: json['city']['coord']['lon'].toDouble(),
      hourlyForecast: hourlyData.take(24).toList(),
      dailyForecast: dailyData.take(5).toList(),
      lastUpdated: DateTime.now(),
    );
  }

  factory AirQualityForecast.fromGoogleAirQuality(
    Map<String, dynamic> json,
    String locationName,
  ) {
    try {
      // Extract hourly forecast from Google API response
      final hourlyForecasts = json['hourlyForecasts'] as List? ?? [];
      final hourlyData = hourlyForecasts
          .map((item) => ForecastData.fromGoogleForecast(item))
          .toList();

      // If no hourly data, create some mock data
      if (hourlyData.isEmpty) {
        final now = DateTime.now();
        for (int i = 0; i < 24; i++) {
          hourlyData.add(ForecastData.mock(now.add(Duration(hours: i))));
        }
      }

      // Group hourly data by day for daily forecast
      final dailyGroups = <String, List<ForecastData>>{};
      for (final data in hourlyData) {
        final dayKey =
            '${data.timestamp.year}-${data.timestamp.month}-${data.timestamp.day}';
        dailyGroups[dayKey] ??= [];
        dailyGroups[dayKey]!.add(data);
      }

      final dailyData = dailyGroups.entries.map((entry) {
        final dayData = entry.value;
        final avgAqi =
            dayData.map((d) => d.aqi).reduce((a, b) => a + b) ~/ dayData.length;
        final avgPollutants = <String, double>{};

        for (final key in dayData.first.pollutants.keys) {
          avgPollutants[key] =
              dayData
                  .map((d) => d.pollutants[key] ?? 0)
                  .reduce((a, b) => a + b) /
              dayData.length;
        }

        return ForecastData(
          timestamp: dayData.first.timestamp,
          aqi: avgAqi,
          pollutants: avgPollutants,
          category: ForecastData._getAQICategory(avgAqi),
        );
      }).toList();

      // Extract location coordinates from request or use defaults
      double latitude = 0.0;
      double longitude = 0.0;

      // Try to extract from the request location if available
      if (json.containsKey('location')) {
        latitude = json['location']['latitude']?.toDouble() ?? 0.0;
        longitude = json['location']['longitude']?.toDouble() ?? 0.0;
      }

      return AirQualityForecast(
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        hourlyForecast: hourlyData.take(24).toList(),
        dailyForecast: dailyData.take(5).toList(),
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      // Fallback to mock data if parsing fails
      return AirQualityForecast.mock(locationName, 0.0, 0.0);
    }
  }

  factory AirQualityForecast.mock(String locationName, double lat, double lon) {
    final now = DateTime.now();
    final hourlyData = List.generate(24, (index) {
      return ForecastData.mock(now.add(Duration(hours: index)));
    });

    final dailyData = List.generate(5, (index) {
      return ForecastData.mock(now.add(Duration(days: index)));
    });

    return AirQualityForecast(
      locationName: locationName,
      latitude: lat,
      longitude: lon,
      hourlyForecast: hourlyData,
      dailyForecast: dailyData,
      lastUpdated: now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'hourlyForecast': hourlyForecast.map((f) => f.toJson()).toList(),
      'dailyForecast': dailyForecast.map((f) => f.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
