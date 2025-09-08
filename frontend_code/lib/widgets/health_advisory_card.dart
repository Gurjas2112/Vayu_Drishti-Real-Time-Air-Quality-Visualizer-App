import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vayudrishti/core/constants/app_colors.dart';
import 'package:vayudrishti/providers/air_quality_provider.dart';

class HealthAdvisoryCard extends StatefulWidget {
  final int aqi;
  final String category;

  const HealthAdvisoryCard({
    super.key,
    required this.aqi,
    required this.category,
  });

  @override
  State<HealthAdvisoryCard> createState() => _HealthAdvisoryCardState();
}

class _HealthAdvisoryCardState extends State<HealthAdvisoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aqiColor = AppColors.getAQIColor(widget.aqi);
    final aqiBackgroundColor = AppColors.getAQIBackgroundColor(widget.aqi);

    return Consumer<AirQualityProvider>(
      builder: (context, airQualityProvider, child) {
        final healthAdvisory = airQualityProvider.getHealthAdvisory(widget.aqi);
        final recommendations = airQualityProvider.getRecommendations(
          widget.aqi,
        );

        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
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
                    // Enhanced Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: aqiBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getHealthIcon(widget.aqi),
                            color: aqiColor,
                            size: 24,
                          ),
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
                                'For ${widget.category} air quality',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: aqiColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Health emoji
                        Text(
                          _getHealthEmoji(widget.aqi),
                          style: const TextStyle(fontSize: 24),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Enhanced Health Advisory Text
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: aqiBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            healthAdvisory,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 12,
                                color: aqiColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'AQI: ${widget.aqi} - ${widget.category}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: aqiColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Activity-Specific Recommendations
                    const Text(
                      'Activity Guidelines',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Activity Icons Grid
                    _buildActivityGrid(widget.aqi),

                    const SizedBox(height: 16),

                    // General Recommendations
                    const Text(
                      'General Recommendations',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    ...recommendations.map(
                      (recommendation) =>
                          _buildRecommendationItem(recommendation, aqiColor),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActivityGrid(int aqi) {
    final activities = [
      {'icon': '🏃', 'name': 'Running', 'safe': aqi <= 50},
      {'icon': '🚴', 'name': 'Cycling', 'safe': aqi <= 100},
      {'icon': '🏫', 'name': 'School', 'safe': aqi <= 150},
      {'icon': '🏥', 'name': 'Hospital', 'safe': aqi <= 200},
      {'icon': '👶', 'name': 'Children', 'safe': aqi <= 100},
      {'icon': '👴', 'name': 'Elderly', 'safe': aqi <= 50},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        final isSafe = activity['safe'] as bool;
        final color = isSafe ? AppColors.successColor : AppColors.errorColor;

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                activity['icon'] as String,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                activity['name'] as String,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Icon(
                isSafe ? Icons.check_circle : Icons.cancel,
                size: 12,
                color: color,
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

  String _getHealthEmoji(int aqi) {
    if (aqi <= 50) return '😊';
    if (aqi <= 100) return '🙂';
    if (aqi <= 150) return '😐';
    if (aqi <= 200) return '😷';
    if (aqi <= 300) return '😰';
    return '☠️';
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
