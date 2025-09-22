import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vayudrishti/core/constants/app_colors.dart';
import 'package:vayudrishti/providers/location_provider.dart';
import 'package:vayudrishti/providers/air_quality_provider.dart';
import 'package:vayudrishti/core/backend_connection_service.dart';
import 'package:vayudrishti/models/models.dart';

class MapLocation {
  final String name;
  final double latitude;
  final double longitude;
  final int aqi;
  final String category;
  final Map<String, double> pollutants;
  final DateTime timestamp;
  double distance;

  MapLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.aqi,
    required this.category,
    required this.pollutants,
    required this.timestamp,
    required this.distance,
  });

  // Factory method to create from LatestAqi model
  factory MapLocation.fromLatestAqi(LatestAqi aqiData, double distance) {
    return MapLocation(
      name: aqiData.stationName,
      latitude: aqiData.lat,
      longitude: aqiData.lon,
      aqi: aqiData.aqi,
      category: aqiData.aqiCategory,
      pollutants: aqiData.pollutantsMap,
      timestamp: aqiData.timestamp,
      distance: distance,
    );
  }
}

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    // Draw grid lines
    const gridSpacing = 50.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  bool _showHeatmap = true;
  bool _showLegend = true;
  String _mapType = 'normal';
  late AnimationController _legendController;
  late AnimationController _locationController;
  late Animation<double> _legendAnimation;
  late Animation<double> _locationPulseAnimation;
  bool _isLocationLoading = false;
  List<MapLocation> _nearbyLocations = [];
  bool _isLoadingNearbyData = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadNearbyLocations();
    _getCurrentLocationWithPermission();
  }

  void _initializeAnimations() {
    _legendController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _locationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _legendAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _legendController, curve: Curves.easeInOut),
    );

    _locationPulseAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _locationController, curve: Curves.easeInOut),
    );

    if (_showLegend) {
      _legendController.forward();
    }

    _locationController.repeat(reverse: true);
  }

  void _loadNearbyLocations() {
    setState(() {
      _isLoadingNearbyData = true;
    });

    // Try to load real data from backend first
    _loadNearbyLocationsFromBackend()
        .then((_) {
          setState(() {
            _isLoadingNearbyData = false;
          });
        })
        .catchError((_) {
          // Fallback to mock data if backend fails
          _loadMockNearbyLocations();
          setState(() {
            _isLoadingNearbyData = false;
          });
        });
  }

  Future<void> _loadNearbyLocationsFromBackend() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    if (locationProvider.latitude == null ||
        locationProvider.longitude == null) {
      // If no location, use mock data
      _loadMockNearbyLocations();
      return;
    }

    try {
      final airQualityProvider = Provider.of<AirQualityProvider>(
        context,
        listen: false,
      );

      // Use the provider to fetch data which will use the API client
      final success = await airQualityProvider.fetchCurrentAQI(
        locationProvider.latitude!,
        locationProvider.longitude!,
      );

      if (success && airQualityProvider.currentAQI != null) {
        // Create some mock nearby locations based on the real data
        final baseLocation = airQualityProvider.currentAQI!;
        _nearbyLocations = _generateNearbyLocationsFromReal(baseLocation);
      } else {
        _loadMockNearbyLocations();
      }
    } catch (e) {
      // Fallback to mock data
      _loadMockNearbyLocations();
    }
  }

  List<MapLocation> _generateNearbyLocationsFromReal(AirQualityData baseData) {
    final baseLatModifications = [-0.01, 0.005, -0.008, 0.012, 0.003];
    final baseLonModifications = [0.008, -0.006, 0.010, -0.004, 0.007];
    final aqiModifications = [-20, 15, -35, 25, -10];
    final stationNames = [
      'Central Station',
      'Industrial Area',
      'Residential Zone',
      'Commercial District',
      'Green Belt Area',
    ];

    final nearbyLocations = <MapLocation>[];

    for (int i = 0; i < 5; i++) {
      final modifiedAqi = (baseData.aqi + aqiModifications[i]).clamp(0, 500);
      final lat = baseData.latitude + baseLatModifications[i];
      final lon = baseData.longitude + baseLonModifications[i];

      // Calculate distance
      final distance =
          Geolocator.distanceBetween(
            baseData.latitude,
            baseData.longitude,
            lat,
            lon,
          ) /
          1000;

      nearbyLocations.add(
        MapLocation(
          name: stationNames[i],
          latitude: lat,
          longitude: lon,
          aqi: modifiedAqi,
          category: _getAQICategory(modifiedAqi),
          pollutants: _generatePollutantsForAqi(modifiedAqi),
          timestamp: DateTime.now().subtract(Duration(minutes: i * 5)),
          distance: distance,
        ),
      );
    }

    return nearbyLocations;
  }

  void _loadMockNearbyLocations() {
    // Mock nearby locations with different AQI values
    _nearbyLocations = [
      MapLocation(
        name: 'Downtown Area',
        latitude: 28.6139,
        longitude: 77.2090,
        aqi: 165,
        category: 'Poor',
        pollutants: _generatePollutantsForAqi(165),
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        distance: 2.5,
      ),
      MapLocation(
        name: 'Industrial Zone',
        latitude: 28.6300,
        longitude: 77.2200,
        aqi: 245,
        category: 'Very Poor',
        pollutants: _generatePollutantsForAqi(245),
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        distance: 5.2,
      ),
      MapLocation(
        name: 'Green Park',
        latitude: 28.6000,
        longitude: 77.1900,
        aqi: 85,
        category: 'Fair',
        pollutants: _generatePollutantsForAqi(85),
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        distance: 3.8,
      ),
      MapLocation(
        name: 'Airport Area',
        latitude: 28.5665,
        longitude: 77.1031,
        aqi: 120,
        category: 'Moderate',
        pollutants: _generatePollutantsForAqi(120),
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        distance: 15.6,
      ),
      MapLocation(
        name: 'University Campus',
        latitude: 28.6450,
        longitude: 77.2100,
        aqi: 95,
        category: 'Fair',
        pollutants: _generatePollutantsForAqi(95),
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        distance: 7.2,
      ),
    ];
  }

  Map<String, double> _generatePollutantsForAqi(int aqi) {
    // Generate realistic pollutant values based on AQI
    final baseValue = aqi / 2.0;
    return {
      'PM2.5': baseValue,
      'PM10': baseValue * 1.5,
      'O3': baseValue * 0.8,
      'NO2': baseValue * 0.6,
      'SO2': baseValue * 0.4,
      'CO': baseValue * 0.3,
    };
  }

  Future<void> _getCurrentLocationWithPermission() async {
    setState(() {
      _isLocationLoading = true;
    });

    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    final success = await locationProvider.getCurrentLocation();

    if (success && mounted) {
      final airQualityProvider = Provider.of<AirQualityProvider>(
        context,
        listen: false,
      );
      airQualityProvider.refreshData(
        locationProvider.latitude!,
        locationProvider.longitude!,
      );

      // Update distances to nearby locations
      _updateDistancesToNearbyLocations(
        locationProvider.latitude!,
        locationProvider.longitude!,
      );
    }

    setState(() {
      _isLocationLoading = false;
    });
  }

  void _updateDistancesToNearbyLocations(double currentLat, double currentLon) {
    for (var location in _nearbyLocations) {
      final distance =
          Geolocator.distanceBetween(
            currentLat,
            currentLon,
            location.latitude,
            location.longitude,
          ) /
          1000; // Convert to kilometers
      location.distance = distance;
    }

    // Sort by distance
    _nearbyLocations.sort((a, b) => a.distance.compareTo(b.distance));

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _legendController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Air Quality Map',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        actions: [
          Consumer<BackendConnectionService>(
            builder: (context, connectionService, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  connectionService.getConnectionStatusIcon(),
                  color: connectionService.getConnectionStatusColor(),
                  size: 20,
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _showHeatmap ? Icons.layers : Icons.layers_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showHeatmap = !_showHeatmap;
                if (_showHeatmap && !_showLegend) {
                  _showLegend = true;
                  _legendController.forward();
                } else if (!_showHeatmap && _showLegend) {
                  _showLegend = false;
                  _legendController.reverse();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              _showLegend ? Icons.info : Icons.info_outline,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showLegend = !_showLegend;
                if (_showLegend) {
                  _legendController.forward();
                } else {
                  _legendController.reverse();
                }
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.map_outlined, color: Colors.white),
            onSelected: (String value) {
              setState(() {
                _mapType = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'normal', child: Text('Normal View')),
              const PopupMenuItem(
                value: 'satellite',
                child: Text('Satellite View'),
              ),
              const PopupMenuItem(
                value: 'terrain',
                child: Text('Terrain View'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Map Info Banner
          _buildMapInfoBanner(),

          // Map placeholder (since Google Maps requires API key)
          Expanded(
            child: Stack(
              children: [
                _buildMapPlaceholder(),
                // Heatmap Legend
                if (_showHeatmap && _showLegend)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: AnimatedBuilder(
                      animation: _legendAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _legendAnimation.value,
                          child: Opacity(
                            opacity: _legendAnimation.value,
                            child: _buildHeatmapLegend(),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Bottom controls
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildMapInfoBanner() {
    return Consumer2<LocationProvider, AirQualityProvider>(
      builder: (context, locationProvider, airQualityProvider, child) {
        final currentAQI = airQualityProvider.currentAQI;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationProvider.currentAddress ?? 'Getting location...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (currentAQI != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'AQI: ${currentAQI.aqi} (${currentAQI.category})',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _showHeatmap ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapPlaceholder() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[50]!, Colors.green[50]!],
            ),
          ),
          child: Stack(
            children: [
              // Location service status
              if (_isLocationLoading)
                _buildLocationLoadingOverlay()
              else if (locationProvider.errorMessage != null)
                _buildLocationErrorOverlay(locationProvider)
              else
                _buildLocationMap(locationProvider),

              // Map type indicator
              _buildMapTypeIndicator(),

              // Current location marker (if available)
              if (locationProvider.currentPosition != null &&
                  !_isLocationLoading)
                _buildCurrentLocationMarker(),

              // Nearby locations with AQI data
              ..._buildNearbyLocationMarkers(),

              // Instructions card
              if (locationProvider.currentPosition == null &&
                  !_isLocationLoading)
                _buildLocationInstructions(locationProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationLoadingOverlay() {
    return Container(
      color: Colors.white.withValues(alpha: 0.8),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryColor),
            SizedBox(height: 16),
            Text(
              'Getting your location...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please allow location access for better experience',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationErrorOverlay(LocationProvider locationProvider) {
    return Container(
      color: Colors.white.withValues(alpha: 0.9),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_off,
                size: 64,
                color: AppColors.errorColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'Location Access Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                locationProvider.errorMessage ?? 'Unable to access location',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _getCurrentLocationWithPermission,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => locationProvider.openAppSettings(),
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceColor,
                      foregroundColor: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationMap(LocationProvider locationProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[100]!, Colors.green[100]!, Colors.orange[100]!],
        ),
      ),
      child: CustomPaint(size: Size.infinite, painter: MapGridPainter()),
    );
  }

  Widget _buildMapTypeIndicator() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _mapType == 'satellite' ? Icons.satellite : Icons.map,
              size: 16,
              color: AppColors.primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              _mapType == 'satellite' ? 'Satellite' : 'Normal',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLocationMarker() {
    return Center(
      child: AnimatedBuilder(
        animation: _locationPulseAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Pulse effect
              Transform.scale(
                scale: _locationPulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              // Main marker
              Consumer<AirQualityProvider>(
                builder: (context, airQualityProvider, child) {
                  final currentAQI = airQualityProvider.currentAQI;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: currentAQI != null
                          ? AppColors.getAQIColor(currentAQI.aqi)
                          : AppColors.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (currentAQI != null
                                      ? AppColors.getAQIColor(currentAQI.aqi)
                                      : AppColors.primaryColor)
                                  .withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 24,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildNearbyLocationMarkers() {
    return _nearbyLocations.asMap().entries.map((entry) {
      final index = entry.key;
      final location = entry.value;

      // Calculate position on screen (mock positioning)
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      final positions = [
        Offset(screenWidth * 0.3, screenHeight * 0.25),
        Offset(screenWidth * 0.7, screenHeight * 0.15),
        Offset(screenWidth * 0.2, screenHeight * 0.55),
        Offset(screenWidth * 0.8, screenHeight * 0.45),
        Offset(screenWidth * 0.6, screenHeight * 0.65),
      ];

      if (index >= positions.length) return const SizedBox.shrink();

      final position = positions[index];

      return Positioned(
        left: position.dx - 25,
        top: position.dy - 25,
        child: GestureDetector(
          onTap: () => _showLocationDetails(location),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.getAQIColor(location.aqi),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.getAQIColor(
                    location.aqi,
                  ).withValues(alpha: 0.6),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  location.aqi.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${location.distance.toStringAsFixed(1)}km',
                  style: const TextStyle(color: Colors.white, fontSize: 8),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLocationInstructions(LocationProvider locationProvider) {
    return Positioned(
      bottom: 120,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.location_searching,
              color: AppColors.primaryColor,
              size: 32,
            ),
            const SizedBox(height: 12),
            const Text(
              'Enable Location Access',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Allow location access to view real-time air quality data for your area and discover nearby monitoring stations.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _getCurrentLocationWithPermission,
                icon: const Icon(Icons.location_on),
                label: const Text('Get My Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'AQI Scale (0-500)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // Color gradient bar
          Container(
            height: 8,
            width: 120,
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
          const SizedBox(height: 6),
          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendLabel('Good', '0-50', AppColors.aqiGood),
              _buildLegendLabel('Hazardous', '300+', AppColors.aqiHazardous),
            ],
          ),
          const SizedBox(height: 8),
          // Legend items
          Column(
            children: [
              _buildLegendItem('Good', '0-50', AppColors.aqiGood, '😊'),
              _buildLegendItem('Fair', '51-100', AppColors.aqiFair, '🙂'),
              _buildLegendItem(
                'Moderate',
                '101-150',
                AppColors.aqiModerate,
                '😐',
              ),
              _buildLegendItem('Poor', '151-200', AppColors.aqiPoor, '😷'),
              _buildLegendItem(
                'V.Poor',
                '201-300',
                AppColors.aqiVeryPoor,
                '😰',
              ),
              _buildLegendItem(
                'Hazardous',
                '300+',
                AppColors.aqiHazardous,
                '☠️',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendLabel(String text, String range, Color color) {
    return Column(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          range,
          style: const TextStyle(fontSize: 7, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    String category,
    String range,
    Color color,
    String emoji,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            '$category ($range)',
            style: const TextStyle(fontSize: 8, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showLocationDetails(MapLocation location) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final aqiColor = AppColors.getAQIColor(location.aqi);
        final category = _getAQICategory(location.aqi);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  aqiColor.withValues(alpha: 0.1),
                  aqiColor.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Location name and distance
                Row(
                  children: [
                    Icon(Icons.location_on, color: aqiColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.directions,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${location.distance.toStringAsFixed(1)} km away',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // AQI Value Circle
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: aqiColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: aqiColor.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Text(
                    location.aqi.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category and emoji
                Text(
                  '$category ${_getAQIEmoji(location.aqi)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: aqiColor,
                  ),
                ),
                const SizedBox(height: 12),

                // Health advice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: aqiColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _getHealthAdvice(location.aqi),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),

                // Pollutants data
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Key Pollutants',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: location.pollutants.entries
                            .take(3) // Show top 3 pollutants
                            .map(
                              (entry) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: aqiColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${entry.key}: ${entry.value.toStringAsFixed(1)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: aqiColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Timestamp
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Updated: ${_formatTimestamp(location.timestamp)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Coordinates info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Latitude',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            location.latitude.toStringAsFixed(4),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppColors.borderColor,
                      ),
                      Column(
                        children: [
                          const Text(
                            'Longitude',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            location.longitude.toStringAsFixed(4),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: aqiColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getAQIEmoji(int aqi) {
    if (aqi <= 50) return '😊';
    if (aqi <= 100) return '🙂';
    if (aqi <= 150) return '😐';
    if (aqi <= 200) return '😷';
    if (aqi <= 300) return '😰';
    return '☠️';
  }

  String _getAQICategory(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Fair';
    if (aqi <= 150) return 'Moderate';
    if (aqi <= 200) return 'Poor';
    if (aqi <= 300) return 'Very Poor';
    return 'Hazardous';
  }

  String _getHealthAdvice(int aqi) {
    if (aqi <= 50) return 'Air quality is satisfactory for most people.';
    if (aqi <= 100) {
      return 'Sensitive individuals should consider limiting outdoor activities.';
    }
    if (aqi <= 150) {
      return 'Everyone should reduce prolonged outdoor activities.';
    }
    if (aqi <= 200) return 'Everyone should limit outdoor activities.';
    if (aqi <= 300) return 'Everyone should avoid outdoor activities.';
    return 'Health alert: everyone should avoid outdoor activities.';
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildControlButton(
              icon: Icons.my_location,
              label: 'My Location',
              onTap: _getCurrentLocationWithPermission,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildControlButton(
              icon: _showHeatmap ? Icons.layers : Icons.layers_outlined,
              label: 'Heatmap',
              onTap: () {
                setState(() {
                  _showHeatmap = !_showHeatmap;
                  if (_showHeatmap && !_showLegend) {
                    _showLegend = true;
                    _legendController.forward();
                  } else if (!_showHeatmap && _showLegend) {
                    _showLegend = false;
                    _legendController.reverse();
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildControlButton(
              icon: Icons.refresh,
              label: 'Refresh',
              onTap: () {
                final airQualityProvider = Provider.of<AirQualityProvider>(
                  context,
                  listen: false,
                );
                final locationProvider = Provider.of<LocationProvider>(
                  context,
                  listen: false,
                );

                if (locationProvider.latitude != null &&
                    locationProvider.longitude != null) {
                  airQualityProvider.refreshData(
                    locationProvider.latitude!,
                    locationProvider.longitude!,
                  );
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refreshing air quality data...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
