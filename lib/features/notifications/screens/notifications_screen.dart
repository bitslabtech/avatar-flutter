import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/app_notification.dart';
import '../../notifications/providers/notification_provider.dart'; // Correct relative import if needed or absolute
import '../../../widgets/common/loading_indicator.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String? _expandedNotificationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadNotifications();
    });
  }

  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Filter notifications
    final unreadNotifications = state.notifications.where((n) => !n.isRead).toList();
    final readNotifications = state.notifications.where((n) => n.isRead).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Modern Header
            _buildModernHeader(isDark, unreadNotifications.isNotEmpty),
            
            const SizedBox(height: 16),
            
            // 2. Custom Sliding Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCustomTabBar(isDark, unreadNotifications.length),
            ),
            
            const SizedBox(height: 20),

            // 3. Content
            Expanded(
              child: state.isLoading && state.notifications.isEmpty
                  ? Center(child: LoadingIndicator())
                  : state.error != null
                      ? _buildErrorState(state.error!)
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _selectedTabIndex == 0
                                ? _buildNotificationList(unreadNotifications, isDark, isUnreadList: true)
                                : _buildNotificationList(readNotifications, isDark, isUnreadList: false),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTabBar(bool isDark, int unreadCount) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Sliding Pill
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: _selectedTabIndex == 0 ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Tab Labels
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = 0),
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Unread',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _getTabTextColor(isDark, 0),
                            fontSize: 14,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 0 ? AppColors.primaryBlue : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = 1),
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: Text(
                      'Read',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _getTabTextColor(isDark, 1),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Color _getTabTextColor(bool isDark, int index) {
    if (_selectedTabIndex == index) {
      return isDark ? Colors.white : Colors.black87;
    }
    return isDark ? Colors.grey.shade500 : Colors.grey.shade600;
  }

  Widget _buildNotificationList(List<AppNotification> notifications, bool isDark, {required bool isUnreadList}) {
    if (notifications.isEmpty) {
      return _buildEmptyState(isDark, isUnreadList ? 'All caught up!' : 'No read notifications');
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationProvider.notifier).loadNotifications(refresh: true),
      child: ListView.separated(
        key: ValueKey<int>(_selectedTabIndex), // Force rebuild on tab switch
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildPremiumNotificationCard(
            notification, 
            isDark, 
            isUnread: !notification.isRead
          );
        },
      ),
    );
  }

  Widget _buildModernHeader(bool isDark, bool hasUnread) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black87,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
          ),
          
          // Centered Title
          Text(
            'Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),

          // Action Button (or placeholder for balance)
          if (hasUnread)
            IconButton(
              onPressed: () {
                ref.read(notificationProvider.notifier).markAllAsRead();
              },
              tooltip: 'Mark all as read',
              icon: Icon(
                Icons.done_all_rounded,
                color: AppColors.primaryBlue,
                size: 22,
              ),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                padding: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else
             const SizedBox(width: 44), // Spacer to balance back button
        ],
      ),
    );
  }

  Widget _buildPremiumNotificationCard(AppNotification notification, bool isDark, {required bool isUnread}) {
    final iconData = _getIconData(notification.type);
    final isExpanded = _expandedNotificationId == notification.id;
    
    return Container(
      key: ValueKey(notification.id),
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedNotificationId = isExpanded ? null : notification.id;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: isUnread 
              ? Border.all(color: AppColors.primaryBlue.withOpacity(0.3), width: 1.5)
              : Border.all(color: Colors.transparent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconData.backgroundColor.withOpacity(isDark ? 0.15 : 0.6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      iconData.icon,
                      color: iconData.color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Content Header
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                                  height: 1.2,
                                ),
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                              )
                            ]
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatRelativeTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Body Text
              Padding(
                padding: const EdgeInsets.only(left: 64), // Align with text start
                child: Text(
                  notification.body,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF4A4A4A),
                    height: 1.5,
                  ),
                  maxLines: isExpanded ? null : 2,
                  overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
              ),

              // Action Buttons
              if (isExpanded) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 64, right: 8), // Add right padding to prevent overflow
                  child: Row(
                    children: [
                      // Mark as Read Button (Left)
                      if (isUnread)
                        Flexible(
                          child: TextButton.icon(
                            onPressed: () {
                              ref.read(notificationProvider.notifier).markAsRead(notification.id);
                            },
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text('Mark as Read'),
                            style: TextButton.styleFrom(
                              foregroundColor: isDark ? Colors.grey[300] : const Color(0xFF4A4A4A),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      
                      // Spacing between buttons
                      if (isUnread && notification.data != null && notification.data!['orderId'] != null)
                        const SizedBox(width: 8),

                      // View Details Button (Right)
                      if (notification.data != null && notification.data!['orderId'] != null)
                        Flexible(
                          child: TextButton.icon(
                            onPressed: () => _handleNavigation(context, notification),
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                            label: const Text('View Details'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryBlue,
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState(String error) {
    final lowerError = error.toLowerCase();
    final isAuthError = lowerError.contains('401') || 
                        lowerError.contains('authentication') ||
                        lowerError.contains('unauthorized') ||
                        lowerError.contains('bad response') && lowerError.contains('null'); // Covers DioException [bad response]: null

    if (isAuthError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_clock_outlined, size: 48, color: Colors.red),
              ),
              const SizedBox(height: 24),
              const Text(
                'Session Expired',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your authentication session has expired. Please login again to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Clear auth state if possible or just navigate
                    // Ideally we should logout, but navigation forces new login flow
                    context.go('/auth-choice'); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Login Again',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Error: $error', 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(notificationProvider.notifier).loadNotifications(refresh: true),
            child: const Text('Retry'),
          )
        ],
      ),
    );
  }


  // Helper methods like _getIconData, _formatRelativeTime, _handleNavigation remain same but need to be outside class if I replace whole class, or I can just leave them if I replace build method and helpers.
  // The replace tool instruction was to replace "body". Let's assume I am replacing from `build` method down to `_handleNavigation`.
  // Wait, I need to be careful not to delete the helper methods if they are not included in my ReplacementContent.
  // My ReplacementContent starts at `Widget build` and ends at `return Container(...)` of _buildNotificationCard.
  // Actually I'm replacing lines 27 to 435. I must include all helpers.

  NotificationIconData _getIconData(String type) {
    switch (type) {
      case 'order_update':
      case 'new_order':
        return NotificationIconData(
          icon: Icons.local_shipping_rounded,
          color: const Color(0xFF136DEC),
          backgroundColor: const Color(0xFFDCEBFF),
        );
      case 'promotion':
        return NotificationIconData(
          icon: Icons.percent_rounded,
          color: const Color(0xFFEA580C),
          backgroundColor: const Color(0xFFFFEDD5),
        );
      case 'account_update':
        return NotificationIconData(
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF16A34A),
          backgroundColor: const Color(0xFFDCFCE7),
        );
      case 'cart_reminder':
        return NotificationIconData(
          icon: Icons.shopping_cart_rounded,
          color: const Color(0xFFEAB308),
          backgroundColor: const Color(0xFFFEF3C7),
        );
      case 'system_alert':
        return NotificationIconData(
          icon: Icons.security_rounded,
          color: const Color(0xFF6B7280),
          backgroundColor: const Color(0xFFF3F4F6),
        );
      default:
        return NotificationIconData(
          icon: Icons.notifications_rounded,
          color: const Color(0xFF8B5CF6),
          backgroundColor: const Color(0xFFF3E8FF),
        );
    }
  }

  String _formatRelativeTime(DateTime time) {
    // Requested format: DD-MM-YYYY
    return '${time.day.toString().padLeft(2, '0')}-${time.month.toString().padLeft(2, '0')}-${time.year}';
  }

  void _handleNavigation(BuildContext context, AppNotification notification) {
    if (notification.data != null && notification.data!['orderId'] != null) {
      final orderId = notification.data!['orderId'];
      
      if (notification.type == 'new_order') {
        try {
          context.pushNamed('admin-order-detail', pathParameters: {'id': orderId});
        } catch (e) {
          debugPrint('Navigation error: $e');
        }
      } else {
        try {
          context.pushNamed('order-detail', pathParameters: {'id': orderId});
        } catch (e) {
          debugPrint('Navigation error: $e');
        }
      }
    }
  }
}

class NotificationIconData {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  NotificationIconData({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });
}
