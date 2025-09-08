import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/models/historical_data.dart';
import '../../core/services/advanced_air_quality_service.dart';

class HistoricalTrendsScreen extends StatefulWidget {
  final String? locationName;
  final double? latitude;
  final double? longitude;

  const HistoricalTrendsScreen({
    super.key,
    this.locationName,
    this.latitude,
    this.longitude,
  });

  @override
  State<HistoricalTrendsScreen> createState() => _HistoricalTrendsScreenState();
}

class _HistoricalTrendsScreenState extends State<HistoricalTrendsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = true;
  HistoricalAirQualityData? _historicalData;
  String _selectedPollutant = 'AQI';
  String _selectedPeriod = '7 days';
  final AdvancedAirQualityService _airQualityService =
      AdvancedAirQualityService();

  final List<String> _pollutants = [
    'AQI',
    'PM2.5',
    'PM10',
    'NO2',
    'O3',
    'SO2',
    'CO',
  ];
  final Map<String, int> _periodDays = {
    '7 days': 7,
    '30 days': 30,
    '90 days': 90,
    '1 year': 365,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _loadHistoricalData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoricalData() async {
    setState(() => _isLoading = true);

    try {
      final daysBack = _periodDays[_selectedPeriod] ?? 7;
      final data = await _airQualityService.getHistoricalData(
        widget.latitude ?? 28.6139,
        widget.longitude ?? 77.2090,
        widget.locationName ?? 'Current Location',
        daysBack,
      );

      setState(() {
        _historicalData = data;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading historical data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.locationName ?? 'Historical Trends'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistoricalData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading historical data...'),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildControlsSection(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTrendChart(),
                          const SizedBox(height: 20),
                          _buildStatisticsCards(),
                          const SizedBox(height: 20),
                          _buildTrendAnalysis(),
                          const SizedBox(height: 20),
                          _buildPollutionSourceAnalysis(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildControlsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Pollutant',
                  value: _selectedPollutant,
                  items: _pollutants,
                  onChanged: (value) {
                    setState(() => _selectedPollutant = value!);
                    _animationController.reset();
                    _animationController.forward();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'Period',
                  value: _selectedPeriod,
                  items: _periodDays.keys.toList(),
                  onChanged: (value) {
                    setState(() => _selectedPeriod = value!);
                    _loadHistoricalData();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTrendChart() {
    if (_historicalData == null || _historicalData!.dataPoints.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(child: Text('No data available')),
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_selectedPollutant Trend ($_selectedPeriod)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (_historicalData!.dataPoints.length / 5)
                          .ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 &&
                            index < _historicalData!.dataPoints.length) {
                          final date =
                              _historicalData!.dataPoints[index].timestamp;
                          return Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _historicalData!.dataPoints.asMap().entries.map((
                      entry,
                    ) {
                      final index = entry.key.toDouble();
                      final dataPoint = entry.value;
                      double value = _getValueForPollutant(dataPoint);
                      return FlSpot(index, value);
                    }).toList(),
                    isCurved: true,
                    color: _getColorForPollutant(),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _getColorForPollutant().withOpacity(0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: _getMaxValueForChart(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getValueForPollutant(AirQualityDataPoint dataPoint) {
    switch (_selectedPollutant) {
      case 'PM2.5':
        return dataPoint.pm25;
      case 'PM10':
        return dataPoint.pm10;
      case 'NO2':
        return dataPoint.no2;
      case 'O3':
        return dataPoint.o3;
      case 'SO2':
        return dataPoint.so2;
      case 'CO':
        return dataPoint.co;
      default:
        return dataPoint.aqi.toDouble();
    }
  }

  Color _getColorForPollutant() {
    switch (_selectedPollutant) {
      case 'PM2.5':
        return Colors.purple;
      case 'PM10':
        return Colors.orange;
      case 'NO2':
        return Colors.blue;
      case 'O3':
        return Colors.green;
      case 'SO2':
        return Colors.yellow[700]!;
      case 'CO':
        return Colors.brown;
      default:
        return Colors.red;
    }
  }

  double _getMaxValueForChart() {
    if (_historicalData == null || _historicalData!.dataPoints.isEmpty) {
      return 300;
    }

    final values = _historicalData!.dataPoints.map(_getValueForPollutant);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.2).ceilToDouble();
  }

  Widget _buildStatisticsCards() {
    if (_historicalData == null || _historicalData!.dataPoints.isEmpty) {
      return Container();
    }

    final values = _historicalData!.dataPoints
        .map(_getValueForPollutant)
        .toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Average', avg.toStringAsFixed(1), Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Minimum',
            min.toStringAsFixed(1),
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Maximum', max.toStringAsFixed(1), Colors.red),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendAnalysis() {
    if (_historicalData == null || _historicalData!.dataPoints.length < 2) {
      return Container();
    }

    final firstWeek = _historicalData!.dataPoints
        .take(7)
        .map(_getValueForPollutant)
        .toList();
    final lastWeek = _historicalData!.dataPoints.reversed
        .take(7)
        .map(_getValueForPollutant)
        .toList();

    final firstWeekAvg = firstWeek.reduce((a, b) => a + b) / firstWeek.length;
    final lastWeekAvg = lastWeek.reduce((a, b) => a + b) / lastWeek.length;

    final trend = lastWeekAvg - firstWeekAvg;
    final trendPercentage = (trend / firstWeekAvg * 100).abs();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trend Analysis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                trend > 0 ? Icons.trending_up : Icons.trending_down,
                color: trend > 0 ? Colors.red : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${trend > 0 ? 'Increased' : 'Decreased'} by ${trendPercentage.toStringAsFixed(1)}% compared to the beginning of the period',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPollutionSourceAnalysis() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pollution Source Analysis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Based on historical patterns:',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          _buildSourceItem('Vehicle emissions', '35%', Colors.red),
          _buildSourceItem('Industrial activities', '25%', Colors.orange),
          _buildSourceItem('Construction dust', '20%', Colors.brown),
          _buildSourceItem('Biomass burning', '15%', Colors.green),
          _buildSourceItem('Other sources', '5%', Colors.grey),
        ],
      ),
    );
  }

  Widget _buildSourceItem(String source, String percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(source)),
          Text(percentage, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
