import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/address.dart';
import '../../../core/api/address_api_service.dart';
import '../../../providers/auth_provider.dart';

final addressApiServiceProvider = Provider<AddressApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AddressApiService(apiClient);
});

class AddressNotifier extends StateNotifier<AsyncValue<List<Address>>> {
  final AddressApiService _apiService;

  AddressNotifier(this._apiService) : super(const AsyncValue.loading()) {
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final addresses = await _apiService.getAddresses();
      state = AsyncValue.data(addresses);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addAddress(Address address) async {
    try {
      final currentList = state.value ?? [];
      state = const AsyncValue.loading();

      // Auto-mark as default if this is the very first address
      final addressToSave = currentList.isEmpty
          ? address.copyWith(isDefault: true)
          : address;

      final newAddress = await _apiService.createAddress(addressToSave);
      state = AsyncValue.data([...currentList, newAddress]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateAddress(Address address) async {
    try {
      // Store current list BEFORE setting loading state
      final currentList = state.value ?? [];
      state = const AsyncValue.loading();
      
      final updatedAddress = await _apiService.updateAddress(address);
      
      // Replace the updated address in the list
      final updatedList = currentList.map((a) {
        if (a.id == updatedAddress.id) {
          return updatedAddress;
        }
        // If new address is default, unset others
        if (updatedAddress.isDefault && a.isDefault) {
          return a.copyWith(isDefault: false);
        }
        return a;
      }).toList();
      
      state = AsyncValue.data(updatedList);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteAddress(String id) async {
    final currentList = state.value ?? [];
    final target = currentList.firstWhere((a) => a.id == id,
        orElse: () => currentList.first);

    // Block deletion of the default address
    if (target.isDefault) {
      throw Exception(
        'Default address cannot be deleted. '
        'Please set another address as default first, then delete this one.',
      );
    }

    try {
      state = const AsyncValue.loading();
      await _apiService.deleteAddress(id);
      final updatedList = currentList.where((a) => a.id != id).toList();
      state = AsyncValue.data(updatedList);
    } catch (error, stackTrace) {
      // Restore previous list on failure
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _loadAddresses();
  }

  /// Returns the default address, or the first address if none is marked default.
  Address? get defaultAddress {
    final list = state.value ?? [];
    if (list.isEmpty) return null;
    try {
      return list.firstWhere((a) => a.isDefault);
    } catch (_) {
      return list.first;
    }
  }
}

final addressProvider = StateNotifierProvider<AddressNotifier, AsyncValue<List<Address>>>((ref) {
  final apiService = ref.watch(addressApiServiceProvider);
  return AddressNotifier(apiService);
});
