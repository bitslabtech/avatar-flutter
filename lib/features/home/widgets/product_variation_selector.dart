import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product.dart';
import '../../../providers/catalog_provider.dart';
import '../../../core/utils/currency_utils.dart';

class ProductVariationSelector extends ConsumerStatefulWidget {
  final Product parentProduct;
  final Function(Product) onAddToCart;

  const ProductVariationSelector({
    super.key,
    required this.parentProduct,
    required this.onAddToCart,
  });

  @override
  ConsumerState<ProductVariationSelector> createState() => _ProductVariationSelectorState();
}

class _ProductVariationSelectorState extends ConsumerState<ProductVariationSelector> {
  late Product _selectedProduct;

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.parentProduct;
  }

  @override
  Widget build(BuildContext context) {
    // If no group ID, shouldn't be here, but handle gracefully
    final groupId = widget.parentProduct.variationGroupId;
    if (groupId == null) return const SizedBox.shrink();

    final variationsAsync = ref.watch(relatedVariationsProvider(groupId));

    return Container(
       padding: const EdgeInsets.all(16),
       decoration: const BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
       ),
       child: Column(
         mainAxisSize: MainAxisSize.min,
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
           // Drag Handle
           Center(
             child: Container(
               width: 40,
               height: 4,
               margin: const EdgeInsets.only(bottom: 16),
               decoration: BoxDecoration(
                 color: Colors.grey[300],
                 borderRadius: BorderRadius.circular(2),
               ),
             ),
           ),

           // Selected Product Preview
           Row(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               ClipRRect(
                 borderRadius: BorderRadius.circular(8),
                 child: CachedNetworkImage(
                   imageUrl: _selectedProduct.primaryImageUrl,
                   width: 80,
                   height: 80,
                   fit: BoxFit.contain,
                   placeholder: (_, __) => Container(color: Colors.grey[100]),
                   errorWidget: (_, __, ___) => Container(color: Colors.grey[100], child: const Icon(Icons.error)),
                 ),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       _selectedProduct.name,
                       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                       maxLines: 2,
                       overflow: TextOverflow.ellipsis,
                     ),
                     const SizedBox(height: 8),
                     Text(
                       CurrencyUtils.format(_selectedProduct.price),
                       style: TextStyle(
                         fontSize: 16,
                         fontWeight: FontWeight.bold,
                         color: Theme.of(context).colorScheme.primary,
                       ),
                     ),
                     if (_selectedProduct.variant != null || _selectedProduct.size != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Selected: ${_getVariantLabel(_selectedProduct)}',
                             style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ),
                   ],
                 ),
               ),
             ],
           ),

           const SizedBox(height: 24),
           const Text('Select Option', style: TextStyle(fontWeight: FontWeight.bold)),
           const SizedBox(height: 12),

           // Variations List
           variationsAsync.when(
             data: (variations) {
               if (variations.isEmpty) {
                  return const Text('No other variations available');
               }
               // Ensure current product is in the list
               final allVariations = [...variations];
               if (!allVariations.any((p) => p.id == widget.parentProduct.id)) {
                  allVariations.insert(0, widget.parentProduct);
               }
               // Remove duplicates just in case
               final uniqueVariations = { for (var v in allVariations) v.id : v }.values.toList();

               return Wrap(
                 spacing: 12,
                 runSpacing: 12,
                 children: uniqueVariations.map((product) {
                   final isSelected = product.id == _selectedProduct.id;
                   return GestureDetector(
                     onTap: () {
                       setState(() => _selectedProduct = product);
                     },
                     child: _buildVariantChip(product, isSelected),
                   );
                 }).toList(),
               );
             },
             loading: () => const Center(child: CircularProgressIndicator()),
             error: (err, stack) => Text('Error loading variations: $err', style: const TextStyle(color: Colors.red)),
           ),

           const SizedBox(height: 32),

           // Add to Cart Button
           ElevatedButton(
             onPressed: () => widget.onAddToCart(_selectedProduct),
             style: ElevatedButton.styleFrom(
               backgroundColor: Theme.of(context).colorScheme.primary,
               foregroundColor: Colors.white,
               padding: const EdgeInsets.symmetric(vertical: 16),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               elevation: 0,
             ),
             child: const Text('Add to Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
           ),
           SizedBox(height: 16 + MediaQuery.of(context).viewPadding.bottom), // Bottom safety for system nav
         ],
       ),
    );
  }
  
  String _getVariantLabel(Product p) {
     if (p.variant != null && p.variant!.isNotEmpty) return p.variant!;
     if (p.size != null && p.size!.isNotEmpty) return p.size!;
     // Fallback to extraction from name if possible, or just "Option"
     return 'Option';
  }

  Widget _buildVariantChip(Product product, bool isSelected) {
    // If color variant, show color circle?
    // We don't have explicit hex code in model yet, but might be in 'variant' text (e.g. "Red")
    // For now, simpler text/image chip.
    // If we have images, show small thumbnail.
    
    return Container(
      width: 70, // Fixed width for uniformity
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[200]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
           ClipRRect(
             borderRadius: BorderRadius.circular(4),
             child: CachedNetworkImage(
               imageUrl: product.primaryImageUrl,
               width: 60,
               height: 60,
               fit: BoxFit.contain,
               placeholder: (_, __) => Container(color: Colors.grey[100]),
             ),
           ),
           const SizedBox(height: 4),
           Text(
             _getVariantLabel(product),
             style: TextStyle(
               fontSize: 11,
               fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
               color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
             ),
             maxLines: 1,
             overflow: TextOverflow.ellipsis,
             textAlign: TextAlign.center,
           ),
        ],
      ),
    );
  }
}
