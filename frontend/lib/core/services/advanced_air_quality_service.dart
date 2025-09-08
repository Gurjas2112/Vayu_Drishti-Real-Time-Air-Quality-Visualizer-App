import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/historical_data.dart';
import '../models/forecast_data.dart';
import '../models/health_advisory.dart';

class AdvancedAirQualityService {
  static const String _baseUrl = AppConstants.googleAirQualityBaseUrl;
  static const String _apiKey = AppConstants.googleApiKey;

  // Get historical air quality data
  Future<HistoricalAirQualityData> getHistoricalData(
    double latitude,
    double longitude,
    String locationName,
    int daysBack,
  ) async {
    try {
      // Note: Google Air Quality API doesn't provide historical data
      // This would typically connect to a different API or database
      // For now, return mock data
      return HistoricalAirQualityData.mock(
        locationName,
        latitude,
        longitude,
        daysBack,
      );
    } catch (e) {
      return HistoricalAirQualityData.mock(
        locationName,
        latitude,
        longitude,
        daysBack,
      );
    }
  }

  // Get air quality forecast with weather integration
  Future<AirQualityForecast> getDetailedForecast(
    double latitude,
    double longitude,
    String locationName,
  ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl${AppConstants.forecastUrl}?key=$_apiKey',
      );

      final requestBody = {
        'universalAqi': true,
        'location': {'latitude': latitude, 'longitude': longitude},
        'period': {
          'startTime': DateTime.now().toIso8601String(),
          'endTime': DateTime.now()
              .add(const Duration(days: 3))
              .toIso8601String(),
        },
        'extraComputations': [
          'POLLUTANT_CONCENTRATION',
          'LOCAL_AQI',
          'HEALTH_RECOMMENDATIONS',
          'DOMINANT_POLLUTANT',
        ],
        'pageSize': 72, // 3 days * 24 hours
        'languageCode': 'en',
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AirQualityForecast.fromGoogleAirQuality(data, locationName);
      } else {
        throw Exception(
          'Failed to fetch forecast data: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Return mock data if API fails
      return AirQualityForecast.mock(locationName, latitude, longitude);
    }
  }

  // Generate comprehensive health advisory
  HealthAdvisory generateHealthAdvisory(
    String locationName,
    int currentAQI,
    Map<String, double> pollutants,
  ) {
    return HealthAdvisory.fromAQI(locationName, currentAQI, pollutants);
  }

  // Get pollution source analysis (mock implementation)
  Future<Map<String, dynamic>> getPollutionSourceAnalysis(
    double latitude,
    double longitude,
  ) async {
    // This would integrate with satellite data, traffic data, and industrial data
    // For now, return mock analysis
    return {
      'primarySources': [
        {'type': 'Vehicle Traffic', 'contribution': 45.0, 'severity': 'High'},
        {'type': 'Industrial', 'contribution': 30.0, 'severity': 'Medium'},
        {'type': 'Construction', 'contribution': 15.0, 'severity': 'Low'},
        {'type': 'Natural', 'contribution': 10.0, 'severity': 'Low'},
      ],
      'nearbyIndustries': [
        {'name': 'Power Plant', 'distance': 2.5, 'impact': 'High'},
        {'name': 'Manufacturing Unit', 'distance': 1.8, 'impact': 'Medium'},
      ],
      'trafficDensity': 'High',
      'windDirection': 'Northwest',
      'windSpeed': 3.2,
      'recommendations': [
        'Major pollution from vehicle traffic in the area',
        'Industrial emissions contributing significantly',
        'Wind patterns dispersing pollution southward',
      ],
    };
  }

  // Get satellite imagery data (mock implementation)
  Future<List<Map<String, dynamic>>> getSatelliteImagery(
    double latitude,
    double longitude,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // This would integrate with satellite imagery APIs (like NASA, ESA, or commercial providers)
    final images = <Map<String, dynamic>>[];
    final days = endDate.difference(startDate).inDays;

    for (int i = 0; i <= days; i += 7) {
      // Weekly intervals
      final date = startDate.add(Duration(days: i));
      images.add({
        'date': date.toIso8601String(),
        'imageUrl':
            'https://example.com/satellite/${date.millisecondsSinceEpoch}.jpg',
        'analysisData': {
          'no2Levels': 50 + (i % 100),
          'pm25Levels': 30 + (i % 80),
          'aerosolOpticalDepth': 0.2 + (i % 5) * 0.1,
          'cloudCover': 20 + (i % 60),
        },
        'description': 'Satellite data showing pollution levels',
      });
    }

    return images;
  }

