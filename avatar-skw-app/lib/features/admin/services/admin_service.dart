import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../models/banner.dart';
import '../../../models/category.dart' as models;

class AdminService {
  final ApiClient _apiClient;

  AdminService(this._apiClient);

  /// Create a new banner
  Future<Banner> createBanner(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.adminBanners,
        data: data,
      );
      return Banner.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update an existing banner
  Future<Banner> updateBanner(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.patch(
        ApiEndpoints.adminBannerById(id),
        data: data,
      );
      return Banner.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete a banner
  Future<void> deleteBanner(String id) async {
    try {
      await _apiClient.dio.delete(ApiEndpoints.adminBannerById(id));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all banners (admin view, includes inactive)
  Future<List<Banner>> getBanners() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.adminBanners);
      final List<dynamic> data = response.data;
      return data.map((json) => Banner.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Reorder banners
  Future<void> reorderBanners(List<String> ids) async {
    try {
      await _apiClient.dio.patch(
        ApiEndpoints.adminBannersReorder,
        data: {'ids': ids},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response?.statusCode == 403) {
      return Exception('Permission Denied: You do not have access to perform this action.');
    }
    return Exception(
      e.response?.data['message'] ?? e.message ?? 'An error occurred',
    );
  }

  // Categories
  Future<List<models.Category>> getCategories() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.adminCategories);
      final List<dynamic> data = response.data;
      return data.map((json) => models.Category.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<models.Category> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.patch(
        ApiEndpoints.adminCategoryById(id),
        data: data,
      );
      return models.Category.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> reorderCategories(List<Map<String, dynamic>> orders) async {
    try {
      await _apiClient.dio.patch(
        ApiEndpoints.adminCategoriesReorder,
        data: orders,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _apiClient.dio.get('/admin/orders/dashboard');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Admin Management
  Future<List<dynamic>> getAdmins() async {
    try {
      final response = await _apiClient.dio.get('/users/admins');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> createAdmin(Map<String, dynamic> data) async {
    try {
      await _apiClient.dio.post('/users/admins', data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateAdminPermissions(String id, Map<String, dynamic> permissions) async {
    try {
      await _apiClient.dio.patch('/users/admins/$id/permissions', data: {'permissions': permissions});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateAdminStatus(String id, String status) async {
    try {
      await _apiClient.dio.patch('/users/$id/status', data: {'status': status});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteAdmin(String id) async {
    try {
      await _apiClient.dio.delete('/users/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Audit Logs
  Future<List<dynamic>> getAuditLogs(String userId) async {
    try {
      final response = await _apiClient.dio.get('/audit-logs', queryParameters: {'userId': userId});
      final data = response.data;
      if (data is Map && data.containsKey('data')) {
        return data['data'];
      }
      return data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
