import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/category.dart' as models;
import '../../../../core/api/api_client.dart';
import '../../../models/banner.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/admin_settings.dart';
import '../services/admin_service.dart';

// Admin Service Provider
final adminServiceProvider = Provider<AdminService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminService(apiClient);
});

// Admin Banners State Notifier
class AdminBannersNotifier extends StateNotifier<AsyncValue<List<Banner>>> {
  final AdminService _adminService;
  DateTime? _lastFetched;
  static const _staleAfter = Duration(minutes: 5);

  bool get _isDataFresh =>
      _lastFetched != null &&
      DateTime.now().difference(_lastFetched!) < _staleAfter;

  AdminBannersNotifier(this._adminService) : super(const AsyncValue.loading()) {
    loadBanners();
  }

  Future<void> loadBanners({bool force = false}) async {
    if (!force && _isDataFresh && state.hasValue) return;
    try {
      if (!state.hasValue) {
        state = const AsyncValue.loading();
      }
      final banners = await _adminService.getBanners();
      state = AsyncValue.data(banners);
      _lastFetched = DateTime.now();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBanner(Map<String, dynamic> data) async {
    try {
      await _adminService.createBanner(data);
      await loadBanners(force: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBanner(String id, Map<String, dynamic> data) async {
    try {
      await _adminService.updateBanner(id, data);
      await loadBanners(force: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBanner(String id) async {
    try {
      await _adminService.deleteBanner(id);
      await loadBanners(force: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reorderBanners(int oldIndex, int newIndex) async {
    final currentBanners = state.value;
    if (currentBanners == null) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = currentBanners.removeAt(oldIndex);
    currentBanners.insert(newIndex, item);

    // Optimistic update
    state = AsyncValue.data(List.from(currentBanners));

    try {
      final ids = currentBanners.map((b) => b.id).toList();
      await _adminService.reorderBanners(ids);
    } catch (e) {
      // Revert on error
      await loadBanners(force: true);
      rethrow;
    }
  }
}

// ... (existing imports, but I need to handle imports carefully with replace)

// Admin Banners Provider
final adminBannersProvider = StateNotifierProvider<AdminBannersNotifier, AsyncValue<List<Banner>>>((ref) {
  final adminService = ref.watch(adminServiceProvider);
  return AdminBannersNotifier(adminService);
});

// Admin Categories Notifier
class AdminCategoriesNotifier extends StateNotifier<AsyncValue<List<models.Category>>> {
  final AdminService _adminService;
  DateTime? _lastFetched;
  static const _staleAfter = Duration(minutes: 5);

  bool get _isDataFresh =>
      _lastFetched != null &&
      DateTime.now().difference(_lastFetched!) < _staleAfter;

  AdminCategoriesNotifier(this._adminService) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  Future<void> loadCategories({bool force = false}) async {
    if (!force && _isDataFresh && state.hasValue) return;
    try {
      if (!state.hasValue) {
        state = const AsyncValue.loading();
      }
      final categories = await _adminService.getCategories();
      categories.sort((a, b) => a.order.compareTo(b.order));
      state = AsyncValue.data(categories);
      _lastFetched = DateTime.now();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleCategoryStatus(models.Category category) async {
    try {
      final updated = await _adminService.updateCategory(category.id, {'isActive': !category.isActive});
      state = state.whenData((categories) {
        return categories.map((c) => c.id == updated.id ? updated : c).toList();
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reorderCategories(List<models.Category> newOrder) async {
    try {
      // Optimistic update
      state = AsyncValue.data(newOrder);

      final orderPayload = newOrder.asMap().entries.map((entry) => {
        'id': entry.value.id,
        'order': entry.key,
      }).toList();

      await _adminService.reorderCategories(orderPayload);
    } catch (e) {
       await loadCategories(force: true);
       rethrow;
    }
  }
}

final adminCategoriesProvider = StateNotifierProvider<AdminCategoriesNotifier, AsyncValue<List<models.Category>>>((ref) {
  final adminService = ref.watch(adminServiceProvider);
  return AdminCategoriesNotifier(adminService);
});

class AdminDashboardStatsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final AdminService _adminService;
  DateTime? _lastFetched;
  static const _staleAfter = Duration(minutes: 5);

  bool get _isDataFresh =>
      _lastFetched != null &&
      DateTime.now().difference(_lastFetched!) < _staleAfter;

  AdminDashboardStatsNotifier(this._adminService) : super(const AsyncValue.loading()) {
    loadStats();
  }

  Future<void> loadStats({bool force = false}) async {
    if (!force && _isDataFresh && state.hasValue) return;
    try {
      if (!state.hasValue) {
        state = const AsyncValue.loading();
      }
      final stats = await _adminService.getDashboardStats();
      state = AsyncValue.data(stats);
      _lastFetched = DateTime.now();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adminDashboardStatsProvider = StateNotifierProvider<AdminDashboardStatsNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  final adminService = ref.watch(adminServiceProvider);
  return AdminDashboardStatsNotifier(adminService);
});


class AdminSettingsNotifier extends StateNotifier<AdminSettings> {
  AdminSettingsNotifier() : super(const AdminSettings());

  void toggleNewConsumerAlert(bool value) {
    state = state.copyWith(newConsumerAlert: value);
  }

  void updateLastUserCount(int count) {
    state = state.copyWith(lastUserCount: count);
  }
}

final adminSettingsProvider = StateNotifierProvider<AdminSettingsNotifier, AdminSettings>((ref) {
  return AdminSettingsNotifier();
});
