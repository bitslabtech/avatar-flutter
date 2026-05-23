import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../models/user.dart';
import '../../providers/create_order_provider.dart';
import '../../providers/orders_provider.dart';
import 'step_1_user_selection.dart';
import 'step_2_product_selection.dart';
import 'step_2_address_selection.dart';
import 'step_3_review_cart.dart';

class AdminCreateOrderScreen extends ConsumerStatefulWidget {
  final User? preSelectedUser;

  const AdminCreateOrderScreen({super.key, this.preSelectedUser});

  @override
  ConsumerState<AdminCreateOrderScreen> createState() => _AdminCreateOrderScreenState();
}

class _AdminCreateOrderScreenState extends ConsumerState<AdminCreateOrderScreen> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Schedule the pre-selection for after the first frame so the provider is alive
    if (widget.preSelectedUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasInitialized && mounted) {
          _hasInitialized = true;
          final notifier = ref.read(createOrderProvider.notifier);
          notifier.selectUser(widget.preSelectedUser!);
          notifier.setStep(1); // Jump to product selection
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createOrderProvider);
    final notifier = ref.read(createOrderProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundBlack : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('New Order'),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.backgroundBlack : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Custom Stepper Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: isDark ? AppColors.backgroundBlack : Colors.white,
            child: Row(
              children: [
                _buildStep(isDark, 0, 'Customer', state.currentStep),
                _buildConnector(isDark, 0, state.currentStep),
                _buildStep(isDark, 1, 'Products', state.currentStep),
                _buildConnector(isDark, 1, state.currentStep),
                _buildStep(isDark, 2, 'Address', state.currentStep),
                _buildConnector(isDark, 2, state.currentStep),
                _buildStep(isDark, 3, 'Review', state.currentStep),
              ],
            ),
          ),
          
          Expanded(
            child: IndexedStack(
              index: state.currentStep,
              children: const [
                Step1UserSelection(),
                Step2ProductSelection(),
                Step2AddressSelection(),
                Step3ReviewCart(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundBlack : Colors.white,
          border: Border(top: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            if (state.currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => notifier.setStep(state.currentStep - 1),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: isDark ? Colors.grey : Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Back', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                ),
              ),
            
            if (state.currentStep > 0) const SizedBox(width: 16),
            
            if (state.currentStep > 0) const SizedBox(width: 16),
            
            // Next Button
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: state.isLoading ? null : () => _handleNext(context, ref, state),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlueFor(isDark),
                  disabledBackgroundColor: AppColors.primaryBlueFor(isDark).withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: state.isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        state.currentStep == 3 ? 'Place Order' : 'Next',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                 ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNext(BuildContext context, WidgetRef ref, CreateOrderState state) async {
    final notifier = ref.read(createOrderProvider.notifier);

    // Validation
    if (state.currentStep == 0) {
      if (state.selectedUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a customer')));
        return;
      }
      notifier.setStep(1);
    } else if (state.currentStep == 1) {
      if (state.cartItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one product')));
        return;
      }
      notifier.setStep(2);
    } else if (state.currentStep == 2) {
      // Validate address
      final addr = state.shippingAddress;
      if (addr == null || (addr['name']?.isEmpty ?? true) || (addr['phone']?.isEmpty ?? true) || (addr['street']?.isEmpty ?? true)) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in required address fields')));
         return;
      }
      notifier.setStep(3);
    } else if (state.currentStep == 3) {
      // Submit
      final success = await notifier.submitOrder();
      if (context.mounted) {
        if (success) {
           // Refresh orders list
           ref.read(ordersProvider.notifier).loadData();
           
           context.pop(); // Close screen
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
             content: Text('Order placed successfully'),
             backgroundColor: Colors.green,
           ));
        } else {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
             content: Text(state.error ?? 'Failed to place order'),
             backgroundColor: Colors.red,
           ));
        }
      }
    }
  }

  Widget _buildStep(bool isDark, int stepIndex, String label, int currentStep) {
    final isActive = stepIndex <= currentStep;
    final isCurrent = stepIndex == currentStep;
    
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.primaryBlueFor(isDark) : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              border: isCurrent ? Border.all(color: AppColors.primaryBlueFor(isDark), width: 2) : null,
            ),
            child: Center(
              child: isActive 
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text('${stepIndex + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey : Colors.grey.shade600)),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppColors.primaryBlueFor(isDark) : (isDark ? Colors.grey : Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(bool isDark, int stepIndex, int currentStep) {
    final isActive = stepIndex < currentStep;
    return Expanded(
       child: Container(
         height: 2,
         color: isActive ? AppColors.primaryBlueFor(isDark) : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
         margin: const EdgeInsets.only(bottom: 20),
       ),
    );
  }
}
