import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/catalog_provider.dart';
import '../../../providers/upload_provider.dart';
import '../providers/admin_provider.dart';
import '../../../models/product.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../models/banner.dart' as model; // Pre-existing import found in original file context might look different, aliasing to avoid conflict if any. Assuming `import '../../../models/banner.dart'` exists or adding it.
// Wait, I need to check imports. `../../../models/banner.dart` is NOT imported in the original file I viewed. 
// Original imports:
// import 'package:image_picker/image_picker.dart';
// import '../../../core/theme/app_colors.dart';
// import '../../../providers/catalog_provider.dart';
// import '../../../providers/upload_provider.dart';
// import '../providers/admin_provider.dart';
// import '../../../models/product.dart';
// import '../../../core/utils/currency_utils.dart';

// I need to add import for Banner first.

class AdminAddBannerScreen extends ConsumerStatefulWidget {
  final model.Banner? banner;
  const AdminAddBannerScreen({super.key, this.banner});

  @override
  ConsumerState<AdminAddBannerScreen> createState() => _AdminAddBannerScreenState();
}

class _AdminAddBannerScreenState extends ConsumerState<AdminAddBannerScreen> {
  final _titleController = TextEditingController();
  final _tagController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _btnTextController = TextEditingController();
  
  // Link Configuration
  String _linkType = 'Product'; // 'Product' or 'Category'
  String? _selectedLinkValue; // Stores Product ID or Category Name
  String? _selectedLinkDisplay; // Stores Product Name or Category Name (for display)

