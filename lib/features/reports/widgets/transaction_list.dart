import 'package:flutter/material.dart';
import '../../../models/order.dart';

class TransactionList extends StatelessWidget {
  final List<Order> orders;
  final bool isDark;

  const TransactionList({
    super.key,
    required this.orders,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A), // slate-900
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF), // blue-50
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D4ED8), // primary blue-700ish
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.take(5).length, // Show only top 5 recent
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildTransactionCard(order);
          },
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Order order) {
    final bool isDealer = order.user?['role'] == 'dealer';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFF1F5F9)), // slate-100
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDealer ? const Color(0xFFFAF5FF) : const Color(0xFFEFF6FF), // purple-50 : blue-50
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDealer ? const Color(0xFFF3E8FF) : const Color(0xFFDBEAFE), // purple-100 : blue-100
              ),
            ),
            child: Icon(
              isDealer ? Icons.storefront : Icons.shopping_bag_outlined,
              color: isDealer ? const Color(0xFF9333EA) : const Color(0xFF2563EB), // purple-600 : primary
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      order.user?['name'] ?? 'Unknown User',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A), // slate-900
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDealer ? const Color(0xFFFAF5FF) : const Color(0xFFF1F5F9), // purple-50 : slate-100
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDealer ? const Color(0xFFF3E8FF) : const Color(0xFFE2E8F0), // purple-100 : slate-200
                        ),
                      ),
                      child: Text(
                        isDealer ? 'DEALER' : 'CONSUMER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDealer ? const Color(0xFF7E22CE) : const Color(0xFF475569), // purple-700 : slate-600
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '#${order.orderNo}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8), // slate-400
                      ),
                    ),
                    const SizedBox(width: 8),
                    const CircleAvatar(radius: 2, backgroundColor: Color(0xFFCBD5E1)), // slate-300
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(order.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B), // slate-500
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Amount & Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${(order.grandTotalPaise / 100).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A), // slate-900
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getStatusText(order.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusTextColor(order.status),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple formatter, can use intl package if available globally
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, $hour:${date.minute.toString().padLeft(2, '0')} $ampm';
  }
  
  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return const Color(0xFF10B981); // emerald-500
      case OrderStatus.pending:
      case OrderStatus.confirmed:
      case OrderStatus.dispatched:
        return const Color(0xFFFBBF24); // amber-400
      case OrderStatus.cancelled:
      case OrderStatus.returned:
        return const Color(0xFFEF4444); // red-500
      default:
        return const Color(0xFF94A3B8); // slate-400
    }
  }

  String _getStatusText(OrderStatus status) {
    if (status == OrderStatus.delivered) return 'Paid';
    return status.name.substring(0, 1).toUpperCase() + status.name.substring(1);
  }

  Color _getStatusTextColor(OrderStatus status) {
     switch (status) {
      case OrderStatus.delivered:
        return const Color(0xFF059669); // emerald-600
      case OrderStatus.pending:
      case OrderStatus.confirmed:
      case OrderStatus.dispatched:
        return const Color(0xFF64748B); // slate-500 
      case OrderStatus.cancelled:
      case OrderStatus.returned:
        return const Color(0xFFDC2626); // red-600
      default:
        return const Color(0xFF64748B); // slate-500
    }
  }
}
