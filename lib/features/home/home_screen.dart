import '../../core/animations/bounce_tap.dart';
// Home screen with banner slider, categories, and product grid
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../models/product.dart';
import '../admin/providers/settings_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/error_widget.dart';
import 'widgets/banner_slider.dart';
import 'widgets/swipeable_card_deck.dart';
import '../../models/banner.dart' as models;
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
  Widget _buildGuestBanner(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2226) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2E343A) : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Avatar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Sign in or register to view pricing & order',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            BounceTap(
              onTap: () => context.push('/auth-choice'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Join Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleNoticeBanner(BuildContext context, AuthState authState, bool isDark) {
    if (!authState.isAuthenticated) {
      return _buildGuestBanner(context, isDark);
    }
    final user = authState.user;
    if (user != null && user.isDealer) {
      if (user.status == 'pending') {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: BounceTap(
            onTap: () => context.go('/profile'),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262015) : AppColors.dealerGoldSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.dealerGold.withValues(alpha: isDark ? 0.4 : 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dealerGold.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.dealerGold.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.hourglass_top_rounded, color: AppColors.dealerGold, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dealer Approval Pending',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'We are reviewing your application. Tap to view status.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.amber[100]?.withOpacity(0.8) : const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E)),
                ],
              ),
            ),
          ),
        );
      } else if (user.status == 'rejected') {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: BounceTap(
            onTap: () => context.go('/profile'),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2B1414) : const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dealer Application Not Approved',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.errorRed,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tap here to contact support or view details.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.errorRed),
                ],
              ),
            ),
          ),
        );
      } else if (user.status == 'approved') {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF132A1C) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: AppColors.successGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Verified Dealer Access — Wholesale pricing active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.green[300] : const Color(0xFF065F46),
                    ),
                  ),
                ),
                if (user.discountPercentage > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${user.discountPercentage.toStringAsFixed(0)}% OFF',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    }
    return const SizedBox.shrink();
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

  void _handleDeckCardTap(SwipeCardData item) {
    if (item.banner != null) {
      final banner = item.banner!;
      if (banner.linkUrl != null && banner.linkUrl!.isNotEmpty) {
        final url = banner.linkUrl!;
        if (url.startsWith('/?category=')) {
          final category = Uri.parse(url).queryParameters['category'];
          if (category != null) {
            context.pushNamed('category-products', pathParameters: {'name': category});
            return;
          }
        } else if (url.startsWith('/category/')) {
          final category = url.split('/category/').last;
          context.pushNamed('category-products', pathParameters: {'name': category});
          return;
        } else {
          context.push(url);
          return;
        }
      }
      context.go('/catalog');
    } else if (item.product != null) {
      context.push('/product/${item.product!.id}');
    } else if (item.linkUrl != null && item.linkUrl!.isNotEmpty) {
      context.push(item.linkUrl!);
    } else {
      context.go('/catalog');
    }
  }

  List<SwipeCardData> _buildDeckItems(List<dynamic> banners, List<Product> products) {
    final items = <SwipeCardData>[];
    for (final b in banners) {
      if (b is models.Banner) {
        if (b.isActive && b.imageUrl.isNotEmpty) {
          items.add(SwipeCardData.fromBanner(b));
        }
      }
    }
    // If fewer than 3 items, supplement with top products so the stacked 3-card deck displays fully
    if (items.length < 3 && products.isNotEmpty) {
      for (final p in products) {
        if (p.primaryImageUrl.isNotEmpty && !items.any((x) => x.id == p.id)) {
          items.add(SwipeCardData.fromProduct(p));
          if (items.length >= 5) break;
        }
      }
    }
    return items;
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
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: NotificationBell(isDark: isDark),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.shopping_bag_outlined,
                              size: 20,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                            onPressed: () => context.go('/cart'),
                          ),
                          if (cartState.itemCount > 0)
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '${cartState.itemCount > 9 ? '9+' : cartState.itemCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    height: 1,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              // 2. Sticky Search Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _HomeScreenSearchBarDelegate(
                  minHeight: 68,
                  maxHeight: 68,
                  child: Container(
                    color: theme.scaffoldBackgroundColor,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    alignment: Alignment.center,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 1,
                        ),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (val) => _handleSearch(val, unfocus: true),
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search cookware, appliances, tableware...',
                          hintStyle: TextStyle(
                            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: _clearSearch,
                                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                              )
                            : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

              // 1. Category Filter Rail
              if (_searchController.text.isEmpty)
              categoriesAsync.when(
                data: (categories) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6.0, bottom: 4.0),
                    child: CategoryChips(
                      categories: categories,
                      selectedCategory: null,
                      onCategorySelected: _handleCategorySelected,
                    ),
                  ),
                ),
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (error, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // 2. Stacked Card UI for Banner (Below Categories)
              if (_searchController.text.isEmpty)
              bannersAsync.when(
                data: (banners) {
                  final deckItems = _buildDeckItems(banners, productsState.products);
                  if (deckItems.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: SwipeableCardDeck(
                        items: deckItems,
                        onTapCard: _handleDeckCardTap,
                      ),
                    ),
                  );
                },
                loading: () => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Container(
                      height: 360,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ),
                error: (error, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // New Arrivals (Horizontal List)
              if (_searchController.text.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'New Arrivals',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => context.go('/catalog'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Row(
                          children: [
                            Text('See All'),
                            SizedBox(width: 2),
                            Icon(Icons.arrow_forward_ios_rounded, size: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // New Arrivals list — skeleton while loading, real cards once ready
              if (_searchController.text.isEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 275,
                    child: productsState.isLoading && productsState.products.isEmpty
                        ? ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 4,
                            separatorBuilder: (_, __) => const SizedBox(width: 14),
                            itemBuilder: (_, __) => _HorizontalProductSkeleton(isDark: isDark),
                          )
                        : productsState.products.isNotEmpty
                            ? ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                scrollDirection: Axis.horizontal,
                                itemCount: productsState.products.take(6).length,
                                separatorBuilder: (_, __) => const SizedBox(width: 14),
                                itemBuilder: (context, index) {
                                  final product = productsState.products[index];
                                  return SizedBox(
                                    width: 175,
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
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _searchController.text.isNotEmpty ? 'Search Results' : 'Recommended for You',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
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
    return Container(
      width: 175,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Shimmer(width: double.infinity, height: 130, radius: 16, isDark: isDark),
          const SizedBox(height: 10),
          _Shimmer(width: 60, height: 10, radius: 4, isDark: isDark),
          const SizedBox(height: 6),
          _Shimmer(width: 130, height: 12, radius: 4, isDark: isDark),
          const SizedBox(height: 4),
          _Shimmer(width: 90, height: 12, radius: 4, isDark: isDark),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Shimmer(width: 70, height: 16, radius: 4, isDark: isDark),
              _Shimmer(width: 34, height: 34, radius: 17, isDark: isDark),
            ],
          ),
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
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: _Shimmer(width: double.infinity, height: double.infinity, radius: 16, isDark: isDark),
          ),
          const SizedBox(height: 10),
          _Shimmer(width: 60, height: 10, radius: 4, isDark: isDark),
          const SizedBox(height: 6),
          _Shimmer(width: double.infinity, height: 12, radius: 4, isDark: isDark),
          const SizedBox(height: 4),
          _Shimmer(width: 100, height: 12, radius: 4, isDark: isDark),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Shimmer(width: 70, height: 16, radius: 4, isDark: isDark),
              _Shimmer(width: 34, height: 34, radius: 17, isDark: isDark),
            ],
          ),
        ],
      ),
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

