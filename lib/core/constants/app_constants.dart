/// App-wide constants for Avatar Flutter app
/// Centralized configuration values used throughout the application
class AppConstants {
  // API Configuration
  // Base URL for the backend API - can be overridden via environment
  static const String baseUrl = 'http://192.168.31.211:3000';
  
  // API Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user';
  static const String onboardingSeenKey = 'onboarding_seen';
  
  // Animation Durations
  static const Duration splashAnimationDuration = Duration(milliseconds: 2000);
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Private constructor to prevent instantiation
  AppConstants._();
}

