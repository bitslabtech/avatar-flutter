/// Reusable product card widget
/// Used in product grids with Hero animation support
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../models/product.dart';
import '../../core/utils/currency_utils.dart';
import '../../features/wishlist/providers/wishlist_provider.dart';

class ProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final bool showPrice; // Whether to show price (false for guests)

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.showPrice = true, // Default to showing price
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isPendingDealer = user != null && user.isDealer && user.status == 'pending';
    final isRejected = user != null && user.status == 'rejected';
    // Show price if explicitly requested AND not pending/rejected
    final shouldShowPrice = showPrice && !isPendingDealer && !isRejected;

    if (!shouldShowPrice && !isPendingDealer) {
      debugPrint('DEBUG_PRICE: Show Login for ${product.name}. User: ${user?.role}, ShowPrice: $showPrice');
    }
    if (shouldShowPrice && product.price == null) {
      debugPrint('DEBUG_PRICE: Price NULL for ${product.name}. User: ${user?.role}');
    }

    return Container( // Changed from Card to Container for custom shadow controll
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Expanded(
                flex: 4, // More space for image
                child: Stack(
                  children: [
                      Hero(
                        tag: 'product-${product.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: product.primaryImageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[100],
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[100],
                              child: const Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                          ),
                        ),
                      ), // Added closing parenthesis
                    
                    // Badge (Top Left)
                    if (product.badge != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getBadgeColor(product.badge!),
                            borderRadius: BorderRadius.circular(6),
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
                      ),

                    // Variation Indicator
                    if (product.variationGroupId != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.style_outlined, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Options', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      
                    // Add Button Overlay (Bottom Right)
                    // Hide Add to Cart for Pending Dealers
                    if (onAddToCart != null && !isPendingDealer)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            onTap: onAddToCart,
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.add, size: 20, color: AppColors.primaryBlue),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Product info
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rating removed as per request (no data available yet)
                        // Row(children: [Icon(Icons.star...), Text('4.5')...]),
                        const SizedBox(height: 4),
                        // Product name
                        Text(
                          product.name,
                          style: const TextStyle(
                            color: AppColors.backgroundBlack,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    
                    // Price Logic
                    if (shouldShowPrice && product.price != null)
                      Builder(
                        builder: (context) {
                          // Calculate discount if dealer
                          double displayPrice = product.price!;
                          bool hasDiscount = false;
                          
                          if (user != null && user.isDealer && !isPendingDealer) {
                             final discount = user.discountPercentage ?? 0.0;
                             if (discount > 0) {
                               displayPrice = product.price! * (1 - (discount / 100));
                               hasDiscount = true;
                             }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                CurrencyUtils.format(displayPrice),
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (hasDiscount)
                                Text(
                                  CurrencyUtils.format(product.price),
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: Colors.black54, // Explicit strike color
                                  ),
                                ),
                            ],
                          );
                        }
                      )
                    else if (isPendingDealer || isRejected)
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isRejected ? Colors.red : Colors.amber).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isRejected ? Colors.red : Colors.amber),
                        ),
                        child: Text(
                          isRejected ? 'Account Rejected' : 'Approval Pending',
                          style: TextStyle(
                            color: isRejected ? Colors.red : Colors.amber,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Text(
                        'Login for price',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
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

