import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../models/product.dart';
import '../../../providers/auth_provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';

class ProductStats {
  final int totalProducts;
  final int activeProducts;
  final int inactiveProducts;
  final int categoryUnassigned;
  final int brandUnassigned;
  final int gstUnassigned;

  ProductStats({
    required this.totalProducts,
    required this.activeProducts,
    required this.inactiveProducts,
    required this.categoryUnassigned,
    required this.brandUnassigned,
    required this.gstUnassigned,
  });
}

// Enum for stat card filters
enum StatCardFilter {
  none,
  total,
  active,
  inactive,
  categoryUnassigned,
  brandUnassigned,
  gstUnassigned,
}

// Status filter enum - mutually exclusive
enum StatusFilter {
  all,      // Show both active and inactive
  active,   // Show only active
  inactive, // Show only inactive
}

// Filter options for the filter modal
class FilterOptions {
  final StatusFilter statusFilter;
  final bool showCategoryUnassigned;
  final bool showBrandUnassigned;
  final bool showGstUnassigned;

  FilterOptions({
    this.statusFilter = StatusFilter.all,
    this.showCategoryUnassigned = false,
    this.showBrandUnassigned = false,
    this.showGstUnassigned = false,
  });

  FilterOptions copyWith({
    StatusFilter? statusFilter,
    bool? showCategoryUnassigned,
    bool? showBrandUnassigned,
    bool? showGstUnassigned,
  }) {
    return FilterOptions(
      statusFilter: statusFilter ?? this.statusFilter,
      showCategoryUnassigned: showCategoryUnassigned ?? this.showCategoryUnassigned,
      showBrandUnassigned: showBrandUnassigned ?? this.showBrandUnassigned,
      showGstUnassigned: showGstUnassigned ?? this.showGstUnassigned,
    );
  }

  bool get hasActiveFilters => statusFilter != StatusFilter.all || showCategoryUnassigned || showBrandUnassigned || showGstUnassigned;

  FilterOptions clear() => FilterOptions();
}

class ProductState {
  final bool isLoading;
  final bool isLoadingMore;
  final List<Product> products;
  final String? error;
  final String searchQuery;
  final String? selectedCategory;
  final StatCardFilter statCardFilter;
  final FilterOptions filterOptions;
  final ProductStats stats;
  final int currentPage;
  final int totalPages;
  final int totalProducts;
  final bool hasMore;

  ProductState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.products = const [],
    this.error,
    this.searchQuery = '',
    this.selectedCategory,
    this.statCardFilter = StatCardFilter.none,
    FilterOptions? filterOptions,
    required this.stats,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalProducts = 0,
    this.hasMore = false,
  }) : filterOptions = filterOptions ?? FilterOptions();

  ProductState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<Product>? products,
    String? error,
    String? searchQuery,
    String? selectedCategory,
    bool clearSelectedCategory = false,
    StatCardFilter? statCardFilter,
    FilterOptions? filterOptions,
    ProductStats? stats,
    int? currentPage,
    int? totalPages,
    int? totalProducts,
    bool? hasMore,
  }) {
    return ProductState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      products: products ?? this.products,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: clearSelectedCategory ? null : (selectedCategory ?? this.selectedCategory),
      statCardFilter: statCardFilter ?? this.statCardFilter,
      filterOptions: filterOptions ?? this.filterOptions,
      stats: stats ?? this.stats,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalProducts: totalProducts ?? this.totalProducts,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  // Filtered Products Getter
  List<Product> get filteredProducts {
    final filtered = products.where((product) {
      // Search Filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesName = product.name.toLowerCase().contains(query);
        final matchesSku = product.sku.toLowerCase().contains(query);
        final matchesBrand = product.brand.toLowerCase().contains(query);
        final matchesCategory = product.category.toLowerCase().contains(query);
        if (!matchesName && !matchesSku && !matchesBrand && !matchesCategory) return false;
      }
      
      // Category Filter (from chips)
      if (selectedCategory != null && selectedCategory!.isNotEmpty) {
        if (product.category != selectedCategory) return false;
      }

      // Stat Card Filter
      switch (statCardFilter) {
        case StatCardFilter.active:
          if (!product.isActive) return false;
          break;
        case StatCardFilter.inactive:
          if (product.isActive) return false;
          break;
        case StatCardFilter.categoryUnassigned:
          if (product.category.isNotEmpty && product.category != 'Uncategorized') return false;
          break;
        case StatCardFilter.brandUnassigned:
          if (product.brand.isNotEmpty && product.brand != 'Unknown' && product.brand != 'Generic') return false;
          break;
        case StatCardFilter.gstUnassigned:
          if (product.gstPercent != null) return false;
          break;
        case StatCardFilter.total:
        case StatCardFilter.none:
          break;
      }

      // Filter Options (from modal)
      // Status filter (mutually exclusive)
      switch (filterOptions.statusFilter) {
        case StatusFilter.active:
          if (!product.isActive) return false;
          break;
        case StatusFilter.inactive:
          if (product.isActive) return false;
          break;
        case StatusFilter.all:
          break;
      }
      
      // Additional filters (can be combined with status)
      if (filterOptions.showCategoryUnassigned && product.category.isNotEmpty && product.category != 'Uncategorized') return false;
      if (filterOptions.showBrandUnassigned && product.brand.isNotEmpty && product.brand != 'Unknown' && product.brand != 'Generic') return false;
      if (filterOptions.showGstUnassigned && product.gstPercent != null) return false;
      
      return true;
    }).toList();
    return filtered;
  }

  // Get unique categories from products
  List<String> get uniqueCategories {
    final categories = products
        .map((p) => p.category)
        .where((c) => c.isNotEmpty && c != 'Uncategorized')
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }
}

