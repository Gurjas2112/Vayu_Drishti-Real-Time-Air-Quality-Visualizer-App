class AppConstants {
  // App Info
  static const String appName = 'VayuDrishti';
  static const String appTagline = 'Swasth Jeevan ki Shrishti!';
  static const String appSubtitle = 'ISRO Satellite Air Quality Monitor';
  static const String appVersion = 'v1.0.0';

  // API Keys & URLs
  static const String googleApiKey = 'AIzaSyBaYwd_u4y5VyL0ZYMOFYqS2eMYMPMwWKQ';
  static const String googleAirQualityBaseUrl =
      'https://airquality.googleapis.com/v1';
  static const String currentConditionsUrl = '/currentConditions:lookup';
  static const String forecastUrl = '/forecast:lookup';

  // Legacy OpenWeatherMap URLs (for fallback)
  static const String openWeatherMapBaseUrl =
      'https://api.openweathermap.org/data/2.5';
  static const String airPollutionUrl = '/air_pollution';
  static const String weatherUrl = '/weather';

  // Default location (Delhi)
  static const double defaultLatitude = 28.6139;
  static const double defaultLongitude = 77.2090;
  static const String defaultCityName = 'Delhi';

  // AQI Categories
  static const Map<String, Map<String, dynamic>> aqiCategories = {
    'good': {
      'range': [0, 50],
      'message': 'Air quality is good. Perfect for outdoor activities!',
      'recommendations': [
        'Enjoy outdoor activities',
        'Open windows for fresh air',
        'Perfect time for exercise',
      ],
    },
    'fair': {
      'range': [51, 100],
      'message': 'Air quality is fair. Moderate outdoor activities are fine.',
      'recommendations': [
        'Outdoor activities are acceptable',
        'Sensitive individuals should limit prolonged outdoor exertion',
        'Good time for light exercise',
      ],
    },
    'moderate': {
      'range': [101, 150],
      'message':
          'Air quality is moderate. Limit outdoor activities for sensitive groups.',
      'recommendations': [
        'Limit prolonged outdoor activities',
        'Children and elderly should be cautious',
        'Consider wearing a mask outdoors',
      ],
    },
    'poor': {
      'range': [151, 200],
      'message': 'Air quality is poor. Avoid outdoor activities.',
      'recommendations': [
        'Avoid outdoor activities',
        'Wear N95 mask when going out',
        'Keep windows closed',
        'Use air purifier indoors',
      ],
    },
    'very_poor': {
      'range': [201, 300],
      'message': 'Air quality is very poor. Stay indoors.',
      'recommendations': [
        'Stay indoors as much as possible',
        'Avoid all outdoor physical activities',
        'Wear N95 mask if you must go out',
        'Use air purifier and keep windows closed',
      ],
    },
    'hazardous': {
      'range': [301, 500],
      'message': 'Air quality is hazardous. Emergency conditions!',
      'recommendations': [
        'Stay indoors at all times',
        'Avoid all outdoor activities',
        'Emergency conditions for all',
        'Use air purifier and seal windows',
        'Consider leaving the area',
      ],
    },
  };

  // Pollutant Info
  static const Map<String, Map<String, dynamic>> pollutantInfo = {
    'pm2_5': {
      'name': 'PM2.5',
      'unit': 'μg/m³',
      'description': 'Fine particulate matter',
      'safe_limit': 15.0,
    },
    'pm10': {
      'name': 'PM10',
      'unit': 'μg/m³',
      'description': 'Coarse particulate matter',
      'safe_limit': 45.0,
    },
    'o3': {
      'name': 'O₃',
      'unit': 'μg/m³',
      'description': 'Ozone',
      'safe_limit': 100.0,
    },
    'no2': {
      'name': 'NO₂',
      'unit': 'μg/m³',
      'description': 'Nitrogen dioxide',
      'safe_limit': 40.0,
    },
    'so2': {
      'name': 'SO₂',
      'unit': 'μg/m³',
      'description': 'Sulfur dioxide',
      'safe_limit': 20.0,
    },
    'co': {
      'name': 'CO',
      'unit': 'mg/m³',
      'description': 'Carbon monoxide',
      'safe_limit': 10.0,
    },
  };

  // Animation durations
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Padding & Margins
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;

  // Border radius
  static const double defaultBorderRadius = 12.0;
  static const double largeBorderRadius = 16.0;
  static const double extraLargeBorderRadius = 24.0;

  // SharedPreferences Keys
  static const String userTokenKey = 'user_token';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';
  static const String lastLocationKey = 'last_location';
  static const String notificationEnabledKey = 'notification_enabled';
  static const String themeKey = 'theme_mode';

  // Route names
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String homeRoute = '/home';
  static const String mapRoute = '/map';
  static const String forecastRoute = '/forecast';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';

  // Error messages
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String locationErrorMessage =
      'Unable to get location. Please enable location services.';
  static const String authErrorMessage =
      'Authentication failed. Please try again.';
  static const String genericErrorMessage =
      'Something went wrong. Please try again.';

  // Success messages
  static const String loginSuccessMessage = 'Login successful!';
  static const String signupSuccessMessage = 'Account created successfully!';
  static const String locationUpdateMessage = 'Location updated successfully!';
}
