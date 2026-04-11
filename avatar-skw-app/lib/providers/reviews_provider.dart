import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import 'auth_provider.dart';
import '../models/review.dart';

final reviewsProvider = StateNotifierProvider.family<ReviewsNotifier, AsyncValue<List<Review>>, String>((ref, productId) {
  return ReviewsNotifier(ref.watch(apiClientProvider), productId);
});

class ReviewsNotifier extends StateNotifier<AsyncValue<List<Review>>> {
  final ApiClient _apiClient;
  final String productId;

  ReviewsNotifier(this._apiClient, this.productId) : super(const AsyncValue.loading()) {
    loadReviews();
  }

  Future<void> loadReviews() async {
    try {
      final response = await _apiClient.get('/reviews/product/$productId');
      final List<dynamic> data = response.data;
      final reviews = data.map((json) => Review.fromJson(json)).toList();
      state = AsyncValue.data(reviews);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addReview(int rating, String comment) async {
    try {
      await _apiClient.post('/reviews', data: {
        'productId': productId,
        'rating': rating,
        'comment': comment,
      });
      // Refresh reviews after adding
      loadReviews(); 
    } catch (e) {
      rethrow; // Let UI handle error
    }
  }
}
