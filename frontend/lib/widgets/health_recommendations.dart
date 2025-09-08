import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/air_quality_provider.dart';

class HealthRecommendations extends StatelessWidget {
  const HealthRecommendations({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AirQualityProvider>(
      builder: (context, provider, child) {
        final recommendations = provider.getHealthRecommendations();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Recommendations',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...recommendations.map(
              (recommendation) => _buildRecommendationCard(
                context,
                recommendation,
                _getIconForRecommendation(recommendation),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    String text,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardLinearGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForRecommendation(String recommendation) {
    final lowerCase = recommendation.toLowerCase();

    if (lowerCase.contains('mask')) return Icons.masks;
    if (lowerCase.contains('window')) return Icons.window;
    if (lowerCase.contains('exercise') || lowerCase.contains('outdoor')) {
      return Icons.directions_run;
    }
    if (lowerCase.contains('indoor') || lowerCase.contains('stay')) {
      return Icons.home;
    }
    if (lowerCase.contains('purifier')) return Icons.air;
    if (lowerCase.contains('avoid')) return Icons.warning;

    return Icons.health_and_safety;
  }
}
