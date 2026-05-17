import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/address.dart';
import '../../../providers/cart_provider.dart';
import '../providers/checkout_provider.dart';
import '../../profile/providers/address_provider.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutProvider);
    final cartState = ref.watch(cartProvider);
    final addressState = ref.watch(addressProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1C2333) : Colors.white;
    final borderColor = isDark ? const Color(0xFF323F67) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101522) : const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: Text('Checkout', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back, color: textColor),
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: borderColor, height: 1),
        ),
      ),
      body: cartState.isEmpty
          ? const Center(child: Text('Cart is empty'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 2 Progress Bar
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                       children: [
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             const Text('Step 2 of 3', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                             Text('Place Order', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
                           ],
                         ),
                         const SizedBox(height: 8),
                         ClipRRect(
                           borderRadius: BorderRadius.circular(4),
                           child: LinearProgressIndicator(
                             value: 0.66,
                             backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                             color: AppColors.primaryBlue,
                             minHeight: 6,
                           ),
                         ),
                       ],
                    ),
                  ),

                  // Inline Address Selection
                  _buildSectionHeader('Saved Addresses', textColor),
                  addressState.when(
                    data: (addresses) {
                      if (addresses.isEmpty) {
                        return Center(
                           child: Column(
                             children: [
                               Icon(Icons.location_off_outlined, size: 48, color: Colors.grey.shade400),
                               const SizedBox(height: 12),
                               const Text('No addresses found'),
                               const SizedBox(height: 12),
                             ],
                           ),
                        );
                      }
                      return Column(
                        children: addresses.map((address) {
                          final isSelected = checkoutState.selectedAddress?.id == address.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: InkWell(
                              onTap: () => ref.read(checkoutProvider.notifier).selectAddress(address),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected ? (isDark ? AppColors.primaryBlue.withOpacity(0.1) : Colors.blue.shade50) : surfaceColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primaryBlue : borderColor,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      address.type == 'Home' ? Icons.home_outlined : Icons.work_outline,
                                      color: isSelected ? AppColors.primaryBlue : (isDark?Colors.white70:Colors.grey.shade600)
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(address.type.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                                              if (address.isDefault)
                                                Container(
                                                  margin: const EdgeInsets.only(left: 8),
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primaryBlue.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text('DEFAULT', style: TextStyle(fontSize: 10, color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(address.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
                                          Text('${address.street}, ${address.city}', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    Radio<String>(
                                      value: address.id,
                                      groupValue: checkoutState.selectedAddress?.id,
                                      activeColor: AppColors.primaryBlue,
                                      onChanged: (val) => ref.read(checkoutProvider.notifier).selectAddress(address),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Error loading addresses: $err', style: const TextStyle(color: Colors.red)),
                  ),
                  
                  // Add New Address Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                         context.pushNamed('add-address');
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add New Address'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, style: BorderStyle.none), // Mimic dashed border if possible or just solid
                        backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                        foregroundColor: isDark ? Colors.white70 : Colors.grey[700],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side:  BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Order Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Subtotal', cartState.draftOrder?.subtotalDisplay ?? '\$0.00', textColor),
                        const SizedBox(height: 8),
                         // Removed Shipping Row as per request
                         if ((cartState.draftOrder?.taxPaise ?? 0) > 0) ...[
                            _buildSummaryRow('Tax', cartState.draftOrder?.taxDisplay ?? '\$0.00', textColor),
                            const SizedBox(height: 8),
                         ],
                         // Shipping is Free/Removed
                         _buildSummaryRow('Shipping', 'Free', Colors.green, isBold: true),

                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                        _buildSummaryRow('Total Payment', cartState.draftOrder?.grandTotalDisplay ?? '\$0.00', textColor, isBold: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: checkoutState.isProcessing 
              ? null 
              : () async {
                  final success = await ref.read(checkoutProvider.notifier).placeOrder();
                  if (success && context.mounted) {
                    context.goNamed('order-success');
                  } else if (context.mounted && checkoutState.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(checkoutState.error!), backgroundColor: Colors.red));
                  }
              },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: checkoutState.isProcessing
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Place Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color.withOpacity(0.7),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color textColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: textColor, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14)),
        Text(value, style: TextStyle(color: textColor, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14)),
      ],
    );
  }


}
