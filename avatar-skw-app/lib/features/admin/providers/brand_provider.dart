import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../providers/auth_provider.dart';

enum BrandFilter { all, active, inactive, unassigned }

class BrandItem {
  final String id;
  final String name;
  final String? logo;
  final bool isActive;
  final int productCount;
  final String? createdAt;

  BrandItem({
    required this.id,
    required this.name,
    this.logo,
    required this.isActive,
    required this.productCount,
    this.createdAt,
  });

  factory BrandItem.fromJson(Map<String, dynamic> json) {
    try {
      return BrandItem(
        id: json['id'],
        name: json['name'],
        logo: json['logo'] is String ? json['logo'] : null, // Safely handle non-string logo
        isActive: json['isActive'] ?? true,
        productCount: json['productCount'] is int ? json['productCount'] : 0,
        createdAt: json['createdAt']?.toString(), // Ensure string
      );
    } catch (e) {
      print('Error parsing BrandItem: $e');
      print('JSON: $json');
      rethrow;
    }
  }

}

class BrandState {
  final bool isLoading;
  final List<BrandItem> brands;
  final String? error;
  final String searchQuery;
  final BrandFilter filter;

  BrandState({
    this.isLoading = false,
    this.brands = const [],
    this.error,
    this.searchQuery = '',
    this.filter = BrandFilter.all,
  });

  BrandState copyWith({
    bool? isLoading,
    List<BrandItem>? brands,
    String? error,
    String? searchQuery,
    BrandFilter? filter,
  }) {
    return BrandState(
      isLoading: isLoading ?? this.isLoading,
      brands: brands ?? this.brands,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
    );
  }

  // Stats
  int get totalCount => brands.length;
  int get activeCount => brands.where((b) => b.isActive).length;
  int get inactiveCount => brands.where((b) => !b.isActive).length;

  // Filtered List
  List<BrandItem> get filteredBrands {
    return brands.where((b) {
      // Search
      if (searchQuery.isNotEmpty && !b.name.toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }
      // Filter
      switch (filter) {
        case BrandFilter.active:
          return b.isActive;
        case BrandFilter.inactive:
          return !b.isActive;
        case BrandFilter.unassigned:
          return b.productCount == 0 && b.isActive; // Assuming 'unassigned' means active brands with no products, similar to categories? Or maybe just no products. The design doesn't explicitly define 'unassigned' filter but we used it for categories. Let's keep it consistent.
        case BrandFilter.all:
        default:
          return true;
      }
    }).toList();
  }
}

final brandProvider = StateNotifierProvider<BrandNotifier, BrandState>((ref) {
  return BrandNotifier(ref.read(apiClientProvider));
});

class BrandNotifier extends StateNotifier<BrandState> {
  final ApiClient _apiClient;

  BrandNotifier(this._apiClient) : super(BrandState());

  Future<void> loadBrands() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await _apiClient.get('/brands'); // Using public endpoint, or admin? Controller has public GET but likely admin specific for this management view. Controller is '/brands'.
      // Note: Controller uses @UseGuards(JwtAuthGuard, RolesGuard) at class level, so it is protected.
      final List<dynamic> data = response.data;
      final brands = data.map((e) => BrandItem.fromJson(e)).toList();
      state = state.copyWith(isLoading: false, brands: brands);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilter(BrandFilter filter) {
    state = state.copyWith(filter: filter);
  }

  Future<bool> createBrand({required String name, bool isActive = true, String? logo}) async {
    try {
      await _apiClient.post('/brands', data: {
        'name': name,
        'isActive': isActive,
        'logo': logo,
      });
      await loadBrands();
      return true;
    } catch (e) {
      return false;
    }
  }

   Future<bool> updateBrand({required String id, required String name, required bool isActive, String? logo}) async {
    try {
      await _apiClient.patch('/brands/$id', data: {
        'name': name,
        'isActive': isActive,
        'logo': logo,
      });
      await loadBrands();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteBrand(String id) async {
    try {
      await _apiClient.delete('/brands/$id');
      await loadBrands();
      return true;
    } catch (e) {
      return false;
    }
  }
}
