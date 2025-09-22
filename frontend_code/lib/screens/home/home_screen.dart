import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vayudrishti/core/constants/app_colors.dart';
import 'package:vayudrishti/core/constants/app_strings.dart';
import 'package:vayudrishti/providers/air_quality_provider.dart';
import 'package:vayudrishti/providers/location_provider.dart';
import 'package:vayudrishti/providers/auth_provider.dart';
import 'package:vayudrishti/core/backend_connection_service.dart';
import 'package:vayudrishti/widgets/aqi_card.dart';
import 'package:vayudrishti/widgets/pollutant_card.dart';
import 'package:vayudrishti/widgets/health_advisory_card.dart';
import 'package:vayudrishti/screens/profile/notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    final airQualityProvider = Provider.of<AirQualityProvider>(
      context,
      listen: false,
    );

    // Get location first
    final locationSuccess = await locationProvider.getCurrentLocation();

    if (locationSuccess &&
        locationProvider.latitude != null &&
        locationProvider.longitude != null) {
      // Fetch air quality data
      await airQualityProvider.fetchCurrentAQI(
        locationProvider.latitude!,
        locationProvider.longitude!,
      );
    }
  }

  Future<void> _refreshData() async {
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
      await airQualityProvider.refreshData(
        locationProvider.latitude!,
        locationProvider.longitude!,
      );
    } else {
      await _initializeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.primaryColor,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildWelcomeSection(),
                  const SizedBox(height: 16),
                  _buildConnectionStatusSection(),
                  const SizedBox(height: 20),
                  _buildMainAQICard(),
                  const SizedBox(height: 20),
                  _buildPollutantsSection(),
                  const SizedBox(height: 20),
                  _buildHealthAdvisorySection(),
                  const SizedBox(height: 20),
                  _buildQuickActionsSection(),
                  const SizedBox(height: 100), // Bottom padding for navigation
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Consumer2<LocationProvider, BackendConnectionService>(
      builder: (context, locationProvider, connectionService, child) {
        return SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.primaryColor,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
            title: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      AppStrings.appName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      connectionService.getConnectionStatusIcon(),
                      color: connectionService.getConnectionStatusColor(),
                      size: 16,
                    ),
                  ],
                ),
                Text(
                  locationProvider.currentAddress ?? 'Getting location...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshData,
            ),
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildConnectionStatusSection() {
    return Consumer<BackendConnectionService>(
      builder: (context, connectionService, child) {
        // Only show if there are connection issues
        if (connectionService.hasAnyConnection &&
            connectionService.errorMessage == null) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: connectionService.hasAnyConnection
                ? Colors.orange.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: connectionService.hasAnyConnection
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Colors.red.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                connectionService.getConnectionStatusIcon(),
                color: connectionService.getConnectionStatusColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connectionService.getConnectionStatusSummary(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: connectionService.getConnectionStatusColor(),
                      ),
                    ),
                    if (connectionService.errorMessage != null)
                      Text(
                        connectionService.errorMessage!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (!connectionService.hasAnyConnection)
                TextButton(
                  onPressed: () => connectionService.retryConnections(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(0, 0),
                  ),
                  child: const Text('Retry', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final displayName = user?.displayName ?? 'User';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppStrings.welcome}, $displayName!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Stay informed about air quality in your area',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.air,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainAQICard() {
    return Consumer<AirQualityProvider>(
      builder: (context, airQualityProvider, child) {
        if (airQualityProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }

        if (airQualityProvider.errorMessage != null) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.errorColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.errorColor,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  airQualityProvider.errorMessage!,
                  style: const TextStyle(
                    color: AppColors.errorColor,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final aqiData = airQualityProvider.currentAQI;
        if (aqiData == null) {
          return const Center(child: Text('No data available'));
        }

        return AQICard(aqiData: aqiData);
      },
    );
  }

  Widget _buildPollutantsSection() {
    return Consumer<AirQualityProvider>(
      builder: (context, airQualityProvider, child) {
        final aqiData = airQualityProvider.currentAQI;
        if (aqiData == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Air Pollutants',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: aqiData.pollutants.length,
              itemBuilder: (context, index) {
                final pollutant = aqiData.pollutants.keys.elementAt(index);
                final value = aqiData.pollutants[pollutant]!;
                return PollutantCard(
                  name: pollutant,
                  value: value,
                  unit: _getPollutantUnit(pollutant),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHealthAdvisorySection() {
    return Consumer<AirQualityProvider>(
      builder: (context, airQualityProvider, child) {
        final aqiData = airQualityProvider.currentAQI;
        if (aqiData == null) return const SizedBox.shrink();

        return HealthAdvisoryCard(aqi: aqiData.aqi, category: aqiData.category);
      },
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.map_outlined,
                title: 'View Map',
                subtitle: 'See AQI heatmap',
                onTap: () {
                  // Navigate to map tab
                  DefaultTabController.of(context).animateTo(1);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.trending_up_outlined,
                title: 'Forecast',
                subtitle: '24hr prediction',
                onTap: () {
                  // Navigate to forecast tab
                  DefaultTabController.of(context).animateTo(2);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPollutantUnit(String pollutant) {
    switch (pollutant) {
      case 'CO':
        return 'mg/m³';
      default:
        return 'μg/m³';
    }
  }
}
