import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vayudrishti/core/constants/app_colors.dart';
import 'package:vayudrishti/core/constants/app_strings.dart';
import 'package:vayudrishti/providers/auth_provider.dart';
import 'package:vayudrishti/providers/air_quality_provider.dart';
import 'package:vayudrishti/providers/location_provider.dart';
import 'package:vayudrishti/providers/notification_provider.dart';
import 'package:vayudrishti/core/routes/app_routes.dart';
import 'package:vayudrishti/core/backend_connection_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // Initialize backend connection service
  WidgetsBinding.instance.addPostFrameCallback((_) {
    BackendConnectionService.instance.initialize();
  });

  runApp(const VayuDrishtiApp());
}

class VayuDrishtiApp extends StatelessWidget {
  const VayuDrishtiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AirQualityProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider.value(value: BackendConnectionService.instance),
      ],
      child: Builder(
        builder: (context) {
          // Initialize NotificationProvider after all providers are available
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final notificationProvider = Provider.of<NotificationProvider>(
              context,
              listen: false,
            );
            final airQualityProvider = Provider.of<AirQualityProvider>(
              context,
              listen: false,
            );
            final locationProvider = Provider.of<LocationProvider>(
              context,
              listen: false,
            );

            if (!notificationProvider.isInitialized) {
              notificationProvider.initialize(
                backendService: BackendConnectionService.instance,
                airQualityProvider: airQualityProvider,
                locationProvider: locationProvider,
              );
            }
          });

          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primaryColor: AppColors.primaryColor,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primaryColor,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
              ),
            ),
            initialRoute: AppRoutes.splash,
            routes: AppRoutes.routes,
          );
        },
      ),
    );
  }
}
