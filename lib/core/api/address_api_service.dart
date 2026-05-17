import 'dart:convert';
import '../../models/address.dart';
import '../../providers/auth_provider.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

class AddressApiService {
  final ApiClient _apiClient;

  AddressApiService(this._apiClient);

  /// Get all addresses for the current user
  Future<List<Address>> getAddresses() async {
    final response = await _apiClient.get(ApiEndpoints.addresses);
    // Backend returns array directly, not wrapped in {data: ...}
    if (response.data is List) {
      final List<dynamic> data = response.data;
      return data.map((json) => Address.fromJson(json)).toList();
    }
    return [];
  }

  /// Get a single address by ID
  Future<Address> getAddress(String id) async {
    final response = await _apiClient.get(ApiEndpoints.addressById(id));
    // Backend returns object directly
    return Address.fromJson(response.data);
  }

  /// Create a new address
  Future<Address> createAddress(Address address) async {
    final response = await _apiClient.post(
      ApiEndpoints.addresses,
      data: address.toJson(),
    );
    // Backend returns created address directly
    return Address.fromJson(response.data);
  }

  /// Update an existing address
  Future<Address> updateAddress(Address address) async {
    final response = await _apiClient.patch(
      ApiEndpoints.addressById(address.id),
      data: address.toJson(),
    );
    // Backend returns updated address directly
    return Address.fromJson(response.data);
  }

  /// Delete an address
  Future<void> deleteAddress(String id) async {
    await _apiClient.delete(ApiEndpoints.addressById(id));
  }
}
