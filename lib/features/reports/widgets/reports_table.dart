import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../providers/reports_provider.dart';
import '../../../models/order.dart'; 
import '../../../core/utils/currency_utils.dart'; 

class ReportsTable extends StatelessWidget {
  final ReportsState state;
  final bool isDark;
  final Function(int) onPageChanged;
  final ScrollController? scrollController;

  const ReportsTable({
    super.key,
    required this.state,
    required this.isDark,
    required this.onPageChanged,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.report == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.report == null || state.report!.data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    final orders = state.report!.data;
    final meta = state.report!.meta;

    return Column(
      children: [
        // List View (Cards)
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
            itemCount: orders.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildTransactionCard(context, order);
            },
          ),
        ),

        // Modern Pagination Controls
        _buildPaginationControls(meta),
      ],
    );
  }

  Widget _buildTransactionCard(BuildContext context, Order order) {
    final bool isDealer = order.user?['isDealer'] == true;
    final Color primaryColor = isDark ? Colors.blueAccent : const Color(0xFF136DEC);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Date and Order No
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tag_rounded,
                      size: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.orderNo,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: order.orderNo));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order number copied')),
                        );
                      },
                      child: Icon(Icons.copy_rounded, size: 14, color: primaryColor),
                    ),
                  ],
                ),
                Text(
                  _formatDate(order.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            
            // Middle Row: User Details and Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // User Info
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDealer 
                            ? (isDark ? Colors.purple[900]?.withValues(alpha: 0.3) : Colors.purple[50])
                            : (isDark ? Colors.blue[900]?.withValues(alpha: 0.3) : Colors.blue[50]),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDealer ? Icons.storefront_rounded : Icons.person_rounded,
                          size: 20,
                          color: isDealer ? Colors.purple : primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.user?['name'] ?? 'Unknown User',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey[200] : const Color(0xFF334155),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.user?['role'] ?? (isDealer ? 'Dealer' : 'Customer'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDealer ? Colors.purple : primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyUtils.format(order.grandTotalPaise / 100),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStatusBadge(order.status.nameStr),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls(dynamic meta) {
    if (meta.totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: meta.page > 1 ? () => onPageChanged(meta.page - 1) : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: meta.page > 1 
                        ? (isDark ? Colors.grey[700]! : Colors.grey[300]!)
                        : Colors.transparent,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: meta.page > 1 
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.grey,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Page Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Page ${meta.page} of ${meta.totalPages}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : const Color(0xFF475569),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Next Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: meta.page < meta.totalPages ? () => onPageChanged(meta.page + 1) : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: meta.page < meta.totalPages 
                        ? (isDark ? Colors.grey[700]! : Colors.grey[300]!)
                        : Colors.transparent,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: meta.page < meta.totalPages 
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;
    
    switch (status.toLowerCase()) {
      case 'confirmed': 
        color = Colors.blue[700]!; 
        bgColor = Colors.blue[50]!;
        if(isDark) { color = Colors.blue[400]!; bgColor = Colors.blue[900]!.withValues(alpha: 0.3); }
        break;
      case 'delivered': 
        color = Colors.green[700]!; 
        bgColor = Colors.green[50]!;
        if(isDark) { color = Colors.green[400]!; bgColor = Colors.green[900]!.withValues(alpha: 0.3); }
        break;
      case 'cancelled': 
        color = Colors.red[700]!; 
        bgColor = Colors.red[50]!;
        if(isDark) { color = Colors.red[400]!; bgColor = Colors.red[900]!.withValues(alpha: 0.3); }
        break;
      case 'pending': 
      default:
        color = Colors.orange[700]!; 
        bgColor = Colors.orange[50]!;
        if(isDark) { color = Colors.orange[400]!; bgColor = Colors.orange[900]!.withValues(alpha: 0.3); }
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
  }
}
