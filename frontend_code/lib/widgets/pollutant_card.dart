import 'package:flutter/material.dart';
import 'package:vayudrishti/core/constants/app_colors.dart';

class PollutantCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final pollutantColor = _getPollutantColor(name, value);
    final level = _getPollutantLevel(name, value);

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
          // Header with icon and name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: pollutantColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getPollutantIcon(name),
                  color: pollutantColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Value
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value.toStringAsFixed(1),
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
                  unit,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Level indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: pollutantColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              level,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: pollutantColor,
              ),
            ),
          ),
        ],
      ),
    );
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
