import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'config.dart';

class AqiApiClient {
  final Dio _dio;
  final Logger _logger = Logger();

  AqiApiClient({String? baseUrl})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? AppConfig.backendBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    // Add interceptors for logging and error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.i('API Request: ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.i(
            'API Response: ${response.statusCode} ${response.requestOptions.uri}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          _logger.e('API Error: ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  static final AqiApiClient instance = AqiApiClient();

  Future<Response<dynamic>> getLatestByLocation({
    required double lat,
    required double lon,
    int hours = 24,
  }) async {
    try {
      return await _dio.get(
        '/api/aqi/latest',
        queryParameters: {'lat': lat, 'lon': lon, 'hours': hours},
      );
    } catch (e) {
      _logger.e('Error getting latest AQI by location: $e');
      rethrow;
    }
  }

  Future<Response<dynamic>> getByStation(String stationId) async {
    try {
      return await _dio.get('/api/aqi/station/$stationId');
    } catch (e) {
      _logger.e('Error getting AQI by station: $e');
      rethrow;
    }
  }

  Future<Response<dynamic>> getHistorical({
    required String stationId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      return await _dio.get(
        '/api/aqi/historical',
        queryParameters: {
          'stationId': stationId,
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
      );
    } catch (e) {
      _logger.e('Error getting historical AQI: $e');
      rethrow;
    }
  }

  // Health check endpoint
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Health check failed: $e');
      return false;
    }
  }
}
