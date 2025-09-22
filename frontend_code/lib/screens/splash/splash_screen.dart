import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vayudrishti/core/constants/app_colors.dart';
import 'package:vayudrishti/core/constants/app_strings.dart';
import 'package:vayudrishti/core/routes/app_routes.dart';
import 'package:vayudrishti/providers/auth_provider.dart';
import 'package:vayudrishti/core/backend_connection_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late AnimationController _textController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _progressValue;
  late Animation<double> _textOpacity;

  String _currentText = AppStrings.initializingConnection;

  final List<String> _loadingTexts = [
    AppStrings.initializingConnection,
    'Connecting to backend services...',
    'Checking API connectivity...',
    'Setting up real-time updates...',
    AppStrings.connectingToServers,
    AppStrings.loadingData,
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startLoadingSequence();
  }

  void _initializeAnimations() {
    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    // Progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );
  }

  void _startLoadingSequence() async {
    // Start logo animation
    await _logoController.forward();

    // Wait a bit then start progress and text animations
    await Future.delayed(const Duration(milliseconds: 500));

    _textController.forward();
    _progressController.forward();

    // Change loading text periodically while initializing backend
    _changeLoadingText();

    // Initialize backend services for authenticated users
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      await _initializeBackendServices();
    }

    // Wait for animations to complete
    await Future.delayed(const Duration(milliseconds: 2000));

    // Navigate to appropriate screen
    _navigateToNextScreen();
  }

  Future<void> _initializeBackendServices() async {
    try {
      if (!mounted) return;

      final backendService = Provider.of<BackendConnectionService>(
        context,
        listen: false,
      );

      // Update text to show backend initialization
      setState(() {
        _currentText = 'Initializing backend services...';
      });

      // Initialize backend connections
      await backendService.initialize();

      if (!mounted) return;

      // Update text based on connection status
      if (backendService.hasAnyConnection) {
        setState(() {
          _currentText = 'Backend services ready!';
        });
      } else {
        setState(() {
          _currentText = 'Running in offline mode';
        });
      }

      // Wait a moment to show the status
      await Future.delayed(const Duration(milliseconds: 1000));
    } catch (e) {
      // Handle any errors gracefully
      if (mounted) {
        setState(() {
          _currentText = 'Starting in offline mode...';
        });
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }
  }

  void _changeLoadingText() async {
    // Show initial loading texts faster
    for (int i = 0; i < 3 && i < _loadingTexts.length; i++) {
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        await _textController.reverse();
        setState(() {
          _currentText = _loadingTexts[i];
        });
        await _textController.forward();
      }
    }
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.mainNavigation);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(
                              opacity: _logoOpacity.value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.satellite_alt,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      // App Name
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _logoOpacity.value,
                            child: Column(
                              children: [
                                Text(
                                  AppStrings.appName,
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.3,
                                        ),
                                        offset: const Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  AppStrings.tagline,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    letterSpacing: 1,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  AppStrings.subtitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Loading Section
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Loading Text
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _textOpacity.value,
                            child: Text(
                              _currentText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      // Progress Bar
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return Column(
                            children: [
                              LinearProgressIndicator(
                                value: _progressValue.value,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.3,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withValues(alpha: 0.9),
                                ),
                                minHeight: 4,
                              ),

                              const SizedBox(height: 10),

                              Text(
                                '${(_progressValue.value * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
