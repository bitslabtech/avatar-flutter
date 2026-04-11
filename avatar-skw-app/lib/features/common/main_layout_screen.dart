
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';

import '../../features/notifications/providers/notification_provider.dart';
import '../../models/app_notification.dart';

class MainLayoutScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayoutScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Listen for Account Updates (Real-time approval/rejection)
    ref.listen(notificationProvider, (previous, next) async {
      final accountUpdate = next.notifications.firstWhere(
        (n) => n.type == 'account_update' && !n.isRead,
        orElse: () => AppNotification(
          id: '',
          title: '',
          body: '',
          type: '',
          isRead: true,
          createdAt: DateTime.now(),
        ),
      );

      if (accountUpdate.id.isNotEmpty) {
        // 1. Refresh User Profile
        await ref.read(authProvider.notifier).refreshUser();
        
        // 2. Mark as read immediately so we don't loop
        ref.read(notificationProvider.notifier).markAsRead(accountUpdate.id);

        // 3. Show Snackbar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(accountUpdate.body),
              backgroundColor: accountUpdate.body.toLowerCase().contains('rejected') ? Colors.red : Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () => navigationShell.goBranch(3),
              ),
            ),
          );
        }

        // 4. If Rejected, FORCE navigate to Profile (Status Screen)
        final user = ref.read(authProvider).user;
        if (user?.status == 'rejected') {
           navigationShell.goBranch(3);
        }
      }
    });
    
    return Scaffold(
      extendBody: true, // Important for floating bar to overlay body
      body: navigationShell,
      bottomNavigationBar: _FloatingNavBar(
        navigationShell: navigationShell,
        isDark: isDark,
      ),
    );
  }
}

class _FloatingNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  final bool isDark;

  const _FloatingNavBar({
    required this.navigationShell,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final authState = ref.watch(authProvider);

    final navItems = [
      _NavItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: 'Home',
        index: 0,
      ),
      _NavItem(
        icon: Icons.grid_view_outlined,
        selectedIcon: Icons.grid_view_rounded,
        label: 'Shop',
        index: 1,
      ),
      _NavItem(
        icon: Icons.shopping_cart_outlined,
        selectedIcon: Icons.shopping_cart_rounded,
        label: 'Cart',
        index: 2,
        badgeCount: (authState.isAuthenticated && authState.user?.status != 'rejected') ? cartState.itemCount : 0,
      ),
      _NavItem(
        icon: Icons.person_outline,
        selectedIcon: Icons.person_rounded,
        label: authState.isAuthenticated ? 'Profile' : 'Login',
        index: 3,
      ),
    ].where((item) {
      // Remove Cart for Guest users AND Rejected users
      if (item.label == 'Cart') {
        if (!authState.isAuthenticated) return false;
        if (authState.user?.status == 'rejected') return false;
      }
      return true;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E1E1E) : Colors.white).withOpacity(0.95), // Less transparent for solid feel
        border: Border(
           top: BorderSide(
             color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
             width: 1,
           ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            top: false,
            child: SizedBox(
               height: 70,
               child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround, // Distribute evenly
                children: navItems.map((item) {
                  final isSelected = navigationShell.currentIndex == item.index;
                  return Expanded(
                    child: _NavBarItem(
                      item: item,
                      isSelected: isSelected,
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        navigationShell.goBranch(
                          item.index,
                          initialLocation: item.index == navigationShell.currentIndex,
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final int index;
  final int badgeCount;

  _NavItem({
    required this.icon, 
    this.selectedIcon,
    required this.label, 
    required this.index,
    this.badgeCount = 0,
  });
}

class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = AppColors.primaryBlue;
    final unselectedColor = isDark ? Colors.grey[500] : Colors.grey[600];
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                decoration: BoxDecoration(
                   color: isSelected ? selectedColor.withOpacity(0.1) : Colors.transparent,
                   borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
                  color: isSelected ? selectedColor : unselectedColor,
                  size: 26,
                ),
              ),
              if (item.badgeCount > 0)
                Positioned(
                  right: 12,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.5))
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        item.badgeCount > 99 ? '99+' : item.badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              color: isSelected ? selectedColor : unselectedColor,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
