import 'package:flutter/material.dart';
import 'package:vayudrishti/screens/splash/splash_screen.dart';
import 'package:vayudrishti/screens/auth/login_screen.dart';
import 'package:vayudrishti/screens/auth/signup_screen.dart';
import 'package:vayudrishti/screens/home/main_navigation_screen.dart';
import 'package:vayudrishti/screens/home/home_screen.dart';
import 'package:vayudrishti/screens/map/map_screen.dart';
import 'package:vayudrishti/screens/forecast/forecast_screen.dart';
import 'package:vayudrishti/screens/profile/profile_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String mainNavigation = '/main';
  static const String home = '/home';
  static const String map = '/map';
  static const String forecast = '/forecast';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    signup: (context) => const SignupScreen(),
    mainNavigation: (context) => const MainNavigationScreen(),
    home: (context) => const HomeScreen(),
    map: (context) => const MapScreen(),
    forecast: (context) => const ForecastScreen(),
    profile: (context) => const ProfileScreen(),
  };
}
