import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/air_quality_provider.dart';
import '../../widgets/air_quality_card.dart';
import '../../widgets/forecast_chart.dart';
import '../../widgets/health_recommendations.dart';
import 'map_screen.dart';
import 'forecast_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AirQualityProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      const MapScreen(),
      const ForecastScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomePage() {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.primaryLinearGradient),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Provider.of<AirQualityProvider>(
              context,
              listen: false,
            ).refreshData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildCurrentAQI(),
                const SizedBox(height: 20),
                _buildPollutantsGrid(),
                const SizedBox(height: 20),
                _buildQuickForecast(),
                const SizedBox(height: 20),
                const HealthRecommendations(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${authProvider.currentUser?.name.split(' ').first ?? 'User'}!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Consumer<AirQualityProvider>(
                  builder: (context, provider, child) {
                    return Text(
                      provider.currentLocationName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    );
                  },
                ),
              ],
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: AppTheme.textPrimaryColor,
                onPressed: () {
                  // Handle notifications
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentAQI() {
    return Consumer<AirQualityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.currentAirQuality == null) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          );
        }

        if (provider.currentAirQuality == null) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: Text('Unable to load air quality data')),
          );
        }

        return AirQualityCard(airQuality: provider.currentAirQuality!);
      },
    );
  }

  Widget _buildPollutantsGrid() {
    return Consumer<AirQualityProvider>(
      builder: (context, provider, child) {
        if (provider.currentAirQuality == null) {
          return const SizedBox.shrink();
        }

        final pollutants = provider.currentAirQuality!.pollutants;
        final pollutantWidgets = pollutants.entries.map((entry) {
          return _buildPollutantCard(entry.key, entry.value);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Air Quality Components',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: pollutantWidgets,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPollutantCard(String pollutantKey, double value) {
    final pollutantNames = {
      'pm2_5': 'PM2.5',
      'pm10': 'PM10',
      'o3': 'O₃',
      'no2': 'NO₂',
      'so2': 'SO₂',
      'co': 'CO',
    };

    final units = {
      'pm2_5': 'μg/m³',
      'pm10': 'μg/m³',
      'o3': 'μg/m³',
      'no2': 'μg/m³',
      'so2': 'μg/m³',
      'co': 'mg/m³',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardLinearGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pollutantNames[pollutantKey] ?? pollutantKey.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const Spacer(),
          Text(
            value.toStringAsFixed(1),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          Text(
            units[pollutantKey] ?? '',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickForecast() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '24-Hour Forecast',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentIndex = 2; // Navigate to forecast tab
                });
              },
              child: Text(
                'View All',
                style: TextStyle(
                  color: AppTheme.secondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const ForecastChart(showHourly: true),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.surfaceColor.withValues(alpha: 0.8),
            AppTheme.surfaceColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins'),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up_outlined),
            activeIcon: Icon(Icons.trending_up),
            label: 'Forecast',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
