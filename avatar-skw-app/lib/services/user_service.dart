/// User service
/// Handles user profile management
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/user.dart';

class UserService {
  final ApiClient _apiClient;

  UserService(this._apiClient);

  /// Get current user profile
  Future<User> getProfile() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.userMe);
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update user profile
  Future<User> updateProfile({
    String? name,
    String? email,
    Map<String, dynamic>? address,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (address != null) data['address'] = address;

      final response = await _apiClient.dio.patch(
        ApiEndpoints.userMe,
        data: data,
      );
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle DioException and throw user-friendly error
  Exception _handleError(DioException e) {
    final message = e.response?.data['message'] ?? 
                   e.message ?? 
                   'An error occurred while updating your profile';
    return Exception(message);
  }
}

