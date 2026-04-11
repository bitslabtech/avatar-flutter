import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../services/dealer_repository.dart';

// Repository Provider
final dealerRepositoryProvider = Provider<DealerRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DealerRepository(apiClient);
});

// Dealers List State State
class DealersNotifier extends StateNotifier<AsyncValue<List<User>>> {
  final DealerRepository _repository;

  DealersNotifier(this._repository) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh({bool showDeleted = false}) async {
    state = const AsyncValue.loading();
    try {
      final dealers = await _repository.getDealers(showDeleted: showDeleted);
      state = AsyncValue.data(dealers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(String userId, String status) async {
    try {
      await _repository.updateDealerStatus(userId, status);
      await refresh(); // Refresh list to show updated status
    } catch (e) {
      // Handle error (maybe show snackbar in UI)
      rethrow;
    }
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _repository.updateDealerProfile(userId, data);
      await refresh();
    } catch (e) {
      rethrow;
    }
  }
  Future<void> addDealer(Map<String, dynamic> data) async {
    try {
      await _repository.createDealer(data);
      await refresh();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDealer(String userId) async {
    try {
      await _repository.deleteDealer(userId);
      await refresh();
    } catch (e) {
      rethrow;
    }
  }
}

final dealersProvider = StateNotifierProvider<DealersNotifier, AsyncValue<List<User>>>((ref) {
  final repo = ref.watch(dealerRepositoryProvider);
  return DealersNotifier(repo);
});
