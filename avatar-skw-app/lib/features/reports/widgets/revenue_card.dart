import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/sales_report.dart';
import '../../../models/order.dart';

class RevenueCard extends StatelessWidget {
  final ReportSummary summary;
  final List<Order> chartData;
  final bool isDark;

  const RevenueCard({
    super.key,
    required this.summary,
    required this.chartData,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFF1F5F9)), // slate-100
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background Decoration
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF).withValues(alpha: 0.5), // blue-50
                  shape: BoxShape.circle,
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.white.withValues(alpha: 0.0)),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Revenue',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[400] : const Color(0xFF64748B), // slate-500
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            // Format currency
                            '₹${summary.totalRevenue.toStringAsFixed(2)}', 
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A), // slate-900
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                      
                      // Trend Badge (Static for now as backend doesn't provide trend yet)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5), // emerald-50
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFD1FAE5)), // emerald-100
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.trending_up, color: Color(0xFF059669), size: 18), // emerald-600
                            const SizedBox(width: 4),
                            const Text(
                              '+12%', // STATIC PLACEHOLDER
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF047857), // emerald-700
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // Chart Area
                  SizedBox(
                    height: 128,
                    width: double.infinity,
                    child: _buildChart(),
                  ),

                  const SizedBox(height: 16),
                  
                  Center(
                    child: Text(
                      'Revenue trend for selected period vs previous 30 days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8), // slate-400
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (chartData.isEmpty) return const SizedBox();

    // Process data: Group by Date
    final Map<String, double> salesByDate = {};
    for (var order in chartData) {
      // Basic grouping by day
      final date = '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}-${order.createdAt.day.toString().padLeft(2, '0')}';
      salesByDate[date] = (salesByDate[date] ?? 0) + (order.grandTotalPaise / 100);
    }

    // Sort by date key
    final sortedKeys = salesByDate.keys.toList()..sort();
    
    // Create spots
    final spots = List.generate(sortedKeys.length, (index) {
        return FlSpot(index.toDouble(), salesByDate[sortedKeys[index]]!);
    });

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false), // Disable touch for overview card
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primaryBlue,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false), // Hide dots by default like design
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryBlue.withValues(alpha: 0.2),
                  AppColors.primaryBlue.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
