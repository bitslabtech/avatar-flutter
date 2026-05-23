/// Order state provider using Riverpod
/// Manages user orders list
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import 'cart_provider.dart'; // Import orderServiceProvider from here

// Orders state
class OrdersState {
  final List<Order> orders;
  final bool isLoading;
  final String? error;

  OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  OrdersState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Orders notifier
class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrderService _orderService;

  OrdersNotifier(this._orderService) : super(OrdersState()) {
    loadOrders();
  }

  /// Load user orders
  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final orders = await _orderService.getOrders();
      // Filter out draft orders (they're handled by cart)
      final nonDraftOrders = orders.where((o) => !o.isDraft).toList();
      // Sort by createdAt descending so newest orders appear at top
      nonDraftOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(
        orders: nonDraftOrders,
        isLoading: false,
      );
    } catch (e, stack) {
      print('Error loading orders: $e');
      print(stack);
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Refresh orders list
  Future<void> refresh() async {
    await loadOrders();
  }

  /// Update order status (Admin)
  /// Update order status (Admin)
  Future<void> updateOrderStatus(String orderId, String status, {DateTime? estimatedDeliveryDate, String? notes, String? courierProvider, String? trackingNumber}) async {
     await _orderService.updateStatus(orderId, status, estimatedDeliveryDate: estimatedDeliveryDate, notes: notes, courierProvider: courierProvider, trackingNumber: trackingNumber);
     await loadOrders();
  }
}

// Orders provider (only available when authenticated)
final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  return OrdersNotifier(orderService);
});

// Single order provider (by ID)
final orderProvider = FutureProvider.family<Order, String>((ref, orderId) async {
  final orderService = ref.watch(orderServiceProvider);
  return await orderService.getOrder(orderId);
});

