import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/create_order_provider.dart';
import '../../../../core/utils/currency_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Step3ReviewCart extends ConsumerWidget {
  const Step3ReviewCart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createOrderProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.cartItems.isEmpty) {
      return Center(child: Text("Cart is empty", style: TextStyle(color: isDark ? Colors.white : Colors.black)));
    }

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
                           const SizedBox(width: 16), // Added spacing to prevent title touching price
                   Builder(
                     builder: (context) {
                       final priceWithGst = (product.price ?? 0) * (1 + (product.gstPercent ?? 0) / 100);
                       final lineTotal = priceWithGst * entry.value;
                       
                       return Text(
                         CurrencyUtils.format(lineTotal),
                         style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                       );
                     }
                   ),
                        ],
                      ),
                    );
                  }),
                  Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                         Text(CurrencyUtils.format(state.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryBlue)),
                      ],
                    ),
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
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                        child: Text(
                          (state.selectedUser?.name ?? '?')[0].toUpperCase(), 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
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
