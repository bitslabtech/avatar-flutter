/// Product detail screen with Hero animation
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:readmore/readmore.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product.dart';
import '../../core/utils/currency_utils.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../models/review.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../providers/reviews_provider.dart';
import '../../features/wishlist/providers/wishlist_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final PageController _pageController = PageController();
  bool _showAllReviews = false;

  Future<void> _handleAddToCart(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    try {
      await ref.read(cartProvider.notifier).addToCart(product);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product added to cart'),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productProvider(widget.productId));
    final authState = ref.watch(authProvider);
    final isAuth = authState.isAuthenticated || authState.user != null;
    final isAuthenticated = isAuth; // Normalized boolean
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    // Color Palette based on design
    final bgLight = const Color(0xFFF6F7F8);
    final bgDark = const Color(0xFF101822);
    final primaryColor = const Color(0xFF136DEC);
    final textDark = const Color(0xFF111827); // Gray-900 equivalent
    final textLight = Colors.white;

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      body: productAsync.when(
        data: (product) => Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Hero Image Carousel
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800), // Responsive Centering
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildImageCarousel(context, product, isDark),

                                // Content
                                Container(
                                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), // Fixed bottom padding for sticky bar
                                  child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 2. Title & Price
                              _buildHeader(context, product, primaryColor, isDark),
                              
                              const SizedBox(height: 12),
                              
                              // 3. Rating & Stock
                              _buildRatingAndStock(context, isDark, primaryColor),

                              // Variation Selector (New)
                              _buildVariationSelector(context, product, isDark),
                              
                              const SizedBox(height: 24),
                              
                              // 4. Description
                              _buildDescription(context, product.description, primaryColor, isDark),

                              const SizedBox(height: 12),
                              Divider(color: isDark ? Colors.grey[800] : Colors.grey[200]),
                              const SizedBox(height: 12),

                              // 5. Specifications
                              if (product.specs != null && product.specs!.isNotEmpty) ...[
                                Text(
                                  'Specifications',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? textLight : textDark,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildSpecifications(context, product, isDark),
                                const SizedBox(height: 24),
                              ],

                              // 6. Reviews (Conditional - currently hidden as data missing)
                              // 6. Reviews
                              _buildReviews(context, isDark, primaryColor), 
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Stacking order continues
      ],
    ),

            // Top Buttons (Overlay)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCircleButton(
                        context, 
                        isDark, 
                        Icons.arrow_back_ios_new, 
                        () => context.pop(),
                        iconSize: 20,
                      ),
                      const SizedBox(), // Empty space for alignment
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Sticky Bar (Always visible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildStickyBottomBar(context, product, isAuthenticated, primaryColor, isDark),
            ),
          ],
        ),
        loading: () => const Scaffold(body: Center(child: LoadingIndicator())),
        error: (error, stack) => Scaffold(
          appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
          body: AppErrorWidget(
            message: error.toString(),
            onRetry: () => ref.refresh(productProvider(widget.productId)),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton(BuildContext context, bool isDark, IconData icon, VoidCallback onPressed, {double iconSize = 24, Color? color}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color ?? (isDark ? Colors.white : Colors.grey[900]),
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildImageCarousel(BuildContext context, Product product, bool isDark) {
    final images = (product.images != null && product.images!.isNotEmpty) 
        ? product.images! 
        : ['https://via.placeholder.com/400x500?text=No+Image'];

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 4 / 5,
          child: Container(
             decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
             ),
             clipBehavior: Clip.antiAlias,
             child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(child: LoadingIndicator(color: isDark ? Colors.white : Colors.blue)),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                );
              },
            ),
          ),
        ),
        
        // Gradient overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? Colors.black : Colors.black).withOpacity(0.0),
                  (isDark ? Colors.black : Colors.black).withOpacity(0.1), // Gentle shadow
                ],
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
          ),
        ),

        // Indicators
        if (images.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: images.length,
                effect: ExpandingDotsEffect(
                  activeDotColor: const Color(0xFF136DEC),
                  dotColor: Colors.white.withOpacity(0.6),
                  dotHeight: 6,
                  dotWidth: 6,
                  spacing: 6,
                ),
              ),
            ),
          ),
      // Wishlist Button - Bottom Right
        Positioned(
          bottom: 16,
          right: 16,
           child: Consumer(
            builder: (context, ref, child) {
              final wishlistState = ref.watch(wishlistProvider);
              final isWishlisted = wishlistState.productIds.contains(product.id);
              
              return _buildCircleButton(
                context,
                isDark,
                isWishlisted ? Icons.favorite : Icons.favorite_border,
                () async {
                   final isAdded = await ref.read(wishlistProvider.notifier).toggleWishlist(product);
                   if (context.mounted) {
                     ScaffoldMessenger.of(context).clearSnackBars();
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                         content: Text(isAdded ? 'Added to Wishlist' : 'Removed from Wishlist'),
                         backgroundColor: isAdded ? AppColors.successGreen : Colors.black87,
                         duration: const Duration(seconds: 1),
                         behavior: SnackBarBehavior.floating,
                       ),
                     );
                   }
                },
                color: isWishlisted ? AppColors.errorRed : null,
                iconSize: 24, // Slightly larger for primary action
              );
            }
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Product product, Color primaryColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            product.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111827),
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (product.price != null)
              Builder(
                builder: (context) {
                   final user = ref.watch(authProvider).user;
                   final isPendingDealer = user != null && user.isDealer && user.status == 'pending';
                   
                   if (isPendingDealer) return const SizedBox.shrink(); // Or show 'Pending'

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
                     crossAxisAlignment: CrossAxisAlignment.end,
                     children: [
                       Text(
                        CurrencyUtils.format(displayPrice),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      if (hasDiscount)
                        Text(
                          CurrencyUtils.format(product.price),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                            decorationColor: isDark ? Colors.white70 : Colors.black54, // Explicit strike
                          ),
                        ),
                     ],
                   );
                }
              )
            else
               const SizedBox.shrink(),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingAndStock(BuildContext context, bool isDark, Color primaryColor) {
    final reviewsAsync = ref.watch(reviewsProvider(widget.productId));

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: reviewsAsync.when(
            loading: () => const SizedBox(width: 50, height: 20, child: LoadingIndicator()),
            error: (_, __) => const SizedBox(),
            data: (reviews) {
              double avg = 0;
              if (reviews.isNotEmpty) {
                avg = reviews.map((e) => e.rating).reduce((a, b) => a + b) / reviews.length;
              }
              return Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    reviews.isEmpty ? 'New' : avg.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    height: 12,
                    width: 1,
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                  ),
                  Text(
                    '${reviews.length} Reviews',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'In Stock',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: primaryColor,
          ),
        ),
      ],
    );
  }



  Widget _buildVariationSelector(BuildContext context, Product currentProduct, bool isDark) {
    if (currentProduct.variationGroupId == null) return const SizedBox.shrink();

    final variationsAsync = ref.watch(relatedVariationsProvider(currentProduct.variationGroupId!));

    return variationsAsync.when(
      loading: () => const SizedBox(height: 50, child: LoadingIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (variations) {
        if (variations.length <= 1) return const SizedBox.shrink();

        // Check variation type to decide what to show
        // If type contains 'Color' -> Show Color Selector
        // If type contains 'Size' -> Show Size Selector (or both)
        // For simplicity, we handle 'Size' and 'Color' explicitly if data exists
        
        final uniqueSizes = variations.map((p) => p.size).where((s) => s != null).toSet().toList();
        final uniqueVariants = variations.map((p) => p.variant).where((v) => v != null).toSet().toList(); // e.g. Color
        
        // Sort them
        uniqueSizes.sort(); 
        uniqueVariants.sort();

        // Determine what to show based on the PRIMARY variation type of the group
        // We use the currentProduct's type, or fallback to the first sibling's type
        final variationType = (currentProduct.variationType ?? variations.first.variationType ?? '').toLowerCase();
        
        // Show Color if type contains 'color' or 'style' or if it's 'Color & Size'
        final showColor = variationType.contains('color') || variationType.contains('style') || variationType.contains('mixture');
        
        // Show Size if type contains 'size' or 'dimension'
        final showSize = variationType.contains('size') || variationType.contains('dimension');

        // Fallback: If neither is detected (e.g. custom type), try to guess based on data
        final autoShowColor = !showColor && !showSize && uniqueVariants.isNotEmpty;
        final autoShowSize = !showColor && !showSize && uniqueSizes.isNotEmpty;

        final displayColor = showColor || autoShowColor;
        final displaySize = showSize || autoShowSize;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            if (displayColor && uniqueVariants.isNotEmpty) ...[
              Text(
                'Color', // Or 'Variant'
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: uniqueVariants.map((variant) {
                  final isSelected = currentProduct.variant == variant;
                  // To find target product:
                  // We want a product with THIS variant (color) and SAME size as current (if size exists)
                  // Or just the first product with this variant.
                  // Best effort matching:
                  Product? target;
                  if (currentProduct.size != null) {
                     target = variations.firstWhere(
                       (p) => p.variant == variant && p.size == currentProduct.size,
                       orElse: () => variations.firstWhere((p) => p.variant == variant, orElse: () => currentProduct),
                     );
                  } else {
                     target = variations.firstWhere((p) => p.variant == variant, orElse: () => currentProduct);
                  }
                  
                  return _buildChoiceChip(
                    context, 
                    label: variant!, 
                    isSelected: isSelected, 
                    isDark: isDark,
                    onTap: () {
                      if (!isSelected && target != null) {
                         context.pushReplacement('/product/${target.id}'); 
                         // Note: pushReplacement prevents back stack pollution
                      }
                    }
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            if (displaySize && uniqueSizes.isNotEmpty) ...[
              Text(
                'Size',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: uniqueSizes.map((size) {
                  final isSelected = currentProduct.size == size;
                  // Best effort matching for Size
                  Product? target;
                  if (currentProduct.variant != null) {
                     target = variations.firstWhere(
                       (p) => p.size == size && p.variant == currentProduct.variant,
                       orElse: () => variations.firstWhere((p) => p.size == size, orElse: () => currentProduct),
                     );
                  } else {
                     target = variations.firstWhere((p) => p.size == size, orElse: () => currentProduct);
                  }

                  return _buildChoiceChip(
                    context, 
                    label: size!, 
                    isSelected: isSelected, 
                    isDark: isDark,
                    onTap: () {
                      if (!isSelected && target != null) {
                         context.pushReplacement('/product/${target.id}');
                      }
                    }
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            Divider(color: isDark ? Colors.grey[800] : Colors.grey[200]),
          ],
        );
      },
    );
  }

  Widget _buildChoiceChip(BuildContext context, {required String label, required bool isSelected, required bool isDark, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
             ? const Color(0xFF136DEC) 
             : (isDark ? Colors.grey[800] : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
             color: isSelected 
                ? const Color(0xFF136DEC) 
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
             width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
             fontWeight: FontWeight.bold,
             color: isSelected 
                ? Colors.white 
                : (isDark ? Colors.grey[300] : Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context, String? description, Color primaryColor, bool isDark) {
    final hasDescription = description != null && description.isNotEmpty;
    final displayText = hasDescription ? description : 'No description available for this product.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        ReadMoreText(
          displayText,
          trimLines: 3,
          colorClickableText: primaryColor,
          trimMode: TrimMode.Line,
          trimCollapsedText: 'Read more',
          trimExpandedText: ' Show less',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark ? Colors.grey[300] : Colors.grey[600],
            fontStyle: hasDescription ? FontStyle.normal : FontStyle.italic,
          ),
          moreStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor),
        ),
      ],
    );
  }

  Widget _buildSpecifications(BuildContext context, Product product, bool isDark) {
    final specs = product.specs!;
    final entries = specs.entries.toList();
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(entries.length, (index) {
          final entry = entries[index];
          final isLast = index == entries.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                    Text(
                      entry.value.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) 
                Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[300]),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStickyBottomBar(
    BuildContext context, 
    Product product, 
    bool isAuthenticated, 
    Color primaryColor, 
    bool isDark
  ) {
    // Access ref via context since we are in a method of class State
    // But since this is a method, we need access to ref. 
    // Optimization: Pass ref or user status from build method. 
    // However, since we are inside State<ConsumerStatefulWidget>, we have access to `ref` property directly.
    
    final user = ref.watch(authProvider).user;
    final isPendingDealer = user != null && user.isDealer && user.status == 'pending';
    final isRejected = user != null && user.status == 'rejected';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101822) : Colors.white,
        border: Border(
           top: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[100]!),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea( // respect bottom safe area
        top: false,
        child: (isPendingDealer || isRejected)
          ? Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: null, // Disabled
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey, 
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                    disabledForegroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: Icon(isRejected ? Icons.block : Icons.lock_clock, size: 20),
                  label: Text(
                    isRejected ? 'Account Rejected' : 'Pending Approval',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          : Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Price',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                  if (isAuthenticated && product.price != null && !isRejected)
                    Builder(
                      builder: (context) {
                        double displayPrice = product.price!;
                        if (user != null && user.isDealer) {
                           final discount = user.discountPercentage ?? 0.0;
                           if (discount > 0) {
                             displayPrice = product.price! * (1 - (discount / 100));
                           }
                        }
                        return Text(
                          CurrencyUtils.format(displayPrice),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        );
                      }
                    )
                  else
                    InkWell(
                      onTap: () => context.push('/auth-choice'),
                      child: Text(
                        'Login to view',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isAuthenticated && !isRejected) ...[
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _handleAddToCart(context, ref, product),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                    disabledForegroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    shadowColor: primaryColor.withOpacity(0.4),
                  ),
                  icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                  label: const Text(
                    'Add to Cart',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviews(BuildContext context, bool isDark, Color primaryColor) {
    final reviewsAsync = ref.watch(reviewsProvider(widget.productId));
    final user = ref.watch(authProvider).user;
    final isAuthenticated = ref.watch(authProvider).isAuthenticated;
    final isPendingDealer = user != null && user.isDealer && user.status == 'pending';

    return reviewsAsync.when(
      loading: () => const Center(child: LoadingIndicator()),
      error: (_, __) => const SizedBox(),
      data: (reviews) {
        // Calculate stats
        double avgRating = 0;
        final distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
        
        if (reviews.isNotEmpty) {
           avgRating = reviews.map((e) => e.rating).reduce((a, b) => a + b) / reviews.length;
           for (var r in reviews) {
             if (distribution.containsKey(r.rating)) {
               distribution[r.rating] = distribution[r.rating]! + 1;
             }
           }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customer Reviews',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                if (isAuthenticated && !isPendingDealer)
                  Consumer(
                    builder: (context, ref, child) {
                      final ordersState = ref.watch(ordersProvider);
                      // Check if user has a DELIVERED order containing this product
                      final hasPurchased = ordersState.orders.any((o) => 
                        o.status == OrderStatus.delivered && 
                        o.items.any((i) => i.productId == widget.productId)
                      );

                      if (!hasPurchased) return const SizedBox.shrink();

                      return TextButton(
                        onPressed: () => _showWriteReviewDialog(context, isDark),
                        child: Text('Write a Review', style: TextStyle(color: primaryColor)),
                      );
                    }
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                   Row(
                     children: [
                       Text(
                         avgRating.toStringAsFixed(1),
                         style: TextStyle(
                           fontSize: 48,
                           fontWeight: FontWeight.bold,
                           color: isDark ? Colors.white : const Color(0xFF111827),
                         ),
                       ),
                       const SizedBox(width: 16),
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Row(
                             children: List.generate(5, (index) => Icon(
                               index < avgRating.round() ? Icons.star : Icons.star_border,
                               color: Colors.amber,
                               size: 20,
                             )),
                           ),
                           const SizedBox(height: 4),
                           Text(
                             '${reviews.length} Reviews',
                             style: TextStyle(
                               color: isDark ? Colors.grey[400] : Colors.grey[600],
                             ),
                           ),
                         ],
                       ),
                     ],
                   ),
                   const SizedBox(height: 16),
                   // Progress Bars
                   ...List.generate(5, (index) {
                     final star = 5 - index;
                     final count = distribution[star] ?? 0;
                     final percentage = reviews.isEmpty ? 0.0 : count / reviews.length;
                     return Padding(
                       padding: const EdgeInsets.only(bottom: 8),
                       child: Row(
                         children: [
                           SizedBox(
                             width: 12,
                             child: Text(
                               '$star',
                               style: TextStyle(
                                 fontSize: 12,
                                 fontWeight: FontWeight.bold,
                                 color: isDark ? Colors.grey[400] : Colors.grey[600],
                               ),
                             ),
                           ),
                           const Icon(Icons.star, size: 12, color: Colors.grey),
                           const SizedBox(width: 8),
                           Expanded(
                             child: ClipRRect(
                               borderRadius: BorderRadius.circular(4),
                               child: LinearProgressIndicator(
                                 value: percentage,
                                 backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                                 valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                                 minHeight: 6,
                               ),
                             ),
                           ),
                           const SizedBox(width: 8),
                           SizedBox(
                             width: 24,
                             child: Text(
                               '$count',
                               textAlign: TextAlign.end,
                               style: TextStyle(
                                 fontSize: 12, 
                                 color: isDark ? Colors.grey[400] : Colors.grey[600],
                               ),
                             ),
                           ),
                         ],
                       ),
                     );
                   }),
                   
                   const SizedBox(height: 16),
                   if (!_showAllReviews && reviews.isNotEmpty)
                     SizedBox(
                       width: double.infinity,
                       child: OutlinedButton(
                         onPressed: () => setState(() => _showAllReviews = true),
                         style: OutlinedButton.styleFrom(
                           side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                           padding: const EdgeInsets.symmetric(vertical: 12),
                         ),
                         child: Text(
                           'Read All Reviews',
                           style: TextStyle(
                             color: isDark ? Colors.white : const Color(0xFF111827),
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ),
                     ),
                ],
              ),
            ),
            
            // Actual Reviews List (Conditional)
            if (_showAllReviews) ...[
               const SizedBox(height: 16),
               ...reviews.map((review) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          review.userName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          _formatDate(review.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) => Icon(
                        index < review.rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      )),
                    ),
                    if (review.comment != null && review.comment!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        review.comment!,
                        style: TextStyle(
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              )),
               
               // Collapse Button
               SizedBox(
                 width: double.infinity,
                 child: TextButton(
                   onPressed: () => setState(() => _showAllReviews = false),
                   child: Text('Show Less', style: TextStyle(color: primaryColor)),
                 ),
               ),
            ],
            
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showWriteReviewDialog(BuildContext context, bool isDark) {
    int rating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Drag Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),

                  // 2. Title
                  Text(
                    'Rate this Product',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How was your experience?',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Star Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starRating = index + 1;
                      return GestureDetector(
                        onTap: () => setModalState(() => rating = starRating),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                            color: index < rating ? Colors.amber : (isDark ? Colors.grey[700] : Colors.grey[300]),
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 32),

                  // 4. Comment Input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      controller: commentController,
                      maxLines: 4,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Write your thoughts here...',
                        hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                        filled: true,
                        fillColor: isDark ? Colors.black.withOpacity(0.2) : Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 5. Buttons
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ElevatedButton(
                      onPressed: () async {
                         if (commentController.text.trim().isEmpty) {
                           // Optional: Validate comment
                         }
                         
                         try {
                           Navigator.pop(context); // Close modal using Navigator
                           
                           // Show loading or optimistic update?
                           // For now, simple provider call
                           await ref.read(reviewsProvider(widget.productId).notifier)
                                    .addReview(rating, commentController.text);
                           
                           if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(
                                 content: Text('Review submitted successfully!'), 
                                 backgroundColor: AppColors.successGreen,
                                 behavior: SnackBarBehavior.floating,
                               ),
                             );
                           }
                         } catch (e) {
                            if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(
                                 content: Text('Failed to submit review'), 
                                 backgroundColor: AppColors.errorRed,
                                 behavior: SnackBarBehavior.floating,
                               ),
                             );
                           }
                         }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Submit Review',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  
                  // Cancel Text Button
                   Padding(
                     padding: const EdgeInsets.symmetric(vertical: 12),
                     child: TextButton(
                       onPressed: () => Navigator.pop(context),
                       child: Text(
                         'Cancel', 
                         style: TextStyle(
                           color: isDark ? Colors.grey[400] : Colors.grey[600],
                           fontWeight: FontWeight.w600
                         )
                       ),
                     ),
                   ),

                  const SizedBox(height: 12), // Bottom padding
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


