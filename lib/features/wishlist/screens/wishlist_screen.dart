
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import '../../../../widgets/common/error_widget.dart';
import '../../../../widgets/common/loading_indicator.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wishlistProvider.notifier).loadWishlist();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wishlistState = ref.watch(wishlistProvider);
    final authState = ref.watch(authProvider); // Watch auth for user status
    final user = authState.user;
    final isPendingDealer = user != null && user.isDealer && user.status == 'pending';
    final isRejected = user != null && user.status == 'rejected';
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter items locally based on search
    final filteredItems = _searchController.text.isEmpty
        ? wishlistState.items
        : wishlistState.items.where((p) => 
            p.name.toLowerCase().contains(_searchController.text.toLowerCase())
          ).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Wishlist',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: theme.iconTheme.color),
          onPressed: () => context.pop(),
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final cart = ref.watch(cartProvider);
              final user = ref.watch(authProvider).user;
              if (user?.status == 'rejected') return const SizedBox.shrink();
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.shopping_cart_outlined, color: theme.iconTheme.color),
                    onPressed: () => context.go('/cart'),
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.errorRed,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search wishlist...',
                  prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
      body: wishlistState.isLoading && wishlistState.items.isEmpty
          ? const Center(child: LoadingIndicator())
          : wishlistState.error != null
              ? Center(child: Text(wishlistState.error!))
              : filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'No matching items found'
                                : 'Your wishlist is empty',
                            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                          ),
                          if (_searchController.text.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: TextButton(
                                onPressed: () => context.go('/home'),
                                child: const Text('Start Shopping'),
                              ),
                            ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.60, // Adjusted to prevent overflow (tall card)
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final product = filteredItems[index];
                        return GestureDetector(
                          onTap: () => context.push('/product/${product.id}'), // Navigation
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: isDark ? Colors.white10 : Colors.grey[200]!,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Image + Heart Button
                                Expanded(
                                  flex: 5,
                                  child: Stack(
                                    children: [
                                      SizedBox.expand(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                          child: CachedNetworkImage(
                                            imageUrl: product.primaryImageUrl,
                                            fit: BoxFit.contain,
                                            placeholder: (context, url) => Container(color: Colors.grey[200]),
                                            errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: InkWell(
                                          onTap: () async {
                                            final isAdded = await ref.read(wishlistProvider.notifier).toggleWishlist(product);
                                            if (context.mounted) {
                                               ScaffoldMessenger.of(context).clearSnackBars();
                                               ScaffoldMessenger.of(context).showSnackBar(
                                                 SnackBar(
                                                   content: Text(isAdded ? 'Added to Wishlist' : 'Removed from Wishlist'),
                                                   backgroundColor: isAdded ? AppColors.successGreen : Colors.black87,
                                                   duration: const Duration(seconds: 1),
                                                 ),
                                               );
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(20),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.9),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.favorite,
                                              size: 18,
                                              color: AppColors.errorRed,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Content
                                Expanded(
                                  flex: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              (product.price != null && !isRejected)
                                                ? '₹${product.price}' 
                                                : (isRejected ? 'Account Rejected' : ''), // Handle null price & rejection
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Modern "Add to Cart" Button or Pending Status
                                        SizedBox(
                                          width: double.infinity,
                                          height: 36,
                                          child: ElevatedButton(
                                            onPressed: (isPendingDealer || isRejected)
                                              ? null 
                                              : () async {
                                                  // Safe Add to Cart with Error Handling
                                                  try {
                                                    await ref.read(cartProvider.notifier).addToCart(product);
                                                    
                                                    // Item remains in wishlist as per user request
                                                    
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('Added to Cart'),
                                                          duration: Duration(seconds: 1),
                                                          behavior: SnackBarBehavior.floating,
                                                          backgroundColor: AppColors.successGreen,
                                                        ),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Failed to add: ${e.toString()}'),
                                                          backgroundColor: AppColors.errorRed,
                                                          behavior: SnackBarBehavior.floating,
                                                        ),
                                                      );
                                                    }
                                                  }
                                              },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: (isPendingDealer || isRejected) ? Colors.grey : Colors.black, // Grey for pending
                                              foregroundColor: Colors.white,
                                              disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                                              disabledForegroundColor: Colors.grey[600],
                                              elevation: 0,
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  (isPendingDealer || isRejected) ? (isRejected ? Icons.block : Icons.lock_clock) : Icons.shopping_bag_outlined, 
                                                  size: 16
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  isPendingDealer ? 'Pending' : (isRejected ? 'Rejected' : 'Add to Cart'),
                                                  style: const TextStyle(
                                                    fontSize: 12, 
                                                    fontWeight: FontWeight.w600,
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
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
