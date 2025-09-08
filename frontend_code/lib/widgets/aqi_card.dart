import 'package:flutter/material.dart';
import 'package:vayudrishti/core/constants/app_colors.dart';
import 'package:vayudrishti/providers/air_quality_provider.dart';
import 'package:intl/intl.dart';

class AQICard extends StatefulWidget {
  final AirQualityData aqiData;

  const AQICard({super.key, required this.aqiData});

  @override
  State<AQICard> createState() => _AQICardState();
}

class _AQICardState extends State<AQICard> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _scaleController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  String _getAQIEmoji(int aqi) {
    if (aqi <= 50) return '😊'; // Good
    if (aqi <= 100) return '🙂'; // Fair
    if (aqi <= 150) return '😐'; // Moderate
    if (aqi <= 200) return '😷'; // Poor
    if (aqi <= 300) return '😰'; // Very Poor
    return '☠️'; // Hazardous
  }

  @override
  Widget build(BuildContext context) {
    final aqiColor = AppColors.getAQIColor(widget.aqiData.aqi);
    final aqiBackgroundColor = AppColors.getAQIBackgroundColor(
      widget.aqiData.aqi,
    );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
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
              border: Border.all(
                color: aqiColor.withValues(alpha: 0.3),
                width: 1,
              ),
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
                // Enhanced Header with Live Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Air Quality Index',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withValues(
                                            alpha: 0.6,
                                          ),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        Text(
                          'Last updated: ${DateFormat('HH:mm').format(widget.aqiData.timestamp)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.8,
                            ),
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
                        boxShadow: [
                          BoxShadow(
                            color: aqiColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.aqiData.category,
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

                // Enhanced Main AQI Display with Emoji
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Emoji Indicator
                    Text(
                      _getAQIEmoji(widget.aqiData.aqi),
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(width: 16),
                    // AQI Number
                    Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.aqiData.aqi.toString(),
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
                        // Quick Health Status
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: aqiColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getHealthStatus(widget.aqiData.aqi),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: aqiColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Enhanced AQI Scale
                _buildEnhancedAQIScale(),

                const SizedBox(height: 20),

                // Enhanced Primary Pollutants with Progress Bars
                _buildEnhancedPollutants(),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getHealthStatus(int aqi) {
    if (aqi <= 50) return 'Healthy';
    if (aqi <= 100) return 'Acceptable';
    if (aqi <= 150) return 'Unhealthy for Sensitive';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  Widget _buildEnhancedAQIScale() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'AQI Scale',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Current: ${widget.aqiData.aqi}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.getAQIColor(widget.aqiData.aqi),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
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
            // Current AQI Indicator
            Positioned(
              left:
                  (widget.aqiData.aqi / 500) *
                  (MediaQuery.of(context).size.width -
                      80), // Adjust for padding
              child: Column(
                children: [
                  Container(
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildEnhancedPollutants() {
    // Get top 3 pollutants by value
    final sortedPollutants = widget.aqiData.pollutants.entries.toList()
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
            final maxValue = entry.key == 'CO'
                ? 40.0
                : 150.0; // Different max for CO
            final progress = (entry.value / maxValue).clamp(0.0, 1.0);

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
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
                        color: AppColors.getAQIColor(widget.aqiData.aqi),
                      ),
                    ),
                    Text(
                      entry.key == 'CO' ? 'mg/m³' : 'μg/m³',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Progress bar for pollutant level
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.getAQIColor(widget.aqiData.aqi),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScaleLabel(String text, Color color) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }
}
