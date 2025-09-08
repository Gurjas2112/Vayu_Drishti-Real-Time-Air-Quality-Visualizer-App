import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vayudrishti/core/constants/app_colors.dart';
import 'package:vayudrishti/core/constants/app_strings.dart';
import 'package:vayudrishti/providers/auth_provider.dart';
import 'package:vayudrishti/providers/air_quality_provider.dart';
import 'package:vayudrishti/providers/location_provider.dart';
import 'package:vayudrishti/core/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      ],
      child: MaterialApp(
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
      ),
    );
  }
}
