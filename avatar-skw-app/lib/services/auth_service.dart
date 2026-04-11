/// Authentication service
/// Handles login, register, token refresh, and user management
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/constants/app_constants.dart';
import '../models/auth_response.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  /// Login with phone and password
  /// Returns AuthResponse with user and tokens
  Future<AuthResponse> login(String phone, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {
          'phone': phone,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);
      
      // Store tokens and user data
      await _storeAuthData(authResponse);
      
      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Register a new user
  /// Returns AuthResponse with user and tokens
  Future<AuthResponse> register({
    required String name,
    required String phone,
    required String password,
    String? email,
    String role = 'consumer',
    String? companyName,
    String? gstVat,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'phone': phone,
          'password': password,
          if (email != null) 'email': email,
          'role': role,
          if (companyName != null) 'companyName': companyName,
          if (gstVat != null) 'gstVat': gstVat,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);
      
      // Store tokens and user data
      await _storeAuthData(authResponse);
      
      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Refresh access token using refresh token
  Future<AuthResponse> refreshToken() async {
    try {
      const storage = FlutterSecureStorage();
      final refreshToken = await storage.read(key: AppConstants.refreshTokenKey);
      
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await _apiClient.dio.post(
        ApiEndpoints.refresh,
        data: {
          'refreshToken': refreshToken,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);
      
      // Update stored tokens
      await _storeAuthData(authResponse);
      
      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get current authenticated user
  Future<User> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.me);
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Logout - clear stored tokens and user data
  Future<void> logout() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: AppConstants.accessTokenKey);
    await storage.delete(key: AppConstants.refreshTokenKey);
    await storage.delete(key: AppConstants.userKey);
    await _apiClient.clearAuthToken();
  }

  /// Check if user is authenticated (has valid token)
  Future<bool> isAuthenticated() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: AppConstants.accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: AppConstants.accessTokenKey);
  }

  /// Store authentication data (tokens and user)
  Future<void> _storeAuthData(AuthResponse authResponse) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: AppConstants.accessTokenKey, value: authResponse.accessToken);
    await storage.write(key: AppConstants.refreshTokenKey, value: authResponse.refreshToken);
    await storage.write(key: AppConstants.userKey, value: authResponse.user.toJson().toString());
    
    // Update API client with new token
    await _apiClient.setAuthToken(authResponse.accessToken);
  }

  /// Upload User Avatar
  Future<User> uploadAvatar(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiClient.dio.post(
        '/users/upload-avatar', // Hardcoded for now matching controller
        data: formData,
      );
      
      final user = User.fromJson(response.data);
      
      // Update stored user data
      const storage = FlutterSecureStorage();
      await storage.write(key: AppConstants.userKey, value: user.toJson().toString());
      
      return user;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update user profile
  Future<User> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.patch(
        ApiEndpoints.userMe, 
        data: data,
      );
      
      final user = User.fromJson(response.data);
      
      // Update stored user data
      const storage = FlutterSecureStorage();
      await storage.write(key: AppConstants.userKey, value: user.toJson().toString());
      
      return user;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle DioException and throw user-friendly error
  Exception _handleError(DioException e) {
    final message = e.response?.data['message'] ?? 
                   e.message ?? 
                   'An error occurred during authentication';
    return Exception(message);
  }

  /// Request OTP for Password Reset
  Future<void> forgotPassword(String phone) async {
    try {
      await _apiClient.dio.post(
        ApiEndpoints.forgotPassword,
        data: {'phone': phone},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Verify OTP and get Reset Token
  Future<String> verifyOtp(String phone, String otp) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.verifyOtp,
        data: {'phone': phone, 'otp': otp},
      );
      // Backend returns { resetToken: '...' }
      return response.data['resetToken'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Reset Password using Token
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      await _apiClient.dio.post(
        ApiEndpoints.resetPassword,
        data: {'token': token, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}

