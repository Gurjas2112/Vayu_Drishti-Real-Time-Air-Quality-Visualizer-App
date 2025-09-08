import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Purple to Indigo gradient
  static const Color primaryColor = Color(0xFF6B46C1); // Purple-600
  static const Color secondaryColor = Color(0xFF4F46E5); // Indigo-600
  static const Color accentColor = Color(0xFF7C3AED); // Violet-600

  // Gradient colors
  static const Color gradientStart = Color(0xFF1E1B4B); // Dark purple
  static const Color gradientEnd = Color(0xFF312E81); // Indigo-900

  // AQI Status colors
  static const Color aqiGood = Color(0xFF10B981); // Green-500
  static const Color aqiFair = Color(0xFFF59E0B); // Amber-500
  static const Color aqiModerate = Color(0xFFEF4444); // Red-500
  static const Color aqiPoor = Color(0xFF991B1B); // Red-800
  static const Color aqiVeryPoor = Color(0xFF7C2D12); // Orange-900
  static const Color aqiHazardous = Color(0xFF450A0A); // Red-950

  // Text colors
  static const Color textPrimary = Color(0xFF111827); // Gray-900
  static const Color textSecondary = Color(0xFF6B7280); // Gray-500
  static const Color textLight = Color(0xFFFFFFFF); // White

  // Background colors
  static const Color backgroundLight = Color(0xFFFFFFFF); // White
  static const Color backgroundDark = Color(0xFF1F2937); // Gray-800
  static const Color surfaceColor = Color(0xFFF9FAFB); // Gray-50
  static const Color cardColor = Color(0xFFFFFFFF); // White

  // Border colors
  static const Color borderColor = Color(0xFFE5E7EB); // Gray-200
  static const Color dividerColor = Color(0xFFD1D5DB); // Gray-300

  // Status colors
  static const Color successColor = Color(0xFF10B981); // Green-500
  static const Color warningColor = Color(0xFFF59E0B); // Amber-500
  static const Color errorColor = Color(0xFFEF4444); // Red-500
  static const Color infoColor = Color(0xFF3B82F6); // Blue-500

  // Transparent colors
  static const Color transparent = Colors.transparent;
  static const Color shadow = Color(0x1A000000); // Black with 10% opacity

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
  );

  // AQI color mapping
  static Color getAQIColor(int aqi) {
    if (aqi <= 50) return aqiGood;
    if (aqi <= 100) return aqiFair;
    if (aqi <= 150) return aqiModerate;
    if (aqi <= 200) return aqiPoor;
    if (aqi <= 300) return aqiVeryPoor;
    return aqiHazardous;
  }

  // AQI background color (lighter version)
  static Color getAQIBackgroundColor(int aqi) {
    if (aqi <= 50) return aqiGood.withValues(alpha: 0.1);
    if (aqi <= 100) return aqiFair.withValues(alpha: 0.1);
    if (aqi <= 150) return aqiModerate.withValues(alpha: 0.1);
    if (aqi <= 200) return aqiPoor.withValues(alpha: 0.1);
    if (aqi <= 300) return aqiVeryPoor.withValues(alpha: 0.1);
    return aqiHazardous.withValues(alpha: 0.1);
  }
}
