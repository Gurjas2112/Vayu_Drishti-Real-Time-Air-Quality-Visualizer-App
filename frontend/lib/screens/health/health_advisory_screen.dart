import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/air_quality_service.dart';
import '../../core/models/air_quality_data.dart';
import '../../widgets/custom_button.dart';

class HealthAdvisoryScreen extends StatefulWidget {
  final String locationName;
  final double latitude;
  final double longitude;
  final int currentAQI;

  const HealthAdvisoryScreen({
    super.key,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.currentAQI,
  });

  @override
  State<HealthAdvisoryScreen> createState() => _HealthAdvisoryScreenState();
}

class _HealthAdvisoryScreenState extends State<HealthAdvisoryScreen>
    with TickerProviderStateMixin {
  final AirQualityService _airQualityService = AirQualityService();

  AirQualityData? _airQualityData;
  bool _isLoading = true;
  String _errorMessage = '';

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAirQualityData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadAirQualityData() async {
    try {
      final data = await _airQualityService.getCurrentAirQuality(
        widget.latitude,
        widget.longitude,
        widget.locationName,
      );

      setState(() {
        _airQualityData = data;
        _isLoading = false;
      });

      // Start animations
      _fadeController.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        _slideController.forward();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load air quality data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Health Advisory'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage.isNotEmpty
          ? _buildErrorView()
          : _buildHealthAdvisoryContent(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading health recommendations...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Retry',
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = '';
                });
                _loadAirQualityData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthAdvisoryContent() {
    if (_airQualityData == null) return const SizedBox();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationHeader(),
              const SizedBox(height: 20),
              _buildAQIOverview(),
              const SizedBox(height: 20),
              _buildHealthRecommendations(),
              const SizedBox(height: 20),
              _buildPollutantBreakdown(),
              const SizedBox(height: 20),
              _buildProtectionMeasures(),
              const SizedBox(height: 20),
              _buildActivityRecommendations(),
              const SizedBox(height: 20),
              _buildEmergencyInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryLinearGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.locationName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Health Advisory for Current Location',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.health_and_safety,
            color: Colors.white.withOpacity(0.8),
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildAQIOverview() {
    final aqi = _airQualityData!.aqi;
    final category = _airQualityData!.category;
    final color = _getAQIColor(aqi);

    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.air, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Air Quality Index',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          aqi.toString(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _airQualityData!.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRecommendations() {
    final recommendations = _getHealthRecommendations(_airQualityData!.aqi);

    return _buildSection(
      title: 'Health Recommendations',
      icon: Icons.favorite,
      color: Colors.red,
      child: Column(
        children: recommendations.map((recommendation) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: recommendation['severity'] == 'high'
                        ? Colors.red
                        : recommendation['severity'] == 'medium'
                        ? Colors.orange
                        : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recommendation['text'],
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPollutantBreakdown() {
    return _buildSection(
      title: 'Pollutant Levels',
      icon: Icons.science,
      color: Colors.purple,
      child: Column(
        children: _airQualityData!.pollutants.entries.map((entry) {
          final pollutant = entry.key.toUpperCase();
          final value = entry.value;
          final status = _getPollutantStatus(pollutant, value);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    pollutant,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: status['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status['label'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: status['color'],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProtectionMeasures() {
    final measures = _getProtectionMeasures(_airQualityData!.aqi);

    return _buildSection(
      title: 'Protection Measures',
      icon: Icons.shield,
      color: Colors.blue,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: measures.length,
        itemBuilder: (context, index) {
          final measure = measures[index];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(measure['icon'], size: 32, color: AppTheme.primaryColor),
                const SizedBox(height: 8),
                Text(
                  measure['title'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  measure['description'],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityRecommendations() {
    final activities = _getActivityRecommendations(_airQualityData!.aqi);

    return _buildSection(
      title: 'Activity Recommendations',
      icon: Icons.directions_run,
      color: Colors.green,
      child: Column(
        children: activities.map((activity) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: activity['recommended']
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: activity['recommended']
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  activity['recommended'] ? Icons.check_circle : Icons.cancel,
                  color: activity['recommended'] ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    activity['activity'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  activity['recommended'] ? 'Safe' : 'Avoid',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: activity['recommended'] ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmergencyInfo() {
    return _buildSection(
      title: 'Emergency Information',
      icon: Icons.emergency,
      color: Colors.red,
      child: Column(
        children: [
          _buildEmergencyCard(
            icon: Icons.local_hospital,
            title: 'Emergency Helpline',
            subtitle: 'Call 102 for medical emergency',
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _buildEmergencyCard(
            icon: Icons.warning,
            title: 'Air Quality Alert',
            subtitle: 'Enable notifications for air quality warnings',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildEmergencyCard(
            icon: Icons.masks,
            title: 'Protection Guidelines',
            subtitle: 'Use N95 masks when AQI > 100',
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEmergencyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAQIColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow.shade700;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.brown;
  }

  List<Map<String, dynamic>> _getHealthRecommendations(int aqi) {
    if (aqi <= 50) {
      return [
        {
          'text':
              'Air quality is satisfactory and poses little to no health risk.',
          'severity': 'low',
        },
        {'text': 'Enjoy outdoor activities as usual.', 'severity': 'low'},
      ];
    } else if (aqi <= 100) {
      return [
        {
          'text': 'Air quality is acceptable for most people.',
          'severity': 'low',
        },
        {
          'text':
              'Sensitive individuals may experience minor respiratory symptoms.',
          'severity': 'medium',
        },
        {
          'text':
              'Consider reducing prolonged outdoor exertion if you are sensitive.',
          'severity': 'medium',
        },
      ];
    } else if (aqi <= 150) {
      return [
        {
          'text': 'Sensitive groups may experience health effects.',
          'severity': 'medium',
        },
        {
          'text':
              'People with heart or lung disease, older adults, and children should reduce prolonged outdoor exertion.',
          'severity': 'high',
        },
        {
          'text': 'Consider wearing a mask when outdoors.',
          'severity': 'medium',
        },
      ];
    } else if (aqi <= 200) {
      return [
        {
          'text': 'Everyone may begin to experience health effects.',
          'severity': 'high',
        },
        {
          'text':
              'Sensitive groups may experience more serious health effects.',
          'severity': 'high',
        },
        {
          'text':
              'Avoid outdoor activities, especially for children and elderly.',
          'severity': 'high',
        },
        {
          'text': 'Use air purifiers indoors and keep windows closed.',
          'severity': 'high',
        },
      ];
    } else {
      return [
        {
          'text':
              'Health alert: everyone may experience serious health effects.',
          'severity': 'high',
        },
        {'text': 'Avoid all outdoor activities.', 'severity': 'high'},
        {'text': 'Stay indoors and use air purifiers.', 'severity': 'high'},
        {
          'text':
              'Seek medical attention if experiencing breathing difficulties.',
          'severity': 'high',
        },
      ];
    }
  }

  Map<String, dynamic> _getPollutantStatus(String pollutant, double value) {
    // Simplified status based on common pollutant thresholds
    if (pollutant == 'PM2.5') {
      if (value <= 12) return {'label': 'Good', 'color': Colors.green};
      if (value <= 35)
        return {'label': 'Moderate', 'color': Colors.yellow.shade700};
      if (value <= 55)
        return {'label': 'Unhealthy for Sensitive', 'color': Colors.orange};
      if (value <= 150) return {'label': 'Unhealthy', 'color': Colors.red};
      return {'label': 'Very Unhealthy', 'color': Colors.purple};
    } else if (pollutant == 'PM10') {
      if (value <= 54) return {'label': 'Good', 'color': Colors.green};
      if (value <= 154)
        return {'label': 'Moderate', 'color': Colors.yellow.shade700};
      if (value <= 254)
        return {'label': 'Unhealthy for Sensitive', 'color': Colors.orange};
      if (value <= 354) return {'label': 'Unhealthy', 'color': Colors.red};
      return {'label': 'Very Unhealthy', 'color': Colors.purple};
    }

    // Default status for other pollutants
    if (value <= 50) return {'label': 'Good', 'color': Colors.green};
    if (value <= 100)
      return {'label': 'Moderate', 'color': Colors.yellow.shade700};
    return {'label': 'High', 'color': Colors.red};
  }

  List<Map<String, dynamic>> _getProtectionMeasures(int aqi) {
    List<Map<String, dynamic>> baseMeasures = [
      {
        'icon': Icons.masks,
        'title': 'Wear Mask',
        'description': aqi > 100 ? 'Use N95 mask' : 'Optional',
      },
      {
        'icon': Icons.home,
        'title': 'Stay Indoors',
        'description': aqi > 150 ? 'Recommended' : 'As needed',
      },
      {
        'icon': Icons.air,
        'title': 'Air Purifier',
        'description': aqi > 100 ? 'Use indoors' : 'Optional',
      },
      {
        'icon': Icons.local_drink,
        'title': 'Stay Hydrated',
        'description': 'Drink plenty of water',
      },
    ];

    if (aqi > 200) {
      baseMeasures.addAll([
        {
          'icon': Icons.close,
          'title': 'Close Windows',
          'description': 'Keep air out',
        },
        {
          'icon': Icons.healing,
          'title': 'Avoid Exercise',
          'description': 'Rest indoors',
        },
      ]);
    }

    return baseMeasures;
  }

  List<Map<String, dynamic>> _getActivityRecommendations(int aqi) {
    return [
      {'activity': 'Outdoor Jogging/Running', 'recommended': aqi <= 50},
      {'activity': 'Cycling', 'recommended': aqi <= 100},
      {'activity': 'Walking', 'recommended': aqi <= 150},
      {'activity': 'Outdoor Sports', 'recommended': aqi <= 50},
      {'activity': 'Indoor Exercise', 'recommended': true},
      {'activity': 'Gardening', 'recommended': aqi <= 100},
    ];
  }
}
