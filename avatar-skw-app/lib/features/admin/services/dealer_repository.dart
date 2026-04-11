import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../models/user.dart';

class DealerRepository {
  final ApiClient _apiClient;

  DealerRepository(this._apiClient);

  Future<List<User>> getDealers({String? status, bool showDeleted = false}) async {
    try {
      final response = await _apiClient.dio.get(
        '/users', // Using relative path as base URL is set
        queryParameters: {
          'role': 'dealer',
          if (status != null) 'status': status,
          if (showDeleted) 'showDeleted': 'true',
        },
      );
      
      return (response.data as List)
          .map((json) => User.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch dealers: ${e.toString()}');
    }
  }

  Future<User> updateDealerStatus(String userId, String status) async {
    try {
      Response response;
      if (status == 'approved') {
        response = await _apiClient.dio.post(
          '/users/dealers/$userId/approve',
          data: {},
        );
      } else if (status == 'rejected') {
        response = await _apiClient.dio.post(
          '/users/dealers/$userId/reject',
          data: {},
        );
      } else {
        response = await _apiClient.dio.patch(
          '/users/$userId/status',
          data: {'status': status},
        );
      }
      
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update dealer status: ${e.toString()}');
    }
  }

  Future<User> updateDealerProfile(String userId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.patch(
        '/users/dealers/$userId',
        data: data,
      );
      
      return User.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final message = e.response?.data['message'] ?? e.message;
        throw Exception(message);
      }
      throw Exception('Failed to update dealer profile: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update dealer profile: ${e.toString()}');
    }
  }
  Future<User> createDealer(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          ...data,
          'role': 'dealer',
        },
      );
      
      // Auto-approve the new dealer
      final userId = response.data['user']['id'];
      return await updateDealerStatus(userId, 'approved');
    } catch (e) {
      throw Exception('Failed to create dealer: ${e.toString()}');
    }
  }

  Future<void> deleteDealer(String userId) async {
    try {
      await _apiClient.dio.delete('/users/$userId');
    } catch (e) {
      throw Exception('Failed to delete dealer: ${e.toString()}');
    }
  }
}
