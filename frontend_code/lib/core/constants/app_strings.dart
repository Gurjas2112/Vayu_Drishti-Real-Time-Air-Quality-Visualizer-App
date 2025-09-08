class AppStrings {
  // App Identity
  static const String appName = 'VayuDrishti';
  static const String tagline = 'Swasth Jeevan ki Shrishti!';
  static const String subtitle = 'ISRO Satellite Air Quality Monitor';

  // Splash Screen
  static const String initializingConnection =
      'Initializing satellite connection...';
  static const String loadingData = 'Loading air quality data...';
  static const String connectingToServers = 'Connecting to ISRO servers...';

  // Authentication
  static const String login = 'Login';
  static const String signup = 'Sign Up';
  static const String forgotPassword = 'Forgot Password?';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String createAccount = 'Create Account';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String signInHere = 'Sign in here';
  static const String signUpHere = 'Sign up here';
  static const String logout = 'Logout';

  // Home Screen
  static const String welcome = 'Welcome';
  static const String currentAQI = 'Current AQI';
  static const String airQualityIndex = 'Air Quality Index';
  static const String location = 'Location';
  static const String lastUpdated = 'Last Updated';
  static const String refresh = 'Refresh';

  // Navigation
  static const String home = 'Home';
  static const String map = 'Map';
  static const String forecast = 'Forecast';
  static const String profile = 'Profile';

  // AQI Levels
  static const String good = 'Good';
  static const String fair = 'Fair';
  static const String moderate = 'Moderate';
  static const String poor = 'Poor';
  static const String veryPoor = 'Very Poor';
  static const String hazardous = 'Hazardous';

  // Pollutants
  static const String pm25 = 'PM2.5';
  static const String pm10 = 'PM10';
  static const String co = 'CO';
  static const String no2 = 'NO2';
  static const String o3 = 'O3';
  static const String so2 = 'SO2';

  // Units
  static const String ugm3 = 'μg/m³';
  static const String ppm = 'ppm';

  // Forecast
  static const String hourlyForecast = '24-Hour Forecast';
  static const String dailyForecast = '7-Day Forecast';
  static const String forecast24h = '24H';
  static const String forecast72h = '72H';
  static const String forecastWeekly = 'Weekly';

  // Health Advisory
  static const String healthAdvisory = 'Health Advisory';
  static const String recommendations = 'Recommendations';

  // Health Messages
  static const String healthGood =
      'Air quality is considered satisfactory. Ideal for all outdoor activities.';
  static const String healthFair =
      'Air quality is acceptable. Unusually sensitive people should consider limiting prolonged outdoor exertion.';
  static const String healthModerate =
      'Members of sensitive groups may experience health effects. Limit prolonged outdoor exertion.';
  static const String healthPoor =
      'Health warnings of emergency conditions. Everyone may experience more serious health effects.';
  static const String healthVeryPoor =
      'Health alert: everyone may experience serious health effects. Avoid outdoor activities.';
  static const String healthHazardous =
      'Emergency conditions: the entire population is at risk. Stay indoors and avoid all physical activities.';

  // Map
  static const String satelliteView = 'Satellite';
  static const String normalView = 'Normal';
  static const String aqiHeatmap = 'AQI Heatmap';
  static const String currentLocation = 'Current Location';

  // Profile
  static const String editProfile = 'Edit Profile';
  static const String settings = 'Settings';
  static const String notifications = 'Notifications';
  static const String about = 'About';
  static const String privacyPolicy = 'Privacy Policy';
  static const String termsOfService = 'Terms of Service';
  static const String contactUs = 'Contact Us';
  static const String version = 'Version';

  // Error Messages
  static const String errorGeneral = 'Something went wrong. Please try again.';
  static const String errorNetwork =
      'Network error. Please check your connection.';
  static const String errorLocation =
      'Unable to get your location. Please enable location services.';
  static const String errorAuth = 'Authentication failed. Please try again.';
  static const String errorInvalidEmail = 'Please enter a valid email address.';
  static const String errorPasswordTooShort =
      'Password must be at least 6 characters.';
  static const String errorPasswordMismatch = 'Passwords do not match.';
  static const String errorEmptyField = 'This field cannot be empty.';

  // Success Messages
  static const String successLogin = 'Login successful!';
  static const String successSignup = 'Account created successfully!';
  static const String successLogout = 'Logged out successfully!';
  static const String successDataUpdated = 'Data updated successfully!';

  // Loading Messages
  static const String loading = 'Loading...';
  static const String loadingAQIData = 'Loading air quality data...';
  static const String loadingLocation = 'Getting your location...';
  static const String loadingMap = 'Loading map...';
  static const String loadingForecast = 'Loading forecast...';

  // Buttons
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String retry = 'Retry';
  static const String save = 'Save';
  static const String update = 'Update';
  static const String delete = 'Delete';
  static const String share = 'Share';
  static const String close = 'Close';

  // About
  static const String aboutDescription =
      'VayuDrishti is an advanced air quality monitoring application powered by ISRO satellite data. Monitor real-time air pollution levels, get health recommendations, and stay informed about the air you breathe.';
  static const String developedBy = 'Developed with ❤️ for cleaner air';
  static const String poweredBy = 'Powered by ISRO Satellite Technology';
}
