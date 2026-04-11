/// Order model representing a user's order
/// Maps to the backend Order entity
/// Note: All monetary values are in paise (divide by 100 for ₹)
import '../core/utils/currency_utils.dart';
import 'order_item.dart';

enum OrderStatus {
  draft,
  pending,
  confirmed,
  dispatched,
  delivered,
  returned,
  cancelled,
}

class Order {
  final String id;
  final String orderNo;
  final OrderStatus status;
  final int subtotalDpPaise;
  final int discountAppliedPaise;
  final int courierFeePaise;
  final int? shippingOverridePaise;
  final int taxPaise;
  final int grandTotalPaise;
  final List<OrderItem> items;
  final Map<String, dynamic>? addressSnapshot;
  final Map<String, dynamic>? courier;
  final Map<String, dynamic>? tracking;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? estimatedDeliveryDate;
  final Map<String, dynamic>? user; // User relation snapshot
  final String? paymentMethod;
  final String? notes;

  Order({
    required this.id,
    required this.orderNo,
    required this.status,
    required this.subtotalDpPaise,
    required this.discountAppliedPaise,
    required this.courierFeePaise,
    this.shippingOverridePaise,
    required this.taxPaise,
    required this.grandTotalPaise,
    required this.items,
    this.addressSnapshot,
    this.courier,
    this.tracking,
    required this.createdAt,
    required this.updatedAt,
    this.estimatedDeliveryDate,
    this.user,
    this.paymentMethod,
    this.notes,
  });

  /// Create Order from JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    // Helper to parse int from either int or string (bigint serialization)
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Order(
      id: json['id'] as String,
      orderNo: json['orderNo'] as String,
      status: _parseStatus(json['status'] as String),
      subtotalDpPaise: parseInt(json['subtotalDpPaise']),
      discountAppliedPaise: parseInt(json['discountAppliedPaise']),
      courierFeePaise: parseInt(json['courierFeePaise']),
      shippingOverridePaise: json['shippingOverridePaise'] != null ? parseInt(json['shippingOverridePaise']) : null,
      taxPaise: parseInt(json['taxPaise']),
      grandTotalPaise: parseInt(json['grandTotalPaise']),
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      addressSnapshot: json['addressSnapshot'] as Map<String, dynamic>?,
      courier: json['courier'] as Map<String, dynamic>?,
      tracking: json['tracking'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] is String 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] is String 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      estimatedDeliveryDate: json['estimatedDeliveryDate'] is String 
          ? DateTime.parse(json['estimatedDeliveryDate']) 
          : null,
      user: json['user'] as Map<String, dynamic>?,
      paymentMethod: json['paymentMethod'] as String?,
      notes: json['notes'] as String?,
    );
  }

  /// Convert Order to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNo': orderNo,
      'status': status.toString().split('.').last,
      'subtotalDpPaise': subtotalDpPaise,
      'discountAppliedPaise': discountAppliedPaise,
      'courierFeePaise': courierFeePaise,
      'shippingOverridePaise': shippingOverridePaise,
      'taxPaise': taxPaise,
      'grandTotalPaise': grandTotalPaise,
      'items': items.map((item) => item.toJson()).toList(),
      'addressSnapshot': addressSnapshot,
      'courier': courier,
      'tracking': tracking,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'estimatedDeliveryDate': estimatedDeliveryDate?.toIso8601String(),
      'user': user,
      'notes': notes,
    };
  }

  /// Parse status string to enum
  static OrderStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return OrderStatus.draft;
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'dispatched':
        return OrderStatus.dispatched;
      case 'delivered':
        return OrderStatus.delivered;
      case 'returned':
        return OrderStatus.returned;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.draft;
    }
  }

  /// Get display prices in ₹ format using CurrencyUtils
  String get subtotalDisplay => CurrencyUtils.formatPaise(subtotalDpPaise);
  String get discountDisplay => CurrencyUtils.formatPaise(discountAppliedPaise);
  String get courierFeeDisplay => CurrencyUtils.formatPaise(courierFeePaise);
  String get taxDisplay => CurrencyUtils.formatPaise(taxPaise);
  String get grandTotalDisplay => CurrencyUtils.formatPaise(grandTotalPaise);
  
  /// Check if order is a draft (cart)
  bool get isDraft => status == OrderStatus.draft;
}

class OrderStats {
  final int total;
  final int pending;
  final int inTransit; // Maps to dispatched
  final int delivered;
  final int returned;
  final int cancelled;

  const OrderStats({
    this.total = 0,
    this.pending = 0,
    this.inTransit = 0,
    this.delivered = 0,
    this.returned = 0,
    this.cancelled = 0,
  });

  factory OrderStats.fromJson(Map<String, dynamic> json) {
    return OrderStats(
      total: json['total'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      inTransit: json['inTransit'] as int? ?? 0,
      delivered: json['delivered'] as int? ?? 0,
      returned: json['returned'] as int? ?? 0,
      cancelled: json['cancelled'] as int? ?? 0,
    );
  }
}

extension OrderStatusX on OrderStatus {
  /// Safe getter for enum name (helper for older Dart runtimes)
  String get nameStr => toString().split('.').last;
}