final productManagementProvider = StateNotifierProvider<ProductManagementNotifier, ProductState>((ref) {
  return ProductManagementNotifier(ref.read(apiClientProvider));
});

class ProductManagementNotifier extends StateNotifier<ProductState> {
  final ApiClient _apiClient;
  DateTime? _lastFetched;
  static const _staleAfter = Duration(minutes: 2);

  bool get _isDataFresh =>
      _lastFetched != null &&
      DateTime.now().difference(_lastFetched!) < _staleAfter;

  ProductManagementNotifier(this._apiClient) : super(ProductState(
    stats: ProductStats(totalProducts: 0, activeProducts: 0, inactiveProducts: 0, categoryUnassigned: 0, brandUnassigned: 0, gstUnassigned: 0)
  ));

  Future<void> loadProducts({bool showSkeleton = false, bool force = false}) async {
    // Skip re-fetch if data is fresh and caller did not request skeleton or force.
    if (!showSkeleton && !force && _isDataFresh && state.products.isNotEmpty) return;

    // Build query params from current filter state
    final query = _buildQueryParams(page: 1);
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        products: showSkeleton ? [] : null,
        currentPage: 1,
        stats: showSkeleton
            ? ProductStats(
                totalProducts: 0,
                activeProducts: 0,
                inactiveProducts: 0,
                categoryUnassigned: 0,
                brandUnassigned: 0,
                gstUnassigned: 0,
              )
            : null,
      );
      final response = await _apiClient.get('/admin/products', queryParameters: query);
      final paginated = response.data as Map<String, dynamic>;

      final data = (paginated['data'] as List<dynamic>? ?? []);
      final products = data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
      final total = paginated['total'] as int? ?? products.length;
      final totalPages = paginated['totalPages'] as int? ?? 1;

