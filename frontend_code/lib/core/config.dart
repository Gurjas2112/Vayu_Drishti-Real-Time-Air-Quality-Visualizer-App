class AppConfig {
  // Backend configuration
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  // Supabase configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '<YOUR_SUPABASE_URL>',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '<YOUR_SUPABASE_ANON_KEY>',
  );

  // Development settings
  static const bool isDevelopment =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'development') ==
      'development';

  // API settings
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Real-time settings
  static const Duration realtimeReconnectDelay = Duration(seconds: 5);
  static const int maxRealtimeReconnectAttempts = 3;

  // Logging settings
  static const bool enableDebugLogging = bool.fromEnvironment(
    'DEBUG_LOGGING',
    defaultValue: true,
  );

  // Cache settings
  static const Duration cacheTimeout = Duration(minutes: 5);
  static const int maxCacheSize = 100;

  // Location settings
  static const double locationAccuracy = 100.0; // meters
  static const Duration locationTimeout = Duration(seconds: 30);

  // AQI settings
  static const Duration aqiUpdateInterval = Duration(minutes: 15);
  static const Duration forecastUpdateInterval = Duration(hours: 1);

  // UI settings
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double defaultBorderRadius = 12.0;
  static const double defaultPadding = 16.0;

  // Helper methods
  static bool get isProduction => !isDevelopment;

  static String get environmentName =>
      isDevelopment ? 'Development' : 'Production';

  static Map<String, dynamic> get configSummary => {
    'environment': environmentName,
    'backendBaseUrl': backendBaseUrl,
    'supabaseConfigured': supabaseUrl != '<YOUR_SUPABASE_URL>',
    'debugLogging': enableDebugLogging,
  };
}
