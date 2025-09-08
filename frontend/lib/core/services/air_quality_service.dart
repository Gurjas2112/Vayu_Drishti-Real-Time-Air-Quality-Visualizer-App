import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/air_quality_data.dart';
import '../models/forecast_data.dart';

class AirQualityService {
  static const String _baseUrl = AppConstants.googleAirQualityBaseUrl;
  static const String _apiKey = AppConstants.googleApiKey;

  // Get current air quality data using Google Air Quality API
  Future<AirQualityData> getCurrentAirQuality(
    double latitude,
    double longitude,
    String locationName,
  ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl${AppConstants.currentConditionsUrl}?key=$_apiKey',
      );

      final requestBody = {
        'universalAqi': true,
        'location': {'latitude': latitude, 'longitude': longitude},
        'extraComputations': [
          'HEALTH_RECOMMENDATIONS',
          'DOMINANT_POLLUTANT',
          'POLLUTANT_CONCENTRATION',
          'LOCAL_AQI',
          'POLLUTANT_ADDITIONAL_INFO',
        ],
        'languageCode': 'en',
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AirQualityData.fromGoogleAirQuality(data, locationName);
      } else {
        throw Exception(
          'Failed to fetch air quality data: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      // Return mock data if API fails
      return AirQualityData.mock(locationName, latitude, longitude);
    }
  }

  // Get air quality forecast using Google Air Quality API
  Future<AirQualityForecast> getAirQualityForecast(
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
              .add(const Duration(days: 5))
              .toIso8601String(),
        },
        'extraComputations': [
          'POLLUTANT_CONCENTRATION',
          'LOCAL_AQI',
          'HEALTH_RECOMMENDATIONS',
        ],
        'pageSize': 24,
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
          'Failed to fetch forecast data: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      // Return mock data if API fails
      return AirQualityForecast.mock(locationName, latitude, longitude);
    }
  }

  // Get multiple locations air quality data for map
  Future<List<AirQualityData>> getMultipleLocationsAirQuality(
    List<Map<String, dynamic>> locations,
  ) async {
    final results = <AirQualityData>[];

    for (final location in locations) {
      try {
        final data = await getCurrentAirQuality(
          location['latitude'],
          location['longitude'],
          location['name'],
        );
        results.add(data);
      } catch (e) {
        // Continue with other locations if one fails
        // Failed to get air quality for ${location['name']}: $e
      }
    }

    return results;
  }

  // Get weather data using OpenWeatherMap as fallback (for additional context)
  Future<Map<String, dynamic>> getWeatherData(
    double latitude,
    double longitude,
  ) async {
    try {
      // Using OpenWeatherMap for weather data since Google doesn't provide weather API
      final url = Uri.parse(
        '${AppConstants.openWeatherMapBaseUrl}${AppConstants.weatherUrl}?lat=$latitude&lon=$longitude&appid=demo_key&units=metric',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch weather data: ${response.statusCode}');
      }
    } catch (e) {
      // Return mock weather data
      return {
        'main': {'temp': 25.0, 'humidity': 60, 'pressure': 1013},
        'weather': [
          {'main': 'Clear', 'description': 'clear sky', 'icon': '01d'},
        ],
        'wind': {'speed': 3.5, 'deg': 180},
        'visibility': 10000,
      };
    }
  }

  // Mock data for major Indian cities
  static List<Map<String, dynamic>> getMajorIndianCities() {
    return [
      {'name': 'Delhi', 'latitude': 28.6139, 'longitude': 77.2090},
      {'name': 'Mumbai', 'latitude': 19.0760, 'longitude': 72.8777},
      {'name': 'Bangalore', 'latitude': 12.9716, 'longitude': 77.5946},
      {'name': 'Chennai', 'latitude': 13.0827, 'longitude': 80.2707},
      {'name': 'Kolkata', 'latitude': 22.5726, 'longitude': 88.3639},
      {'name': 'Hyderabad', 'latitude': 17.3850, 'longitude': 78.4867},
      {'name': 'Pune', 'latitude': 18.5204, 'longitude': 73.8567},
      {'name': 'Ahmedabad', 'latitude': 23.0225, 'longitude': 72.5714},
      {'name': 'Jaipur', 'latitude': 26.9124, 'longitude': 75.7873},
      {'name': 'Lucknow', 'latitude': 26.8467, 'longitude': 80.9462},
    ];
  }
}
