import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../providers/auth_provider.dart';

class GstItem {
  final String id;
  final int percentage;
  final bool isActive;

  GstItem({
    required this.id,
    required this.percentage,
    required this.isActive,
  });

  factory GstItem.fromJson(Map<String, dynamic> json) {
    return GstItem(
      id: json['id'],
      percentage: json['percentage'],
      isActive: json['isActive'] ?? true,
    );
  }
}

enum GstFilter { all, active, inactive }

class GstState {
  final bool isLoading;
  final List<GstItem> rates;
  final String? error;
  final String searchQuery;
  final GstFilter filter;

  GstState({
    this.isLoading = false,
    this.rates = const [],
    this.error,
    this.searchQuery = '',
    this.filter = GstFilter.all,
  });

  GstState copyWith({
    bool? isLoading,
    List<GstItem>? rates,
    String? error,
    String? searchQuery,
    GstFilter? filter,
  }) {
    return GstState(
      isLoading: isLoading ?? this.isLoading,
      rates: rates ?? this.rates,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
    );
  }

  int get totalCount => rates.length;
  int get activeCount => rates.where((r) => r.isActive).length;
  int get inactiveCount => rates.where((r) => !r.isActive).length;

  List<GstItem> get filteredRates {
    return rates.where((item) {
      if (searchQuery.isNotEmpty && !item.percentage.toString().contains(searchQuery)) {
        return false;
      }
      switch (filter) {
        case GstFilter.active:
          return item.isActive;
        case GstFilter.inactive:
          return !item.isActive;
        case GstFilter.all:
        default:
          return true;
      }
    }).toList();
  }
}

final gstProvider = StateNotifierProvider<GstNotifier, GstState>((ref) {
  return GstNotifier(ref.read(apiClientProvider));
});

class GstNotifier extends StateNotifier<GstState> {
  final ApiClient _apiClient;

  GstNotifier(this._apiClient) : super(GstState());

  Future<void> loadGstRates() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await _apiClient.get('/gst');
      final List<dynamic> data = response.data;
      final rates = data.map((e) => GstItem.fromJson(e)).toList();
      state = state.copyWith(isLoading: false, rates: rates);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilter(GstFilter filter) {
    state = state.copyWith(filter: filter);
  }

  Future<bool> createGstRate(int percentage, {bool isActive = true}) async {
    try {
      await _apiClient.post('/gst', data: {
        'percentage': percentage,
        'isActive': isActive,
      });
      await loadGstRates();
      return true;
    } catch (e) {
      if (e.toString().contains('409')) {
         state = state.copyWith(error: 'Rate already exists'); // Simple error feedback, can be better handled
      }
      return false;
    }
  }

  Future<bool> updateGstRate(String id, {int? percentage, bool? isActive}) async {
    try {
      final data = <String, dynamic>{};
      if (percentage != null) data['percentage'] = percentage;
      if (isActive != null) data['isActive'] = isActive;

      await _apiClient.patch('/gst/$id', data: data);
      await loadGstRates();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteGstRate(String id) async {
    try {
      await _apiClient.delete('/gst/$id');
      await loadGstRates();
      return true;
    } catch (e) {
      return false;
    }
  }
}
