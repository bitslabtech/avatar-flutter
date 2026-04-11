import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/order.dart';
import '../providers/orders_provider.dart';
import '../../../../providers/auth_provider.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  late final TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController.addListener(_onScroll);
    
    // Load data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersProvider.notifier).setSearchQuery('');
      ref.read(ordersProvider.notifier).loadData();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(ordersProvider.notifier).loadMoreOrders();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundBlack : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(ordersProvider.notifier).loadData(),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildStatsGrid(isDark, state.stats),
                          const SizedBox(height: 16),
                          _buildSearchBar(isDark),
                          const SizedBox(height: 16),
                          _buildFilterTabs(isDark, state.filter),
                          const SizedBox(height: 16),

                          if (state.isLoading && state.orders.isEmpty)
                            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),

                          if (state.error != null)
                            Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${state.error}', style: const TextStyle(color: Colors.red)))),

                          if (!state.isLoading && state.error == null && state.filteredOrders.isEmpty)
                            _buildEmptyState(isDark),
                        ]),
                      ),
                    ),

                    if (state.filteredOrders.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildOrderCard(isDark, state.filteredOrders[index]),
                            ),
                            childCount: state.filteredOrders.length,
                          ),
                        ),
                      ),

                    // Load More Spinner
                    if (state.isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      ),

                    // End of list
                    if (!state.hasMore && state.orders.isNotEmpty && !state.isLoading)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'All ${state.totalOrders} orders loaded',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 60)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundBlack : AppColors.backgroundLight,
        border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Order Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final user = ref.read(authProvider).user;
              if (user?.hasPermission('orders', 'create') != true) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('You do not have permission to create orders')),
                 );
                 return;
              }
              context.pushNamed('admin-create-order');
            },
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isDark, OrderStats stats) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard(isDark, 'Total Orders', '${stats.total}', Icons.shopping_bag, Colors.blue),
        _buildStatCard(isDark, 'Pending', '${stats.pending}', Icons.schedule, Colors.orange),
        _buildStatCard(isDark, 'In Transit', '${stats.inTransit}', Icons.local_shipping, Colors.indigo),
        _buildStatCard(isDark, 'Delivered', '${stats.delivered}', Icons.check_circle, Colors.green),
        _buildStatCard(isDark, 'Returned', '${stats.returned}', Icons.assignment_return, Colors.red),
        _buildStatCard(isDark, 'Cancelled', '${stats.cancelled}', Icons.cancel, Colors.grey),
      ],
    );
  }

  Widget _buildStatCard(bool isDark, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => ref.read(ordersProvider.notifier).setSearchQuery(v),
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: 'Search Order ID, Name...',
          hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
          prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark, OrderFilter currentFilter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
           _buildFilterTab(isDark, 'All Orders', Icons.view_list, OrderFilter.all, currentFilter),
           const SizedBox(width: 12),
           _buildFilterTab(isDark, 'Pending', Icons.schedule, OrderFilter.pending, currentFilter),
           const SizedBox(width: 12),
           _buildFilterTab(isDark, 'In Transit', Icons.local_shipping, OrderFilter.dispatched, currentFilter),
           const SizedBox(width: 12),
           _buildFilterTab(isDark, 'Delivered', Icons.check_circle, OrderFilter.delivered, currentFilter),
           const SizedBox(width: 12),
           _buildFilterTab(isDark, 'Returned', Icons.assignment_return, OrderFilter.returned, currentFilter),
           const SizedBox(width: 12),
           _buildFilterTab(isDark, 'Cancelled', Icons.cancel, OrderFilter.cancelled, currentFilter),
        ],
      ),
    );
  }

  Widget _buildFilterTab(bool isDark, String label, IconData icon, OrderFilter value, OrderFilter currentFilter) {
    final isSelected = currentFilter == value;
    final bgColor = isSelected ? AppColors.primaryBlue : (isDark ? AppColors.surfaceDark : Colors.white);
    final fgColor = isSelected ? Colors.white : (isDark ? Colors.white : Colors.grey.shade700);
    final iconColor = isSelected ? Colors.white : (isDark ? Colors.white : Colors.grey.shade500);

    return InkWell(
      onTap: () => ref.read(ordersProvider.notifier).setFilter(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? null : Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(bool isDark, Order order) {
    // Status Logic
    Color statusColor;
    Color statusBgColor;
    String statusText = order.status.nameStr.toUpperCase();

    switch (order.status) {
      case OrderStatus.pending:
        statusColor = Colors.orange;
        statusBgColor = Colors.orange.withOpacity(0.1);
        break;
      case OrderStatus.dispatched:
        statusColor = Colors.blue;
        statusBgColor = Colors.blue.withOpacity(0.1);
        statusText = 'SHIPPED'; // As per design
        break;
      case OrderStatus.delivered:
        statusColor = Colors.green;
        statusBgColor = Colors.green.withOpacity(0.1);
        break;
      case OrderStatus.returned:
        statusColor = Colors.red;
        statusBgColor = Colors.red.withOpacity(0.1);
        break;
      case OrderStatus.cancelled:
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.withOpacity(0.1);
        break;
      default:
        statusColor = Colors.blue;
        statusBgColor = Colors.blue.withOpacity(0.1);
    }
    
    // User Info
    final userName = order.user?['name'] ?? 'Unknown User';
    // final userAvatar = order.user?['avatar']; // If we had avatar URL

    // Items Summary
    final itemsSummary = order.items.map((i) => i.name).join(', ');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Top Row: ID + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderNo}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimeAgo(order.createdAt),
                       style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Customer Row
          Row(
            children: [
              // Avatar Placeholder
               Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      itemsSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, height: 1),
          const SizedBox(height: 12),

          // Footer: Total + Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'TOTAL AMOUNT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    order.grandTotalDisplay,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              
              Row(
                children: [
                  _buildActionButton(isDark, Icons.visibility, Colors.grey, () {
                    context.pushNamed('admin-order-detail', pathParameters: {'id': order.id});
                  }),
                  const SizedBox(width: 8),
                  _buildActionButton(isDark, Icons.edit, Colors.white, () {
                    final user = ref.read(authProvider).user;
                    if (user?.hasPermission('orders', 'update') != true) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('You do not have permission to update orders')),
                       );
                       return;
                    }
                    context.pushNamed('admin-order-detail', pathParameters: {'id': order.id});
                  }, bgColor: AppColors.primaryBlue),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isDark, IconData icon, Color color, VoidCallback onTap, {Color? bgColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bgColor ?? (isDark ? AppColors.backgroundBlack : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color == Colors.grey ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600) : color),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} mins ago';
    return 'Just now';
  }
}