      state = state.copyWith(
        isLoading: false,
        products: products,
        currentPage: 1,
        totalPages: totalPages,
        totalProducts: total,
        hasMore: 1 < totalPages,
        stats: _calcStats(products),
      );
      _lastFetched = DateTime.now();

    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Fetches the next page and appends results to existing list.
  Future<void> loadMoreProducts() async {
    if (state.isLoadingMore || !state.hasMore) return;
    final nextPage = state.currentPage + 1;
    final query = _buildQueryParams(page: nextPage);
    try {
      state = state.copyWith(isLoadingMore: true);
      final response = await _apiClient.get('/admin/products', queryParameters: query);
      final paginated = response.data as Map<String, dynamic>;

      final data = (paginated['data'] as List<dynamic>? ?? []);
      final newProducts = data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
      final totalPages = paginated['totalPages'] as int? ?? state.totalPages;
      final merged = [...state.products, ...newProducts];

      state = state.copyWith(
        isLoadingMore: false,
        products: merged,
        currentPage: nextPage,
        totalPages: totalPages,
        hasMore: nextPage < totalPages,
        stats: _calcStats(merged),
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Map<String, dynamic> _buildQueryParams({int page = 1}) {
    final params = <String, dynamic>{
      'page': page,
      'limit': 30,
    };
    if (state.searchQuery.isNotEmpty) params['search'] = state.searchQuery;
    if (state.selectedCategory != null && state.selectedCategory!.isNotEmpty) {
      params['category'] = state.selectedCategory;
    }
    if (state.filterOptions.statusFilter == StatusFilter.active) {
      params['isActive'] = 'true';
    } else if (state.filterOptions.statusFilter == StatusFilter.inactive) {
      params['isActive'] = 'false';
    }
    return params;
  }

  ProductStats _calcStats(List<Product> products) {
    int active = 0, inactive = 0, catUnassigned = 0, brandUnassigned = 0, gstUnassigned = 0;
    for (var p in products) {
      if (p.isActive) { active++; } else { inactive++; }
      if (p.category.isEmpty || p.category == 'Uncategorized') catUnassigned++;
      if (p.brand.isEmpty || p.brand == 'Unknown' || p.brand == 'Generic') brandUnassigned++;
      if (p.gstPercent == null) gstUnassigned++;
    }
    return ProductStats(
      totalProducts: products.length,
      activeProducts: active,
      inactiveProducts: inactive,
      categoryUnassigned: catUnassigned,
      brandUnassigned: brandUnassigned,
      gstUnassigned: gstUnassigned,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
    loadProducts();
  }

  void setCategoryFilter(String? category) {
    if (category == null || category.isEmpty) {
      state = state.copyWith(clearSelectedCategory: true, currentPage: 1);
    } else {
      state = state.copyWith(selectedCategory: category, currentPage: 1);
    }
    loadProducts();
  }
  
  void clearCategoryFilter() {
    state = state.copyWith(clearSelectedCategory: true, currentPage: 1);
    loadProducts();
  }

  void setStatCardFilter(StatCardFilter filter) {
    // Toggle: if same filter clicked, clear it
    if (state.statCardFilter == filter) {
      state = state.copyWith(statCardFilter: StatCardFilter.none);
    } else {
      state = state.copyWith(statCardFilter: filter);
    }
  }

  void clearStatCardFilter() {
    state = state.copyWith(statCardFilter: StatCardFilter.none);
  }

  void setFilterOptions(FilterOptions options) {
    state = state.copyWith(filterOptions: options, currentPage: 1);
    loadProducts();
  }

  void clearFilterOptions() {
    state = state.copyWith(filterOptions: FilterOptions(), currentPage: 1);
    loadProducts();
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await _apiClient.delete('/admin/products/$id');
      await loadProducts();
      return true;
    } catch (e) {
      print('DEBUG: Delete Error: $e');
      return false;
    }
  }

  Future<bool> toggleProductStatus(String id, bool isActive) async {
    try {
       await _apiClient.patch('/admin/products/$id', data: {'isActive': isActive});
       await loadProducts(force: true);
       return true;
    } catch (e) {
      print('DEBUG: Toggle Status Error: $e');
      return false;
    }
  }

  Future<dynamic> createProduct(Map<String, dynamic> productData) async {
    try {
      await _apiClient.post('/admin/products', data: productData);
      await loadProducts();
      return true;
    } catch (e) {
      print('DEBUG: Create Error: $e');
      if (e is DioException && e.response?.statusCode == 403) {
        return 'Permission Denied: You cannot create products.';
      }
      // Extract message from Exception if possible
      final msg = e.toString().replaceAll('Exception:', '').trim();
      return msg;
    }
  }

  Future<dynamic> updateProduct(String id, Map<String, dynamic> productData) async {
    try {
      await _apiClient.patch('/admin/products/$id', data: productData);
      await loadProducts();
      return true;
    } catch (e) {
      print('DEBUG: Update Error: $e');
      if (e is DioException && e.response?.statusCode == 403) {
        return 'Permission Denied: You cannot edit products.';
      }
      final msg = e.toString().replaceAll('Exception:', '').trim();
      return msg;
    }
  }

  Future<String?> exportProducts() async {
    try {
      final response = await _apiClient.get(
        '/admin/products/export',
        options: Options(responseType: ResponseType.bytes),
      );
      
      final Uint8List bytes = Uint8List.fromList(response.data);

      // Prompt user to save file
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Product Export',
        fileName: 'products_export_${DateTime.now().microsecondsSinceEpoch}.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: bytes,
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(response.data);
        return outputFile;
      }
      return null;
    } catch (e) {
      print('DEBUG: Export Error: $e');
      return null;
    }
  }

  Future<String?> pickImportFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single.path;
      }
      return null;
    } catch (e) {
      print('DEBUG: File Pick Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> uploadImportFile(String path) async {
    try {
        String fileName = path.split(Platform.pathSeparator).last;
        
        FormData formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(path, filename: fileName),
        });

        final response = await _apiClient.post(
          '/admin/products/import', 
          data: formData,
        );
        
        await loadProducts();
        
        return {
          'success': true,
          'message': 'Successfully imported products.',
          'data': response.data
        };
    } catch (e) {
       print('DEBUG: Import Error: $e');
       if (e is DioException) {
          final errorData = e.response?.data;
          // Capture validation errors specifically
          if (errorData is Map && errorData.containsKey('errors')) {
              return {
                'success': false,
                'message': errorData['message'] ?? 'Validation Failed',
                'data': {'errors': errorData['errors']}
              };
          }
          return {
            'success': false, 
            'message': errorData?['message'] ?? e.message ?? 'Import Failed'
          };
       }
       return {'success': false, 'message': e.toString()};
    }
  }
}
