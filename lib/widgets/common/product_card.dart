/// Reusable product card widget
/// Used in product grids with Hero animation support and animated wishlist button
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product.dart';
import '../../core/utils/currency_utils.dart';
import '../../features/admin/providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../features/wishlist/providers/wishlist_provider.dart';

class ProductCard extends ConsumerStatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final bool showPrice;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.showPrice = true,
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard>
    with TickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;

  late AnimationController _cartController;
  late Animation<double> _cartScaleAnimation;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.easeInOut,
    ));

    _cartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _cartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _cartController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _heartController.dispose();
    _cartController.dispose();
    super.dispose();
  }

  Future<void> _handleWishlistTap() async {
    final user = ref.read(authProvider).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to use wishlist')),
      );
      return;
    }
    _heartController.forward(from: 0);
    await ref.read(wishlistProvider.notifier).toggleWishlist(widget.product);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final settings = ref.watch(adminSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = AppColors.primaryBlueFor(isDark);
    final isPendingDealer = user != null && user.isDealer && user.status == 'pending';
    final isRejected = user != null && user.status == 'rejected';
    final shouldShowPrice = widget.showPrice && !isPendingDealer && !isRejected;
    final isInWishlist = ref.watch(wishlistProvider).productIds.contains(widget.product.id);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    Hero(
                      tag: 'product-${widget.product.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: widget.product.primaryImageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Container(
                            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                            child: const Icon(Icons.image_not_supported, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),

                    // Badge (Top Left)
                    if (widget.product.badge != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getBadgeColor(widget.product.badge!),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                            ],
                          ),
                          child: Text(
                            widget.product.badge!.toUpperCase(),
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
                    if (widget.product.variationGroupId != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.style_outlined, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Options', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),

                    // ❤️ Wishlist Button (Top Right) — always visible
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _handleWishlistTap,
                        child: AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) => Transform.scale(
                            scale: _scaleAnimation.value,
                            child: child,
                          ),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, animation) => ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                              child: Icon(
                                isInWishlist ? Icons.favorite : Icons.favorite_border,
                                key: ValueKey(isInWishlist),
                                size: 16,
                                color: isInWishlist ? Colors.red : Colors.white,
                              ),
                            ),
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
                        const SizedBox(height: 4),
                        Text(
                          widget.product.name,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.backgroundBlack,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    // Price Row & Cart Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              if (shouldShowPrice && widget.product.price != null) {
                                double displayPrice = widget.product.getDisplayPrice(user, isGstInclusive: settings.priceIncludesGst);
                                double originalDisplayPrice = widget.product.getOriginalDisplayPrice(isGstInclusive: settings.priceIncludesGst);
                                bool hasDiscount = user != null && user.isDealer && !isPendingDealer && user.discountPercentage > 0;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      CurrencyUtils.format(displayPrice),
                                      style: TextStyle(
                                        color: primaryBlue,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (hasDiscount)
                                      Text(
                                        CurrencyUtils.format(originalDisplayPrice),
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                          decoration: TextDecoration.lineThrough,
                                          decorationColor: Colors.black54,
                                        ),
                                      ),
                                  ],
                                );
                              } else if (isPendingDealer || isRejected) {
                                return Container(
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
                                );
                              } else {
                                return Text(
                                  'Login for price',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        // 🛒 Add to Cart Button (Bottom Right)
                        if (widget.onAddToCart != null && !isPendingDealer)
                          GestureDetector(
                            onTap: () {
                              _cartController.forward(from: 0.0);
                              widget.onAddToCart?.call();
                            },
                            child: AnimatedBuilder(
                              animation: _cartScaleAnimation,
                              builder: (context, child) => Transform.scale(
                                scale: _cartScaleAnimation.value,
                                child: child,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: primaryBlue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.add_shopping_cart, 
                                  size: 18, 
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                          ),
                      ],
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
      case 'new': return AppColors.primaryBlueDark;
      default: return AppColors.primaryBlueDark;
    }
  }
}
