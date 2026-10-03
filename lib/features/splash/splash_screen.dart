import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Video splash screen featuring Avatar brand animation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    // Use dark/immersive status bar for the video splash
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    // Safety fallback timer: auto-navigates if video takes too long or fails
    _fallbackTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted && !_hasNavigated) {
        _navigateToNextScreen();
      }
    });

    try {
      final controller = VideoPlayerController.asset(
        'assets/animations/avatar-skw-splash-screen.mp4',
      );
      _videoController = controller;

      await controller.initialize();
      if (!mounted) return;

      setState(() {
        _isVideoInitialized = true;
      });

      controller.setLooping(false);
      await controller.play();

      controller.addListener(_onVideoProgress);
    } catch (e) {
      debugPrint('Video splash initialization error: $e');
      // If video initialization fails (e.g., in test or unsupported hardware), fallback will navigate
      if (mounted && !_hasNavigated) {
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted && !_hasNavigated) {
            _navigateToNextScreen();
          }
        });
      }
    }
  }

  void _onVideoProgress() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    final position = controller.value.position;
    final duration = controller.value.duration;

    if (duration > Duration.zero && position >= duration) {
      controller.removeListener(_onVideoProgress);
      _navigateToNextScreen();
    }
  }

  Future<void> _navigateToNextScreen() async {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _fallbackTimer?.cancel();

    if (!mounted) return;

    // Check if onboarding has been seen
    final prefs = await SharedPreferences.getInstance();
    final onboardingSeen = prefs.getBool(AppConstants.onboardingSeenKey) ?? false;

    if (!mounted) return;

    // First time users see onboarding, then go to home
    if (!onboardingSeen) {
      if (mounted) context.go('/onboarding');
    } else {
      if (mounted) context.go('/home');
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    final controller = _videoController;
    if (controller != null) {
      controller.removeListener(_onVideoProgress);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _videoController;
    final isVideoReady = _isVideoInitialized &&
        controller != null &&
        controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Branding (shown while loading or as fallback)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo/skw-avatar-favicon-white.png',
                  width: 80,
                  height: 80,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.kitchen,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'AVATAR',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'KITCHEN & HOME APPLIANCES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 3,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          // Video Player
          if (isVideoReady)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),

          // Skip button (subtle top-right pill)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: GestureDetector(
              onTap: _navigateToNextScreen,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
