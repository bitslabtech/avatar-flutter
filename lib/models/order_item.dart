/// Order item model representing a single product in an order
/// Maps to the backend OrderItem entity
import '../core/utils/currency_utils.dart';
import '../core/api/api_endpoints.dart';
class OrderItem {
  final String id;
  final String productId;
  final String sku;
  final String name;
  final int qty;
  final int dpPricePaise; // Price in paise (divide by 100 for ₹)
  final int lineTotalDpPaise; // Total for this line item in paise
  final double taxPercent;
  final String? imageUrl;

  OrderItem({
    required this.id,
    required this.productId,
    required this.sku,
    required this.name,
    required this.qty,
    required this.dpPricePaise,
    required this.lineTotalDpPaise,
    required this.taxPercent,
    this.imageUrl,
  });

  String? get resolvedImageUrl => imageUrl != null ? ApiEndpoints.resolveImageUrl(imageUrl!) : null;

  /// Create OrderItem from JSON
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    String parseString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map) return value['id']?.toString() ?? ''; // Handle object expansion
      return value.toString();
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    String? parseImageUrl(Map<String, dynamic> json) {
      // 1. Try direct imageUrl field
      if (json['imageUrl'] != null && (json['imageUrl'] as String).isNotEmpty) {
        return json['imageUrl'] as String;
      }
      // 2. Fallback to product.images[0] if product relation is expanded
      if (json['product'] != null && json['product'] is Map) {
         final product = json['product'] as Map;
         if (product['images'] != null && product['images'] is List && (product['images'] as List).isNotEmpty) {
           return (product['images'] as List).first.toString();
         }
      }
      return null;
    }

    return OrderItem(
      id: parseString(json['id']),
      productId: parseString(json['productId']),
      sku: parseString(json['sku']),
      name: parseString(json['name']),
      qty: parseInt(json['qty']),
      dpPricePaise: parseInt(json['dpPricePaise']),
      lineTotalDpPaise: parseInt(json['lineTotalDpPaise']),
      taxPercent: parseDouble(json['taxPercent']),
      imageUrl: parseImageUrl(json),
    );
  }

  /// Convert OrderItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'sku': sku,
      'name': name,
      'qty': qty,
      'dpPricePaise': dpPricePaise,
      'lineTotalDpPaise': lineTotalDpPaise,
      'taxPercent': taxPercent,
      'imageUrl': imageUrl,
    };
  }

  /// Get display price in ₹ format (INCLUSIVE of tax for UI)
  String get priceDisplay {
    final inclusivePaise = (dpPricePaise * (1 + taxPercent / 100)).round();
    return CurrencyUtils.formatPaise(inclusivePaise);
  }
  
  /// Get line total display price in ₹ format (INCLUSIVE of tax for UI)
  String get lineTotalDisplay {
    final inclusivePaise = (lineTotalDpPaise * (1 + taxPercent / 100)).round();
    return CurrencyUtils.formatPaise(inclusivePaise);
  }
}

