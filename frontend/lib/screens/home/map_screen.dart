import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/air_quality_service.dart';
import '../../core/services/location_service.dart';
import '../../core/models/air_quality_data.dart';
import '../trends/historical_trends_screen.dart';
import '../forecast/forecast_dashboard_screen.dart';
import '../health/health_advisory_screen.dart';
import '../settings/notification_settings_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with AutomaticKeepAliveClientMixin {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  final AirQualityService _airQualityService = AirQualityService();

  Set<Marker> _markers = {};
  bool _isLoading = true;
  String _errorMessage = '';
  bool _disposed = false;
  List<AirQualityData> _airQualityDataList = [];

  // Default to Delhi coordinates
  LatLng _currentLocation = const LatLng(28.6139, 77.2090);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _disposed = true;
    _mapController?.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _initializeMap() async {
    try {
      // Try to get current location
      await _getCurrentLocation();

      // Load air quality data for major cities
      await _loadAirQualityMarkers();

      _safeSetState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Map initialization error: $e');
      _safeSetState(() {
        _errorMessage =
            'Failed to load map data. Please check your internet connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (!_disposed && mounted) {
        _safeSetState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      // Use default location (Delhi) if location services fail
      debugPrint('Location error: $e');
    }
  }

  Future<void> _loadAirQualityMarkers() async {
    try {
      final cities = AirQualityService.getMajorIndianCities();
      final List<AirQualityData> airQualityDataList = await _airQualityService
          .getMultipleLocationsAirQuality(cities);

      if (_disposed || !mounted) return;

      final Set<Marker> markers = {};

      for (final data in airQualityDataList) {
        try {
          final marker = Marker(
            markerId: MarkerId(data.locationName),
            position: LatLng(data.latitude, data.longitude),
            icon: await _getMarkerIcon(data.aqi),
            infoWindow: InfoWindow(
              title: data.locationName,
              snippet: 'AQI: ${data.aqi} (${data.category})',
              onTap: () => _showAirQualityDetails(data),
            ),
          );
          markers.add(marker);
        } catch (markerError) {
          debugPrint(
            'Error creating marker for ${data.locationName}: $markerError',
          );
        }
      }

      _safeSetState(() {
        _markers = markers;
        _airQualityDataList = airQualityDataList;
      });
    } catch (e) {
      debugPrint('Error loading air quality markers: $e');
      // Continue with empty markers instead of crashing
      _safeSetState(() {
        _markers = {};
        _airQualityDataList = [];
      });
    }
  }

  Future<BitmapDescriptor> _getMarkerIcon(int aqi) async {
    try {
      // Use default marker with different colors based on AQI
      if (aqi <= 50) {
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      } else if (aqi <= 100) {
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueYellow,
        );
      } else if (aqi <= 150) {
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        );
      } else if (aqi <= 200) {
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      } else if (aqi <= 300) {
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet,
        );
      } else {
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      }
    } catch (e) {
      debugPrint('Error creating marker icon: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  void _showAirQualityDetails(AirQualityData data) {
    if (_disposed || !mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.locationName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getAQIColor(data.aqi).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getAQIColor(data.aqi)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'AQI: ${data.aqi}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getAQIColor(data.aqi),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            data.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(data.message, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Main Pollutants',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: data.pollutants.entries.map((entry) {
                  return Chip(
                    label: Text(
                      '${entry.key.toUpperCase()}: ${entry.value.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: AppTheme.cardColor,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryLinearGradient),
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 20),
                Text(
                  'Loading Air Quality Map...',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryLinearGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.white70,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Error Loading Map',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _safeSetState(() {
                      _isLoading = true;
                      _errorMessage = '';
                    });
                    _initializeMap();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show alternative UI for web if Google Maps has issues
    if (kIsWeb) {
      return _buildWebMapView();
    }

    return _buildNativeMapView();
  }

  Widget _buildNativeMapView() {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 6.0,
            ),
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              if (!_disposed) {
                _mapController = controller;
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
          ),
          _buildMapHeader(),
          _buildLocationButton(),
        ],
      ),
    );
  }

  Widget _buildWebMapView() {
    return Scaffold(
      body: Stack(
        children: [
          // Try to show Google Map, but catch any errors
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: _buildGoogleMapWidget(),
          ),
          _buildMapHeader(),
          _buildLocationButton(),
        ],
      ),
    );
  }

  Widget _buildGoogleMapWidget() {
    try {
      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLocation,
          zoom: 6.0,
        ),
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          if (!_disposed) {
            _mapController = controller;
          }
        },
        myLocationEnabled: false, // Disable for web to avoid issues
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        mapToolbarEnabled: false,
      );
    } catch (e) {
      debugPrint('Google Maps widget error: $e');
      // If Google Maps fails, show the list view
      return _buildCityListView();
    }
  }

  Widget _buildCityListView() {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.primaryLinearGradient),
      child: _airQualityDataList.isEmpty
          ? const Center(
              child: Text(
                'No air quality data available',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(
                top: 120,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              itemCount: _airQualityDataList.length,
              itemBuilder: (context, index) {
                final data = _airQualityDataList[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getAQIColor(data.aqi),
                      child: Text(
                        data.aqi.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      data.locationName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${data.category} - ${data.message}'),
                    trailing: Icon(
                      Icons.location_on,
                      color: _getAQIColor(data.aqi),
                    ),
                    onTap: () => _showAirQualityDetails(data),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMapHeader() {
    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.air, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Air Quality Map',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        kIsWeb
                            ? 'Showing air quality data for major cities'
                            : 'Tap markers for detailed AQI information',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppTheme.primaryColor),
                  onSelected: _handleMenuSelection,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'trends',
                      child: Row(
                        children: [
                          Icon(Icons.trending_up, size: 20),
                          SizedBox(width: 8),
                          Text('Historical Trends'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'forecast',
                      child: Row(
                        children: [
                          Icon(Icons.cloud_queue, size: 20),
                          SizedBox(width: 8),
                          Text('3-Day Forecast'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'health',
                      child: Row(
                        children: [
                          Icon(Icons.favorite, size: 20),
                          SizedBox(width: 8),
                          Text('Health Advisory'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'notifications',
                      child: Row(
                        children: [
                          Icon(Icons.notifications, size: 20),
                          SizedBox(width: 8),
                          Text('Notification Settings'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Quick access buttons
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.trending_up,
                    label: 'Trends',
                    onTap: () => _handleMenuSelection('trends'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.cloud_queue,
                    label: 'Forecast',
                    onTap: () => _handleMenuSelection('forecast'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.favorite,
                    label: 'Health',
                    onTap: () => _handleMenuSelection('health'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 16),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuSelection(String value) {
    // Default values for current location
    final String locationName = 'Current Location';
    final double latitude = _currentLocation.latitude;
    final double longitude = _currentLocation.longitude;
    final int currentAQI = 75; // Default AQI value

    switch (value) {
      case 'trends':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoricalTrendsScreen(
              locationName: locationName,
              latitude: latitude,
              longitude: longitude,
            ),
          ),
        );
        break;
      case 'forecast':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForecastDashboardScreen(
              locationName: locationName,
              latitude: latitude,
              longitude: longitude,
            ),
          ),
        );
        break;
      case 'health':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HealthAdvisoryScreen(
              locationName: locationName,
              latitude: latitude,
              longitude: longitude,
              currentAQI: currentAQI,
            ),
          ),
        );
        break;
      case 'notifications':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationSettingsScreen(),
          ),
        );
        break;
    }
  }

  Widget _buildLocationButton() {
    return Positioned(
      bottom: 100,
      right: 16,
      child: FloatingActionButton(
        onPressed: () async {
          try {
            final position = await _locationService.getCurrentLocation();
            final newLocation = LatLng(position.latitude, position.longitude);

            if (_mapController != null && !_disposed) {
              await _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(newLocation, 12.0),
              );
            }

            _safeSetState(() {
              _currentLocation = newLocation;
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location updated'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            debugPrint('Location button error: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Unable to get current location. Please check location permissions.',
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
