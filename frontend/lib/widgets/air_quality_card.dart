import 'package:flutter/material.dart';
import '../core/models/air_quality_data.dart';

class AirQualityCard extends StatelessWidget {
  final AirQualityData airQuality;

  const AirQualityCard({super.key, required this.airQuality});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: _getGradientForAQI(airQuality.aqi),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getColorForAQI(airQuality.aqi).withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Air Quality Index',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${airQuality.aqi}',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                    ),
                  ),
                  Text(
                    airQuality.category,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconForAQI(airQuality.aqi),
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    airQuality.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForAQI(int aqi) {
    if (aqi <= 50) return const Color(0xFF10B981); // Green
    if (aqi <= 100) return const Color(0xFFF59E0B); // Yellow
    if (aqi <= 150) return const Color(0xFFEF4444); // Red
    if (aqi <= 200) return const Color(0xFF8B5CF6); // Purple
    if (aqi <= 300) return const Color(0xFF991B1B); // Dark red
    return const Color(0xFF450A0A); // Very dark red
  }

  LinearGradient _getGradientForAQI(int aqi) {
    final baseColor = _getColorForAQI(aqi);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [baseColor, baseColor.withValues(alpha: 0.8)],
    );
  }

  IconData _getIconForAQI(int aqi) {
    if (aqi <= 50) return Icons.mood; // Good
    if (aqi <= 100) return Icons.sentiment_satisfied; // Fair
    if (aqi <= 150) return Icons.sentiment_neutral; // Moderate
    if (aqi <= 200) return Icons.sentiment_dissatisfied; // Poor
    if (aqi <= 300) return Icons.sentiment_very_dissatisfied; // Very poor
    return Icons.dangerous; // Hazardous
  }
}
