import 'package:flutter/material.dart';
import 'package:vayudrishti/core/constants/app_colors.dart';

class PollutantCard extends StatefulWidget {
  final String name;
  final double value;
  final String unit;

  const PollutantCard({
    super.key,
    required this.name,
    required this.value,
    required this.unit,
  });

  @override
  State<PollutantCard> createState() => _PollutantCardState();
}

class _PollutantCardState extends State<PollutantCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    final progress = _getProgressValue(widget.name, widget.value);
    _progressAnimation = Tween<double>(begin: 0.0, end: progress).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _getProgressValue(String pollutant, double value) {
    double maxValue;
    switch (pollutant) {
      case 'PM2.5':
        maxValue = 150.0;
        break;
      case 'PM10':
        maxValue = 354.0;
        break;
      case 'O3':
        maxValue = 240.0;
        break;
      case 'NO2':
        maxValue = 800.0;
        break;
      case 'SO2':
        maxValue = 500.0;
        break;
      case 'CO':
        maxValue = 15.0;
        break;
      default:
        maxValue = 100.0;
    }
    return (value / maxValue).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final pollutantColor = _getPollutantColor(widget.name, widget.value);
    final level = _getPollutantLevel(widget.name, widget.value);
    final healthIcon = _getHealthIcon(widget.name, widget.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pollutantColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header with icon and name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: pollutantColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getPollutantIcon(widget.name),
                  color: pollutantColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Health indicator emoji
              Text(healthIcon, style: const TextStyle(fontSize: 16)),
            ],
          ),

          const SizedBox(height: 12),

          // Enhanced Value Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: pollutantColor,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  widget.unit,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Animated Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    level,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: pollutantColor,
                    ),
                  ),
                  Text(
                    '${(_getProgressValue(widget.name, widget.value) * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Stack(
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return SizedBox(
                        height: 6,
                        width: double.infinity,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: pollutantColor,
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: pollutantColor.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Enhanced Level indicator with trend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pollutantColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getTrendIcon(), size: 10, color: pollutantColor),
                    const SizedBox(width: 4),
                    Text(
                      level,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: pollutantColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Health status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getHealthStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getHealthStatus(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: _getHealthStatusColor(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getHealthIcon(String pollutant, double value) {
    final level = _getPollutantLevel(pollutant, value);
    switch (level) {
      case 'Good':
        return '😊';
      case 'Fair':
        return '🙂';
      case 'Moderate':
        return '😐';
      case 'Poor':
        return '😷';
      case 'Very Poor':
        return '☠️';
      default:
        return '❓';
    }
  }

  IconData _getTrendIcon() {
    // For now, showing stable trend. In real app, this would be calculated from historical data
    return Icons.trending_flat;
  }

  String _getHealthStatus() {
    final level = _getPollutantLevel(widget.name, widget.value);
    switch (level) {
      case 'Good':
        return 'Safe';
      case 'Fair':
        return 'OK';
      case 'Moderate':
        return 'Caution';
      case 'Poor':
        return 'Unhealthy';
      case 'Very Poor':
        return 'Dangerous';
      default:
        return 'Unknown';
    }
  }

  Color _getHealthStatusColor() {
    final level = _getPollutantLevel(widget.name, widget.value);
    switch (level) {
      case 'Good':
        return AppColors.successColor;
      case 'Fair':
        return AppColors.infoColor;
      case 'Moderate':
        return AppColors.warningColor;
      case 'Poor':
      case 'Very Poor':
        return AppColors.errorColor;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getPollutantColor(String pollutant, double value) {
    switch (pollutant) {
      case 'PM2.5':
        if (value <= 12) return AppColors.aqiGood;
        if (value <= 35) return AppColors.aqiFair;
        if (value <= 55) return AppColors.aqiModerate;
        if (value <= 150) return AppColors.aqiPoor;
        return AppColors.aqiVeryPoor;

      case 'PM10':
        if (value <= 54) return AppColors.aqiGood;
        if (value <= 154) return AppColors.aqiFair;
        if (value <= 254) return AppColors.aqiModerate;
        if (value <= 354) return AppColors.aqiPoor;
        return AppColors.aqiVeryPoor;

      case 'O3':
        if (value <= 108) return AppColors.aqiGood;
        if (value <= 140) return AppColors.aqiFair;
        if (value <= 180) return AppColors.aqiModerate;
        if (value <= 240) return AppColors.aqiPoor;
        return AppColors.aqiVeryPoor;

      case 'NO2':
        if (value <= 100) return AppColors.aqiGood;
        if (value <= 200) return AppColors.aqiFair;
        if (value <= 400) return AppColors.aqiModerate;
        if (value <= 800) return AppColors.aqiPoor;
        return AppColors.aqiVeryPoor;

      case 'SO2':
        if (value <= 100) return AppColors.aqiGood;
        if (value <= 200) return AppColors.aqiFair;
        if (value <= 350) return AppColors.aqiModerate;
        if (value <= 500) return AppColors.aqiPoor;
        return AppColors.aqiVeryPoor;

      case 'CO':
        if (value <= 4) return AppColors.aqiGood;
        if (value <= 9) return AppColors.aqiFair;
        if (value <= 12) return AppColors.aqiModerate;
        if (value <= 15) return AppColors.aqiPoor;
        return AppColors.aqiVeryPoor;

      default:
        return AppColors.textSecondary;
    }
  }

  String _getPollutantLevel(String pollutant, double value) {
    switch (pollutant) {
      case 'PM2.5':
        if (value <= 12) return 'Good';
        if (value <= 35) return 'Fair';
        if (value <= 55) return 'Moderate';
        if (value <= 150) return 'Poor';
        return 'Very Poor';

      case 'PM10':
        if (value <= 54) return 'Good';
        if (value <= 154) return 'Fair';
        if (value <= 254) return 'Moderate';
        if (value <= 354) return 'Poor';
        return 'Very Poor';

      case 'O3':
        if (value <= 108) return 'Good';
        if (value <= 140) return 'Fair';
        if (value <= 180) return 'Moderate';
        if (value <= 240) return 'Poor';
        return 'Very Poor';

      case 'NO2':
        if (value <= 100) return 'Good';
        if (value <= 200) return 'Fair';
        if (value <= 400) return 'Moderate';
        if (value <= 800) return 'Poor';
        return 'Very Poor';

      case 'SO2':
        if (value <= 100) return 'Good';
        if (value <= 200) return 'Fair';
        if (value <= 350) return 'Moderate';
        if (value <= 500) return 'Poor';
        return 'Very Poor';

      case 'CO':
        if (value <= 4) return 'Good';
        if (value <= 9) return 'Fair';
        if (value <= 12) return 'Moderate';
        if (value <= 15) return 'Poor';
        return 'Very Poor';

      default:
        return 'Unknown';
    }
  }

  IconData _getPollutantIcon(String pollutant) {
    switch (pollutant) {
      case 'PM2.5':
      case 'PM10':
        return Icons.blur_on;
      case 'O3':
        return Icons.wb_sunny;
      case 'NO2':
        return Icons.local_gas_station;
      case 'SO2':
        return Icons.factory;
      case 'CO':
        return Icons.smoke_free;
      default:
        return Icons.air;
    }
  }
}
