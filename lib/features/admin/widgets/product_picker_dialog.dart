import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avatar_app/core/theme/app_colors.dart';
import 'package:avatar_app/features/admin/providers/product_management_provider.dart';
import 'package:avatar_app/models/product.dart';
import 'package:avatar_app/core/utils/currency_utils.dart';

class ProductPickerDialog extends ConsumerStatefulWidget {
  const ProductPickerDialog({super.key});

  @override
  ConsumerState<ProductPickerDialog> createState() => _ProductPickerDialogState();
}

class _ProductPickerDialogState extends ConsumerState<ProductPickerDialog> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear any existing filters/search and refresh products
      final notifier = ref.read(productManagementProvider.notifier);
      notifier.setSearchQuery('');
      notifier.clearCategoryFilter();
      notifier.clearStatCardFilter();
      notifier.clearFilterOptions();
      notifier.loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productManagementProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                   Text('Select Product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                   const Spacer(),
                   IconButton(
                     icon: const Icon(Icons.close),
                     onPressed: () => Navigator.of(context).pop(),
                     color: isDark ? Colors.grey[400] : Colors.grey[600],
                   ),
                ],
              ),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => ref.read(productManagementProvider.notifier).setSearchQuery(val),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                  filled: true,
                  fillColor: isDark ? Colors.black26 : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // List
            Expanded(
              child: state.isLoading && state.products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                  ? Center(child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: ${state.error}', style: const TextStyle(color: Colors.red)),
                    ))
                  : state.filteredProducts.isEmpty
                    ? Center(child: Text('No products found (${state.products.length} total)', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])))
                    : ListView.builder(
                      itemCount: state.filteredProducts.length,
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      itemBuilder: (context, index) {
                        final product = state.filteredProducts[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              image: (product.resolvedImageUrls != null && product.resolvedImageUrls!.isNotEmpty) 
                                ? DecorationImage(image: NetworkImage(product.resolvedImageUrls!.first), fit: BoxFit.cover)
                                : null,
                            ),
                            child: (product.resolvedImageUrls == null || product.resolvedImageUrls!.isEmpty) 
                                ? Icon(Icons.image, size: 20, color: Colors.grey[500]) : null,
                          ),
                          title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, 
                              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                          subtitle: Text(
                            'SKU: ${product.sku}', 
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])
                          ),
                          trailing: Text(
                             CurrencyUtils.format(product.price ?? 0),
                             style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                          ),
                          onTap: () {
                            Navigator.of(context).pop(product);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
