// Home screen with banner slider, categories, and product grid
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/error_widget.dart';
import 'widgets/banner_slider.dart';
import 'widgets/category_chips.dart';
import 'widgets/product_grid.dart';
import 'widgets/home_skeleton.dart';
import '../../widgets/common/product_card.dart';
import '../notifications/widgets/notification_bell.dart';
import 'widgets/product_variation_selector.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  const HomeScreen({super.key, this.initialCategory});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _searchController;
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Load initial data (all products)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsProvider.notifier).refresh();
      if (widget.initialCategory != null) {
        context.push('/category/${widget.initialCategory}');
      }
      
      // Load cart data if authenticated
      if (ref.read(authProvider).isAuthenticated) {
        ref.read(cartProvider.notifier).loadCart();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _handleSearch(String query, {bool unfocus = false}) {
    if (unfocus) _searchFocus.unfocus();
    ref.read(productsProvider.notifier).loadProducts(search: query.isEmpty ? null : query);
  }

  void _clearSearch() {
    _searchController.clear();
    _handleSearch('');
  }

  void _handleCategorySelected(String? category) {
    if (category == null) {
      // "All" selected, maybe scroll to top or just do nothing if already on home
      return;
    }
    context.pushNamed('category-products', pathParameters: {'name': category});
  }

  Future<void> _handleAddToCart(product) async {
    // Check for variations
    if (product.variationGroupId != null && product.variationGroupId!.isNotEmpty) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true, // Show above bottom navigation bar
        backgroundColor: Colors.transparent,
        builder: (context) => ProductVariationSelector(
          parentProduct: product,
          onAddToCart: (selectedProduct) {
             context.pop(); // Close sheet
             _performAddToCart(selectedProduct);
          },
        ),
      );
    } else {
       _performAddToCart(product);
    }
  }

  Future<void> _performAddToCart(product) async {
    try {
      await ref.read(cartProvider.notifier).addToCart(product);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product added to cart'),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final bannersAsync = ref.watch(bannersProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final cartState = ref.watch(cartProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Listen to auth changes to refresh products (show/hide prices)
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated) {
        ref.read(productsProvider.notifier).refresh();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Refresh all data
            ref.invalidate(bannersProvider);
            ref.invalidate(categoriesProvider);
            await ref.read(productsProvider.notifier).refresh();
          },
          child: CustomScrollView(
            slivers: [
              // 1. Sticky Header (Logo, Cart)
              SliverAppBar(
                floating: false,
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Image.asset(
                  isDark
                      ? 'assets/logo/skw-avatar-logo-dark.png'
                      : 'assets/logo/skw-avatar-logo-light.png',
                  height: 36,
                  fit: BoxFit.contain,
                ),
                centerTitle: true,
                actions: [
                  if (authState.isAuthenticated && authState.user?.status != 'rejected') ...[
                    NotificationBell(isDark: isDark),
                    Stack(
                      children: [
                        IconButton(
                          icon: Icon(Icons.shopping_cart_outlined, color: theme.iconTheme.color),
                          onPressed: () => context.go('/cart'),
                        ),
                        if (cartState.itemCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlueFor(isDark),
                                shape: BoxShape.circle,
                                border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),

              // 2. Sticky Search Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _HomeScreenSearchBarDelegate(
                  minHeight: 70, // Height + Padding
                  maxHeight: 70,
                  child: Container(
                    color: theme.scaffoldBackgroundColor, // Match bg
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    alignment: Alignment.center,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.transparent : Colors.grey[300]!,
                        ),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (val) => _handleSearch(val, unfocus: true),
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                        decoration: InputDecoration(
                          hintText: 'Find fridges, washers...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                          suffixIcon: _searchController.text.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: _clearSearch,
                                color: isDark ? Colors.grey[400] : Colors.grey[500],
                              )
                            : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (val) {
                          setState(() {});
                          
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce = Timer(const Duration(milliseconds: 500), () {
                            _handleSearch(val, unfocus: false);
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // ── Full-page skeleton while initial data loads ──────────────
              // Show the skeleton as a SliverFillRemaining overlay until BOTH
              // banners AND categories have resolved on the very first load.
              if (_searchController.text.isEmpty &&
                  (bannersAsync.isLoading || categoriesAsync.isLoading) &&
                  productsState.products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: const HomeSkeletonLoader(),
                )
              else ...[

              // Hero Carousel (Banner)
              if (_searchController.text.isEmpty)
              bannersAsync.when(
                data: (banners) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: BannerSlider(banners: banners),
                  ),
                ),
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (error, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // Category Filter Rail
              if (_searchController.text.isEmpty)
              categoriesAsync.when(
                data: (categories) => SliverToBoxAdapter(
                  child: CategoryChips(
                    categories: categories,
                    selectedCategory: null,
                    onCategorySelected: _handleCategorySelected,
                  ),
                ),
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (error, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // New Arrivals (Horizontal List)
              if (_searchController.text.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Text(
                    'New Arrivals',
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                  ),
                ),
              ),
              // New Arrivals list — skeleton while loading, real cards once ready
              if (_searchController.text.isEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 260,
                    child: productsState.isLoading && productsState.products.isEmpty
                        ? ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 4,
                            separatorBuilder: (_, __) => const SizedBox(width: 16),
                            itemBuilder: (_, __) => _HorizontalProductSkeleton(isDark: isDark),
                          )
                        : productsState.products.isNotEmpty
                            ? ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                scrollDirection: Axis.horizontal,
                                itemCount: productsState.products.take(5).length,
                                separatorBuilder: (_, __) => const SizedBox(width: 16),
                                itemBuilder: (context, index) {
                                  final product = productsState.products[index];
                                  return SizedBox(
                                    width: 160,
                                    child: ProductCard(
                                      product: product,
                                      showPrice: authState.isAuthenticated && authState.user?.status != 'rejected',
                                      onAddToCart: (authState.isAuthenticated && authState.user?.status != 'rejected')
                                          ? () => _handleAddToCart(product)
                                          : null,
                                      onTap: () => context.push('/product/${product.id}'),
                                    ),
                                  );
                                },
                              )
                            : const SizedBox.shrink(),
                  ),
                ),


              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Text(
                    _searchController.text.isNotEmpty ? 'Search Results' : 'Recommended for You',
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                  ),
                ),
              ),

              // Recommended Grid — skeleton while loading, real grid once ready
              if (productsState.isLoading && productsState.products.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 4,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (_, __) => _GridProductSkeleton(isDark: isDark),
                    ),
                  ),
                )
              else if (productsState.error != null && productsState.products.isEmpty)
                SliverFillRemaining(
                  child: AppErrorWidget(
                    message: productsState.error!,
                    onRetry: () => ref.read(productsProvider.notifier).refresh(),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: ProductGrid(
                    products: productsState.products,
                    showPrice: authState.isAuthenticated && authState.user?.status != 'rejected',
                    onAddToCart: (authState.isAuthenticated && authState.user?.status != 'rejected') ? _handleAddToCart : null,
                  ),
                ),

              // Close the else branch opened above the banner
              ],
                
              const SliverToBoxAdapter(child: SizedBox(height: 100)),

            // End of slivers within the else-block (placeholder for clarity)
            ],
          ),
        ),
      ),

    );
  }
}


