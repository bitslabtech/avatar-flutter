import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/app_notification.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../../widgets/common/loading_indicator.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String? _expandedNotificationId;
  int _selectedTabIndex = 0;
  final Set<String> _locallyReadNotifications = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Filter notifications using local state to prevent sudden jumps
    final unreadNotifications = state.notifications.where((n) {
      return !n.isRead || _locallyReadNotifications.contains(n.id);
    }).toList();
    
    final readNotifications = state.notifications.where((n) {
      return n.isRead && !_locallyReadNotifications.contains(n.id);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Premium Header
            _buildPremiumHeader(isDark, unreadNotifications.isNotEmpty),
            
            // 2. Sleek Sliding Tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _buildSleekTabBar(isDark, unreadNotifications.length),
            ),
            
            // 3. Content
            Expanded(
              child: state.isLoading && state.notifications.isEmpty
                  ? Center(child: LoadingIndicator())
                  : state.error != null
                      ? _buildErrorState(state.error!)
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _selectedTabIndex == 0
                              ? _buildNotificationList(unreadNotifications, isDark, isUnreadList: true)
                              : _buildNotificationList(readNotifications, isDark, isUnreadList: false),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleekTabBar(bool isDark, int unreadCount) {
    final bgColor = isDark ? const Color(0xFF1C212A) : Colors.white;
    final activeBgColor = Theme.of(context).colorScheme.primary;
    final inactiveTextColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Sliding Pill
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: _selectedTabIndex == 0 ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: activeBgColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: activeBgColor.withOpacity(0.4),
                      blurRadius: 8,
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
                            fontWeight: FontWeight.w700,
                            color: _selectedTabIndex == 0 ? Colors.white : inactiveTextColor,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 0 ? Colors.white.withOpacity(0.2) : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                color: _selectedTabIndex == 0 ? Colors.white : Colors.black87,
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
                        fontWeight: FontWeight.w700,
                        color: _selectedTabIndex == 1 ? Colors.white : inactiveTextColor,
                        fontSize: 14,
                        letterSpacing: 0.5,
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

  Widget _buildNotificationList(List<AppNotification> notifications, bool isDark, {required bool isUnreadList}) {
    if (notifications.isEmpty) {
      return _buildEmptyState(isDark, isUnreadList ? 'You\'re all caught up!' : 'No read notifications');
    }

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: isDark ? const Color(0xFF1C212A) : Colors.white,
      onRefresh: () async {
        setState(() {
          _locallyReadNotifications.clear();
        });
        await ref.read(notificationProvider.notifier).loadNotifications(refresh: true);
      },
      child: ListView.separated(
        key: ValueKey<int>(_selectedTabIndex), // Force rebuild on tab switch
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          // It's unread if the backend says so AND it hasn't been locally read yet
          final bool isUnread = !notification.isRead && !_locallyReadNotifications.contains(notification.id);
          return _buildUltraPremiumNotificationCard(
            notification, 
            isDark, 
            isUnread: isUnread
          );
        },
      ),
    );
  }

  Widget _buildPremiumHeader(bool isDark, bool hasUnread) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C212A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
            ),
          ),
          
          // Title
          Text(
            'Notifications',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF111827),
              letterSpacing: -0.5,
            ),
          ),

          // Mark all as read
          if (hasUnread)
            InkWell(
              onTap: () {
                setState(() {
                  _locallyReadNotifications.clear();
                });
                ref.read(notificationProvider.notifier).markAllAsRead();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.done_all_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
              ),
            )
          else
            const SizedBox(width: 46),
        ],
      ),
    );
  }

  Widget _buildUltraPremiumNotificationCard(AppNotification notification, bool isDark, {required bool isUnread}) {
    final iconData = _getIconData(notification.type);
    final isExpanded = _expandedNotificationId == notification.id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedNotificationId = isExpanded ? null : notification.id;
          if (!notification.isRead && !_locallyReadNotifications.contains(notification.id)) {
            _locallyReadNotifications.add(notification.id);
            ref.read(notificationProvider.notifier).markAsRead(notification.id);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C212A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnread 
                ? Theme.of(context).colorScheme.primary.withOpacity(0.5) 
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            width: isUnread ? 1.5 : 1,
          ),
          boxShadow: [
            if (isUnread)
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Unread Glow effect behind the card
              if (isUnread)
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Glassmorphic Icon
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                iconData.backgroundColor,
                                iconData.backgroundColor.withOpacity(0.5),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.05 : 0.4)),
                            boxShadow: [
                              BoxShadow(
                                color: iconData.color.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(iconData.icon, color: iconData.color, size: 24),
                        ),
                        const SizedBox(width: 16),
                        
                        // Text Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notification.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF111827),
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                  if (isUnread)
                                    Container(
                                      width: 10,
                                      height: 10,
                                      margin: const EdgeInsets.only(left: 8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                                            blurRadius: 6,
                                            spreadRadius: 2,
                                          )
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatRelativeTime(notification.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 14),
                    
                    // Body
                    Padding(
                      padding: const EdgeInsets.only(left: 68),
                      child: Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade300 : const Color(0xFF4B5563),
                          height: 1.5,
                        ),
                        maxLines: isExpanded ? null : 2,
                        overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      ),
                    ),

                    // Actions
                    if (isExpanded && notification.data != null && notification.data!['orderId'] != null) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(left: 68),
                        child: TextButton.icon(
                          onPressed: () => _handleNavigation(context, notification),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: const Text('View Order Details'),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade200,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_active_outlined, size: 64, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
          ),
          const SizedBox(height: 32),
          Text(
            message,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1F2937),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new updates',
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
              fontSize: 14,
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
                        lowerError.contains('bad response') && lowerError.contains('null');

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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Your authentication session has expired. Please login again to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => context.go('/auth-choice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: const Text('Login Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            child: Text('Error: $error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
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
