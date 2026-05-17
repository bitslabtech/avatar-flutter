import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/category_provider.dart';
import '../../../../providers/upload_provider.dart';
import '../../../../providers/auth_provider.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).loadCategories();
    });
  }

  void _showFilterModal(BuildContext context, bool isDark, CategoryFilter currentFilter) {
    CategoryFilter tempFilter = currentFilter;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF232C48) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filter Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFilterRadio(isDark, 'All Categories', tempFilter == CategoryFilter.all, () => setModalState(() => tempFilter = CategoryFilter.all)),
                _buildFilterRadio(isDark, 'Active Only', tempFilter == CategoryFilter.active, () => setModalState(() => tempFilter = CategoryFilter.active)),
                _buildFilterRadio(isDark, 'Inactive Only', tempFilter == CategoryFilter.inactive, () => setModalState(() => tempFilter = CategoryFilter.inactive)),
                _buildFilterRadio(isDark, 'Unassigned Only', tempFilter == CategoryFilter.unassigned, () => setModalState(() => tempFilter = CategoryFilter.unassigned)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () { ref.read(categoryProvider.notifier).setFilter(CategoryFilter.all); Navigator.pop(ctx); },
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: isDark ? Colors.grey : Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: Text('Clear', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(categoryProvider.notifier).setFilter(tempFilter);
                          Navigator.pop(ctx);
                          if (tempFilter != CategoryFilter.all) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Filtering: ${tempFilter.name}'), backgroundColor: AppColors.primaryBlue, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: const Text('Apply Filter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRadio(bool isDark, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? AppColors.primaryBlue : (isDark ? Colors.grey : Colors.grey.shade400), width: 2)),
              child: isSelected ? Center(child: Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryBlue))) : null,
            ),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryState = ref.watch(categoryProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundBlack : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Expanded(
              child: categoryState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : categoryState.error != null
                      ? Center(child: Text('Error: ${categoryState.error}'))
                      : _buildContent(context, isDark, categoryState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundBlack : Colors.white.withOpacity(0.95),
        border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(Icons.arrow_back, color: isDark ? Colors.grey.shade300 : Colors.grey.shade600),
                style: IconButton.styleFrom(
                   padding: EdgeInsets.zero,
                   visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              final user = ref.read(authProvider).user;
              if (user?.hasPermission('products', 'create') != true) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission Denied: Cannot create categories')));
                 return;
              }
              _showAddDialog(context);
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create New'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.primaryBlue.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, CategoryState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsRow(isDark, state),
          const SizedBox(height: 20),
          _buildSearchBar(isDark),
          const SizedBox(height: 16),
          // Use filteredCategories here
          _buildCategoryList(isDark, state.filteredCategories),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, CategoryState state) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(isDark, 'Total', state.totalCount.toString(), Icons.inventory_2, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(isDark, 'Active', state.activeCount.toString(), Icons.check_circle, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(isDark, 'Unassigned', state.unassignedCount.toString(), Icons.pending, Colors.grey)),
      ],
    );
  }

  Widget _buildStatCard(bool isDark, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final currentFilter = ref.watch(categoryProvider).filter;
    final hasActiveFilter = currentFilter != CategoryFilter.all;
    
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => ref.read(categoryProvider.notifier).setSearchQuery(value),
              decoration: InputDecoration(
                hintText: 'Search categories...',
                hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
          ),
          child: Stack(
            children: [
              IconButton(
                icon: Icon(Icons.tune, color: hasActiveFilter ? AppColors.primaryBlue : (isDark ? Colors.grey.shade300 : Colors.grey.shade600)),
                onPressed: () => _showFilterModal(context, isDark, currentFilter),
              ),
              if (hasActiveFilter)
                Positioned(top: 8, right: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList(bool isDark, List<CategoryItem> categories) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NAME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
              Text('ACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
            ],
          ),
        ),
        ...categories.map((c) => _buildCategoryItem(isDark, c)),
      ],
    );
  }

  Widget _buildCategoryItem(bool isDark, CategoryItem item) {
    // Determine icon based on name if no icon provided (simple fallback logic)
    // In real app, we'd use the stored icon string or fetch image
    IconData iconData = Icons.category;
    if (item.name.toLowerCase().contains('fridge') || item.name.toLowerCase().contains('refrigerator')) iconData = Icons.kitchen;
    else if (item.name.toLowerCase().contains('wash')) iconData = Icons.local_laundry_service;
    else if (item.name.toLowerCase().contains('air') || item.name.toLowerCase().contains('ac')) iconData = Icons.mode_fan_off;
    else if (item.name.toLowerCase().contains('kitchen')) iconData = Icons.blender;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent), // Hover effect tricky in mobile, ignore
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Expanded(
             child: Row(
               children: [
                 Container(
                   width: 40, height: 40,
                   decoration: BoxDecoration(
                     color: isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.shade50,
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                       ? ClipRRect(
                           borderRadius: BorderRadius.circular(8),
                           child: CachedNetworkImage(
                             imageUrl: item.imageUrl!,
                             fit: BoxFit.cover,
                             placeholder: (context, url) => Center(child: Icon(iconData, color: Colors.blue.withOpacity(0.5), size: 16)),
                             errorWidget: (context, url, error) => Icon(iconData, color: Colors.blue, size: 20),
                           ),
                         )
                       : Icon(iconData, color: Colors.blue, size: 20),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         item.name,
                         style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                         overflow: TextOverflow.ellipsis,
                       ),
                       const SizedBox(height: 4),
                       Row(
                         children: [
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                             decoration: BoxDecoration(
                               color: item.isActive 
                                   ? (isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50)
                                   : (isDark ? Colors.grey.withOpacity(0.2) : Colors.grey.shade100),
                               borderRadius: BorderRadius.circular(4),
                             ),
                             child: Text(
                               item.isActive ? 'Active' : 'Inactive',
                               style: TextStyle(
                                 fontSize: 10, 
                                 fontWeight: FontWeight.w600,
                                 color: item.isActive ? Colors.green : Colors.grey,
                               ),
                             ),
                           ),
                           const SizedBox(width: 8),
                           Text(
                             '${item.productCount} Items',
                             style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                           ),
                         ],
                       ),
                     ],
                   ),
                 ),
               ],
             ),
           ),
           Row(
             children: [
               IconButton(
                 onPressed: () {
                   final user = ref.read(authProvider).user;
                   if (user?.hasPermission('products', 'update') != true) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission Denied: Cannot update categories')));
                      return;
                   }
                   context.pushNamed(
                     'admin-category-edit', 
                     pathParameters: {'id': item.id},
                     extra: item, // Pass object to avoid refetch if possible
                   );
                 }, // Navigate to Edit
                 icon: const Icon(Icons.edit_outlined, size: 20),
                 color: Colors.grey,
                 visualDensity: VisualDensity.compact,
               ),
               // Delete removed as per request - moved to Edit Screen
             ],
           ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreateCategoryDialog(),
    );
  }

  void _confirmDelete(CategoryItem item) {
    // ... implementation unchanged ...
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
               await ref.read(categoryProvider.notifier).deleteCategory(item.id);
               if (context.mounted) context.pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CreateCategoryDialog extends ConsumerStatefulWidget {
  const _CreateCategoryDialog();

  @override
  ConsumerState<_CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends ConsumerState<_CreateCategoryDialog> {
  final _nameController = TextEditingController();
  final _titleController = TextEditingController(); // Optional Title
  final _descController = TextEditingController(); // 6-8 words description
  bool _isActive = true;
  
  File? _selectedImage;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text('New Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                   IconButton(
                     onPressed: () => context.pop(),
                     icon: Icon(Icons.close, color: isDark ? Colors.grey : Colors.grey.shade400),
                     padding: EdgeInsets.zero,
                     constraints: const BoxConstraints(),
                   ),
                ],
              ),
              const SizedBox(height: 24),

              // Image Selection
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200, width: 2),
                      image: _selectedImage != null 
                        ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                        : null,
                    ),
                    child: _selectedImage == null 
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, color: AppColors.primaryBlue, size: 32),
                              const SizedBox(height: 8),
                              Text('Add Image *', style: TextStyle(fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.w600)),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Recommended: 800x800 px (Square)', 
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              ),
              if (_selectedImage == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(child: Text('Image is mandatory', style: TextStyle(fontSize: 12, color: Colors.red[300]))),
                ),
              
              const SizedBox(height: 24),

              // Name
              _buildLabel('NAME *', isDark),
              TextField(
                controller: _nameController,
                decoration: _inputDecoration('Category Name (Required)', isDark),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 16),

              // Title
              _buildLabel('TITLE (Optional)', isDark),
              TextField(
                controller: _titleController,
                decoration: _inputDecoration('Display Title (e.g. "Premium Kitchen")', isDark),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 16),

              // Description
              _buildLabel('DESCRIPTION (Optional, 6-8 words)', isDark),
              TextField(
                controller: _descController,
                decoration: _inputDecoration('Short description for banner', isDark),
                maxLines: 2,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 16),

              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Status', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                    Switch.adaptive(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeColor: AppColors.primaryBlue,
                    )
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : () async {
                     if (_selectedImage == null) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image'), backgroundColor: Colors.red));
                       return;
                     }
                     if (_nameController.text.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter category name'), backgroundColor: Colors.red));
                       return;
                     }

                     setState(() => _isUploading = true);

                     try {
                       // 1. Upload Image
                       final uploadService = ref.read(fileUploadServiceProvider);
                       final imageUrl = await uploadService.uploadImage(_selectedImage!);

                       // 2. Create Category
                       final success = await ref.read(categoryProvider.notifier).createCategory(
                         name: _nameController.text.trim(),
                         imageUrl: imageUrl,
                         title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
                         description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                         isActive: _isActive,
                       );

                       if (success && context.mounted) {
                         context.pop();
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category Created Successfully'), backgroundColor: AppColors.successGreen));
                       } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create category'), backgroundColor: Colors.red));
                       }
                     } catch (e) {
                       if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
                       }
                     } finally {
                       if (mounted) setState(() => _isUploading = false);
                     }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isUploading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create Category', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
    );
  }
}
