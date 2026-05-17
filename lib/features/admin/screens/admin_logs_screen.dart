
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart'; // Assuming GoogleFonts is used
import '../../../models/audit_log.dart';
import '../providers/audit_logs_provider.dart';

class AdminLogsScreen extends ConsumerStatefulWidget {
  const AdminLogsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends ConsumerState<AdminLogsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(auditLogsProvider.notifier).loadLogs(refresh: true));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auditLogsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: Text(
          'Activity Logs',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(auditLogsProvider.notifier).loadLogs(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Stats Cards
          _buildStatsCards(state.total, isDark),

          // 2. Filters
          _buildFilters(ref, state.filters.module, isDark),

          // 3. Timeline List
          Expanded(
            child: state.isLoading && state.logs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Text('Error: ${state.error}'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        itemCount: state.logs.length,
                        itemBuilder: (context, index) {
                          final log = state.logs[index];
                          return _buildLogItem(log, isDark, index);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(int total, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _statCard('Total Logs', total.toString(), Icons.history, Colors.blue, isDark)),
          const SizedBox(width: 12),
          Expanded(child: _statCard('Errors', '0', Icons.error_outline, Colors.red, isDark)), // Placeholder for error count
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C3E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(WidgetRef ref, String? currentModule, bool isDark) {
    final modules = ['All', 'PRODUCTS', 'ORDERS', 'USERS', 'AUTH', 'ADMINS'];
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: modules.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final mod = modules[index];
          final isSelected = (mod == 'All' && currentModule == null) || mod == currentModule;
          return ChoiceChip(
            label: Text(mod),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                 ref.read(auditLogsProvider.notifier).setModuleFilter(mod == 'All' ? null : mod);
              }
            },
            backgroundColor: isDark ? const Color(0xFF2C2C3E) : Colors.white,
            selectedColor: Theme.of(context).primaryColor,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogItem(AuditLog log, bool isDark, int index) {
    Color tagColor;
    IconData tagIcon;

    switch (log.action) {
      case 'create':
        tagColor = Colors.green;
        tagIcon = Icons.add_circle_outline;
        break;
      case 'update':
        tagColor = Colors.orange;
        tagIcon = Icons.edit_outlined;
        break;
      case 'delete':
        tagColor = Colors.red;
        tagIcon = Icons.delete_outline;
        break;
      default:
        tagColor = Colors.blue;
        tagIcon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C3E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tagColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(tagIcon, color: tagColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${log.module} • ${DateFormat('MMM d, h:mm a').format(log.createdAt)}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (log.ipAddress != null)
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                         color: isDark ? Colors.black26 : Colors.grey.shade100,
                         borderRadius: BorderRadius.circular(4)
                     ),
                     child: Text(
                       log.ipAddress!,
                       style: GoogleFonts.robotoMono(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54),
                     ),
                   )
              ],
            ),
            if (log.description != null) ...[
              const SizedBox(height: 12),
              Text(
                log.description!,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
             if (log.admin != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: isDark ? Colors.white38 : Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'By: ${log.admin?['name'] ?? 'Unknown'}',
                      style: GoogleFonts.outfit(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey),
                    ),
                  ],
                )
             ]
          ],
        ),
      ),
    );
  }
}
