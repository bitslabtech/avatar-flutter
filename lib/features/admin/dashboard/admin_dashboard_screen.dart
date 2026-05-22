import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../../notifications/widgets/notification_bell.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  DateTime? _lastBackPressTime;

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    final isFirstPress = _lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2);

    if (isFirstPress) {
      _lastBackPressTime = now;
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
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: const Color(0xFF1E293B),
          ),
        );
      }
      return false;
    }

    _lastBackPressTime = null;
    return await _showExitDialog();
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
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.exit_to_app_rounded, color: Theme.of(context).colorScheme.primary, size: 32),
              ),
              const SizedBox(height: 20),
              Text('Exit App?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 8),
              Text('Are you sure you want to exit Avatar?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.4,
                  color: isDark ? Colors.grey[400] : Colors.grey[600])),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey[300]!),
                      ),
                      child: Text('Stay',
                        style: TextStyle(fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Exit', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final user = ref.watch(authProvider).user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Theme Colors based on design
    final surfaceColor = isDark ? const Color(0xFF192033) : Colors.white;
    final backgroundColor = isDark ? const Color(0xFF101522) : const Color(0xFFF6F6F8);
    final borderColor = isDark ? const Color(0xFF323F67) : const Color(0xFFE5E7EB);
    final primaryColor = const Color(0xFF1349ec);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await _onWillPop();
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Alert Listener
          Consumer(
            builder: (context, ref, child) {
              ref.listen(adminDashboardStatsProvider, (previous, next) {
                next.whenData((stats) {
                  final settings = ref.read(adminSettingsProvider);
                  // Only if alert enabled
                  if (settings.newConsumerAlert) {
                    final currentTotal = stats['totalUsers'] as int? ?? 0;
                    final lastTotal = settings.lastUserCount;
                    
                    // Check if new user added (and not first run)
                    if (currentTotal > lastTotal && lastTotal > 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('New Consumer Registered!'),
                          backgroundColor: Colors.teal,
                          action: SnackBarAction(
                            label: 'VIEW', 
                            textColor: Colors.white,
                            onPressed: () => context.pushNamed('admin-users'),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    
                    // Update sync
                    if (currentTotal != lastTotal) {
                       ref.read(adminSettingsProvider.notifier).updateLastUserCount(currentTotal);
                    }
                  } else {
                    // Update sync even if alert disabled, to avoid backlog alerts when enabled later
                     final currentTotal = stats['totalUsers'] as int? ?? 0;
                     if (currentTotal != settings.lastUserCount) {
                       ref.read(adminSettingsProvider.notifier).updateLastUserCount(currentTotal);
                     }
                  }
                });
              });
              return const SizedBox.shrink();
            },
          ),

          // Top App Bar
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: surfaceColor.withValues(alpha: 0.9),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withValues(alpha: 0.1),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'A',
                        style: TextStyle(
                            color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Console',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                NotificationBell(isDark: isDark),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Refresh dashboard stats
                return ref.read(adminDashboardStatsProvider.notifier).loadStats(force: true);
              },
              color: primaryColor,
              backgroundColor: surfaceColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Greeting
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Good morning,\n',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                              height: 1.2,
                            ),
                          ),
                          TextSpan(
                            text: user?.name ?? 'Super Admin',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // KPI Stats Grid
                    // KPI Stats Grid
                    Consumer(
                      builder: (context, ref, child) {
                        final statsAsync = ref.watch(adminDashboardStatsProvider);
                        
                        return statsAsync.when(
                          data: (stats) {
                            final totalSales = (stats['totalSales'] ?? 0) / 100;
                            final totalOrders = stats['totalOrders'] ?? 0;
                            final totalUsers = stats['totalUsers'] ?? 0;
                            final totalAdmins = stats['totalAdmins'] ?? 0;

                            return GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.25, // Adjusted from 1.35 to prevent overflow
                              children: [
                                _buildStatCard(
                                  context: context,
                                  title: 'Total Sales',
                                  value: '₹${totalSales.toStringAsFixed(0)}',
                                  change: '+12%', // Static for now as we don't have comparison data
                                  icon: Icons.attach_money,
                                  color: Colors.green,
                                  surfaceColor: surfaceColor,
                                  borderColor: borderColor,
                                ),
                                _buildStatCard(
                                  context: context,
                                  title: 'Total Orders',
                                  value: totalOrders.toString(),
                                  change: null,
                                  icon: Icons.shopping_cart,
                                  color: Colors.purple,
                                  surfaceColor: surfaceColor,
                                  borderColor: borderColor,
                                ),
                                _buildStatCard(
                                  context: context,
                                  title: 'Total Users',
                                  value: totalUsers.toString(),
                                  change: null,
                                  icon: Icons.group,
                                  color: Colors.blue,
                                  surfaceColor: surfaceColor,
                                  borderColor: borderColor,
                                ),
                                _buildStatCard(
                                  context: context,
                                  title: 'Total Admin',
                                  value: totalAdmins.toString(),
                                  isWarning: false,
                                  icon: Icons.admin_panel_settings,
                                  color: Colors.amber,
                                  surfaceColor: surfaceColor,
                                  borderColor: borderColor,
                                ),
                              ],
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                        );
                      },
                    ),

                    const SizedBox(height: 12),
                    
                    // Management Grid Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text(
                          'Management',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                         TextButton(
                          onPressed: () {}, 
                          child: Text('View All', style: TextStyle(color: primaryColor)),
                         ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Management Grid
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8, // Adjusted from 0.85 to prevent overflow
                      children: [
                        if (user?.hasPermission('products', 'read') == true)
                          _buildMenuCard(
                            context: context,
                            title: 'Products',
                            icon: Icons.inventory_2_outlined,
                            color: Colors.blue,
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                            onTap: () => context.pushNamed('admin-product-management'),
                          ),
                        if (user?.isSuperAdmin == true)
                          _buildMenuCard(
                            context: context,
                            title: 'Admins',
                            icon: Icons.security,
                            color: Colors.redAccent,
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                            onTap: () => context.pushNamed('admin-management'),
                          ),
                        if (user?.hasPermission('orders', 'read') == true)
                          _buildMenuCard(
                            context: context,
                            title: 'Orders',
                            icon: Icons.shopping_bag_outlined,
                            color: Colors.purple,
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                            onTap: () => context.pushNamed('admin-orders'),
                          ),
                        if (user?.hasPermission('dealers', 'read') == true)
                          _buildMenuCard(
                            context: context,
                            title: 'Dealers',
                            icon: Icons.people_outline,
                            color: Colors.pink,
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                            onTap: () => context.pushNamed('admin-dealers'),
                          ),
                        if (user?.hasPermission('users', 'read') == true)
                          _buildMenuCard(
                            context: context,
                            title: 'Users',
                            icon: Icons.manage_accounts_outlined,
                            color: Colors.orange,
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                            onTap: () => context.pushNamed('admin-users'),
                          ),
                        if (user?.hasPermission('configurations', 'read') == true || user?.isSuperAdmin == true)
                          _buildMenuCard(
                            context: context,
                            title: 'Configurations',
                            icon: Icons.tune,
                            color: Colors.blueGrey,
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                            onTap: () => context.pushNamed('admin-configurations'),
                          ),
                         if (user?.hasPermission('ecommerce', 'read') == true)
                          _buildMenuCard(
                            context: context,
                            title: 'E-commerce',
                            icon: Icons.storefront_outlined,
                            color: Colors.green,
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                            onTap: () => context.pushNamed('admin-ecommerce'),
                          ),
                         if (user?.hasPermission('reports', 'read') == true)
                          _buildMenuCard(
                            context: context,
                            title: 'Report',
                            icon: Icons.assessment_outlined,
                            color: Colors.teal,
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                            onTap: () {
                               context.pushNamed('admin-reports');
                            },
                          ),
                          _buildMenuCard(
                            context: context,
                            title: 'Settings',
                            icon: Icons.settings_outlined,
                            color: Colors.blueGrey,
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                            onTap: () => context.pushNamed('admin-settings'),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    String? change,
    bool isWarning = false,
    required IconData icon,
    required Color color,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isWarning ? color.withValues(alpha: 0.3) : borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    change,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
               if (isWarning)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Action Req',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.blueGrey.shade900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required Color surfaceColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


}
