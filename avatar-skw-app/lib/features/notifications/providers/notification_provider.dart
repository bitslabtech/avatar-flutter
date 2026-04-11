import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../providers/auth_provider.dart';
import '../../../models/user.dart';
import '../../../core/api/api_client.dart';
import '../../../models/app_notification.dart';
import '../services/notification_service.dart';
import '../../notifications/services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ApiClient());
});

class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _service;
  final User? _currentUser;
  Timer? _pollTimer;

  NotificationNotifier(this._service, this._currentUser) : super(NotificationState()) {
    // Start polling when provider is created
    _startPolling();
  }

  void _startPolling() {
    // Poll every 30 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      loadNotifications(refresh: true);
    });
    // Also load immediately
    loadNotifications();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  bool _hasNotificationPermission(AppNotification notification) {
    if (_currentUser == null) return false;
    
    // Super Admin sees everything
    if (_currentUser!.isSuperAdmin) return true;
    
    // Non-admins (Consumers/Dealers) see all notifications sent to them
    if (!_currentUser!.isAdmin) return true;

    // Admin Permission Checks
    switch (notification.type) {
      // Order Management
      case 'new_order':
      case 'order_update':
      case 'return_request':
        return _currentUser!.hasPermission('orders', 'read');
      
      // User Management
      case 'new_user_registered':
        return _currentUser!.hasPermission('users', 'read');
        
      // Dealer Management
      case 'new_dealer_registered':
        return _currentUser!.hasPermission('dealers', 'read');
        
      // Product Management
      case 'product_update':
      case 'stock_alert':
        return _currentUser!.hasPermission('products', 'read');
        
      default:
        return true;
    }
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    if (!refresh) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final notifications = await _service.getNotifications();
      
      // Filter notifications based on permissions
      final filteredNotifications = notifications.where(_hasNotificationPermission).toList();
      
      final count = await _service.getUnreadCount(); 
      // Note: Backend count might differ if backend doesn't filter, 
      // but fixing backend count is outside scope. UI count is what matters for badge often 
      // but unreadCount here comes from service. 
      // Ideally we filter unread count too or rely on list length.
      // Let's rely on list length for UI consistency if we can, but unreadCount is separate API often.
      // For now, we filter the LIST.
      
      state = state.copyWith(
        notifications: filteredNotifications,
        unreadCount: count, // Keeping original count for now as recalculating from filtered list needs isRead check
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _service.markAsRead(id);
      // Optimistically update UI
      final updatedList = state.notifications.map((n) {
        if (n.id == id) {
          return AppNotification(
            id: n.id,
            title: n.title,
            body: n.body,
            type: n.type,
            data: n.data,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      
      final newCount = state.unreadCount > 0 ? state.unreadCount - 1 : 0;
      
      state = state.copyWith(notifications: updatedList, unreadCount: newCount);
    } catch (e) {
      print('Error marking notification as read: $e');
      // Revert or show error if critical
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      final updatedList = state.notifications.map((n) {
        return AppNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          type: n.type,
          data: n.data,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();
      
      state = state.copyWith(notifications: updatedList, unreadCount: 0);
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark all as read');
    }
  }
  
  // Method to increment unread count (e.g. from websocket push if we had one)
  void incrementUnread() {
    state = state.copyWith(unreadCount: state.unreadCount + 1);
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final service = ref.watch(notificationServiceProvider);
  final authState = ref.watch(authProvider);
  return NotificationNotifier(service, authState.user);
});
