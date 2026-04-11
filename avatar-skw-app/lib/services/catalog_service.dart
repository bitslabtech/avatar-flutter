/// Catalog service
/// Handles product, category, brand, and banner API calls
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/product.dart';
import '../models/banner.dart';
import '../models/category.dart';

class CatalogService {
  final ApiClient _apiClient;

  CatalogService(this._apiClient);

  /// Get list of products with optional filters
  /// Returns paginated product list
  Future<Map<String, dynamic>> getProducts({
    String? brand,
    String? category,
    String? search,
    int? page,
    int? limit,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (brand != null) queryParams['brand'] = brand;
      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

      final response = await _apiClient.dio.get(
        ApiEndpoints.products,
        queryParameters: queryParams,
      );

      final dynamic responseData = response.data;
      
      // Backend CatalogService returns { products: [...], pagination: {...} }
      // Handle both direct list and object with 'products' key
      List<dynamic> productsList;
      Map<String, dynamic>? paginationData;
      
      if (responseData is List) {
        productsList = responseData;
      } else if (responseData is Map<String, dynamic>) {
        // Check for 'products' key first
        if (responseData.containsKey('products')) {
          productsList = responseData['products'] as List<dynamic>? ?? [];
          paginationData = responseData['pagination'] as Map<String, dynamic>?;
        } else if (responseData.containsKey('data')) {
          // Fallback for wrapped response
          productsList = responseData['data'] as List<dynamic>? ?? [];
          paginationData = responseData['meta'] as Map<String, dynamic>?;
        } else {
          productsList = [];
        }
      } else {
        productsList = [];
      }
      
      final products = productsList.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();

      return {
        'products': products,
        'pagination': paginationData,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get single product by ID or SKU
  Future<Product> getProduct(String idOrSku) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.productById(idOrSku),
      );
      return Product.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get products by variation group ID
  Future<List<Product>> getProductsByGroup(String groupId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.productsByGroup(groupId),
      );
      final List<dynamic> data = response.data is List ? response.data : (response.data['data'] as List<dynamic>? ?? []);
      return data.map((json) => Product.fromJson(json)).toList();
    } on DioException catch (e) {
      // Return empty list instead of throwing for variations,
      // as it's not a critical failure if related items fail to load
      return []; 
    }
  }

  /// Get all available brands
  Future<List<String>> getBrands() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.brands);
       final dynamic responseData = response.data;
      final List<dynamic> data = responseData is List ? responseData : (responseData['data'] as List<dynamic>? ?? []);
      return List<String>.from(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all available categories
  Future<List<Category>> getCategories() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.categories);
      final dynamic responseData = response.data;
      final List<dynamic> data = responseData is List ? responseData : (responseData['data'] as List<dynamic>? ?? []);
      return data.map((json) => Category.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get promotional banners for home screen
  Future<List<Banner>> getBanners() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.banners);
      final dynamic responseData = response.data;
      final List<dynamic> data = responseData is List ? responseData : (responseData['data'] as List<dynamic>? ?? []);
      return data
          .map((json) => Banner.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle DioException and throw user-friendly error
  Exception _handleError(DioException e) {
    final message = e.response?.data['message'] ?? 
                   e.message ?? 
                   'An error occurred while fetching catalog data';
    return Exception(message);
  }
}

