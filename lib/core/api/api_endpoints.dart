/// Centralized API endpoint constants
/// All API routes are defined here for easy maintenance and updates
///
/// To configure the backend URL, pass it via --dart-define at run time:
///   flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000
///
/// Or in VS Code launch.json:
///   "args": ["--dart-define=API_BASE_URL=http://192.168.x.x:3000"]
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // -------------------------------------------------------------------
  // Base URL resolution order:
  //   1. --dart-define=API_BASE_URL=... (developer-supplied at run time)
  //   2. Platform-specific fallback (localhost / Android emulator IP)
  // -------------------------------------------------------------------
  static const String _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    // Use explicitly provided URL first (recommended for all environments)
    if (_definedBaseUrl.isNotEmpty) return _definedBaseUrl;

    // Fallback defaults — suitable for local development only
    if (kIsWeb) {
      return 'http://c12s275hwvq1m8uhll3xzio7.187.127.171.15.sslip.io/';
    } else if (Platform.isAndroid) {
      return 'http://c12s275hwvq1m8uhll3xzio7.187.127.171.15.sslip.io/'; 
    } else {
      return 'http://c12s275hwvq1m8uhll3xzio7.187.127.171.15.sslip.io/';
    }
  }

  /// Resolves a possibly-relative image path to a full URL.
  /// If the URL already starts with http/https it is returned as-is.
  static String resolveImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    // Strip trailing slash from base URL and leading slash from path to avoid doubles
    final base = baseUrl.replaceAll(RegExp(r'/$'), '');
    final relativePath = path.startsWith('/') ? path : '/$path';
    return '$base$relativePath';
  }

  // Authentication endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resetPassword = '/auth/reset-password';

  // Product/Catalog endpoints
  static const String products = '/products';
  static String productById(String id) => '/products/$id';
  static const String brands = '/products/meta/brands';
  static const String categories = '/products/meta/categories';
  static const String banners = '/products/banners';
  static String productsByGroup(String groupId) => '/products/group/$groupId';

  // Order endpoints
  static const String orderDraft = '/orders/draft';
  static const String cartItems = '/orders/cart/items';
  static String cartItem(String productId) => '/orders/cart/items/$productId';
  static const String orders = '/orders';
  static const String orderConfirm = '/orders/confirm';
  static String orderById(String id) => '/orders/$id';
  static String orderInvoice(String id) => '/orders/$id/proforma.pdf';

  // User endpoints
  static const String userMe = '/users/me';

  // Settings endpoints
  static const String settings = '/settings';

  // Admin endpoints
  static const String adminBanners = '/admin/banners';
  static const String adminBannersReorder = '/admin/banners/reorder';
  static String adminBannerById(String id) => '/admin/banners/$id';

  // Admin Categories
  static const String adminCategories = '/admin/categories';
  static const String adminCategoriesReorder = '/admin/categories/reorder';
  static String adminCategoryById(String id) => '/admin/categories/$id';

  // Address endpoints
  static const String addresses = '/addresses';
  static String addressById(String id) => '/addresses/$id';
  
  // Admin address endpoints (for fetching/creating addresses for specific users)
  static String addressesByUserId(String userId) => '/addresses/user/$userId';

  // Private constructor to prevent instantiation
  ApiEndpoints._();
}
