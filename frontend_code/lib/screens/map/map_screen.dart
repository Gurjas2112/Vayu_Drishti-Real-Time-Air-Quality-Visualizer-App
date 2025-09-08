import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vayudrishti/core/constants/app_colors.dart';
import 'package:vayudrishti/providers/location_provider.dart';
import 'package:vayudrishti/providers/air_quality_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _showHeatmap = true;
  String _mapType = 'normal';

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
          IconButton(
            icon: Icon(
              _showHeatmap ? Icons.layers : Icons.layers_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showHeatmap = !_showHeatmap;
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
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Map Info Banner
          _buildMapInfoBanner(),

          // Map placeholder (since Google Maps requires API key)
          Expanded(child: _buildMapPlaceholder()),

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
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        image: const DecorationImage(
          image: NetworkImage(
            'https://via.placeholder.com/800x600/E5E7EB/6B7280?text=Google+Maps+Integration',
          ),
          fit: BoxFit.cover,
          opacity: 0.3,
        ),
      ),
      child: Stack(
        children: [
          // Map type indicator
          Positioned(
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
              child: Text(
                _mapType == 'satellite' ? 'Satellite' : 'Normal',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // Center marker
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Consumer<AirQualityProvider>(
                  builder: (context, airQualityProvider, child) {
                    final currentAQI = airQualityProvider.currentAQI;
                    if (currentAQI == null) {
                      return const CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      );
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.getAQIColor(currentAQI.aqi),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.getAQIColor(
                              currentAQI.aqi,
                            ).withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 24,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Current Location',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // AQI Heatmap overlay indicator
          if (_showHeatmap)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'AQI Heatmap ON',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
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
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Google Maps Integration',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'To enable the map view, add your Google Maps API key to the project configuration.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
              onTap: () {
                // Center on current location
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Centered on your location'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
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
                // Refresh map data
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
