import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/upload_provider.dart';
import '../providers/admin_provider.dart';
import 'admin_add_banner_screen.dart';
import '../../../providers/auth_provider.dart';

class EcommerceHomeScreen extends ConsumerStatefulWidget {
  const EcommerceHomeScreen({super.key});

  @override
  ConsumerState<EcommerceHomeScreen> createState() => _EcommerceHomeScreenState();
}

class _EcommerceHomeScreenState extends ConsumerState<EcommerceHomeScreen> {
  // Mock Data Removed

  bool _showNewArrivals = true;

  bool _showBestSellers = true;

  
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1C2333) : Colors.white;
    final backgroundColor = isDark ? const Color(0xFF101522) : const Color(0xFFF6F6F8);
    final borderColor = isDark ? const Color(0xFF323F67) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : Colors.black87;

    final bannersAsync = ref.watch(adminBannersProvider);

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
          'Home Screen CMS',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: borderColor, height: 1),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final user = ref.read(authProvider).user;
              if (user?.hasPermission('ecommerce', 'update') != true) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission Denied')));
                 return;
              }
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Home Screen Config Saved')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banners Section
            _buildSectionHeader('Promotional Banners', textColor),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                   bannersAsync.when(
                    data: (banners) {
                      if (banners.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Icon(Icons.image_not_supported_outlined, size: 48, color: textColor.withOpacity(0.3)),
                                const SizedBox(height: 12),
                                Text('No banners found', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                                Text('Add your first banner above', style: TextStyle(color: textColor.withOpacity(0.5))),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      return ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: banners.length,
                        onReorder: (oldIndex, newIndex) {
                          ref.read(adminBannersProvider.notifier).reorderBanners(oldIndex, newIndex);
                        },
                        proxyDecorator: (child, index, animation) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (BuildContext context, Widget? child) {
                              final double animValue = Curves.easeInOut.transform(animation.value);
                              return Material(
                                elevation: 8.0 * animValue,
                                color: isDark ? AppColors.surfaceDark : Colors.white,
                                shadowColor: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                child: child,
                              );
                            },
                            child: child,
                          );
                        },
                        itemBuilder: (context, index) {
                          final banner = banners[index];
                          return Card(
                            key: ValueKey(banner.id), // Important for ReorderableListView
                            margin: const EdgeInsets.only(bottom: 12), // Replaces separator
                            color: surfaceColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: borderColor),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(8),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  banner.imageUrl,
                                  width: 80,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        width: 80,
                                        height: 50,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.broken_image, size: 20),
                                      ),
                                ),
                              ),
                              title: Text(banner.title?.isNotEmpty == true ? banner.title! : 'Untitled Banner', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                              subtitle: Text(
                                banner.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(color: banner.isActive ? Colors.green : Colors.grey),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Drag handle indicator
                                  Icon(Icons.drag_indicator, color: textColor.withOpacity(0.3)),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    color: AppColors.primaryBlue,
                                    onPressed: () {
                                      final user = ref.read(authProvider).user;
                                      if (user?.hasPermission('ecommerce', 'update') != true) {
                                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission Denied')));
                                         return;
                                      }
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => AdminAddBannerScreen(banner: banner),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    color: AppColors.errorRed,
                                    onPressed: () {
                                      final user = ref.read(authProvider).user;
                                      if (user?.hasPermission('ecommerce', 'delete') != true) {
                                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission Denied')));
                                         return;
                                      }
                                      // Confirm delete
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Banner?'),
                                          content: const Text('This action cannot be undone.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                ref.read(adminBannersProvider.notifier).deleteBanner(banner.id);
                                              },
                                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, stack) => Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error loading banners', style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                  Divider(height: 1, color: borderColor),
                  InkWell(
                    onTap: () {
                      final user = ref.read(authProvider).user;
                      if (user?.hasPermission('ecommerce', 'create') != true) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission Denied')));
                         return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminAddBannerScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: AppColors.primaryBlue),
                          const SizedBox(width: 8),
                          Text(
                            'Add New Banner',
                            style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Layout Section
            _buildSectionHeader('Homepage Sections', textColor),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('New Arrivals Section', style: TextStyle(color: textColor)),
                    value: _showNewArrivals,
                    activeColor: AppColors.primaryBlue,
                    onChanged: (val) {
                      final user = ref.read(authProvider).user;
                      if (user?.hasPermission('ecommerce', 'update') != true) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission Denied')));
                         return;
                      }
                      setState(() => _showNewArrivals = val);
                    },
                  ),
                  Divider(height: 1, color: borderColor),
                  SwitchListTile(
                    title: Text('Best Sellers Section', style: TextStyle(color: textColor)),
                    value: _showBestSellers,
                    activeColor: AppColors.primaryBlue,
                    onChanged: (val) {
                      final user = ref.read(authProvider).user;
                      if (user?.hasPermission('ecommerce', 'update') != true) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission Denied')));
                         return;
                      }
                      setState(() => _showBestSellers = val);
                    },
                  ),

                ],
              ),
            ),



          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color.withOpacity(0.7),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
