import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../admin/providers/orders_provider.dart'; 

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // In a real app, we would fetch orders for the CURRENT user specifically
    // For now, we reuse the ordersProvider which loads all orders (this assumes client-side filtering or mocked for user)
    // Ideally create a 'myOrdersProvider'
     WidgetsBinding.instance.addPostFrameCallback((_) {
       ref.read(ordersProvider.notifier).loadData();
     });
  }

  @override
  Widget build(BuildContext context) {
    // Determine theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1C2333) : Colors.white;
    final backgroundColor = isDark ? const Color(0xFF101522) : const Color(0xFFF6F6F8);
    final borderColor = isDark ? const Color(0xFF323F67) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : Colors.black87;

    final ordersState = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('My Orders', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
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
      body: ordersState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ordersState.orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No orders yet', style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: ordersState.orders.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final order = ordersState.orders[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Order #${order.id}', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                              _buildStatusBadge(order.status.name),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Date: ${order.createdAt.toString().split(' ')[0]}', style: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          Text('Total: ${order.grandTotalDisplay}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                          const SizedBox(height: 12),
                          Divider(color: borderColor),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                 // Navigate to order detail
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order Details coming soon')));
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.primary,
                                side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                              ),
                              child: const Text('View Details'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'delivered':
        color = Colors.green;
        break;
      case 'processing':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
