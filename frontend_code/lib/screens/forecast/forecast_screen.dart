import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:vayudrishti/core/constants/app_colors.dart';
import 'package:vayudrishti/providers/air_quality_provider.dart';
import 'package:vayudrishti/providers/location_provider.dart';
import 'package:intl/intl.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen>
    with TickerProviderStateMixin {
  String _selectedTimeframe = '24H';
  int _selectedTab = 0;

  final List<String> _timeframes = ['24H', '72H', 'Weekly'];
  final List<String> _tabs = ['AQI', 'PM2.5', 'PM10', 'O3'];

  late AnimationController _chartAnimationController;
  late AnimationController _tabAnimationController;
  late Animation<double> _chartAnimation;
  late Animation<double> _tabAnimation;

  @override
  void initState() {
    super.initState();
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _chartAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _tabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _tabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadForecastData();
      _tabAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _chartAnimationController.dispose();
    _tabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadForecastData() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    final airQualityProvider = Provider.of<AirQualityProvider>(
      context,
      listen: false,
    );

    if (locationProvider.latitude != null &&
        locationProvider.longitude != null) {
      await airQualityProvider.fetchForecastData(
        locationProvider.latitude!,
        locationProvider.longitude!,
      );
      // Trigger chart animation after data loads
      _chartAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Air Quality Forecast',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadForecastData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadForecastData,
        color: AppColors.primaryColor,
        child: CustomScrollView(
          slivers: [
            // Timeframe Selector
            SliverToBoxAdapter(child: _buildTimeframeSelector()),

            // Chart Section
            SliverToBoxAdapter(child: _buildChartSection()),

            // Detailed Forecast List
            SliverToBoxAdapter(child: _buildDetailedForecast()),

            // Health Tips
            SliverToBoxAdapter(child: _buildHealthTips()),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: _timeframes.map((timeframe) {
            final isSelected = _selectedTimeframe == timeframe;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTimeframe = timeframe;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    timeframe,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Chart Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AQI Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _selectedTimeframe,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Enhanced Chart Tabs with Animation
          AnimatedBuilder(
            animation: _tabAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _tabAnimation.value,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _tabs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tab = entry.value;
                      final isSelected = _selectedTab == index;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTab = index;
                          });
                          // Restart chart animation on tab change
                          _chartAnimationController.reset();
                          _chartAnimationController.forward();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryColor
                                : AppColors.surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : AppColors.borderColor,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            tab,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Enhanced Animated Chart
          SizedBox(
            height: 200,
            child: Consumer<AirQualityProvider>(
              builder: (context, airQualityProvider, child) {
                if (airQualityProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  );
                }

                if (airQualityProvider.forecastData.isEmpty) {
                  return const Center(
                    child: Text(
                      'No forecast data available',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return AnimatedBuilder(
                  animation: _chartAnimation,
                  builder: (context, child) {
                    return _buildEnhancedLineChart(
                      airQualityProvider.forecastData,
                      _chartAnimation.value,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedLineChart(
    List<ForecastData> forecastData,
    double animationValue,
  ) {
    final spots = <FlSpot>[];
    final maxDataPoints = _selectedTimeframe == '24H'
        ? 24
        : _selectedTimeframe == '72H'
        ? 72
        : 168;

    for (int i = 0; i < forecastData.length && i < maxDataPoints; i++) {
      final data = forecastData[i];
      double value;

      switch (_selectedTab) {
        case 0: // AQI
          value = data.aqi.toDouble();
          break;
        case 1: // PM2.5
          value = data.pollutants['PM2.5'] ?? 0;
          break;
        case 2: // PM10
          value = data.pollutants['PM10'] ?? 0;
          break;
        case 3: // O3
          value = data.pollutants['O3'] ?? 0;
          break;
        default:
          value = data.aqi.toDouble();
      }

      spots.add(FlSpot(i.toDouble(), value * animationValue));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _selectedTab == 0 ? 50 : 20,
          verticalInterval: maxDataPoints / 6,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.borderColor.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: AppColors.borderColor.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _selectedTab == 0 ? 50 : 20,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxDataPoints / 6,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < forecastData.length) {
                  final dateTime = forecastData[value.toInt()].dateTime;
                  if (_selectedTimeframe == 'Weekly') {
                    return Text(
                      DateFormat('dd/MM').format(dateTime),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    );
                  } else {
                    return Text(
                      DateFormat('HH:mm').format(dateTime),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: AppColors.borderColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final DateTime dateTime = forecastData[spot.x.toInt()].dateTime;
                final String unit = _selectedTab == 0
                    ? 'AQI'
                    : _selectedTab == 1 || _selectedTab == 2
                    ? 'μg/m³'
                    : 'μg/m³';

                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)} $unit\n${DateFormat('HH:mm').format(dateTime)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((spotIndex) {
              return TouchedSpotIndicatorData(
                FlLine(color: AppColors.primaryColor, strokeWidth: 2),
                FlDotData(
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                        radius: 6,
                        color: AppColors.primaryColor,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                ),
              );
            }).toList();
          },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.primaryColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryColor.withValues(
                    alpha: 0.3 * animationValue,
                  ),
                  AppColors.primaryColor.withValues(
                    alpha: 0.1 * animationValue,
                  ),
                ],
              ),
            ),
          ),
        ],
        minY: 0,
      ),
    );
  }

  Widget _buildDetailedForecast() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Hourly Forecast',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Consumer<AirQualityProvider>(
            builder: (context, airQualityProvider, child) {
              if (airQualityProvider.forecastData.isEmpty) {
                return const Center(child: Text('No forecast data available'));
              }

              return Column(
                children: airQualityProvider.forecastData
                    .take(8) // Show first 8 hours
                    .map((forecast) => _buildForecastItem(forecast))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForecastItem(ForecastData forecast) {
    final aqiColor = AppColors.getAQIColor(forecast.aqi);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: aqiColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 60,
            child: Text(
              DateFormat('HH:mm').format(forecast.dateTime),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // AQI Value
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: aqiColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              forecast.aqi.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(width: 16),

          // Category
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  forecast.category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: aqiColor,
                  ),
                ),
                Text(
                  'PM2.5: ${forecast.pollutants['PM2.5']?.toStringAsFixed(1)} μg/m³',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Weather icon placeholder
          Icon(_getWeatherIcon(forecast.aqi), color: aqiColor, size: 24),
        ],
      ),
    );
  }

  Widget _buildHealthTips() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.infoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tips_and_updates,
                  color: AppColors.infoColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Health Tips for Tomorrow',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem(
            'Morning Exercise',
            'Best air quality expected between 6-8 AM',
            Icons.fitness_center,
            AppColors.successColor,
          ),
          _buildTipItem(
            'Afternoon Caution',
            'Air quality may worsen after 2 PM',
            Icons.warning,
            AppColors.warningColor,
          ),
          _buildTipItem(
            'Evening Activities',
            'Consider indoor activities after 6 PM',
            Icons.home,
            AppColors.infoColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(int aqi) {
    if (aqi <= 50) return Icons.wb_sunny;
    if (aqi <= 100) return Icons.wb_cloudy;
    if (aqi <= 150) return Icons.cloud;
    if (aqi <= 200) return Icons.foggy;
    return Icons.visibility_off;
  }
}
