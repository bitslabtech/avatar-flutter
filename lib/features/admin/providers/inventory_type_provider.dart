import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class InventoryTypeModel {
  final String id;
  final String name;
  final String? description;

  InventoryTypeModel({required this.id, required this.name, this.description});

  factory InventoryTypeModel.fromJson(Map<String, dynamic> json) {
    return InventoryTypeModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}

class InventoryTypeNotifier extends StateNotifier<AsyncValue<List<InventoryTypeModel>>> {
  final ApiClient _apiClient;

  InventoryTypeNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    loadInventoryTypes();
  }

  Future<void> loadInventoryTypes() async {
    try {
      state = const AsyncValue.loading();
      final response = await _apiClient.get(ApiEndpoints.inventoryTypes);
      final List<dynamic> data = response.data;
      final types = data.map((e) => InventoryTypeModel.fromJson(e)).toList();
      state = AsyncValue.data(types);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final inventoryTypeProvider = StateNotifierProvider<InventoryTypeNotifier, AsyncValue<List<InventoryTypeModel>>>((ref) {
  return InventoryTypeNotifier(ref.watch(apiClientProvider));
});
