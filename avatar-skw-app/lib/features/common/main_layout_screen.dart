
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

class MainLayoutScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayoutScreen({super.key, required this.navigationShell});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen> {
  DateTime? _lastBackPressTime;

  /// Called on every Android back press / back gesture.
  /// Returns [true] to allow pop (exit), [false] to block it.
  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    final shell = widget.navigationShell;

    // If we're NOT on the root tab (index 0) and can go up, let the shell handle it
    if (shell.currentIndex != 0) {
      shell.goBranch(0, initialLocation: true);
      return false;
    }

    // On root tab — check double-press window (2 seconds)
    final isFirstPress = _lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2);

    if (isFirstPress) {
      _lastBackPressTime = now;
      // Show a snackbar hint on first press
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.exit_to_app, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Press back again to exit'),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: const Color(0xFF1E293B),
          ),
        );
      }
      return false; // Block exit
    }

    // Second press within window — show confirmation dialog
    _lastBackPressTime = null; // Reset
    final shouldExit = await _showExitDialog();
    return shouldExit;
  }

  Future<bool> _showExitDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.exit_to_app_rounded,
                  color: AppColors.primaryBlue,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Exit App?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Are you sure you want to exit Avatar?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  // Stay
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        'Stay',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Exit
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Exit',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: () => widget.navigationShell.goBranch(3),
              ),
            ),
          );
        }

        // 4. If Rejected, FORCE navigate to Profile (Status Screen)
        final user = ref.read(authProvider).user;
        if (user?.status == 'rejected') {
           widget.navigationShell.goBranch(3);
        }
      }
    });
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await _onWillPop();
        if (shouldExit && context.mounted) {
          // Physically exit the app
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody: true, // Important for floating bar to overlay body
        body: widget.navigationShell,
        bottomNavigationBar: _FloatingNavBar(
          navigationShell: widget.navigationShell,
          isDark: isDark,
        ),
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
