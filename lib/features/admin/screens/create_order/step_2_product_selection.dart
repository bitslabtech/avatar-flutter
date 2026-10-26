import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/product_management_provider.dart';
import '../../providers/create_order_provider.dart';
import '../../providers/inventory_type_provider.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../screens/product_list_screen.dart';

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
    final inventoryState = ref.watch(inventoryTypeProvider);

    String resolveUomName(String uomId) {
       return inventoryState.maybeWhen(
         data: (types) {
           final t = types.firstWhere((t) => t.id == uomId, orElse: () => InventoryTypeModel(id: '', name: 'Unit'));
           return t.name;
         },
         orElse: () => 'Unit'
       );
    }

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
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                     children: [
                       Icon(Icons.shopping_cart, size: 16, color: Theme.of(context).colorScheme.primary),
                       const SizedBox(width: 8),
                       Text(
                         '${createOrderCart.length} items selected',
                         style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                       ),
                       const Spacer(),
                       Text(
                         'Total: ${CurrencyUtils.format(ref.read(createOrderProvider).totalAmount)}',
                         style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
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
                        final cartItem = createOrderCart[product.id];
                        final orderedQty = cartItem?.orderedQty.toInt() ?? 0;
                        final currentUomId = cartItem?.orderedUomId ?? product.baseUomId;
                        final uomName = currentUomId != null ? resolveUomName(currentUomId) : 'Pc';

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
                                    fit: BoxFit.contain,
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
                              // Quantity Controls
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildQtyBtn(isDark, Icons.remove, () {
                                          if (orderedQty > 0) {
                                            int conversion = 1;
                                            if (currentUomId != product.baseUomId && product.bulkUoms != null) {
                                              final bulk = product.bulkUoms!.firstWhere((b) => b['uomId'] == currentUomId, orElse: () => null);
                                              if (bulk != null) conversion = bulk['conversionRate'] ?? 1;
                                            }
                                            final newQ = orderedQty - 1;
                                            createOrderNotifier.addToCart(product, CartItemData(qty: newQ * conversion, orderedQty: newQ.toDouble(), orderedUomId: currentUomId, orderedUomName: uomName));
                                          }
                                        }),
                                        SizedBox(
                                          width: 32,
                                          child: Text(
                                            '$orderedQty',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                                          ),
                                        ),
                                        _buildQtyBtn(isDark, Icons.add, () {
                                          int conversion = 1;
                                          if (currentUomId != product.baseUomId && product.bulkUoms != null) {
                                            final bulk = product.bulkUoms!.firstWhere((b) => b['uomId'] == currentUomId, orElse: () => null);
                                            if (bulk != null) conversion = bulk['conversionRate'] ?? 1;
                                          }
                                          final newQ = orderedQty + 1;
                                          createOrderNotifier.addToCart(product, CartItemData(qty: newQ * conversion, orderedQty: newQ.toDouble(), orderedUomId: currentUomId, orderedUomName: uomName));
                                        }),
                                      ],
                                    ),
                                  ),
                                  if (product.baseUomId != null || (product.bulkUoms != null && product.bulkUoms!.isNotEmpty))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: InkWell(
                                        onTap: () {
                                          // Show UOM selector
                                          _showUomSelector(context, product, cartItem, createOrderNotifier, resolveUomName);
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(uomName, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                            Icon(Icons.arrow_drop_down, size: 16, color: Theme.of(context).colorScheme.primary),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
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

  void _showUomSelector(BuildContext context, Product product, CartItemData? cartItem, CreateOrderNotifier notifier, String Function(String) resolveName) {
    final List<Map<String, dynamic>> options = [];
    
    if (product.baseUomId != null) {
      options.add({'uomId': product.baseUomId, 'conversionRate': 1});
    }
    
    if (product.bulkUoms != null) {
      for (var b in product.bulkUoms!) {
        options.add(b);
      }
    }

    if (options.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Select Unit of Measurement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const Divider(height: 1),
              ...options.map((opt) {
                final id = opt['uomId'] as String;
                final rate = opt['conversionRate'] as int;
                final name = resolveName(id);
                final displayName = rate == 1 ? name : '$name (x$rate)';
                
                return ListTile(
                  title: Text(displayName),
                  trailing: cartItem?.orderedUomId == id ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (cartItem != null) {
                      final baseQty = cartItem.orderedQty.toInt() * rate;
                      notifier.addToCart(product, CartItemData(
                        qty: baseQty,
                        orderedQty: cartItem.orderedQty,
                        orderedUomId: id,
                        orderedUomName: name,
                      ));
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
