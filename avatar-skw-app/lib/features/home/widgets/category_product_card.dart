import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user.dart';

class CategoryProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onToggleWishlist;
  final bool showPrice;

  const CategoryProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onToggleWishlist,
    this.showPrice = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final user = ref.watch(authProvider).user;
    final isPendingDealer = user != null && user.isDealer && user.status == 'pending';
    final shouldShowPrice = (showPrice || user != null) && !isPendingDealer;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D2333) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isDark ? const Color(0xFF2A3245) : const Color(0xFFF1F5F9), // slate-800 / slate-100
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: product.primaryImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                  
                  // Wishlist Button (Top Right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onToggleWishlist,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          boxShadow: [
                           // Backdrop blur simulated by semi-transparent bg 
                           // Real blur needs BackdropFilter but that's expensive in lists
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Badge (Top Left)
                  if (product.badge != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getBadgeColor(product.badge!), // Helper method
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
                        boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                        ],
                      ),
                      child: Text(
                        product.badge!.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  )
                  else if (product.discountPercentage == null || product.discountPercentage == 0) // Fallback to "NEW" if no badge and no discount? Or just keep original logic?
                  // Keeping original "NEW" logic if no badge is set, but maybe "NEW" should be a badge option now?
                  // Let's rely on the explicit badge being set for now to avoid confusion.
                   const SizedBox.shrink(), // Placeholder to remove old "NEW" logic block completely if desired, or keep it as fallback.
                   // The user requirement implies they want to control "New", "Popular" etc manually.
                   // So I will remove the auto-New logic to prioritize the manual badge, OR make manual badge overlap.
                   // Let's replace the old auto-New logic with this.
                  
                  // "SALE" Badge
                   if (product.discountPercentage != null && product.discountPercentage! > 0)
                  Positioned(
                    top: product.badge != null ? 34 : 8, // Push down if badge exists
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'SALE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Variation Indicator
                  if (product.variationGroupId != null)
                    Positioned(
                      top: 8,
                      right: 40, // Offset from wishlist button
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.style_outlined, size: 12, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info Section
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6), // Reduced vertical padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Review Stars
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)), // yellow-400
                        const SizedBox(width: 4),
                        Text(
                          '4.8 (128)', // Mock data
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), // slate-400 / 500
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2), // Reduced spacing
                    
                    // Product Title
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A), // slate-900
                        height: 1.2,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Price Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (shouldShowPrice && product.price != null)
                           Builder(
                             builder: (context) {
                                double displayPrice = product.price!;
                                
                                if (user != null && user.isDealer && !isPendingDealer) {
                                   final discount = user.discountPercentage ?? 0.0;
                                   if (discount > 0) {
                                     displayPrice = product.price! * (1 - (discount / 100));
                                   }
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      CurrencyUtils.format(displayPrice),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                    if (user != null && user.isDealer && !isPendingDealer && (user.discountPercentage ?? 0) > 0)
                                      Text(
                                        CurrencyUtils.format(product.price),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                                          decoration: TextDecoration.lineThrough,
                                          decorationColor: isDark ? Colors.white70 : Colors.black54,
                                        ),
                                      ),
                                  ],
                                );
                             }
                           )
                        else if (isPendingDealer)
                           Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: const Text(
                              'Approval Pending',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                           Text(
                            'Login',
                             style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[500],
                            ),
                           ),
                        
                        // Add Button
                        if (onAddToCart != null && !isPendingDealer)
                        GestureDetector(
                          onTap: onAddToCart,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2A3245) : const Color(0xFFE2E4EA),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add,
                              size: 18,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Color _getBadgeColor(String badge) {
    switch (badge.toLowerCase()) {
      case 'new': return AppColors.primaryBlue;
      case 'popular': return Colors.orange;
      case 'bestseller': return Colors.red;
      case 'trending': return Colors.purple;
      case 'limited': return Colors.black87;
      default: return AppColors.primaryBlue;
    }
  }
}
