/// Catalog state providers using Riverpod
/// Manages products, categories, brands, and banners
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/catalog_service.dart';
import '../models/product.dart';
import '../models/banner.dart';
import '../models/category.dart';
import 'auth_provider.dart';

// Provider for CatalogService
final catalogServiceProvider = Provider<CatalogService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CatalogService(apiClient);
});

// State for products list
class ProductsState {
  final List<Product> products;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? pagination;

  ProductsState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.pagination,
  });

  ProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? pagination,
  }) {
    return ProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pagination: pagination ?? this.pagination,
    );
  }
}

// Products notifier
class ProductsNotifier extends StateNotifier<ProductsState> {
  final CatalogService _catalogService;
  String? _currentBrand;
  String? _currentCategory;
  String? _currentSearch;
  String? _currentSortBy;
  String? _currentSortOrder;

  ProductsNotifier(this._catalogService) : super(ProductsState());

  /// Load products with optional filters
  Future<void> loadProducts({
    String? brand,
    String? category,
    String? search,
    String? sortBy,
    String? sortOrder,
    int? page,
    bool append = false,
  }) async {
    _currentBrand = brand;
    _currentCategory = category;
    _currentSearch = search;
    // Update sort only if provided, effectively persisting last sort if null
    if (sortBy != null) _currentSortBy = sortBy;
    if (sortOrder != null) _currentSortOrder = sortOrder;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _catalogService.getProducts(
        brand: brand,
        category: category,
        search: search,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
        page: page,
      );

      final newProducts = (result['products'] as List<Product>);
      state = state.copyWith(
        products: append ? [...state.products, ...newProducts] : newProducts,
        pagination: result['pagination'],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Refresh products with current filters
  Future<void> refresh() async {
    await loadProducts(
      brand: _currentBrand,
      category: _currentCategory,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    );
  }

  /// Set sorting and reload
  Future<void> setSort(String sortBy, String sortOrder) async {
    _currentSortBy = sortBy;
    _currentSortOrder = sortOrder;
    await refresh();
  }

  /// Clear filters and reload
  Future<void> clearFilters() async {
    _currentBrand = null;
    _currentCategory = null;
    _currentSearch = null;
    _currentSortBy = null;
    _currentSortOrder = null;
    await loadProducts();
  }
}

// Products provider
final productsProvider = StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  final catalogService = ref.watch(catalogServiceProvider);
  return ProductsNotifier(catalogService);
});

// Categories provider
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final catalogService = ref.watch(catalogServiceProvider);
  return await catalogService.getCategories();
});

// Brands provider
final brandsProvider = FutureProvider<List<String>>((ref) async {
  final catalogService = ref.watch(catalogServiceProvider);
  return await catalogService.getBrands();
});

// Banners provider
final bannersProvider = FutureProvider<List<Banner>>((ref) async {
  final catalogService = ref.watch(catalogServiceProvider);
  return await catalogService.getBanners();
});

// Single product provider (by ID)
final productProvider = FutureProvider.family<Product, String>((ref, productId) async {
  final catalogService = ref.watch(catalogServiceProvider);
  return await catalogService.getProduct(productId);
});

// Category specific products provider
final categoryProductsProvider = StateNotifierProvider.autoDispose.family<ProductsNotifier, ProductsState, String>((ref, category) {
  final service = ref.watch(catalogServiceProvider);
  final notifier = ProductsNotifier(service);
  // Perform initial load
  Future.microtask(() => notifier.loadProducts(category: category));
  return notifier;
});

// Related variations provider
final relatedVariationsProvider = FutureProvider.family<List<Product>, String>((ref, groupId) async {
  final catalogService = ref.watch(catalogServiceProvider);
  return await catalogService.getProductsByGroup(groupId);
});

