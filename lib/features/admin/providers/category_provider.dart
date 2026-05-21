import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../providers/auth_provider.dart';

// Simple model for Category Admin view
class CategoryItem {
  final String id;
  final String name;
  final String? icon;
  final String? imageUrl;
  final String? title;
  final String? description;
  final bool isActive;
  final int productCount; // Mapped from backend

  CategoryItem({
    required this.id,
    required this.name,
    this.icon,
    this.imageUrl,
    this.title,
    this.description,
    required this.isActive,
    required this.productCount,
  });

  String? get resolvedImageUrl => imageUrl != null ? ApiEndpoints.resolveImageUrl(imageUrl!) : null;

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      imageUrl: json['imageUrl'] ?? json['image_url'],
      title: json['title'],
      description: json['description'],
      isActive: json['isActive'] ?? true,
      productCount: json['productCount'] ?? 0,
    );
  }
}

// Filter Enum
enum CategoryFilter { all, active, inactive, unassigned }

class CategoryState {
  final bool isLoading;
  final List<CategoryItem> categories;
  final String? error;
  final String searchQuery;
  final CategoryFilter filter;

  CategoryState({
    this.isLoading = false,
    this.categories = const [],
    this.error,
    this.searchQuery = '',
    this.filter = CategoryFilter.all,
  });

  CategoryState copyWith({
    bool? isLoading,
    List<CategoryItem>? categories,
    String? error,
    String? searchQuery,
    CategoryFilter? filter,
  }) {
    return CategoryState(
      isLoading: isLoading ?? this.isLoading,
      categories: categories ?? this.categories,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
    );
  }
  
  // Computed stats (based on FULL list)
  int get activeCount => categories.where((c) => c.isActive).length;
  int get unassignedCount => categories.where((c) => c.productCount == 0 && c.isActive).length; 
  int get totalCount => categories.length;

  // Filtered List
  List<CategoryItem> get filteredCategories {
    return categories.where((c) {
      // 1. Search Filter
      final matchesSearch = c.name.toLowerCase().contains(searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      // 2. Category Filter
      switch (filter) {
        case CategoryFilter.active:
          return c.isActive;
        case CategoryFilter.inactive:
          return !c.isActive;
        case CategoryFilter.unassigned:
          return c.productCount == 0 && c.isActive; 
        case CategoryFilter.all:
        default:
          return true;
      }
    }).toList();
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  return CategoryNotifier(ref.read(apiClientProvider));
});

class CategoryNotifier extends StateNotifier<CategoryState> {
  final ApiClient _apiClient;

  CategoryNotifier(this._apiClient) : super(CategoryState());

  Future<void> loadCategories() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await _apiClient.get('/admin/categories');
      final List<dynamic> data = response.data;
      
      final categories = data.map((e) => CategoryItem.fromJson(e)).toList();
      
      state = state.copyWith(
        isLoading: false,
        categories: categories,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilter(CategoryFilter filter) {
    state = state.copyWith(filter: filter);
  }

  Future<bool> createCategory({
    required String name,
    required String imageUrl,
    String? title,
    String? description,
    bool isActive = true,
  }) async {
    try {
      await _apiClient.post('/admin/categories', data: {
        'name': name,
        'imageUrl': imageUrl,
        'title': title,
        'description': description,
        'isActive': isActive,
      });
      await loadCategories();
      return true;
    } catch (e) {
       // Handle error (toast or state)
       return false;
    }
  }

  Future<bool> updateCategory({
    required String id, 
    required String name, 
    required bool isActive,
    String? imageUrl,
    String? title,
    String? description,
  }) async {
    try {
      await _apiClient.patch('/admin/categories/$id', data: {
        'name': name,
        'isActive': isActive,
        'imageUrl': imageUrl,
        'title': title,
        'description': description,
      });
      await loadCategories();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
     try {
      await _apiClient.delete('/admin/categories/$id');
      await loadCategories();
      return true;
    } catch (e) {
       return false;
    }
  }
}
