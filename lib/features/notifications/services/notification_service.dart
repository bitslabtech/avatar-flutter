import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../models/app_notification.dart';

class NotificationService {
  final ApiClient _apiClient;

  NotificationService(this._apiClient);

  Future<List<AppNotification>> getNotifications({int limit = 20, int offset = 0}) async {
    try {
      final response = await _apiClient.dio.get(
        '/notifications',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final List data = response.data['data'];
      return data.map((e) => AppNotification.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.dio.get('/notifications/unread-count');
      return response.data['count'];
    } catch (e) {
      return 0; // Fail silently
    }
  }

  Future<void> markAsRead(String id) async {
    await _apiClient.dio.patch('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _apiClient.dio.patch('/notifications/read-all');
  }
}
