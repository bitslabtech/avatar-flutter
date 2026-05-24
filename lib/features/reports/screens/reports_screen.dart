import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/reports_provider.dart';
import '../widgets/reports_filter_bar.dart';
import '../widgets/reports_table.dart';
import '../widgets/revenue_card.dart';
import '../widgets/transaction_list.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsProvider.notifier).loadReports();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101822) : const Color(0xFFF8FAFC), // background-light
      appBar: AppBar(
        title: Text(
          'Sales Reports', 
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A), // slate-900
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: -0.5,
          )
        ),
        backgroundColor: isDark ? const Color(0xFF101822) : Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF475569)), // slate-600
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: isDark ? Colors.grey : const Color(0xFF64748B), // slate-500
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'All Transactions'),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () async {
                 try {
                   await ref.read(reportsProvider.notifier).exportReport();
                   if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Report saved successfully')),
                     );
                   }
                 } catch (e) {
                   if (context.mounted) {
                     final msg = e.toString().toLowerCase().contains('cancelled') 
                         ? 'Export cancelled' 
                         : e.toString();
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text(msg)),
                     );
                   }
                 }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4), // green-50
                  border: Border.all(color: const Color(0xFFBBF7D0)), // green-200
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.table_view, color: Color(0xFF1D6F42), size: 20), // table_view
                    const SizedBox(width: 6),
                    const Text(
                      'Export', 
                      style: TextStyle(
                        color: Color(0xFF1D6F42), // excel-green
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(context, reportState, isDark),
          _buildTransactionsTab(context, reportState, isDark),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, ReportsState state, bool isDark) {
    if (state.isLoading && state.report == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text('Error: ${state.error}'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Adjusted padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReportsFilterBar(), // Global filters affect overview too
          const SizedBox(height: 24),
          
          if (state.report != null) ...[
            RevenueCard(
                summary: state.report!.summary, 
                chartData: state.report!.data, 
                isDark: isDark
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(BuildContext context, ReportsState state, bool isDark) {
    return Column(
      children: [
        // Top Filter Bar Section
        Container(
          color: isDark ? const Color(0xFF101822) : Colors.white,
          padding: const EdgeInsets.all(16.0),
          child: const ReportsFilterBar(),
        ),
        
        // Divider
        Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),

        // Transactions List
        Expanded(
          child: Container(
            color: isDark ? const Color(0xFF101822) : const Color(0xFFF8FAFC),
            child: ReportsTable(
              state: state,
              isDark: isDark,
              onPageChanged: (page) {
                ref.read(reportsProvider.notifier).setPage(page);
              },
            ),
          ),
        ),
      ],
    );
  }
}
