import 'dart:io';

class SecureConfig {
  /// Get Google API key for air quality data
  static String? get googleApiKey {
    return Platform.environment['GOOGLE_API_KEY'] ??
        'AIzaSyBaYwd_u4y5VyL0ZYMOFYqS2eMYMPMwWKQ'; // Your provided key
  }

  /// Get mock configuration status
  static bool get isMockMode => true;

  /// Mock user credentials for testing
  static Map<String, String> get mockCredentials => {
    'test@example.com': 'password123',
    'admin@vayudrishti.com': 'admin123',
  };
}
