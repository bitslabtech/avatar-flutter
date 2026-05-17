import 'package:flutter/material.dart';
import '../providers/reports_provider.dart';
import '../../../models/order.dart'; // Import Order model for extension methods
import '../../../core/utils/currency_utils.dart'; // Assuming this exists

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
        child: Text(
          'No transactions found',
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
      );
    }

    final orders = state.report!.data;
    final meta = state.report!.meta;

    return Column(
      children: [
        // Table Header
        Container(
          color: isDark ? const Color(0xFF1F2937) : Colors.grey[50],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildHeaderCell('Date', flex: 2),
              _buildHeaderCell('Order #', flex: 2),
              _buildHeaderCell('User', flex: 3),
              _buildHeaderCell('Amount', flex: 2, align: TextAlign.end),
              _buildHeaderCell('Status', flex: 2, align: TextAlign.center),
            ],
          ),
        ),

        // List View (Rows)
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            padding: EdgeInsets.zero,
            itemCount: orders.length,
            separatorBuilder: (c, i) => Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
            itemBuilder: (context, index) {
              final order = orders[index];
              return Container(
                color: isDark ? const Color(0xFF101822) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    // Date
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatDate(order.createdAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                    // Order No
                    Expanded(
                      flex: 2,
                      child: Text(
                        order.orderNo,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF111418),
                        ),
                      ),
                    ),
                    // User
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.user?['name'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xFF111418),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            order.user?['role'] ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: order.user?['isDealer'] == true ? Colors.purple : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Amount
                    Expanded(
                      flex: 2,
                      child: Text(
                        CurrencyUtils.format(order.grandTotalPaise / 100),
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF111418),
                        ),
                      ),
                    ),
                    // Status
                    Expanded(
                      flex: 2,
                      child: Center(child: _buildStatusBadge(order.status.nameStr)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Pagination Controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            border: Border(top: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Page ${meta.page} of ${meta.totalPages} (${meta.total} items)',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: meta.page > 1 ? () => onPageChanged(meta.page - 1) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: meta.page < meta.totalPages ? () => onPageChanged(meta.page + 1) : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String label, {int flex = 1, TextAlign align = TextAlign.start}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey[300] : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    switch (status.toLowerCase()) {
      case 'confirmed': color = Colors.blue; break;
      case 'delivered': color = Colors.green; break;
      case 'cancelled': color = Colors.red; break;
      case 'pending': color = Colors.orange; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
