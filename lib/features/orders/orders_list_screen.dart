import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh orders when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersProvider.notifier).loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF101822) : const Color(0xFFF6F7F8),
        appBar: AppBar(
           title: const Text('My Orders'),
           backgroundColor: isDark ? const Color(0xFF1A222D) : Colors.white,
           elevation: 0,
           leading: IconButton(
             icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
             onPressed: () {
               if (context.canPop()) {
                 context.pop();
               } else {
                 context.goNamed('home');
               }
             },
           ),
           bottom: TabBar(
             labelColor: Theme.of(context).colorScheme.primary,
             unselectedLabelColor: isDark ? Colors.grey : Colors.grey[600],
             indicatorColor: Theme.of(context).colorScheme.primary,
             tabs: const [
               Tab(text: 'Active Orders'),
               Tab(text: 'Completed'),
               Tab(text: 'Cancelled'),
             ],
           ),
        ),
        body: ordersState.isLoading && ordersState.orders.isEmpty
            ? const Center(child: LoadingIndicator())
            : ordersState.orders.isEmpty && ordersState.error != null
                ? AppErrorWidget(
                    message: ordersState.error!,
                    onRetry: () => ref.read(ordersProvider.notifier).refresh(),
                  )
                : TabBarView(
                    children: [
                       _OrderTabList(orders: ordersState.orders, statusFilter: const [OrderStatus.pending, OrderStatus.confirmed, OrderStatus.dispatched], type: 'active'),
                       _OrderTabList(orders: ordersState.orders, statusFilter: const [OrderStatus.delivered], type: 'completed'),
                       _OrderTabList(orders: ordersState.orders, statusFilter: const [OrderStatus.cancelled, OrderStatus.returned], type: 'cancelled'),
                    ],
                  ),
      ),
    );
  }
}

class _OrderTabList extends ConsumerWidget {
  final List<Order> orders;
  final List<OrderStatus> statusFilter;
  final String type;

