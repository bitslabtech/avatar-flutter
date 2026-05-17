
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

import '../../../models/product.dart';
import '../../../providers/auth_provider.dart';

class WishlistService {
  final ApiClient _apiClient;

  WishlistService(this._apiClient);

  Future<List<Product>> getWishlist() async {
    try {
      final response = await _apiClient.dio.get('/wishlist');
      // Backend returns list of Wishlist entity which has 'product' field
      // We need to extract the product object from it.
      // Response structure: [{ "id": "uuid", "product": { ...productData... }, "user": {...} }]
      
      final List<dynamic> data = response.data;
      return data.map((item) => Product.fromJson(item['product'])).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load wishlist');
    }
  }

  Future<bool> toggleWishlist(String productId) async {
    try {
      final response = await _apiClient.dio.post('/wishlist/toggle/$productId');
      // Returns { status: 'added' | 'removed' }
      return response.data['status'] == 'added';
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to toggle wishlist');
    }
  }
}

final wishlistServiceProvider = Provider<WishlistService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WishlistService(apiClient);
});
