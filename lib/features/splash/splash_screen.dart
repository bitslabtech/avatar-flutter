/// Animated splash screen with kitchen appliance silhouettes
/// Apple-style minimalist animation sequence
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _logoController;
  late AnimationController _loadingController;

  // Silhouette animations
  late Animation<double> _silhouetteOpacity;
  late Animation<double> _silhouetteFade;

  // Logo animations
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _logoPosition;

  // Wordmark animations
  late Animation<double> _wordmarkOpacity;

  // Tagline animations
  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglinePosition;

  // Loading indicator animation
  late Animation<double> _loadingOpacity;

  @override
  void initState() {
    super.initState();

    // Main animation controller (2 seconds total)
    _mainController = AnimationController(
      duration: AppConstants.splashAnimationDuration,
      vsync: this,
    );

    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Loading indicator controller
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // Step 1: Silhouettes fade in (0-0.3s = 0.0-0.15 of 2s duration)
    _silhouetteOpacity = Tween<double>(begin: 0.0, end: 0.15).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.15, curve: Curves.easeIn), // 0.3s / 2.0s = 0.15
      ),
    );

    // Silhouettes fade down further (0.5-1.0s = 0.25-0.5 of 2s duration)
    _silhouetteFade = Tween<double>(begin: 0.15, end: 0.05).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.25, 0.5, curve: Curves.easeOut), // 0.5s/2.0s=0.25, 1.0s/2.0s=0.5
      ),
    );

    // Step 2: Logo scales in and moves up (0.3-0.7s)
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOut,
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeIn,
      ),
    );

    _logoPosition = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOut,
      ),
    );

    // Step 3: Wordmark fades in (0.6-0.9s = 0.3-0.45 of 2s duration)
    _wordmarkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.45, curve: Curves.easeIn), // 0.6s/2.0s=0.3, 0.9s/2.0s=0.45
      ),
    );

    // Step 4: Tagline slides in (0.8-1.2s = 0.4-0.6 of 2s duration)
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.6, curve: Curves.easeIn), // 0.8s/2.0s=0.4, 1.2s/2.0s=0.6
      ),
    );

    _taglinePosition = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.6, curve: Curves.easeOut), // Same as above
      ),
    );

    // Step 5: Loading indicator fades in (1.2-1.5s = 0.6-0.75 of 2s duration)
    _loadingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 0.75, curve: Curves.easeIn), // 1.2s/2.0s=0.6, 1.5s/2.0s=0.75
      ),
    );
  }

  void _startAnimationSequence() {
    // Start main controller
    _mainController.forward();

    // Start logo animation after delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _logoController.forward();
      }
    });

    // Navigate after animation completes
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNextScreen();
      }
    });
  }

  Future<void> _navigateToNextScreen() async {
    // Wait a bit for loading indicator to show
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Check if onboarding has been seen
    final prefs = await SharedPreferences.getInstance();
    final onboardingSeen = prefs.getBool(AppConstants.onboardingSeenKey) ?? false;

    if (!mounted) return; // Check again after async operation

    // First time users see onboarding, then go to home
    // After that, always go to home (guest or authenticated)
    if (!onboardingSeen) {
      // First time - show onboarding
      if (mounted) context.go('/onboarding');
    } else {
      // Go to auth choice screen (router will redirect to home if already authenticated)
      if (mounted) context.go('/auth-choice');
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _logoController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          return Stack(
            children: [
              // Step 1: Kitchen appliance silhouettes (very subtle)
              _buildSilhouettes(context),

              // Center content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Step 2: Avatar logo (red A/swoosh)
                    _buildLogo(),

                    const SizedBox(height: 16),

                    // Step 3: AVATAR wordmark
                    _buildWordmark(context),

                    const SizedBox(height: 12),

                    // Step 4: Tagline
                    _buildTagline(context),

                    const SizedBox(height: 40),

                    // Step 5: Loading indicator
                    _buildLoadingIndicator(context),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSilhouettes(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        // Use the lower of the two opacity values (fade in, then fade down)
        final opacity = _silhouetteFade.value < _silhouetteOpacity.value
            ? _silhouetteFade.value
            : _silhouetteOpacity.value;

        return Opacity(
          opacity: opacity,
          child: Stack(
            children: [
              // Pot silhouette (top-left)
              Positioned(
                left: 50,
                top: 150,
                child: Icon(
                  Icons.soup_kitchen,
                  size: 80,
                  color: isDark ? AppColors.textTertiary : Colors.grey[400],
                ),
              ),
              // Pan silhouette (top-right)
              Positioned(
                right: 50,
                top: 180,
                child: Icon(
                  Icons.set_meal,
                  size: 70,
                  color: isDark ? AppColors.textTertiary : Colors.grey[400],
                ),
              ),
              // Mixer silhouette (bottom-left)
              Positioned(
                left: 80,
                bottom: 200,
                child: Icon(
                  Icons.blender,
                  size: 60,
                  color: isDark ? AppColors.textTertiary : Colors.grey[400],
                ),
              ),
              // Kettle silhouette (bottom-right)
              Positioned(
                right: 70,
                bottom: 180,
                child: Icon(
                  Icons.local_drink,
                  size: 65,
                  color: isDark ? AppColors.textTertiary : Colors.grey[400],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SlideTransition(
          position: _logoPosition,
          child: FadeTransition(
            opacity: _logoOpacity,
            child: ScaleTransition(
              scale: _logoScale,
              child: Image.asset(
                isDark
                    ? 'assets/logo/skw-avatar-favicon-white.png'
                    : 'assets/logo/skw-avatar-favicon.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWordmark(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: _wordmarkOpacity,
      child: Text(
        'AVATAR',
        style: TextStyle(
          color: isDark ? AppColors.textPrimary : Colors.black,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 4,
        ),
      ),
    );
  }

  Widget _buildTagline(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SlideTransition(
      position: _taglinePosition,
      child: FadeTransition(
        opacity: _taglineOpacity,
        child: Text(
          'From the house of SKW',
          style: TextStyle(
            color: isDark ? AppColors.textSecondary : Colors.grey[700],
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: _loadingOpacity,
      child: SizedBox(
        width: 40,
        height: 4,
        child: LinearProgressIndicator(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
          minHeight: 2,
        ),
      ),
    );
  }
}