  const _OrderTabList({required this.orders, required this.statusFilter, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredOrders = orders.where((o) => statusFilter.contains(o.status)).toList();
    // Sort by date desc
    filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (filteredOrders.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(ordersProvider.notifier).refresh();
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: filteredOrders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final order = filteredOrders[index];
          return _OrderCard(order: order);
        },
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No $type orders', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1A222D) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A3441) : const Color(0xFFE5E7EB);
    
    // Product Info
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final otherCount = order.items.length > 1 ? order.items.length - 1 : 0;
    final title = firstItem != null 
        ? '${firstItem.name}${otherCount > 0 ? "...and $otherCount more" : ""}' 
        : 'Order #${order.orderNo}';
        
    final imageUrl = firstItem?.resolvedImageUrl;
    
    // Status Logic
    String statusText;
    Color statusColor;
    Color statusBgColor;
    
    switch (order.status) {
       case OrderStatus.pending:
        statusText = 'Pending';
        statusColor = Colors.orange;
        statusBgColor = Colors.orange.withOpacity(0.1);
        break;
      case OrderStatus.confirmed:
        statusText = 'Processing';
        statusColor = Colors.blue;
        statusBgColor = Colors.blue.withOpacity(0.1);
        break;
      case OrderStatus.dispatched:
        statusText = 'Shipped';
        statusColor = Theme.of(context).colorScheme.primary;
        statusBgColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
        break;
      case OrderStatus.delivered:
        statusText = 'Delivered';
        statusColor = Colors.green;
        statusBgColor = Colors.green.withOpacity(0.1);
        break;
      case OrderStatus.cancelled:
        statusText = 'Cancelled';
        statusColor = Colors.red;
        statusBgColor = Colors.red.withOpacity(0.1);
        break;
       case OrderStatus.returned:
        statusText = 'Returned';
        statusColor = Colors.red;
        statusBgColor = Colors.red.withOpacity(0.1);
        break;
      default:
        statusText = order.status.nameStr;
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.withOpacity(0.1);
    }

    final dateStr = DateFormat('MMM dd, yyyy').format(order.createdAt);
    
    // Estimation text
    String estText = '';
    Color estColor = Colors.grey;
    double progress = 0.0;
    
    if (order.status == OrderStatus.delivered) {
       estText = 'Delivered ${order.updatedAt != null ? DateFormat('MMM dd').format(order.updatedAt) : ''}';
       estColor = Colors.green;
       progress = 1.0;
    } else if (order.estimatedDeliveryDate != null) {
       estText = 'Est. ${DateFormat('MMM dd').format(order.estimatedDeliveryDate!)}';
       estColor = Colors.blue;
       if (order.status == OrderStatus.dispatched) progress = 0.65;
       else if (order.status == OrderStatus.confirmed) progress = 0.35;
       else progress = 0.1;
    } else {
       // Fallback if no date is set but status is active
       if (order.status == OrderStatus.dispatched) {
         estText = 'In Transit';
         estColor = Theme.of(context).colorScheme.primary;
         progress = 0.65;
       } else if (order.status == OrderStatus.confirmed) {
         estText = 'Processing';
         estColor = Colors.blue;
         progress = 0.35;
       } else if (order.status == OrderStatus.pending) {
         estText = 'Order Placed';
         estColor = Colors.orange;
         progress = 0.1;
       }
    }


    return InkWell(
      onTap: () async {
        await context.pushNamed('order-detail', pathParameters: {'id': order.id});
        // Refresh orders list when returning from detail screen
        ref.read(ordersProvider.notifier).loadOrders();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
             BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
             )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    border: Border.all(color: borderColor),
                    image: imageUrl != null ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ) : null,
                  ),
                  child: Stack(
                    children: [
                      if (imageUrl == null)
                        const Center(child: Icon(Icons.image, color: Colors.grey)),
                      if (order.items.length > 0)
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                             color: Colors.black54,
                             padding: const EdgeInsets.symmetric(vertical: 2),
                             alignment: Alignment.center,
                             child: Text(
                               '${order.items.length} Items',
                               style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                             ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Expanded(
                             child: Text(
                               title,
                               maxLines: 2,
                               overflow: TextOverflow.ellipsis,
                               style: TextStyle(
                                 fontSize: 14,
                                 fontWeight: FontWeight.bold,
                                 color: isDark ? Colors.white : const Color(0xFF0F172A), // Slate 900
                               ),
                             ),
                           ),
                           const SizedBox(width: 8),
                            Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                             decoration: BoxDecoration(
                               color: statusBgColor,
                               borderRadius: BorderRadius.circular(12),
                             ),
                             child: Text(
                               statusText.toUpperCase(),
                               style: TextStyle(
                                 color: statusColor,
                                 fontSize: 10,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 4),
                       Text(
                         'Order #${order.orderNo}',
                         style: TextStyle(
                           fontSize: 12,
                           color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                       const SizedBox(height: 4),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text(
                             dateStr,
                             style: TextStyle(
                               fontSize: 12,
                               color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                             ),
                           ),
                           Text(
                             order.grandTotalDisplay,
                             style: TextStyle(
                               fontSize: 14,
                               fontWeight: FontWeight.bold,
                               color: Theme.of(context).colorScheme.primary,
                             ),
                           ),
                         ],
                       ), 
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Footer (Progress / Est Date)
             if (estText.isNotEmpty) ...[
                 const Divider(height: 1),
                 const SizedBox(height: 12),
                 if (order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled && order.status != OrderStatus.returned)
                   Column(
                     children: [
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text(
                             statusText, // Current status description
                             style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                           ),
                           Text(
                             estText,
                             style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600),
                           ),
                         ],
                       ),
                       const SizedBox(height: 8),
                       ClipRRect(
                         borderRadius: BorderRadius.circular(4),
                         child: LinearProgressIndicator(
                           value: progress,
                           backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                           valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                           minHeight: 6,
                         ),
                       ),
                     ],
                   )
                 else
                   Row(
                     children: [
                        Icon(order.status == OrderStatus.delivered ? Icons.check_circle : Icons.info, 
                             size: 16, color: estColor),
                        const SizedBox(width: 4),
                        Text(
                          estText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF334155),
                          ),
                        ),
                     ],
                   ),
             ],
             
             // View Details Link / Action
             if (order.status == OrderStatus.dispatched || order.status == OrderStatus.pending)
               Padding(
                 padding: const EdgeInsets.only(top: 12.0),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.end,
                   children: [
                      Text(
                        'Track Order', 
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: Theme.of(context).colorScheme.primary),
                   ],
                 ),
               ),
          ],
        ),
      ),
    );
  }
}
