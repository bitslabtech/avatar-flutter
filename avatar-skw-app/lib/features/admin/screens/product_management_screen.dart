import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../admin/providers/product_management_provider.dart';
import '../../../providers/auth_provider.dart';
import 'product_add_edit_screen.dart';

import '../../../models/user.dart';

class ProductManagementScreen extends ConsumerStatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  ConsumerState<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends ConsumerState<ProductManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch stats on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productManagementProvider.notifier).loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productState = ref.watch(productManagementProvider);
    final user = ref.watch(authProvider).user;

    ref.listen<ProductState>(productManagementProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        String message = next.error!;
        if (message.contains('Forbidden') || message.contains('403')) {
          message = 'You do not have permission to read products';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundBlack : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, isDark, user?.name ?? 'Super Admin'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsSection(isDark, productState),
                    const SizedBox(height: 32),
                    Text(
                      'Management Controls',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionList(context, isDark, user),
                  ],
                ),
              ),
            ),
             // Bottom Navigation excluded as per request
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark, String userName) {
    final iconBgColor = isDark ? AppColors.surfaceDark : Colors.grey.shade100;
    final iconColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back, color: iconColor),
            style: IconButton.styleFrom(
              backgroundColor: iconBgColor,
              shape: const CircleBorder(),
            ),
          ),
          Text(
            'Product Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
           const SizedBox(width: 48), // Placeholder to balance title
        ],
      ),
    );
  }

  Widget _buildStatsSection(bool isDark, ProductState state) {
    if (state.isLoading && state.stats.totalProducts == 0) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state.error != null && state.stats.totalProducts == 0) {
       return Text('Error loading stats: ${state.error}', style: const TextStyle(color: Colors.red));
    }

    final activeCount = state.stats.activeProducts;
    final inactiveCount = state.stats.totalProducts - activeCount;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Active Products', 
            activeCount.toString(), 
            Icons.verified_outlined, 
            Colors.green, 
            isDark
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Inactive Products', 
            inactiveCount.toString(), 
            Icons.archive_outlined, 
            Colors.orange, 
            isDark
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      // Fix height to ensure alignment regardless of text wrapping, or use AspectRatio in parent
      // Here, keeping flexible but ensuring text doesn't cause drastic imbalance
      constraints: const BoxConstraints(minHeight: 140), 
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                title, 
                style: TextStyle(
                  fontSize: 12, 
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, 
                  fontWeight: FontWeight.w500
                ),
                maxLines: 2, // Allow 2 lines
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionList(BuildContext context, bool isDark, User? user) {
    return Column(
      children: [
        _buildLargeActionButton(
          'Create Products', 
          'Add new inventory items', 
          Icons.add_circle, 
          AppColors.primaryBlue, 
          Colors.white,
          isDark,
          () {
            if (user?.hasPermission('products', 'create') != true) {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('You do not have permission to create products')),
               );
               return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductAddEditScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton('Manage Products', Icons.inventory_2, Colors.blue, isDark, () {
          if (user?.hasPermission('products', 'read') != true) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('You do not have permission to view products')),
             );
             return;
          }
          ref.read(productManagementProvider.notifier).loadProducts(showSkeleton: true);
          context.pushNamed('admin-products');
        }),
        const SizedBox(height: 12),
        _buildActionButton('Bulk Import/Export', Icons.import_export, Colors.teal, isDark, () {
           if (user?.hasPermission('products', 'create') != true) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('You do not have permission to import/export products')),
             );
             return;
          }
          context.pushNamed('admin-product-bulk');
        }),
        const SizedBox(height: 12),
        _buildActionButton('Manage Categories', Icons.category, Colors.purple, isDark, () {
           if (user?.hasPermission('products', 'update') != true) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('You do not have permission to manage categories')),
             );
             return;
          }
          context.pushNamed('admin-categories');
        }),
        const SizedBox(height: 12),
        _buildActionButton('Manage Brands', Icons.branding_watermark, Colors.pink, isDark, () {
           if (user?.hasPermission('products', 'update') != true) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('You do not have permission to manage brands')),
             );
             return;
          }
          context.pushNamed('admin-brands');
        }),
        const SizedBox(height: 12),
        _buildActionButton('Manage GST', Icons.percent, Colors.teal, isDark, () {
           if (user?.hasPermission('products', 'update') != true) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('You do not have permission to manage GST')),
             );
             return;
          }
          context.pushNamed('admin-gst');
        }),
      ],
    );
  }

  Widget _buildLargeActionButton(String title, String subtitle, IconData icon, Color bgColor, Color iconColor, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
       borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: bgColor.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40, 
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
             Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color iconColor, bool isDark, VoidCallback onTap) {
     return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              width: 40, 
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
            ),
            Icon(Icons.chevron_right, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
