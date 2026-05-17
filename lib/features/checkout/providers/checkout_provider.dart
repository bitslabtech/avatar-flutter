import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/address.dart';
import '../../../../providers/cart_provider.dart'; // contains orderServiceProvider definition
import '../../../../services/order_service.dart'; // OrderService class

class CheckoutState {
  final Address? selectedAddress;
  final bool isProcessing;
  final String? error;

  CheckoutState({
    this.selectedAddress,
    this.isProcessing = false,
    this.error,
  });

  CheckoutState copyWith({
    Address? selectedAddress,
    bool? isProcessing,
    String? error,
  }) {
    return CheckoutState(
      selectedAddress: selectedAddress ?? this.selectedAddress,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final OrderService _orderService;
  final Ref _ref;

  CheckoutNotifier(this._orderService, this._ref) : super(CheckoutState());

  void selectAddress(Address address) {
    state = state.copyWith(selectedAddress: address);
  }

  Future<bool> placeOrder() async {
    if (state.selectedAddress == null) {
      state = state.copyWith(error: 'Please select a shipping address');
      return false;
    }

    state = state.copyWith(isProcessing: true, error: null);

    try {
      await _orderService.placeOrder(
        address: state.selectedAddress!,
        paymentMethod: 'COD', // Direct placement (Manual/COD)
      );
      
      // Refresh cart (which should now be empty or get a new draft)
      _ref.invalidate(cartProvider);
      
      state = state.copyWith(isProcessing: false);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }
}

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  return CheckoutNotifier(orderService, ref);
});
