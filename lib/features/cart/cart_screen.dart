/// Cart screen using order drafts
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../admin/providers/settings_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final settings = ref.watch(adminSettingsProvider);
    final theme = Theme.of(context);

    return PopScope(
      // Intercept back press — cart is a tab root, back should go to shop
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.goNamed('home');
          }
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Shopping Cart', style: theme.textTheme.titleLarge),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          iconTheme: theme.iconTheme,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed('home');
              }
            },
            tooltip: 'Back',
          ),
        ),
        body: cartState.isLoading
            ? const Center(child: LoadingIndicator())
            : cartState.isEmpty
                ? _buildEmptyCart(context)
                : _buildCartContent(context, ref, cartState, settings),
      ),
    );
  }


  Widget _buildEmptyCart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: isDark ? AppColors.textTertiary : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add some products to get started',
            style: TextStyle(
              color: isDark ? AppColors.textSecondary : Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(
    BuildContext context,
    WidgetRef ref,
    cartState,
    AdminSettingsState settings,
  ) {
    final draftOrder = cartState.draftOrder!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final minOrderPaise = (settings.minOrderValue * 100).round();
    final orderValuePaise = draftOrder.subtotalDpPaise;
    final isBelowMin = minOrderPaise > 0 && orderValuePaise < minOrderPaise;
    final shortfallRs = isBelowMin ? ((minOrderPaise - orderValuePaise) / 100).toStringAsFixed(2) : null;

    return Column(
      children: [
        // Main Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                // Progress Bar (Step 1 of 3)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                     children: [
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text('Step 1 of 3', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                           Text('Next: Shipping', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
                         ],
                       ),
                       const SizedBox(height: 8),
                       ClipRRect(
                         borderRadius: BorderRadius.circular(4),
                         child: LinearProgressIndicator(
                           value: 0.33,
                           backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                           color: Theme.of(context).colorScheme.primary,
                           minHeight: 6,
                         ),
                       ),
                     ],
                  ),
                ),

                // Cart Items
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: draftOrder.items.length,
                  itemBuilder: (context, index) {
                    final item = draftOrder.items[index];
                    return _buildCartItem(context, ref, item);
                  },
                ),

                // Min Order Warning Banner
                if (isBelowMin)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Add ₹$shortfallRs more to reach the minimum order of ₹${settings.minOrderValue.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.orange, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Promo Code Section REMOVED

                 // Summary Breakdown (In-flow)
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 16),
                   child: Column(
                     children: [
                       // Subtotal (prices are GST-inclusive)
                       _buildTotalRow(context, 'Subtotal', draftOrder.subtotalDisplay),
                       const SizedBox(height: 12),
                       if (draftOrder.courierFeePaise > 0)
                         _buildTotalRow(context, 'Shipping', draftOrder.courierFeeDisplay),
                       if (draftOrder.courierFeePaise > 0)
                         const SizedBox(height: 12),
                     ],
                   ),
                 ),
              ],
            ),
          ),
        ),

        // Sticky Footer
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            boxShadow: [
              BoxShadow(
                color: isDark ? AppColors.shadowDark : Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -8),
              ),
            ],
            border: Border(top: BorderSide(color: isDark ? AppColors.dividerGray : Colors.grey[200]!)),
          ),
          child: SafeArea(
            top: false,
            bottom: false, // Remove internal bottom padding as we have spacer
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TOTAL AMOUNT',
                        style: TextStyle(
                          fontSize: 10, 
                          fontWeight: FontWeight.bold, 
                          letterSpacing: 1, 
                          color: isDark ? Colors.grey[400] : Colors.grey[500]
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        draftOrder.grandTotalDisplay,
                        style: TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.w800, 
                          color: isDark ? Colors.white : Colors.black
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isBelowMin ? null : () => context.pushNamed('checkout'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    backgroundColor: isBelowMin ? Colors.grey : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: isBelowMin ? 0 : 8,
                    shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    children: const [
                       Text('Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                       SizedBox(width: 8),
                       Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 90), // Adjusted spacer for Nav Bar clearance
      ],
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    WidgetRef ref,
    item,
  ) {
    // Re-introduced missing variable
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image (Left) - Optimized to use data from OrderItem directly
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.resolvedImageUrl != null && item.resolvedImageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.resolvedImageUrl!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.error)),
                  )
                : Container(
                    width: 100, 
                    height: 100, 
                    color: Colors.grey[200],
                    child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                  ),
          ),
          const SizedBox(width: 16),
          
          // Right Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Name + Delete
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => ref.read(cartProvider.notifier).removeFromCart(item.productId),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      ),
                    ),
                  ],
                ),
                
                
                const SizedBox(height: 8),


                // Bottom Row: Price + Quantity Stepper
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.priceDisplay,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    
                    // Quantity Stepper
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.grey[50], 
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!)
                      ),
                      child: Row(
                        children: [
                          _StepperButton(
                            icon: Icons.remove, 
                            onTap: () {
                              if (item.qty > 1) {
                                ref.read(cartProvider.notifier).updateQuantity(item.productId, item.qty - 1);
                              } else {
                                ref.read(cartProvider.notifier).removeFromCart(item.productId);
                              }
                            },
                            isDark: isDark
                          ),
                          Container(
                            width: 32,
                            alignment: Alignment.center,
                            child: Text(
                              '${item.qty}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                           _StepperButton(
                            icon: Icons.add, 
                            onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.productId, item.qty + 1),
                            isDark: isDark,
                            isAdd: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(BuildContext context, String label, String value, {bool isTotal = false, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal 
                ? (isDark ? AppColors.textPrimary : Colors.black)
                : (isDark ? AppColors.textSecondary : Colors.grey[500]),
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? (isTotal ? (isDark?Colors.white:Colors.black) : (isDark ? AppColors.textPrimary : Colors.black)),
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final bool isAdd;

  const _StepperButton({required this.icon, required this.onTap, required this.isDark, this.isAdd = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: isAdd ? Theme.of(context).colorScheme.primary : (isDark ? Colors.grey[800] : Colors.white),
          borderRadius: BorderRadius.circular(6),
          boxShadow: isAdd ? [
            BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 4, offset: Offset(0, 2))
          ] : [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))
          ],
        ),
        child: Icon(icon, size: 16, color: isAdd ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[600])),
      ),
    );
  }
}