class _HomeScreenSearchBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _HomeScreenSearchBarDelegate({
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
  bool shouldRebuild(_HomeScreenSearchBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

// ─────────────────────────────────────────────────────────────
// Private skeleton widgets used inline inside the home sliver list
// These use the ShimmerBox from widgets/common/shimmer_box.dart
// ─────────────────────────────────────────────────────────────

class _HorizontalProductSkeleton extends StatelessWidget {
  final bool isDark;
  const _HorizontalProductSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Shimmer(width: 160, height: 160, radius: 12, isDark: isDark),
          const SizedBox(height: 10),
          _Shimmer(width: 140, height: 12, radius: 4, isDark: isDark),
          const SizedBox(height: 6),
          _Shimmer(width: 100, height: 12, radius: 4, isDark: isDark),
          const SizedBox(height: 10),
          _Shimmer(width: 80, height: 16, radius: 4, isDark: isDark),
        ],
      ),
    );
  }
}

class _GridProductSkeleton extends StatelessWidget {
  final bool isDark;
  const _GridProductSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: _Shimmer(width: double.infinity, height: double.infinity, radius: 12, isDark: isDark),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _Shimmer(width: 60, height: 10, radius: 4, isDark: isDark),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _Shimmer(width: double.infinity, height: 12, radius: 4, isDark: isDark),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _Shimmer(width: 90, height: 12, radius: 4, isDark: isDark),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Shimmer(width: 70, height: 16, radius: 4, isDark: isDark),
              _Shimmer(width: 32, height: 32, radius: 8, isDark: isDark),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

/// Lightweight animated shimmer block — drives a repeating sweep animation.
class _Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final bool isDark;

  const _Shimmer({
    required this.width,
    required this.height,
    required this.radius,
    required this.isDark,
  });

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base =
        widget.isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE8E8E8);
    final highlight =
        widget.isDark ? const Color(0xFF3A3A4E) : const Color(0xFFF6F6F6);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final pos = (_anim.value + 2) / 4;
        return Container(
          width: widget.width == double.infinity ? null : widget.width,
          height: widget.height == double.infinity ? null : widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: [
                (pos - 0.3).clamp(0.0, 1.0),
                pos.clamp(0.0, 1.0),
                (pos + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

