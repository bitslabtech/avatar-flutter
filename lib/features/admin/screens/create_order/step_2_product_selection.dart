import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/product_management_provider.dart';
import '../../providers/create_order_provider.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../screens/product_list_screen.dart'; // Reusing stat card widgets if possible or just simple list

class Step2ProductSelection extends ConsumerStatefulWidget {
  const Step2ProductSelection({super.key});

  @override
  ConsumerState<Step2ProductSelection> createState() => _Step2ProductSelectionState();
}

class _Step2ProductSelectionState extends ConsumerState<Step2ProductSelection> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productManagementProvider.notifier).loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productManagementProvider);
    final createOrderNotifier = ref.read(createOrderProvider.notifier);
    final createOrderCart = ref.watch(createOrderProvider).cartItems;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter active products only for new orders
    final activeProducts = productState.filteredProducts.where((p) => p.isActive).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
               TextField(
                controller: _searchController,
                onChanged: (v) => ref.read(productManagementProvider.notifier).setSearchQuery(v),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search Product...',
                  hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Cart Summary (Optional quick view)
              if (createOrderCart.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                     children: [
                       const Icon(Icons.shopping_cart, size: 16, color: AppColors.primaryBlue),
                       const SizedBox(width: 8),
                       Text(
                         '${createOrderCart.length} items selected',
                         style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                       ),
                       const Spacer(),
                       Text(
                         'Total: ${CurrencyUtils.format(ref.read(createOrderProvider).totalAmount)}',
                         style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                       ),
                     ],
                  ),
                ),
            ],
          ),
        ),
        
        Expanded(
          child: productState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : activeProducts.isEmpty
                  ? Center(child: Text('No active products found', style: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade600)))
                  : ListView.separated(
                      itemCount: activeProducts.length,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), // Bottom padding for FAB/Next button space
                      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = activeProducts[index];
                        final quantity = createOrderCart[product.id] ?? 0;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(12),
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
                              // Image
                              Container(
                                width: 60, height: 60,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: product.primaryImageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      maxLines: 2,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      CurrencyUtils.format(product.price),
                                      style: TextStyle(
                                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Counter
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    _buildQtyBtn(isDark, Icons.remove, () {
                                       if (quantity > 0) createOrderNotifier.addToCart(product, quantity - 1);
                                    }),
                                    SizedBox(
                                      width: 32,
                                      child: Text(
                                        '$quantity',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                                      ),
                                    ),
                                    _buildQtyBtn(isDark, Icons.add, () {
                                       createOrderNotifier.addToCart(product, quantity + 1);
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildQtyBtn(bool isDark, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
       borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
      ),
    );
  }
}
