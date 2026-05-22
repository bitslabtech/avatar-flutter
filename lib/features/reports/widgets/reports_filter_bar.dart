import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/reports_provider.dart';

class ReportsFilterBar extends ConsumerWidget {
  const ReportsFilterBar({super.key});

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(reportsProvider);
    final filters = reportState.filters;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Period
          _buildSectionLabel('Date Period'),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Theme.of(context).colorScheme.primary,
                        onPrimary: Colors.white,
                        surface: isDark ? const Color(0xFF1F2937) : Colors.white,
                        onSurface: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                ref.read(reportsProvider.notifier).updateDateRange(picked);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)), // slate-200
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // blue-50
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Range',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : const Color(0xFF64748B), // slate-500
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          (filters.startDate != null && filters.endDate != null)
                              ? '${filters.startDate} - ${filters.endDate}'
                              : 'Select Date Range',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF1E293B), // slate-800
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.expand_more, color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8)), // slate-400
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),

          // User Type
          _buildSectionLabel('User Type'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9), // slate-100
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)), // slate-200
            ),
            child: Row(
              children: [
                _buildUserTypeButton(context, label: 'All', value: null, groupValue: filters.userType, ref: ref),
                _buildUserTypeButton(context, label: 'Dealer', value: 'dealer', groupValue: filters.userType, ref: ref),
                _buildUserTypeButton(context, label: 'Consumer', value: 'consumer', groupValue: filters.userType, ref: ref),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Specific Member
          _buildSectionLabel('Specific Member'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)), // slate-200
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (val) {
                ref.read(reportsProvider.notifier).setSearch(val.isEmpty ? null : val);
              },
              decoration: InputDecoration(
                hintText: 'Search by name or ID...',
                hintStyle: TextStyle(color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8)), // slate-400
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A)), // slate-900
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B), // slate-500
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildUserTypeButton(BuildContext context, {required String label, required String? value, required String? groupValue, required WidgetRef ref}) {
    final isSelected = value == groupValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () => ref.read(reportsProvider.notifier).setUserType(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? Colors.grey[800] : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              )
            ] : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected 
                  ? (isDark ? Colors.white : const Color(0xFF0F172A)) // slate-900
                  : (isDark ? Colors.grey[400] : const Color(0xFF475569)), // slate-600
            ),
          ),
        ),
      ),
    );
  }
}
