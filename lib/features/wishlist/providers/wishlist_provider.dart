
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product.dart';
import '../services/wishlist_service.dart';

class WishlistState {
  final List<Product> items;
  final bool isLoading;
  final String? error;
  final Set<String> productIds;

  WishlistState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.productIds = const {},
  });

  WishlistState copyWith({
    List<Product>? items,
    bool? isLoading,
    String? error,
    Set<String>? productIds,
  }) {
    return WishlistState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      productIds: productIds ?? this.productIds,
    );
  }
}

class WishlistNotifier extends StateNotifier<WishlistState> {
  final WishlistService _service;

  WishlistNotifier(this._service) : super(WishlistState());

  Future<void> loadWishlist() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _service.getWishlist();
      state = state.copyWith(
        items: items,
        isLoading: false,
        productIds: items.map((p) => p.id).toSet(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> toggleWishlist(Product product) async {
    // Optimistic Update
    final isAdded = !state.productIds.contains(product.id);
    final newIds = Set<String>.from(state.productIds);
    final newItems = List<Product>.from(state.items);

    if (isAdded) {
      newIds.add(product.id);
      newItems.insert(0, product); // Add to top
    } else {
      newIds.remove(product.id);
      newItems.removeWhere((p) => p.id == product.id);
    }

    state = state.copyWith(productIds: newIds, items: newItems);

    try {
      await _service.toggleWishlist(product.id);
      // Backend confirmation matched optimistic update, do nothing
      return isAdded;
    } catch (e) {
      // Revert if failed
      if (isAdded) {
        newIds.remove(product.id);
        newItems.removeWhere((p) => p.id == product.id);
      } else {
        newIds.add(product.id);
        newItems.insert(0, product);
      }
      state = state.copyWith(productIds: newIds, items: newItems, error: 'Failed to update wishlist');
      rethrow;
    }
  }

  bool isInWishlist(String productId) {
    return state.productIds.contains(productId);
  }
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, WishlistState>((ref) {
  final service = ref.watch(wishlistServiceProvider);
  return WishlistNotifier(service);
});
