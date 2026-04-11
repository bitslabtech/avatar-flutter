import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user.dart';
import '../../../models/product.dart';
import '../../../providers/auth_provider.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';

class CreateOrderState {
  final int currentStep;
  final User? selectedUser;
  final Map<String, int> cartItems; // ProductId -> Quantity
  final Map<String, Product> productDetails; // ProductId -> Product (for display)
  final Map<String, dynamic>? shippingAddress;
  final bool saveAddressToProfile;
  final bool isLoading;
  final String? error;
  
  // New address selection fields
  final List<Map<String, dynamic>> userAddresses;
  final String? selectedAddressId;
  final bool isLoadingAddresses;

  CreateOrderState({
    this.currentStep = 0,
    this.selectedUser,
    this.cartItems = const {},
    this.productDetails = const {},
    this.isLoading = false,
    this.error,
    this.shippingAddress,
    this.saveAddressToProfile = false,
    this.userAddresses = const [],
    this.selectedAddressId,
    this.isLoadingAddresses = false,
  });

  CreateOrderState copyWith({
    int? currentStep,
    User? selectedUser,
    Map<String, int>? cartItems,
    Map<String, Product>? productDetails,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? shippingAddress,
    bool? saveAddressToProfile,
    List<Map<String, dynamic>>? userAddresses,
    String? selectedAddressId,
    bool? isLoadingAddresses,
    bool clearSelectedAddress = false,
  }) {
    return CreateOrderState(
      currentStep: currentStep ?? this.currentStep,
      selectedUser: selectedUser ?? this.selectedUser,
      cartItems: cartItems ?? this.cartItems,
      productDetails: productDetails ?? this.productDetails,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      saveAddressToProfile: saveAddressToProfile ?? this.saveAddressToProfile,
      userAddresses: userAddresses ?? this.userAddresses,
      selectedAddressId: clearSelectedAddress ? null : (selectedAddressId ?? this.selectedAddressId),
      isLoadingAddresses: isLoadingAddresses ?? this.isLoadingAddresses,
    );
  }
  
  double get totalAmount {
    double total = 0;
    cartItems.forEach((productId, quantity) {
      final product = productDetails[productId];
      if (product != null) {
        // Safe check for price, assuming double or int
        final price = product.price != null 
          ? (product.price is int ? (product.price as int).toDouble() : product.price as double) 
          : 0.0;
        
        // Calculate price with GST
        final priceWithGst = price * (1 + (product.gstPercent ?? 0) / 100);
        
        total += priceWithGst * quantity;
      }
    });
    return total;
  }
}

final createOrderProvider = StateNotifierProvider.autoDispose<CreateOrderNotifier, CreateOrderState>((ref) {
  return CreateOrderNotifier(ref.read(apiClientProvider));
});

class CreateOrderNotifier extends StateNotifier<CreateOrderState> {
  final ApiClient _apiClient;

  CreateOrderNotifier(this._apiClient) : super(CreateOrderState());

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void selectUser(User user) {
    state = state.copyWith(
      selectedUser: user, 
      shippingAddress: null,
      userAddresses: [],
      clearSelectedAddress: true,
    );
    // Fetch user's saved addresses
    fetchUserAddresses(user.id);
  }

  Future<void> fetchUserAddresses(String userId) async {
    state = state.copyWith(isLoadingAddresses: true);
    try {
      final response = await _apiClient.get(ApiEndpoints.addressesByUserId(userId));
      final List<dynamic> data = response.data ?? [];
      final addresses = data.map((e) => Map<String, dynamic>.from(e)).toList();
      state = state.copyWith(
        userAddresses: addresses,
        isLoadingAddresses: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingAddresses: false, error: e.toString());
    }
  }

  void selectAddress(String addressId) {
    final address = state.userAddresses.firstWhere(
      (a) => a['id'] == addressId,
      orElse: () => {},
    );
    if (address.isNotEmpty) {
      state = state.copyWith(
        selectedAddressId: addressId,
        shippingAddress: {
          'name': address['recipientName'] ?? state.selectedUser?.name ?? '',
          'phone': address['phone'] ?? state.selectedUser?.phone ?? '',
          'street': address['street'] ?? '',
          'city': address['city'] ?? '',
          'state': address['state'] ?? '',
          'zipCode': address['zipCode'] ?? '',
          'country': address['country'] ?? 'India',
        },
      );
    }
  }

  void addToCart(Product product, int quantity) {
    final currentCart = Map<String, int>.from(state.cartItems);
    final currentDetails = Map<String, Product>.from(state.productDetails);

    if (quantity <= 0) {
      currentCart.remove(product.id);
    } else {
      currentCart[product.id] = quantity;
      currentDetails[product.id] = product;
    }

    state = state.copyWith(cartItems: currentCart, productDetails: currentDetails);
  }
  
  void clearCart() {
     state = state.copyWith(cartItems: {}, productDetails: {});
  }

  void setShippingAddress(Map<String, dynamic> address) {
    state = state.copyWith(shippingAddress: address, clearSelectedAddress: true);
  }

  void toggleSaveAddress(bool? value) {
    state = state.copyWith(saveAddressToProfile: value ?? false);
  }

  Future<bool> submitOrder() async {
    if (state.selectedUser == null || state.cartItems.isEmpty) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final items = state.cartItems.entries.map((e) => {
        'productId': e.key,
        'qty': e.value,
      }).toList();

      await _apiClient.post('/orders/create-on-behalf', data: {
        'userId': state.selectedUser!.id,
        'items': items,
        'paymentMethod': 'COD', 
        'address': state.shippingAddress,
        'saveAddress': state.saveAddressToProfile,
      });

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
