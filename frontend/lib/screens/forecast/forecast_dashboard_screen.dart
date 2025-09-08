import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/models/forecast_data.dart';
import '../../core/services/advanced_air_quality_service.dart';

class ForecastDashboardScreen extends StatefulWidget {
  final String locationName;
  final double latitude;
  final double longitude;

  const ForecastDashboardScreen({
    super.key,
    required this.locationName,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<ForecastDashboardScreen> createState() =>
      _ForecastDashboardScreenState();
}

class _ForecastDashboardScreenState extends State<ForecastDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = true;
  AirQualityForecast? _forecast;
  final AdvancedAirQualityService _airQualityService =
      AdvancedAirQualityService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadForecastData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadForecastData() async {
    setState(() => _isLoading = true);

    try {
      final forecast = await _airQualityService.getDetailedForecast(
        widget.latitude,
        widget.longitude,
        widget.locationName,
      );

      setState(() {
        _forecast = forecast;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading forecast: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('3-Day Forecast'),
            Text(
              widget.locationName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _animationController.reset();
              _loadForecastData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _loadForecastData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current conditions
                      _buildCurrentConditionsCard(),

                      const SizedBox(height: 16),

                      // 3-day forecast cards
                      _buildForecastCardsSection(),

                      const SizedBox(height: 16),

                      // Hourly forecast chart
                      _buildHourlyForecastChart(),

                      const SizedBox(height: 16),

                      // Weather integration
                      _buildWeatherIntegrationCard(),

                      const SizedBox(height: 16),

                      // Health recommendations
                      _buildHealthRecommendationsCard(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentConditionsCard() {
    if (_forecast == null) return const SizedBox();

    final today = _forecast!.dailyForecast.first;

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              _getAQIColor(today.aqi),
              _getAQIColor(today.aqi).withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Conditions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Icon(
                  _getWeatherIcon('sunny'), // Mock weather condition
                  color: Colors.white,
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${today.aqi}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getAQICategory(today.aqi),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'AQI Level',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCurrentStat(
                    'PM2.5',
                    '${today.pollutants['pm2_5']?.toInt() ?? 0} μg/m³',
                  ),
                ),
                Expanded(
                  child: _buildCurrentStat(
                    'PM10',
                    '${today.pollutants['pm10']?.toInt() ?? 0} μg/m³',
                  ),
                ),
                Expanded(
                  child: _buildCurrentStat(
                    'NO₂',
                    '${today.pollutants['no2']?.toInt() ?? 0} μg/m³',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildForecastCardsSection() {
    if (_forecast == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3-Day Forecast',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _forecast!.dailyForecast.length,
            itemBuilder: (context, index) {
              final forecast = _forecast!.dailyForecast[index];
              final isToday = index == 0;

              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                child: Card(
                  elevation: 2,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: isToday
                          ? Border.all(color: Colors.purple.shade600, width: 2)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isToday ? 'Today' : _getDayName(forecast.timestamp),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isToday
                                ? Colors.purple.shade600
                                : Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${forecast.timestamp.day}/${forecast.timestamp.month}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              _getWeatherIcon(
                                'sunny',
                              ), // Mock weather condition
                              size: 24,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${20 + (index * 2)}°C', // Mock temperature
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getAQIColor(forecast.aqi),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'AQI ${forecast.aqi}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getAQICategory(forecast.aqi),
                          style: TextStyle(
                            fontSize: 11,
                            color: _getAQIColor(forecast.aqi),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecastChart() {
    if (_forecast == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hourly AQI Forecast',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final hour = value.toInt();
                          if (hour % 6 == 0) {
                            return Text(
                              '${hour}h',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getHourlyChartSpots(),
                      isCurved: true,
                      color: Colors.purple.shade600,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.purple.shade100,
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final hour = spot.x.toInt();
                          return LineTooltipItem(
                            'AQI: ${spot.y.toInt()}\nTime: $hour:00',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherIntegrationCard() {
    if (_forecast == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Weather Impact on Air Quality',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ..._forecast!.dailyForecast.map((forecast) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getWeatherIcon('sunny'), // Mock weather condition
                      size: 24,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${forecast.timestamp.day}/${forecast.timestamp.month} - Sunny',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _getWeatherImpactText(forecast),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getAQIColor(forecast.aqi).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${forecast.aqi}',
                        style: TextStyle(
                          color: _getAQIColor(forecast.aqi),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthRecommendationsCard() {
    if (_forecast == null) return const SizedBox();

    final worstDay = _forecast!.dailyForecast.reduce(
      (curr, next) => curr.aqi > next.aqi ? curr : next,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Health Recommendations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Alert for worst day
            if (worstDay.aqi > 100)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alert: Poor Air Quality Expected',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          Text(
                            '${worstDay.timestamp.day}/${worstDay.timestamp.month} - AQI ${worstDay.aqi}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // General recommendations
            ..._getHealthRecommendations(worstDay.aqi).map((rec) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(rec, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getHourlyChartSpots() {
    // Generate mock hourly data for the next 24 hours
    final spots = <FlSpot>[];
    final baseAQI = _forecast?.dailyForecast.first.aqi ?? 100;

    for (int hour = 0; hour < 24; hour++) {
      // Simulate hourly variations
      final variation = (hour % 6 == 0)
          ? -10
          : (hour % 4 == 0)
          ? 15
          : 0;
      final aqi = (baseAQI + variation).clamp(20, 400);
      spots.add(FlSpot(hour.toDouble(), aqi.toDouble()));
    }

    return spots;
  }

  String _getDayName(DateTime date) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[date.weekday % 7];
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return Icons.wb_sunny;
      case 'cloudy':
      case 'overcast':
        return Icons.cloud;
      case 'rainy':
      case 'rain':
        return Icons.water_drop;
      case 'windy':
        return Icons.air;
      default:
        return Icons.wb_cloudy;
    }
  }

  Color _getAQIColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow.shade700;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.brown;
  }

  String _getAQICategory(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  String _getWeatherImpactText(ForecastData forecast) {
    // Since ForecastData doesn't have weather condition, provide generic impact text
    return 'Weather conditions affect pollutant dispersion patterns';
  }

  List<String> _getHealthRecommendations(int maxAQI) {
    if (maxAQI <= 50) {
      return [
        'Air quality is good. Enjoy outdoor activities!',
        'No health precautions needed for most people',
        'Great time for exercise and outdoor sports',
      ];
    } else if (maxAQI <= 100) {
      return [
        'Air quality is acceptable for most people',
        'Sensitive individuals should consider reducing prolonged outdoor exertion',
        'Good time for most outdoor activities',
      ];
    } else if (maxAQI <= 150) {
      return [
        'Sensitive groups should reduce outdoor activities',
        'Children and elderly should limit time outside',
        'Consider wearing masks during outdoor activities',
        'Keep windows closed during poor air quality periods',
      ];
    } else if (maxAQI <= 200) {
      return [
        'Everyone should reduce outdoor activities',
        'Wear N95 masks when going outside',
        'Keep windows and doors closed',
        'Use air purifiers indoors if available',
        'Avoid outdoor exercise',
      ];
    } else {
      return [
        'Stay indoors as much as possible',
        'Emergency measures: seal gaps in windows/doors',
        'Use air purifiers on maximum setting',
        'Seek medical attention if experiencing symptoms',
        'Cancel all outdoor activities',
      ];
    }
  }
}
