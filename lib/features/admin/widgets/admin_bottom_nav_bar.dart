import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class AdminNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
  final int badgeCount;

  const AdminNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
    this.badgeCount = 0,
  });
}

class AdminBottomNavBar extends StatelessWidget {
  final String? currentRoute;

  const AdminBottomNavBar({
    super.key,
    this.currentRoute,
  });

  static const List<AdminNavItem> items = [
    AdminNavItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
      route: '/admin',
    ),
    AdminNavItem(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2_rounded,
      label: 'Products',
      route: '/admin/products',
    ),
    AdminNavItem(
      icon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag_rounded,
      label: 'Orders',
      route: '/admin/orders',
    ),
    AdminNavItem(
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      label: 'Dealers',
      route: '/admin/dealers',
    ),
    AdminNavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Settings',
      route: '/admin/settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalMargin = screenWidth < 360 ? 10.0 : 16.0;

    // Determine effective location
    String location = currentRoute ?? '';
    if (location.isEmpty) {
      try {
        location = GoRouterState.of(context).matchedLocation;
      } catch (_) {
        location = '/admin';
      }
    }

    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(horizontalMargin, 0, horizontalMargin, 16),
        height: 66,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(33),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(33),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1E2226) : Colors.white)
                    .withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(33),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.07),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: items.map((item) {
                  final isSelected = _matchesRoute(location, item.route);
                  return _AdminNavBarItem(
                    item: item,
                    isSelected: isSelected,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (location != item.route) {
                        context.go(item.route);
                      }
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _matchesRoute(String current, String target) {
    if (target == '/admin') {
      return current == '/admin';
    }
    return current.startsWith(target);
  }
}

class _AdminNavBarItem extends StatelessWidget {
  final AdminNavItem item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _AdminNavBarItem({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBgColor = isDark ? Colors.white : AppColors.surfaceDark;
    final activeTextColor = isDark ? AppColors.surfaceDark : Colors.white;
    final inactiveIconColor = isDark ? Colors.white60 : AppColors.surfaceDark;
    final screenWidth = MediaQuery.of(context).size.width;
    // On narrow screens hide the selected label to avoid overflow
    final showLabel = isSelected && screenWidth >= 340;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? (screenWidth < 360 ? 7 : 10) : 6,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  color: isSelected ? activeTextColor : inactiveIconColor,
                  size: 20,
                ),
                if (item.badgeCount > 0)
                  Positioned(
                    top: -5,
                    right: -7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? activeBgColor
                              : (isDark ? const Color(0xFF1E2226) : Colors.white),
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          item.badgeCount > 99 ? '99+' : '${item.badgeCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (showLabel) ...[
              const SizedBox(width: 5),
              Text(
                item.label,
                style: TextStyle(
                  color: activeTextColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
