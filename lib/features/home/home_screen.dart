/// Home screen with banner slider, categories, and product grid
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/curved_header.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_indicator.dart';
import 'widgets/banner_slider.dart';
import 'widgets/category_chips.dart';
import 'widgets/product_grid.dart';
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
              // 1. Sticky Header (Menu, Title, Cart)
              SliverAppBar(
                floating: false,
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.menu, color: theme.iconTheme.color),
                  onPressed: () {}, // Menu action
                ),
                title: Text(
                  'Home Appliances',
                  style: theme.textTheme.titleLarge,
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
                              decoration: const BoxDecoration(
                                color: AppColors.primaryBlue,
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
                        color: isDark ? Colors.grey[800] : Colors.grey[200]!.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
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

              // Hero Carousel (Banner)
              if (_searchController.text.isEmpty)
              bannersAsync.when(
                data: (banners) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: BannerSlider(banners: banners),
                  ),
                ),
                loading: () => const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: Center(child: LoadingIndicator()),
                  ),
                ),
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
                loading: () => const SliverToBoxAdapter(child: SizedBox(height: 50)),
                error: (error, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // New Arrivals (Horizontal List)
              if (_searchController.text.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    children: [
                      Text(
                        'New Arrivals',
                        style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              // Using a temporary horizontal list for New Arrivals
               if (productsState.products.isNotEmpty && _searchController.text.isEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 260, 
                    child: ListView.separated(
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
                             onAddToCart: (authState.isAuthenticated && authState.user?.status != 'rejected') ? () => _handleAddToCart(product) : null,
                             onTap: () => context.push('/product/${product.id}'),
                           ),
                         );
                      },
                    ),
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

              // Recommended Grid
              if (productsState.isLoading && productsState.products.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: LoadingIndicator()),
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
                
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
