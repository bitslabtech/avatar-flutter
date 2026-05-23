
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../models/order.dart';
import '../../../providers/auth_provider.dart';

enum OrderFilter { all, pending, dispatched, delivered, returned, cancelled }

class OrdersState {
  final List<Order> orders;
  final List<Order> filteredOrders;
  final OrderStats stats;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final OrderFilter filter;
  final String searchQuery;
  final int currentPage;
  final int totalPages;
  final int totalOrders;
  final bool hasMore;

  OrdersState({
    this.orders = const [],
    this.filteredOrders = const [],
    this.stats = const OrderStats(),
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.filter = OrderFilter.all,
    this.searchQuery = '',
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalOrders = 0,
    this.hasMore = false,
  });

  OrdersState copyWith({
    List<Order>? orders,
    List<Order>? filteredOrders,
    OrderStats? stats,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    OrderFilter? filter,
    String? searchQuery,
    int? currentPage,
    int? totalPages,
    int? totalOrders,
    bool? hasMore,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalOrders: totalOrders ?? this.totalOrders,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  return OrdersNotifier(ref.read(apiClientProvider));
});

class OrdersNotifier extends StateNotifier<OrdersState> {
  final ApiClient _apiClient;
  DateTime? _lastFetched;
  static const _staleAfter = Duration(minutes: 2);

  bool get _isDataFresh =>
      _lastFetched != null &&
      DateTime.now().difference(_lastFetched!) < _staleAfter;

  OrdersNotifier(this._apiClient) : super(OrdersState());

  Future<void> loadData({bool force = false}) async {
    // Skip if data is still fresh and not forced
    if (!force && _isDataFresh && state.orders.isNotEmpty) return;

    state = state.copyWith(isLoading: true, error: null, currentPage: 1);
    try {
      await Future.wait([
        _loadOrders(page: 1, reset: true),
        _loadStats(),
      ]);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadOrders({int page = 1, bool reset = false}) async {
    try {
      final params = _buildQueryParams(page: page);
      final response = await _apiClient.get('/orders', queryParameters: params);
      final paginated = response.data as Map<String, dynamic>;

      final List<dynamic> data = paginated['data'] ?? [];
      final total = paginated['total'] as int? ?? 0;
      final totalPages = paginated['totalPages'] as int? ?? 1;

      final newOrders = data
          .map((json) => Order.fromJson(json))
          .where((order) => order.status != OrderStatus.draft)
          .toList();

      final merged = reset ? newOrders : [...state.orders, ...newOrders];
      
      // Explicitly guarantee sorting by createdAt DESC (newest at top)
      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = state.copyWith(
        orders: merged,
        isLoading: false,
        isLoadingMore: false,
        currentPage: page,
        totalPages: totalPages,
        totalOrders: total,
        hasMore: page < totalPages,
      );
      if (reset) _lastFetched = DateTime.now();
      _applyClientFilters();
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load orders: $e',
        isLoading: false,
        isLoadingMore: false,
      );
    }
  }

  /// Appends the next page of orders.
  Future<void> loadMoreOrders() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    await _loadOrders(page: state.currentPage + 1, reset: false);
  }

  Future<void> _loadStats() async {
    try {
      final response = await _apiClient.get('/orders/stats');
      final stats = OrderStats.fromJson(response.data);
      state = state.copyWith(stats: stats);
    } catch (e) {
      // Silent fail for stats
    }
  }

  Map<String, dynamic> _buildQueryParams({int page = 1}) {
    final params = <String, dynamic>{
      'page': page,
      'limit': 20,
    };
    if (state.filter != OrderFilter.all) {
      params['status'] = state.filter.name;
    }
    if (state.searchQuery.isNotEmpty) {
      params['search'] = state.searchQuery;
    }
    return params;
  }

  void setFilter(OrderFilter filter) {
    state = state.copyWith(filter: filter, currentPage: 1);
    loadData(force: true);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
    if (query.length >= 2 || query.isEmpty) {
      loadData(force: true);
    }
  }

  /// Update order items via API
  Future<bool> updateOrderItems(String orderId, List<Map<String, dynamic>> items) async {
    try {
      await _apiClient.patch('/orders/$orderId/items', data: {'items': items});
      await loadData(force: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update order status and logistics via API
  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    DateTime? estimatedDeliveryDate,
    String? notes,
    String? courierProvider,
    String? trackingNumber,
    int? shippingOverridePaise, // null => use standard charge, int => override
  }) async {
    try {
      String? dateStr;
      if (estimatedDeliveryDate != null) {
        dateStr =
            '${estimatedDeliveryDate.year.toString().padLeft(4, '0')}-'
            '${estimatedDeliveryDate.month.toString().padLeft(2, '0')}-'
            '${estimatedDeliveryDate.day.toString().padLeft(2, '0')}';
      }
      final payload = <String, dynamic>{
        'status': status,
        if (dateStr != null) 'estimatedDeliveryDate': dateStr,
        if (notes != null) 'notes': notes,
        if (courierProvider != null) 'courierProvider': courierProvider,
        if (trackingNumber != null) 'trackingNumber': trackingNumber,
        'shippingOverridePaise': shippingOverridePaise, // Always send (null or int)
      };
      await _apiClient.patch('/orders/$orderId/status', data: payload);
      await loadData(force: true);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete an order
  Future<void> deleteOrder(String orderId) async {
    try {
      await _apiClient.delete('/orders/$orderId');
      // Optimistic remove from current list
      state = state.copyWith(
        orders: state.orders.where((o) => o.id != orderId).toList(),
        totalOrders: state.totalOrders > 0 ? state.totalOrders - 1 : 0,
      );
      _applyClientFilters();
    } catch (e) {
      rethrow;
    }
  }

  /// Client-side filtering for fast in-memory filtering within loaded pages.
  void _applyClientFilters() {
    var filtered = List<Order>.from(state.orders);

    // Apply Search on loaded results only if query is very short (< 2 chars)
    if (state.searchQuery.isNotEmpty && state.searchQuery.length < 2) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered
          .where((o) =>
              o.orderNo.toLowerCase().contains(query) ||
              (o.user != null &&
                  o.user!['name'].toString().toLowerCase().contains(query)) ||
              o.items.any((i) => i.name.toLowerCase().contains(query)))
          .toList();
    }

    state = state.copyWith(filteredOrders: filtered);
  }
}
