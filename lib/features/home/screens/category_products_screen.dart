import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/catalog_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/error_widget.dart';
import '../../../widgets/common/loading_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/category_product_card.dart';
import '../../wishlist/providers/wishlist_provider.dart';

class CategoryProductsScreen extends ConsumerStatefulWidget {
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryName,
  });

  @override
  ConsumerState<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends ConsumerState<CategoryProductsScreen> {

  Future<void> _handleAddToCart(product) async {
    try {
      await ref.read(cartProvider.notifier).addToCart(product);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added to cart'),
            backgroundColor: AppColors.successGreen,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating, // Floating for better visibility
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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

  Widget _buildSortOption(BuildContext context, String label, String sortBy, String sortOrder, bool isDark) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.grey[300] : Colors.grey[800],
          fontSize: 16,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[500]),
      onTap: () {
        context.pop(); // Close modal
        ref.read(categoryProductsProvider(widget.categoryName).notifier).setSort(sortBy, sortOrder);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch specific category provider
    final productsState = ref.watch(categoryProductsProvider(widget.categoryName));
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101522) : const Color(0xFFF6F6F8), // Matches design bg
      body: CustomScrollView(
        slivers: [
          // 1. Solid App Bar
          SliverAppBar(
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF101522) : const Color(0xFFF6F6F8),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
              onPressed: () => context.pop(),
            ),
            title: Text(
               widget.categoryName, 
               style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
            ),
            actions: [
              if (authState.isAuthenticated && authState.user?.status != 'rejected')
               IconButton(
                icon: Stack(
                  children: [
                    Icon(Icons.shopping_cart_outlined, color: isDark ? Colors.white : Colors.black),
                    Consumer(builder: (context, ref, child) {
                        final cartCount = ref.watch(cartProvider).itemCount;
                        if (cartCount == 0) return const SizedBox.shrink();
                        return Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            '$cartCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                onPressed: () => context.go('/cart'),
              ),
            ],
          ),

          // 2. Banner Image (Moved out of AppBar)
          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, child) {
                 final categoriesAsync = ref.watch(categoriesProvider);
                 final category = categoriesAsync.value?.where((c) => c.name == widget.categoryName).firstOrNull;
                 
                 final imageUrl = (category?.resolvedImageUrl != null && category!.resolvedImageUrl!.isNotEmpty) 
                     ? category.resolvedImageUrl! 
                     : "https://lh3.googleusercontent.com/aida-public/AB6AXuDDaNXGPkjbRx1_W2kLqKSuvvvBJO5R55LZulzR7WbHInQOLanp2JPb99WikejFU79m4d04yO7Jth7mMoJSelqQOrrZCSr1-k2QwHuZ0cDg0y5TG5B-N6f1rV7CYDTCUfjEzu88hY50ivRaZqphA8W3-8BVZ1WvX2Jq2oI-2u70Q06L2HA__N-W4GpFE-hYDnO1D4eSnmeO8a3YdBtrJssHaS4Kxy_1Bw6JJGY6nRauBJ4L89bGm7P9uRAE1z4Ec5oM04tReTrbmBxi"; // Fallback placeholder
                 
                 final displayTitle = category?.title ?? widget.categoryName;
                 final description = category?.description ?? 'Discover the future of ${widget.categoryName.toLowerCase()}.';

                 return Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      // Banner Image - Full Width, Dynamic Height
                      CachedNetworkImage(
                        imageUrl: imageUrl, 
                        width: double.infinity,
                        height: 200, // Fixed height to prevent "long in height" issue
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(height: 200, color: Colors.grey[800]),
                        errorWidget: (context, url, error) => Container(height: 200, color: Colors.grey[800]),
                      ),
                      // Gradient Overlay (Positioned.fill matches image size)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.1),
                                Colors.black.withOpacity(0.8),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Text Content
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayTitle, 
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                                shadows: const [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
              },
            ),
          ),

          // 2. Sticky Search Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickySearchBarDelegate(
              minHeight: 80,
              maxHeight: 80,
              child: Container(
                color: isDark ? const Color(0xFF101522) : const Color(0xFFF6F6F8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1D2333) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2A3245) : const Color(0xFFE2E4EA),
                          ),
                        ),
                        child: TextField(
                          onSubmitted: (value) {
                             ref.read(categoryProductsProvider(widget.categoryName).notifier).loadProducts(
                               category: widget.categoryName,
                               search: value,
                             );
                          },
                          decoration: InputDecoration(
                            hintText: 'Search ${widget.categoryName}...',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey[500], size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: isDark ? const Color(0xFF1D2333) : Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => Container(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sort By',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildSortOption(context, 'Price: Low to High', 'price', 'ASC', isDark),
                                _buildSortOption(context, 'Price: High to Low', 'price', 'DESC', isDark),
                                _buildSortOption(context, 'Newest First', 'createdAt', 'DESC', isDark),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1D2333) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2A3245) : const Color(0xFFE2E4EA),
                          ),
                        ),
                        child: Icon(Icons.tune, color: isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Product Grid
          Builder(
            builder: (context) {
              if (productsState.isLoading && productsState.products.isEmpty) {
                return const SliverFillRemaining(child: Center(child: LoadingIndicator()));
              }
              
              if (productsState.error != null && productsState.products.isEmpty) {
                 return SliverFillRemaining(
                   child: AppErrorWidget(
                     message: productsState.error!,
                     onRetry: () => ref.read(categoryProductsProvider(widget.categoryName).notifier).loadProducts(category: widget.categoryName),
                   ),
                 );
              }

              if (productsState.products.isEmpty) {
                 return SliverFillRemaining(
                   child: Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                         const SizedBox(height: 16),
                         Text(
                           'No products found in ${widget.categoryName}',
                           style: TextStyle(color: Colors.grey[600], fontSize: 16),
                         ),
                       ],
                     ),
                   ),
                 );
              }
              
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65, // Taller aspect ratio for new card
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = productsState.products[index];
                      return CategoryProductCard(
                        product: product,
                        showPrice: authState.isAuthenticated,
                        onAddToCart: authState.isAuthenticated ? () => _handleAddToCart(product) : null,
                        onTap: () => context.push('/product/${product.id}'),
                        onToggleWishlist: () async {
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
                      );
                    },
                    childCount: productsState.products.length,
                  ),
                ),
              );
            },
          ),
          
          // 4. Bottom Padding / Load More Placeholder
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickySearchBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickySearchBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
