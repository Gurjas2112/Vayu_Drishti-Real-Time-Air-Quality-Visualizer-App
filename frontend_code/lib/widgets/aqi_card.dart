import 'package:flutter/material.dart';
import 'package:vayudrishti/core/constants/app_colors.dart';
import 'package:vayudrishti/providers/air_quality_provider.dart';
import 'package:intl/intl.dart';

class AQICard extends StatelessWidget {
  final AirQualityData aqiData;

  const AQICard({super.key, required this.aqiData});

  @override
  Widget build(BuildContext context) {
    final aqiColor = AppColors.getAQIColor(aqiData.aqi);
    final aqiBackgroundColor = AppColors.getAQIBackgroundColor(aqiData.aqi);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            aqiBackgroundColor,
            aqiBackgroundColor.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: aqiColor.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: aqiColor.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Air Quality Index',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Last updated: ${DateFormat('HH:mm').format(aqiData.timestamp)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: aqiColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  aqiData.category,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Main AQI Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                aqiData.aqi.toString(),
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: aqiColor,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'AQI',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: aqiColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // AQI Scale
          _buildAQIScale(),

          const SizedBox(height: 20),

          // Primary Pollutants
          _buildPrimaryPollutants(),
        ],
      ),
    );
  }

  Widget _buildAQIScale() {
    return Column(
      children: [
        const Text(
          'AQI Scale',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              colors: [
                AppColors.aqiGood,
                AppColors.aqiFair,
                AppColors.aqiModerate,
                AppColors.aqiPoor,
                AppColors.aqiVeryPoor,
                AppColors.aqiHazardous,
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildScaleLabel('0', AppColors.aqiGood),
            _buildScaleLabel('50', AppColors.aqiFair),
            _buildScaleLabel('100', AppColors.aqiModerate),
            _buildScaleLabel('150', AppColors.aqiPoor),
            _buildScaleLabel('200', AppColors.aqiVeryPoor),
            _buildScaleLabel('300+', AppColors.aqiHazardous),
          ],
        ),
      ],
    );
  }

  Widget _buildScaleLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildPrimaryPollutants() {
    // Get top 3 pollutants by value
    final sortedPollutants = aqiData.pollutants.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topPollutants = sortedPollutants.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Primary Pollutants',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: topPollutants.map((entry) {
            return Column(
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.value.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getAQIColor(aqiData.aqi),
                  ),
                ),
                Text(
                  entry.key == 'CO' ? 'mg/m³' : 'μg/m³',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
