import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';

class EcommerceDashboardScreen extends ConsumerWidget {
  const EcommerceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1C2333) : Colors.white;
    final backgroundColor = isDark ? const Color(0xFF101522) : const Color(0xFFF6F6F8);
    final borderColor = isDark ? const Color(0xFF323F67) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : Colors.black87;

    final menuItems = [
      {
        'title': 'Home Screen',
        'subtitle': 'Manage banners, sections, layouts',
        'icon': Icons.home,
        'color': Colors.blue,
        'route': 'admin-ecommerce-home',
      },
      {
        'title': 'Product Categories',
        'subtitle': 'Manage category display, featured items',
        'icon': Icons.category,
        'color': Colors.orange,
        'route': 'admin-ecommerce-categories',
      },
      {
        'title': 'Cart Page',
        'subtitle': 'Configure cart settings, messages',
        'icon': Icons.shopping_cart,
        'color': Colors.green,
        'route': 'admin-ecommerce-cart',
      },


    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back, color: textColor),
        ),
        title: Text(
          'Ecommerce Management',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: borderColor, height: 1),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: menuItems.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return _buildMenuCard(
            context: context,
            title: item['title'] as String,
            subtitle: item['subtitle'] as String,
            icon: item['icon'] as IconData,
            color: item['color'] as Color,
            onTap: () {
              final route = item['route'] as String?;
              if (route != null) {
                context.pushNamed(route);
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item['title']} Management Coming Soon')));
              }
            },
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textColor: textColor,
          );
        },
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isDark ? Colors.grey : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