  // Check for pollution alerts and emergency conditions
  Future<List<Map<String, dynamic>>> checkPollutionAlerts(
    String locationName,
    int currentAQI,
  ) async {
    final alerts = <Map<String, dynamic>>[];

    if (currentAQI > 200) {
      alerts.add({
        'type': 'emergency',
        'title': 'Air Quality Emergency',
        'message': 'Hazardous air quality detected in $locationName',
        'severity': 'critical',
        'timestamp': DateTime.now().toIso8601String(),
        'actions': [
          'Stay indoors immediately',
          'Close all windows and doors',
          'Use air purifier if available',
          'Avoid outdoor activities',
        ],
      });
    } else if (currentAQI > 150) {
      alerts.add({
        'type': 'warning',
        'title': 'Air Quality Warning',
        'message': 'Unhealthy air quality in $locationName',
        'severity': 'high',
        'timestamp': DateTime.now().toIso8601String(),
        'actions': [
          'Limit outdoor activities',
          'Wear N95 mask if going outside',
          'Keep windows closed',
        ],
      });
    } else if (currentAQI > 100) {
      alerts.add({
        'type': 'advisory',
        'title': 'Air Quality Advisory',
        'message': 'Moderate air quality in $locationName',
        'severity': 'medium',
        'timestamp': DateTime.now().toIso8601String(),
        'actions': [
          'Sensitive individuals should limit prolonged outdoor activities',
          'Consider indoor exercise alternatives',
        ],
      });
    }

    return alerts;
  }

  // Get health advisory based on current air quality
  Future<HealthAdvisory> getHealthAdvisory(
    double latitude,
    double longitude,
    int currentAQI,
  ) async {
    try {
      // Get location name (in a real app, this might use reverse geocoding)
      String locationName = 'Current Location';

      // Mock pollutant data based on AQI
      Map<String, double> pollutants = {
        'PM2.5': currentAQI * 0.6,
        'PM10': currentAQI * 0.8,
        'NO2': currentAQI * 0.4,
        'O3': currentAQI * 0.5,
        'SO2': currentAQI * 0.2,
        'CO': currentAQI * 0.3,
      };

      return HealthAdvisory.fromAQI(locationName, currentAQI, pollutants);
    } catch (e) {
      // Return a basic advisory if there's an error
      Map<String, double> basicPollutants = {
        'PM2.5': currentAQI * 0.6,
        'PM10': currentAQI * 0.8,
        'NO2': currentAQI * 0.4,
        'O3': currentAQI * 0.5,
        'SO2': currentAQI * 0.2,
        'CO': currentAQI * 0.3,
      };
      return HealthAdvisory.fromAQI(
        'Unknown Location',
        currentAQI,
        basicPollutants,
      );
    }
  }

  // Get air quality trends analysis
  Map<String, dynamic> analyzeTrends(HistoricalAirQualityData historicalData) {
    if (historicalData.dataPoints.isEmpty) {
      return {'trend': 'no_data', 'analysis': 'Insufficient data for analysis'};
    }

    final points = historicalData.dataPoints;
    final recentPoints = points.sublist((points.length * 0.7).round());
    final earlierPoints = points.sublist(0, (points.length * 0.3).round());

    final recentAvgAQI =
        recentPoints.map((p) => p.aqi).reduce((a, b) => a + b) /
        recentPoints.length;
    final earlierAvgAQI =
        earlierPoints.map((p) => p.aqi).reduce((a, b) => a + b) /
        earlierPoints.length;

    final trendDirection = recentAvgAQI > earlierAvgAQI
        ? 'worsening'
        : 'improving';
    final changeMagnitude = (recentAvgAQI - earlierAvgAQI).abs();

    String trendSeverity;
    if (changeMagnitude < 10) {
      trendSeverity = 'stable';
    } else if (changeMagnitude < 25) {
      trendSeverity = 'moderate';
    } else {
      trendSeverity = 'significant';
    }

    return {
      'trend': trendDirection,
      'severity': trendSeverity,
      'changeMagnitude': changeMagnitude.round(),
      'currentAverage': recentAvgAQI.round(),
      'previousAverage': earlierAvgAQI.round(),
      'analysis': _generateTrendAnalysis(
        trendDirection,
        trendSeverity,
        changeMagnitude,
      ),
      'recommendations': _generateTrendRecommendations(
        trendDirection,
        trendSeverity,
      ),
    };
  }

  String _generateTrendAnalysis(
    String direction,
    String severity,
    double magnitude,
  ) {
    if (severity == 'stable') {
      return 'Air quality has remained relatively stable over the analyzed period.';
    }

    final directionText = direction == 'improving'
        ? 'improved'
        : 'deteriorated';
    final severityText = severity == 'moderate'
        ? 'moderately'
        : 'significantly';

    return 'Air quality has $severityText $directionText by ${magnitude.round()} AQI points.';
  }

  List<String> _generateTrendRecommendations(
    String direction,
    String severity,
  ) {
    if (direction == 'worsening') {
      return [
        'Monitor air quality more frequently',
        'Consider relocating sensitive activities indoors',
        'Check local pollution sources and policies',
        'Prepare emergency air quality supplies',
      ];
    } else if (direction == 'improving') {
      return [
        'Continue monitoring for sustained improvement',
        'Gradually increase outdoor activities',
        'Support local clean air initiatives',
      ];
    } else {
      return ['Maintain current precautions', 'Continue regular monitoring'];
    }
  }
}
