/// Cart state provider using Riverpod
/// Manages shopping cart using order drafts
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'auth_provider.dart';

// Provider for OrderService
final orderServiceProvider = Provider<OrderService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrderService(apiClient);
});

// Cart state (using order draft)
class CartState {
  final Order? draftOrder;
  final bool isLoading;
  final String? error;

  CartState({
    this.draftOrder,
    this.isLoading = false,
    this.error,
  });

  CartState copyWith({
    Order? draftOrder,
    bool? isLoading,
    String? error,
  }) {
    return CartState(
      draftOrder: draftOrder,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get cart items count
  int get itemCount {
    if (draftOrder == null) return 0;
    return draftOrder!.items.fold(0, (sum, item) => sum + item.qty);
  }

  /// Check if cart is empty
  bool get isEmpty => draftOrder == null || draftOrder!.items.isEmpty;
}

// Cart notifier
class CartNotifier extends StateNotifier<CartState> {
  final OrderService _orderService;

  CartNotifier(this._orderService) : super(CartState()) {
    // Auto-load cart on initialization so items are visible immediately
    loadCart();
  }

  /// Load current cart (draft order)
  Future<void> loadCart() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final draft = await _orderService.getCurrentDraft();
      state = state.copyWith(
        draftOrder: draft,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Add product to cart
  Future<void> addToCart(Product product, {int quantity = 1}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedDraft = await _orderService.addItemToCart(
        productId: product.id,
        qty: quantity,
      );

      state = state.copyWith(
        draftOrder: updatedDraft,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  /// Update item quantity in cart
  /// Update item quantity in cart
  Future<void> updateQuantity(String productId, int newQuantity) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedDraft = await _orderService.updateCartItem(
        productId: productId,
        qty: newQuantity,
      );

      state = state.copyWith(
        draftOrder: updatedDraft,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(String productId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedDraft = await _orderService.removeItemFromCart(productId);

      state = state.copyWith(
        draftOrder: updatedDraft,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Clear cart
  Future<void> clearCart() async {
    state = state.copyWith(isLoading: true);
    try {
      // Create empty draft
      await _orderService.createOrUpdateDraft(items: []);
      state = state.copyWith(
        draftOrder: null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

// Cart provider (auto-reloads when auth state changes)
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  // Watch auth identity so cart reloads fresh when user logs in or switches
  ref.watch(authProvider.select((s) => '${s.isAuthenticated}_${s.user?.id}'));
  final orderService = ref.watch(orderServiceProvider);
  return CartNotifier(orderService);
});

