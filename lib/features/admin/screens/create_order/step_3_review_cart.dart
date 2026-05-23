import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/create_order_provider.dart';
import '../../../../core/utils/currency_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/settings_provider.dart';

class Step3ReviewCart extends ConsumerWidget {
  const Step3ReviewCart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createOrderProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.cartItems.isEmpty) {
      return Center(child: Text("Cart is empty", style: TextStyle(color: isDark ? Colors.white : Colors.black)));
    }

// Calculate totals
    final settings = ref.watch(adminSettingsProvider);
    final priceIncludesGst = settings.priceIncludesGst;
    final discountPct = state.selectedUser?.role == 'dealer' ? (state.selectedUser?.discountPercentage ?? 0.0) : 0.0;

    double subtotal = 0.0;
    double taxAmount = 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Items
           Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              decoration: BoxDecoration(
                 color: isDark ? AppColors.surfaceDark : Colors.white,
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ...state.cartItems.entries.map((entry) {
                    final product = state.productDetails[entry.key];
                    if (product == null) return const SizedBox.shrink();
                    
                    double rawPrice = (product.price ?? 0).toDouble();
                    if (priceIncludesGst && (product.gstPercent ?? 0) > 0) {
                       rawPrice = rawPrice / (1 + (product.gstPercent ?? 0) / 100);
                    }
                    final dpPrice = discountPct > 0 ? rawPrice * (1 - discountPct / 100) : rawPrice;
                    final lineTotal = dpPrice * entry.value;
                    subtotal += lineTotal;
                    taxAmount += lineTotal * (product.gstPercent ?? 0) / 100;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                           Container(
                             width: 48, height: 48,
                             decoration: BoxDecoration(
                               borderRadius: BorderRadius.circular(8),
                               color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                             ),
                             child: ClipRRect(
                               borderRadius: BorderRadius.circular(8),
                               child: CachedNetworkImage(
                                 imageUrl: product.primaryImageUrl,
                                 fit: BoxFit.cover,
                                 placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                 errorWidget: (context, url, error) => Icon(Icons.image, size: 20, color: Colors.grey.shade400),
                               ),
                             ),
                           ),
                           const SizedBox(width: 12),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                   style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                                 ),
                                 Text('Qty: ${entry.value}', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13)),
                               ],
                             ),
                           ),
                           const SizedBox(width: 16),
                           Text(
                             CurrencyUtils.format(lineTotal),
                             style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                           ),
                        ],
                      ),
                    );
                  }),
                  Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, height: 1),
                  
                  Builder(
                    builder: (context) {
                      final shippingCharge = subtotal > 0 ? settings.shippingCharge : 0.0;
                      final grandTotal = subtotal + shippingCharge + taxAmount;
                      
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Subtotal', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                Text(CurrencyUtils.format(subtotal), style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (shippingCharge > 0)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Shipping', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                  Text(CurrencyUtils.format(shippingCharge), style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                                ],
                              ),
                            if (shippingCharge > 0)
                              const SizedBox(height: 8),
                            if (taxAmount > 0)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Tax (GST)', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                  Text(CurrencyUtils.format(taxAmount), style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                                ],
                              ),
                            const SizedBox(height: 12),
                            Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                                Text(CurrencyUtils.format(grandTotal), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary)),
                              ],
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Customer & Address Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
               color: isDark ? AppColors.surfaceDark : Colors.white,
               borderRadius: BorderRadius.circular(12),
               border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shipping Details',
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                   children: [
                     CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          (state.selectedUser?.name ?? '?')[0].toUpperCase(), 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        ),
                     ),
                     const SizedBox(width: 12),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             state.shippingAddress?['name'] ?? state.selectedUser?.name ?? 'Unknown',
                             style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                           ),
                           if (state.shippingAddress?['street'] != null)
                             Text(
                               '${state.shippingAddress!['street']}, ${state.shippingAddress!['city']}',
                               style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13),
                             ),
                           if (state.shippingAddress?['zipCode'] != null)
                             Text(
                               '${state.shippingAddress!['state']}, ${state.shippingAddress!['zipCode']}',
                               style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13),
                             ),
                           Text(
                             state.shippingAddress?['phone'] ?? state.selectedUser?.phone ?? '',
                             style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13),
                           ),
                         ],
                       ),
                     )
                   ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
