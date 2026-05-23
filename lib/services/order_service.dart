/// Order service
/// Handles order draft (cart) and order management
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/order.dart';
import '../models/address.dart';

class OrderService {
  final ApiClient _apiClient;

  OrderService(this._apiClient);

  /// Create or update order draft (cart)
  /// This is used for the shopping cart functionality
  Future<Order> createOrUpdateDraft({
    required List<Map<String, dynamic>> items, // [{productId, qty}]
    Map<String, dynamic>? address,
    String? courierPreference,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.orderDraft,
        data: {
          'items': items,
          if (address != null) 'address': address,
          if (courierPreference != null) 'courierPreference': courierPreference,
        },
      );
      return Order.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      // Handle the case where backend returns empty cart structure
      return Order.fromJson({
        'id': 'empty',
        'orderNo': 'EMPTY',
        'status': 'draft',
        'items': [],
        'subtotalDpPaise': 0,
        'discountAppliedPaise': 0,
        'courierFeePaise': 0,
        'taxPaise': 0,
        'grandTotalPaise': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Add item to cart (server-side)
  Future<Order> addItemToCart({
    required String productId,
    required int qty,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.cartItems,
        data: {
          'productId': productId,
          'qty': qty,
        },
      );
      return Order.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update cart item quantity
  Future<Order> updateCartItem({
    required String productId,
    required int qty,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        ApiEndpoints.cartItem(productId),
        data: {'qty': qty},
      );
      return Order.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Remove item from cart (server-side)
  Future<Order> removeItemFromCart(String productId) async {
    try {
      final response = await _apiClient.dio.delete(
        ApiEndpoints.cartItem(productId),
      );
      // Handle empty cart response if needed, but backend should return null or empty order
      if (response.data == null || (response.data is String && response.data.isEmpty)) {
         return Order.fromJson({
          'id': 'empty',
          'orderNo': 'EMPTY',
          'status': 'draft',
          'items': [],
          'subtotalDpPaise': 0,
          'grandTotalPaise': 0,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      return Order.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Place/Confirm order
  Future<Order> placeOrder({
    required Address address,
    required String paymentMethod,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.orderConfirm,
        data: {
          'address': {
            'street': address.street,
            'city': address.city,
            'state': address.state,
            'zipCode': address.zipCode,
            'country': 'India', // Optional but good to explicit
            'name': address.name,
            'phone': address.phone,
          },
          'paymentMethod': paymentMethod,
        },
      );
      return Order.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all orders for current user
  Future<List<Order>> getOrders({String? status}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.orders,
        queryParameters: {
          if (status != null) 'status': status,
        },
      );
      // Backend may return a plain List OR a paginated {data: [...], total: N}
      List<dynamic> list;
      if (response.data is List) {
        list = response.data as List<dynamic>;
      } else if (response.data is Map && response.data['data'] is List) {
        list = response.data['data'] as List<dynamic>;
      } else {
        list = [];
      }
      return list
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get single order by ID
  Future<Order> getOrder(String orderId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.orderById(orderId),
      );
      return Order.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update order status (Admin only)
  Future<Order> updateStatus(
    String orderId, 
    String status, {
    DateTime? estimatedDeliveryDate,
    String? notes,
    String? courierProvider,
    String? trackingNumber,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '${ApiEndpoints.orders}/$orderId/status',
        data: {
          'status': status,
          if (estimatedDeliveryDate != null) 
            'estimatedDeliveryDate': estimatedDeliveryDate.toIso8601String(),
          if (notes != null) 'notes': notes,
          if (courierProvider != null) 'courierProvider': courierProvider,
          if (trackingNumber != null) 'trackingNumber': trackingNumber,
        },
      );
      return Order.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get current draft order (cart)
  /// Returns the most recent draft order, or null if none exists
  Future<Order?> getCurrentDraft() async {
    try {
      // Use dedicated GET /orders/draft endpoint — fast, direct DB query, no side effects
      final response = await _apiClient.dio.get(ApiEndpoints.orderDraft);
      if (response.data == null) return null;
      return Order.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      // Fallback: filter from all orders list
      try {
        final orders = await getOrders(status: 'draft');
        if (orders.isEmpty) return null;
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return orders.first;
      } catch (_) {
        return null;
      }
    }
  }

  /// Download proforma GST invoice PDF for an order
  /// Returns raw bytes which the caller can save to disk / share
  Future<Uint8List> downloadInvoice(String orderId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.orderInvoice(orderId),
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data as List<int>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle DioException and throw user-friendly error
  Exception _handleError(DioException e) {
    final message = e.response?.data['message'] ?? 
                   e.message ?? 
                   'An error occurred while processing your order';
    return Exception(message);
  }
}

