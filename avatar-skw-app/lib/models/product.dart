/// Product model representing a home appliance/kitchenware item
/// Maps to the backend Product entity
class Product {
  final String id;
  final String sku;
  final String name;
  final String brand;
  final String category;
  final double? price; 
  final double? mrp; 
  final double? taxPercent; // Null for guests
  final Map<String, dynamic>? specs;
  final String? warrantyPeriod;
  final String? energyRating;
  final String? modelNumber;
  final bool installationRequired;
  final List<String>? images;
  final bool isActive;
  final String? brandId;
  final BrandRel? brandRel;
  final String? categoryId;
  final double? gstPercent;
  final String? variationGroupId;
  final String? variationType;
  final String? variant;
  final String? size;
  final String? description;
  final String? material;
  final String? badge;

  Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.brand,
    required this.category,
    this.price,
    this.mrp,
    this.taxPercent,
    this.specs,
    this.warrantyPeriod,
    this.energyRating,
    this.modelNumber,
    required this.installationRequired,
    this.images,
    this.isActive = true,
    this.brandId,
    this.brandRel,
    this.categoryId,
    this.gstPercent,
    this.description,
    this.variationGroupId,
    this.variationType,
    this.variant,
    this.size,
    this.material,
    this.badge,
  });

  /// Create Product from JSON response
  /// Handles both Admin API format (brandRel object) and Catalog API format (brand string)
  factory Product.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse double from various types
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    // Handle brand - can be object (Admin API) or string (Catalog API)
    String brandName = 'Unknown';
    BrandRel? brandRelObj;
    if (json['brandRel'] != null && json['brandRel'] is Map) {
      brandName = json['brandRel']['name'] ?? 'Unknown';
      brandRelObj = BrandRel.fromJson(json['brandRel']);
    } else if (json['brand'] != null) {
      brandName = json['brand'].toString();
    }
    
    // Handle category - can be object (Admin API) or string (Catalog API)
    String categoryName = 'Uncategorized';
    if (json['category'] != null && json['category'] is Map) {
      categoryName = json['category']['name'] ?? 'Uncategorized';
    } else if (json['category'] != null) {
      categoryName = json['category'].toString();
    }
    
    return Product(
      id: json['id'] ?? '',
      sku: json['sku'] ?? '',
      name: json['name'] ?? '',
      brand: brandName,
      category: categoryName,
      price: parseDouble(json['price']),
      mrp: parseDouble(json['mrp']),
      taxPercent: parseDouble(json['taxPercent']),
      specs: json['specs'] ?? json['specifications'],
      warrantyPeriod: json['warrantyPeriod'],
      energyRating: json['energyRating'],
      modelNumber: json['modelNumber'],
      installationRequired: json['installationRequired'] ?? false,
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      isActive: json['isActive'] ?? true,
      brandId: json['brandId'],
      brandRel: brandRelObj,
      categoryId: json['categoryId'],
      gstPercent: parseDouble(json['gstPercent']),
      description: json['description'],
      variationGroupId: json['variation_group_id'] ?? json['variationGroupId'], // Handle both snake_case (DB/API) and camelCase
      variationType: json['variation_type'] ?? json['variationType'],
      variant: json['variant'],
      size: json['size'],
      material: json['material'],
      badge: json['badge'],
    );
  }

  /// Get the first image URL or a placeholder
  String get primaryImageUrl {
    if (images != null && images!.isNotEmpty) {
      return images!.first;
    }
    return 'https://via.placeholder.com/400x400?text=No+Image'; // Placeholder
  }

  /// Convert Product to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'brand': brand,
      'category': category,
      'price': price,
      'mrp': mrp,
      'taxPercent': taxPercent,
      'specs': specs,
      'warrantyPeriod': warrantyPeriod,
      'energyRating': energyRating,
      'modelNumber': modelNumber,
      'installationRequired': installationRequired,
      'images': images,
      'isActive': isActive,
      'brandId': brandId,
      'brandRel': brandRel?.toJson(),
      'categoryId': categoryId,
      'gstPercent': gstPercent,
      'description': description,
      'variation_group_id': variationGroupId,
      'variation_type': variationType,
      'variant': variant,
      'size': size,
      'material': material,
      'badge': badge,
    };
  }

  int? get discountPercentage {
    final currentPrice = price ?? 0.0;
    final originalPrice = mrp ?? 0.0;
    
    if (originalPrice <= 0 || currentPrice <= 0 || currentPrice >= originalPrice) {
      return null;
    }
    
    return ((originalPrice - currentPrice) / originalPrice * 100).round();
  }
}

class BrandRel {
  final String id;
  final String name;

  BrandRel({required this.id, required this.name});

  factory BrandRel.fromJson(Map<String, dynamic> json) {
    return BrandRel(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