  File? _imageFile;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.banner != null) {
      _titleController.text = widget.banner!.title ?? '';
      _uploadedImageUrl = widget.banner!.imageUrl;
      _tagController.text = widget.banner!.tag ?? '';
      _descriptionController.text = widget.banner!.description ?? '';
      _btnTextController.text = widget.banner!.btnText ?? '';

      // Parse Link URL
      if (widget.banner!.linkUrl != null && widget.banner!.linkUrl!.isNotEmpty) {
        final uri = Uri.parse(widget.banner!.linkUrl!);
        if (uri.path.startsWith('/product/')) {
           _linkType = 'Product';
           _selectedLinkValue = uri.pathSegments.last;
           // We might not have the product name immediately unless we fetch it, 
           // but we can show ID or Generic text for now.
           _selectedLinkDisplay = 'Product #$_selectedLinkValue'; 
           // Potentially fetch product name via provider if needed, but keeping it simple for now.
        } else if (uri.queryParameters.containsKey('category')) {
           _linkType = 'Category';
           _selectedLinkValue = uri.queryParameters['category'];
           _selectedLinkDisplay = _selectedLinkValue;
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _isUploading = true;
      });

      try {
        final url = await ref.read(fileUploadServiceProvider).uploadImage(_imageFile!);
        setState(() {
          _uploadedImageUrl = url;
          _isUploading = false;
        });
      } catch (e) {
        setState(() => _isUploading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        }
      }
    }
  }

  void _showProductSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _ProductSelectionSheet(),
    ).then((selected) {
      if (selected != null && selected is Product) {
        setState(() {
          _selectedLinkValue = selected.id;
          _selectedLinkDisplay = selected.name;
        });
      }
    });
  }

  void _showCategorySelectionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const _CategorySelectionSheet(),
    ).then((selected) {
      if (selected != null && selected is String) {
         setState(() {
          _selectedLinkValue = selected;
          _selectedLinkDisplay = selected;
        });
      }
    });
  }

  Future<void> _saveBanner() async {
    if (_uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide an image')),
      );
      return;
    }

    if (_selectedLinkValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please configure navigation link')),
      );
      return;
    }

    final user = ref.read(authProvider).user;
    final permission = widget.banner != null ? 'update' : 'create';
    if (user?.hasPermission('ecommerce', permission) != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission Denied: Cannot $permission banner')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Construct Link URL based on selection
      String? linkUrl;
      if (_selectedLinkValue != null) {
        if (_linkType == 'Product') {
          linkUrl = '/product/$_selectedLinkValue';
        } else {
          // Assuming category slug or name query param
          linkUrl = '/?category=$_selectedLinkValue';
        }
      }

      final bannerData = {
        'title': _titleController.text,
        'imageUrl': _uploadedImageUrl,
        'linkUrl': linkUrl ?? '',
        'tag': _tagController.text,
        'description': _descriptionController.text,
        'btnText': _btnTextController.text,
        'order': widget.banner?.order ?? 0,
        'isActive': widget.banner?.isActive ?? true,
      };

      if (widget.banner != null) {
        await ref.read(adminBannersProvider.notifier).updateBanner(widget.banner!.id, bannerData);
      } else {
        await ref.read(adminBannersProvider.notifier).addBanner(bannerData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.banner != null ? 'Banner updated!' : 'Banner created!')));
        context.pop();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1C2333) : Colors.white;
    final borderColor = isDark ? const Color(0xFF323F67) : const Color(0xFFE5E7EB);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.banner != null ? 'Edit Banner' : 'Add New Banner'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      // ... rest of the body
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview Area
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A3441) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: _isUploading
                    ? const Center(child: CircularProgressIndicator())
                    : _uploadedImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(ApiEndpoints.resolveImageUrl(_uploadedImageUrl!), fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text('Tap to upload banner image', style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Recommended: 1920x1080 px (16:9 Landscape)', 
                style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 24),

            // Basic Details
            Text('Banner Details', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title (Optional)',
                hintText: 'e.g. Summer Sale',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
             TextField(
              controller: _tagController,
              decoration: const InputDecoration(
                labelText: 'Tag (Optional)',
                hintText: 'e.g. LIMITED TIME',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
             TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Short description for user...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
             TextField(
              controller: _btnTextController,
              decoration: const InputDecoration(
                labelText: 'Button Text (Optional)',
                hintText: 'e.g. SHOP NOW',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Link Configuration
             Text('Navigation Configuration *', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
             const SizedBox(height: 16),
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 border: Border.all(color: borderColor),
                 borderRadius: BorderRadius.circular(8),
                 color: surfaceColor,
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     children: [
                       Expanded(
                         child: RadioListTile<String>(
                           title: const Text('Product'),
                           value: 'Product',
                           groupValue: _linkType,
                            contentPadding: EdgeInsets.zero,
                           onChanged: (val) {
                             setState(() {
                               _linkType = val!;
                               _selectedLinkValue = null;
                               _selectedLinkDisplay = null;
                             });
                           },
                         ),
                       ),
                       Expanded(
                         child: RadioListTile<String>(
                           title: const Text('Category'),
                           value: 'Category',
                           groupValue: _linkType,
                           contentPadding: EdgeInsets.zero,
                           onChanged: (val) {
                             setState(() {
                               _linkType = val!;
                               _selectedLinkValue = null;
                               _selectedLinkDisplay = null;
                             });
                           },
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 8),
                   SizedBox(
                     width: double.infinity,
                     child: OutlinedButton.icon(
                       icon: Icon(_linkType == 'Product' ? Icons.inventory_2_outlined : Icons.category_outlined),
                       label: Text(_selectedLinkDisplay ?? 'Select $_linkType'),
                       style: OutlinedButton.styleFrom(
                         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                         alignment: Alignment.centerLeft,
                       ),
                       onPressed: _linkType == 'Product' ? _showProductSelectionSheet : _showCategorySelectionSheet,
                     ),
                   ),
                 ],
               ),
             ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: ElevatedButton(
          onPressed: (_isSaving || _uploadedImageUrl == null || _selectedLinkValue == null) ? null : _saveBanner,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isSaving 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('PUBLISH BANNER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _ProductSelectionSheet extends ConsumerStatefulWidget {
  const _ProductSelectionSheet();

  @override
  ConsumerState<_ProductSelectionSheet> createState() => _ProductSelectionSheetState();
}

class _ProductSelectionSheetState extends ConsumerState<_ProductSelectionSheet> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reset filters and load initial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsProvider.notifier).clearFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification && notification.metrics.extentAfter < 200) {
      final productsState = ref.read(productsProvider);
      if (!productsState.isLoading && productsState.pagination != null) {
        final currentPage = productsState.pagination!['page'] as int? ?? 1;
        final totalPages = productsState.pagination!['lastPage'] as int? ?? 1;
        
        if (currentPage < totalPages) {
           ref.read(productsProvider.notifier).loadProducts(
             search: _searchController.text.isNotEmpty ? _searchController.text : null,
             page: currentPage + 1,
             append: true,
           );
        }
      }
    }
    return false;
  }

  void _onSearch(String query) {
    ref.read(productsProvider.notifier).loadProducts(search: query);
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1C2333) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white60 : Colors.grey;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
               Padding(
                 padding: const EdgeInsets.all(16),
                 child: Row(
                   children: [
                     const BackButton(),
                     Expanded(
                       child: TextField(
                         controller: _searchController,
                         style: TextStyle(color: textColor),
                         decoration: InputDecoration(
                           hintText: 'Search products...',
                           hintStyle: TextStyle(color: hintColor),
                           prefixIcon: Icon(Icons.search, color: hintColor),
                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                           enabledBorder: OutlineInputBorder(
                             borderRadius: BorderRadius.circular(8),
                             borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey),
                           ),
                           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         ),
                         onSubmitted: _onSearch,
                       ),
                     ),
                     IconButton(
                       icon: Icon(Icons.search, color: textColor),
                       onPressed: () => _onSearch(_searchController.text),
                     ),
                   ],
                 ),
               ),
               Expanded(
                 child: productsState.isLoading && productsState.products.isEmpty
                     ? const Center(child: CircularProgressIndicator())
                     : NotificationListener<ScrollNotification>(
                         onNotification: _onScrollNotification,
                         child: ListView.separated(
                           controller: scrollController,
                           itemCount: productsState.products.length + (productsState.isLoading ? 1 : 0),
                           separatorBuilder: (_, __) => Divider(color: isDark ? Colors.white12 : Colors.grey[200]),
                           itemBuilder: (context, index) {
                             if (index == productsState.products.length) {
                               return const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()));
                             }
                             final product = productsState.products[index];
                             return ListTile(
                               leading: Container(
                                 width: 48,
                                 height: 48,
                                 color: isDark ? Colors.white10 : Colors.grey[200],
                                 child: Image.network(
                                   product.primaryImageUrl,
                                   fit: BoxFit.cover,
                                   errorBuilder: (_,__,___) => Icon(Icons.image, color: hintColor),
                                 ),
                               ),
                               title: Text(product.name, style: TextStyle(color: textColor)),
                               subtitle: Text(
                                 CurrencyUtils.format(product.price),
                                 style: TextStyle(color: hintColor),
                               ),
                               onTap: () => Navigator.pop(context, product),
                             );
                           },
                         ),
                       ),
               ),
            ],
          ),
        );
      },
    );
  }
}

class _CategorySelectionSheet extends ConsumerWidget {
  const _CategorySelectionSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1C2333) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
       height: 400,
       padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 16),
          Expanded(
            child: categoriesAsync.when(
              data: (categories) => ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ListTile(
                    title: Text(category.name, style: TextStyle(color: textColor)),
                    onTap: () => Navigator.pop(context, category.name),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }
}
