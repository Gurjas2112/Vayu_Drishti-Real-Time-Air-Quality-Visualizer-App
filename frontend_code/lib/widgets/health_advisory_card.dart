import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vayudrishti/core/constants/app_colors.dart';
import 'package:vayudrishti/providers/air_quality_provider.dart';

class HealthAdvisoryCard extends StatelessWidget {
  final int aqi;
  final String category;

  const HealthAdvisoryCard({
    super.key,
    required this.aqi,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final aqiColor = AppColors.getAQIColor(aqi);
    final aqiBackgroundColor = AppColors.getAQIBackgroundColor(aqi);

    return Consumer<AirQualityProvider>(
      builder: (context, airQualityProvider, child) {
        final healthAdvisory = airQualityProvider.getHealthAdvisory(aqi);
        final recommendations = airQualityProvider.getRecommendations(aqi);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: aqiColor.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: aqiBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getHealthIcon(aqi), color: aqiColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Health Advisory',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'For $category air quality',
                          style: TextStyle(
                            fontSize: 12,
                            color: aqiColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Health Advisory Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: aqiBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  healthAdvisory,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Recommendations
              const Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              ...recommendations.map(
                (recommendation) =>
                    _buildRecommendationItem(recommendation, aqiColor),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecommendationItem(String recommendation, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getHealthIcon(int aqi) {
    if (aqi <= 50) return Icons.sentiment_very_satisfied;
    if (aqi <= 100) return Icons.sentiment_satisfied;
    if (aqi <= 150) return Icons.sentiment_neutral;
    if (aqi <= 200) return Icons.sentiment_dissatisfied;
    if (aqi <= 300) return Icons.sentiment_very_dissatisfied;
    return Icons.dangerous;
  }
}
