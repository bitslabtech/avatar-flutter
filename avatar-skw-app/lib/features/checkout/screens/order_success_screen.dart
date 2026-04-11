import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/order_provider.dart';

class OrderSuccessScreen extends ConsumerWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1C2333) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101522) : const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: Text('Order Confirmation', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: surfaceColor, // Keep original styling
        elevation: 0,
        automaticallyImplyLeading: false, 
        actions: [
          IconButton(onPressed: () => context.goNamed('home'), icon: Icon(Icons.close, color: textColor))
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // Step 3 Progress Bar
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Column(
                   children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         const Text('Step 3 of 3', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                         Text('Complete', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
                       ],
                     ),
                     const SizedBox(height: 8),
                     ClipRRect(
                       borderRadius: BorderRadius.circular(4),
                       child: LinearProgressIndicator(
                         value: 1.0,
                         backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                         color: AppColors.successGreen,
                         minHeight: 6,
                       ),
                     ),
                   ],
                ),
              ),
              
              const Spacer(),
              
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 80,
                          color: AppColors.successGreen,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Order Placed Successfully!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Order confirmation and details have been sent to your registered email and WhatsApp number.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey : Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                     // Invalidate/Refresh orders so they show up in list
                     ref.invalidate(ordersProvider);
                     context.goNamed('home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Continue Shopping', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                     // Invalidate/Refresh orders AND go to correct screen
                     ref.invalidate(ordersProvider);
                     context.goNamed('orders'); 
                  },
                  child: const Text('View Order History', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
