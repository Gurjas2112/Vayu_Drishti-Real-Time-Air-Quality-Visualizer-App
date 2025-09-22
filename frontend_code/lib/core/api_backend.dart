import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';

class BackendApiClient {
  final Dio _dio;
  final String baseUrl;

  BackendApiClient({String? baseUrl})
    : baseUrl = baseUrl ?? AppConfig.backendBaseUrl,
      _dio = Dio(BaseOptions(baseUrl: baseUrl ?? AppConfig.backendBaseUrl));

  static final BackendApiClient instance = BackendApiClient();

  Future<String?> _getAccessToken() async {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.accessToken;
  }

  Future<Response<dynamic>> getMe() async {
    final token = await _getAccessToken();
    if (token == null) {
      throw StateError('Not authenticated');
    }
    return _dio.get(
      '/api/user/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response<dynamic>> registerFcmToken({
    required String token,
    required String platform,
  }) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      throw StateError('Not authenticated');
    }
    return _dio.post(
      '/api/user/fcm-token',
      data: jsonEncode({'token': token, 'platform': platform}),
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ),
    );
  }
}
