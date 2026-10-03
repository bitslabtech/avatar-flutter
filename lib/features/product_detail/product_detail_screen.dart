import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:readmore/readmore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../models/product.dart';
import '../../models/order.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/reviews_provider.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/swipe_to_action_button.dart';
import '../../widgets/common/full_screen_image_viewer.dart';
import '../wishlist/providers/wishlist_provider.dart';
import '../admin/providers/settings_provider.dart';

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
  int _activeTab = 0;
  int _selectedImageIndex = 0;
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
          const SnackBar(
            content: Text('Product added to cart'),
            backgroundColor: AppColors.successGreen,
            duration: Duration(seconds: 2),
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
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productProvider(widget.productId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return productAsync.when(
      data: (product) => _buildDetails(context, product, isDark),
      loading: () => const Scaffold(
        body: Center(child: LoadingIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
        body: AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.refresh(productProvider(widget.productId)),
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, Product product, bool isDark) {
    const heroHeight = 350.0;
    const overlayOverlap = 300.0;

    final images = product.resolvedImages.isNotEmpty
        ? product.resolvedImages
        : ((product.resolvedImageUrls != null && product.resolvedImageUrls!.isNotEmpty)
            ? product.resolvedImageUrls!
            : (product.primaryImageUrl.isNotEmpty ? [product.primaryImageUrl] : <String>[]));
    final currentImageUrl = images.isNotEmpty && _selectedImageIndex < images.length
        ? images[_selectedImageIndex]
        : (images.isNotEmpty ? images.first : product.primaryImageUrl);

    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAuthenticated = authState.isAuthenticated && user != null;
    final isPendingDealer = user != null && user.isDealer && user.status == 'pending';
    final isRejected = user != null && user.status == 'rejected';
    final shouldShowPrice = isAuthenticated && !isPendingDealer && !isRejected && product.price != null;
    final globalSettings = ref.watch(adminSettingsProvider);
    final displayPrice = product.getDisplayPrice(user, isGstInclusive: globalSettings.priceIncludesGst);
    final originalDisplayPrice = product.getOriginalDisplayPrice(isGstInclusive: globalSettings.priceIncludesGst);
    final hasDiscount = user != null && user.isDealer && !isPendingDealer && (user.discountPercentage > 0);
    final discountPercent = shouldShowPrice
        ? (product.discountPercentage ??
            (product.mrp != null && product.price != null && product.mrp! > product.price! && product.mrp! > 0
                ? (((product.mrp! - product.price!) / product.mrp!) * 100).round()
                : null))
        : null;

    final wishlistState = ref.watch(wishlistProvider);
    final isWishlisted = wishlistState.productIds.contains(product.id);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6),
      body: Stack(
        children: [
          // 1. Static Background Hero Image (Tap to open full screen)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                final activeImages = images.isNotEmpty
                    ? images
                    : (currentImageUrl.isNotEmpty ? [currentImageUrl] : <String>[]);
                if (activeImages.isNotEmpty) {
                  FullScreenImageViewer.open(
                    context,
                    imageUrls: activeImages,
                    initialIndex: _selectedImageIndex.clamp(0, activeImages.length - 1),
                  );
                }
              },
              child: Container(
                color: isDark ? const Color(0xFF1E2226) : const Color(0xFFF3F4F6),
                padding: const EdgeInsets.only(top: 45, bottom: 55),
                child: Center(
                  child: Hero(
                    tag: 'product-${product.id}',
                    child: currentImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: currentImageUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.kitchen_rounded,
                              size: 60,
                              color: Colors.grey,
                            ),
                          )
                        : const Icon(
                            Icons.kitchen_rounded,
                            size: 60,
                            color: Colors.grey,
                          ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Scrollable Content Layer overlapping the image
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Tap Target directly covering the Hero Image area in the scrollable layer
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      final activeImages = images.isNotEmpty
                          ? images
                          : (currentImageUrl.isNotEmpty ? [currentImageUrl] : <String>[]);
                      if (activeImages.isNotEmpty) {
                        FullScreenImageViewer.open(
                          context,
                          imageUrls: activeImages,
                          initialIndex: _selectedImageIndex.clamp(0, activeImages.length - 1),
                        );
                      }
                    },
                    child: const SizedBox(
                      height: overlayOverlap,
                      width: double.infinity,
                    ),
                  ),

                  // The Overlapping Rounded Content Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2226) : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag Indicator Bar
                        Center(
                          child: Container(
                            width: 36,
                            height: 4.5,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : Colors.black12,
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Image Thumbnails Row if multiple images
                        if (images.length > 1)
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: images.length,
                              itemBuilder: (context, idx) {
                                final isSelected = idx == _selectedImageIndex;
                                return GestureDetector(
                                  onTap: () {
                                    final activeImages = images.isNotEmpty
                                        ? images
                                        : (currentImageUrl.isNotEmpty ? [currentImageUrl] : <String>[]);
                                    if (_selectedImageIndex == idx && activeImages.isNotEmpty) {
                                      FullScreenImageViewer.open(
                                        context,
                                        imageUrls: activeImages,
                                        initialIndex: idx.clamp(0, activeImages.length - 1),
                                      );
                                    } else {
                                      setState(() {
                                        _selectedImageIndex = idx;
                                      });
                                    }
                                  },
                                  child: Container(
                                    width: 60,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      color: isDark ? const Color(0xFF262A2E) : const Color(0xFFF8F9FA),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: images[idx],
                                        fit: BoxFit.contain,
                                        placeholder: (_, __) => Container(
                                          color: isDark ? const Color(0xFF262A2E) : const Color(0xFFF8F9FA),
                                        ),
                                        errorWidget: (_, __, ___) => const Icon(
                                          Icons.broken_image,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Title & Price Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                  height: 1.25,
                                ),
                              ),
                              if (shouldShowPrice) ...[
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      CurrencyUtils.format(displayPrice),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    if (hasDiscount || (product.mrp != null && product.mrp! > displayPrice)) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        CurrencyUtils.format(hasDiscount ? originalDisplayPrice : product.mrp!),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textMuted,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                              const SizedBox(height: 10),

                              // Brand, Category & Discount Badges
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (product.brand.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        product.brand,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  if (product.category.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF2B2F33) : const Color(0xFFF1F3F5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        product.category,
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  if (discountPercent != null && discountPercent > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$discountPercent% OFF',
                                        style: const TextStyle(
                                          color: Color(0xFF047857),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF16A34A)),
                                        SizedBox(width: 4),
                                        Text(
                                          'In Stock',
                                          style: TextStyle(
                                            color: Color(0xFF16A34A),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Interactive Variation Selector
                              _buildVariationSelector(context, product, isDark),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // About Product (Description)
                        if (product.description != null && product.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'About Product',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ReadMoreText(
                                  product.description!,
                                  trimLines: 3,
                                  colorClickableText: AppColors.primary,
                                  trimMode: TrimMode.Line,
                                  trimCollapsedText: 'Read more',
                                  trimExpandedText: ' Show less',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    height: 1.5,
                                    color: isDark ? Colors.white70 : AppColors.textMuted,
                                  ),
                                  moreStyle: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),

                        // 3 Capsule Segmented Tabs
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2B2F33) : const Color(0xFFF1F4F9),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                _buildTab(0, 'Details', isDark),
                                _buildTab(1, 'Specs', isDark),
                                _buildTab(2, 'Delivery', isDark),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tab content
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildTabContent(product, isDark),
                        ),

                        const SizedBox(height: 20),

                        // Customer Reviews
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildReviews(context, isDark, AppColors.primary),
                        ),

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Top Floating App Bar (Back & Favorite)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2226) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final isAdded = await ref.read(wishlistProvider.notifier).toggleWishlist(product);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isAdded ? '${product.name} added to Wishlist' : '${product.name} removed from Wishlist'),
                          backgroundColor: isAdded ? AppColors.successGreen : Colors.black87,
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2226) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isWishlisted ? AppColors.errorRed : (isDark ? Colors.white : AppColors.textPrimary),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Fixed Bottom Bar: Add to Cart & Buy Now
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStickyBottomBar(context, product, isAuthenticated, AppColors.primary, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title, bool isDark) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF1E2226) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? (isDark ? Colors.white : AppColors.textPrimary)
                  : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(Product product, bool isDark) {
    if (_activeTab == 0) {
      return Column(
        children: [
          _buildInfoRow('Brand', product.brand.isNotEmpty ? product.brand : 'Avatar', isDark),
          _buildInfoRow('Category', product.category.isNotEmpty ? product.category : 'Kitchenware', isDark),
          if (product.size != null && product.size!.isNotEmpty)
            _buildInfoRow('Size', product.size!, isDark),
          if (product.variant != null && product.variant!.isNotEmpty)
            _buildInfoRow('Variant', product.variant!, isDark),
          if (product.sku.isNotEmpty)
            _buildInfoRow('SKU', product.sku, isDark),
          if (product.gstPercent != null || product.taxPercent != null)
            _buildInfoRow('GST Rate', '${(product.gstPercent ?? product.taxPercent)!.toStringAsFixed(0)}%', isDark),
          if (product.warrantyPeriod != null && product.warrantyPeriod!.isNotEmpty)
            _buildInfoRow('Warranty', product.warrantyPeriod!, isDark),
        ],
      );
    } else if (_activeTab == 1) {
      if (product.specs != null && product.specs!.isNotEmpty) {
        final visibleSpecs = product.specs!.entries
            .where((e) => e.key != 'pricingDetails' && e.key != '_pricingDetails' && e.value != null && e.value.toString().isNotEmpty)
            .toList();
        if (visibleSpecs.isNotEmpty) {
          return Column(
            children: visibleSpecs
                .map((e) => _buildInfoRow(e.key, e.value?.toString() ?? '', isDark))
                .toList(),
          );
        }
      }
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Premium Food-Grade Stainless Steel manufacturing by Avatar (From the house of SKW). Crafted with precision engineering for superior thermal distribution and lifetime durability.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5),
        ),
      );
    } else {
      return const Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.local_shipping_outlined, size: 20, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Direct dispatch from SKW manufacturing warehouse. Dispatched within 24-48 hours with door-step tracked delivery.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_outlined, size: 20, color: Color(0xFF16A34A)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '100% Genuine Avatar quality assurance guarantee with full manufacturer support.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
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

        final uniqueSizes = variations.map((p) => p.size).where((s) => s != null && s.isNotEmpty).toSet().toList();
        final uniqueVariants = variations.map((p) => p.variant).where((v) => v != null && v.isNotEmpty).toSet().toList();

        uniqueSizes.sort();
        uniqueVariants.sort();

        final variationType = (currentProduct.variationType ?? variations.first.variationType ?? '').toLowerCase();
        final showColor = variationType.contains('color') || variationType.contains('style') || variationType.contains('mixture');
        final showSize = variationType.contains('size') || variationType.contains('dimension');

        final displayColor = showColor || (!showColor && !showSize && uniqueVariants.isNotEmpty);
        final displaySize = showSize || (!showColor && !showSize && uniqueSizes.isNotEmpty);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (displayColor && uniqueVariants.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Choose Option:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: uniqueVariants.map((variant) {
                  final isSelected = currentProduct.variant == variant;
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
                      }
                    },
                  );
                }).toList(),
              ),
            ],
            if (displaySize && uniqueSizes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Choose Size:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: uniqueSizes.map((size) {
                  final isSelected = currentProduct.size == size;
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
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildChoiceChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark ? const Color(0xFF262D3D) : const Color(0xFFF1F4F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF333E54) : Colors.transparent),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildStickyBottomBar(
    BuildContext context,
    Product product,
    bool isAuthenticated,
    Color primaryColor,
    bool isDark,
  ) {
    final user = ref.watch(authProvider).user;
    final isPendingDealer = user != null && user.isDealer && user.status == 'pending';
    final isRejected = user != null && user.status == 'rejected';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2226) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2E343A) : AppColors.borderLight,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      child: (isPendingDealer || isRejected)
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                  disabledForegroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: Icon(isRejected ? Icons.block : Icons.lock_clock, size: 20),
                label: Text(
                  isRejected ? 'Account Rejected' : 'Pending Approval',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            )
          : !isAuthenticated
              ? SwipeToActionButton(
                  text: 'Swipe to Login & View Price',
                  onSwiped: () => context.push('/auth-choice'),
                )
              : Row(
                  children: [
                    // 1. Add to Cart Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleAddToCart(context, ref, product),
                        icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                        label: const Text(
                          'Add to Cart',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
                          side: BorderSide(
                            color: isDark ? const Color(0xFF3A4048) : AppColors.borderLight,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 2. Buy Now Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await ref.read(cartProvider.notifier).addToCart(product);
                          if (context.mounted) {
                            context.push('/checkout');
                          }
                        },
                        icon: const Icon(Icons.flash_on_rounded, size: 18),
                        label: const Text(
                          'Buy Now',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                if (isAuthenticated && !isPendingDealer)
                  Consumer(
                    builder: (context, ref, child) {
                      final ordersState = ref.watch(ordersProvider);
                      final hasPurchased = ordersState.orders.any((o) =>
                          o.status == OrderStatus.delivered &&
                          o.items.any((i) => i.productId == widget.productId));

                      if (!hasPurchased) return const SizedBox.shrink();

                      return TextButton(
                        onPressed: () => _showWriteReviewDialog(context, isDark),
                        child: Text('Write a Review', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262A2E) : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                index < avgRating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                                color: AppColors.dealerGold,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${reviews.length} Reviews',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(5, (index) {
                    final star = 5 - index;
                    final count = distribution[star] ?? 0;
                    final percentage = reviews.isEmpty ? 0.0 : count / reviews.length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 12,
                            child: Text(
                              '$star',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          const Icon(Icons.star_rounded, size: 14, color: AppColors.dealerGold),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage,
                                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.dealerGold),
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
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (!_showAllReviews && reviews.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => setState(() => _showAllReviews = true),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        child: Text(
                          'Read All Reviews',
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (_showAllReviews) ...[
              const SizedBox(height: 16),
              ...reviews.map((review) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF262A2E) : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
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
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _formatDate(review.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: AppColors.dealerGold,
                              size: 16,
                            ),
                          ),
                        ),
                        if (review.comment != null && review.comment!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            review.comment!,
                            style: TextStyle(
                              color: isDark ? Colors.grey[300] : AppColors.textPrimary,
                              fontSize: 13.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => setState(() => _showAllReviews = false),
                  child: const Text('Show Less', style: TextStyle(color: AppColors.primary)),
                ),
              ),
            ],
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
                color: isDark ? const Color(0xFF1E2226) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  Text(
                    'Rate this Product',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'How was your experience?',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                            color: index < rating ? AppColors.dealerGold : (isDark ? Colors.grey[700] : Colors.grey[300]),
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      controller: commentController,
                      maxLines: 4,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Write your thoughts here...',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF262A2E) : const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          Navigator.pop(context);
                          await ref
                              .read(reviewsProvider(widget.productId).notifier)
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
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Submit Review',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
