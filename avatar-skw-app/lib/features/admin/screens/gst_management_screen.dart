import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/gst_provider.dart';

class GstManagementScreen extends ConsumerStatefulWidget {
  const GstManagementScreen({super.key});

  @override
  ConsumerState<GstManagementScreen> createState() => _GstManagementScreenState();
}

class _GstManagementScreenState extends ConsumerState<GstManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _deleteConfirmationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gstProvider.notifier).loadGstRates();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _deleteConfirmationController.dispose();
    super.dispose();
  }

  void _showFilterModal(BuildContext context, bool isDark, GstFilter currentFilter) {
    GstFilter tempFilter = currentFilter;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF232C48) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filter GST Rates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFilterRadio(isDark, 'All Rates', tempFilter == GstFilter.all, () => setModalState(() => tempFilter = GstFilter.all)),
                _buildFilterRadio(isDark, 'Active Only', tempFilter == GstFilter.active, () => setModalState(() => tempFilter = GstFilter.active)),
                _buildFilterRadio(isDark, 'Inactive Only', tempFilter == GstFilter.inactive, () => setModalState(() => tempFilter = GstFilter.inactive)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () { ref.read(gstProvider.notifier).setFilter(GstFilter.all); Navigator.pop(ctx); },
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: isDark ? Colors.grey : Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: Text('Clear', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(gstProvider.notifier).setFilter(tempFilter);
                          Navigator.pop(ctx);
                          if (tempFilter != GstFilter.all) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Filtering: ${tempFilter.name}'), backgroundColor: AppColors.primaryBlue, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: const Text('Apply Filter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRadio(bool isDark, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? AppColors.primaryBlue : (isDark ? Colors.grey : Colors.grey.shade400), width: 2)),
              child: isSelected ? Center(child: Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryBlue))) : null,
            ),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gstState = ref.watch(gstProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundBlack : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Expanded(
              child: gstState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : gstState.error != null
                      ? Center(child: Text('Error: ${gstState.error}'))
                      : _buildContent(context, isDark, gstState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundBlack : Colors.white.withOpacity(0.95),
        border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(Icons.arrow_back_ios_new, size: 20, color: isDark ? Colors.white : Colors.black),
                style: IconButton.styleFrom(
                   padding: EdgeInsets.zero,
                   visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'GST Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _showAddEditDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.primaryBlue.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, GstState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsRow(isDark, state),
          const SizedBox(height: 24),
          _buildSearchBar(isDark, state.filter),
          const SizedBox(height: 16),
           _buildListHeader(isDark),
          const SizedBox(height: 12),
          _buildGstList(isDark, state.filteredRates),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, GstState state) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(isDark, 'Total Slabs', state.totalCount.toString(), Icons.percent, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(isDark, 'Active', state.activeCount.toString(), Icons.check_circle, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(isDark, 'Inactive', state.inactiveCount.toString(), Icons.remove_circle, Colors.grey)),
      ],
    );
  }

  Widget _buildStatCard(bool isDark, String label, String value, IconData icon, MaterialColor color) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, GstFilter activeFilter) {
    final hasActiveFilter = activeFilter != GstFilter.all;
    
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => ref.read(gstProvider.notifier).setSearchQuery(value),
              decoration: InputDecoration(
                hintText: 'Search by percentage...',
                hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
          ),
          child: Stack(
            children: [
              IconButton(
                icon: Icon(Icons.tune, color: hasActiveFilter ? AppColors.primaryBlue : (isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
                onPressed: () => _showFilterModal(context, isDark, activeFilter),
              ),
              if (hasActiveFilter)
                Positioned(top: 8, right: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('GST %', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500))),
          Expanded(flex: 1, child: Center(child: Text('STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)))),
          Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: Text('ACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)))),
        ],
      ),
    );
  }

  Widget _buildGstList(bool isDark, List<GstItem> rates) {
    return Column(
      children: rates.map((item) => _buildGstItem(isDark, item)).toList(),
    );
  }

  Widget _buildGstItem(bool isDark, GstItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
      ),
      child: Row(
        children: [
           Expanded(
             flex: 1,
             child: Row(
               children: [
                 Container(
                   width: 40, height: 40,
                   decoration: BoxDecoration(
                     color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Icon(Icons.percent, size: 20, color: isDark ? Colors.grey.shade300 : Colors.grey.shade600),
                 ),
                 const SizedBox(width: 12),
                 Text('${item.percentage}%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
               ],
             ),
           ),
           Expanded(
             flex: 1,
             child: Center(
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                 decoration: BoxDecoration(
                   color: item.isActive 
                       ? (isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50)
                       : (isDark ? Colors.grey.withOpacity(0.2) : Colors.grey.shade100),
                   borderRadius: BorderRadius.circular(20),
                 ),
                 child: Text(
                   item.isActive ? 'Active' : 'Inactive',
                   style: TextStyle(
                     fontSize: 12, 
                     fontWeight: FontWeight.w600,
                     color: item.isActive ? Colors.green.shade600 : Colors.grey.shade600,
                   ),
                 ),
               ),
             ),
           ),
           Expanded(
             flex: 1,
             child: Row(
               mainAxisAlignment: MainAxisAlignment.end,
               children: [
                 IconButton(
                   onPressed: () => _showAddEditDialog(context, item: item),
                   icon: const Icon(Icons.edit, size: 20),
                   color: Colors.grey,
                   style: IconButton.styleFrom(
                     backgroundColor: isDark ? Colors.transparent : Colors.grey.shade50,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                   ),
                 ),
                 const SizedBox(width: 8),
                 IconButton(
                   onPressed: () => _confirmDelete(item),
                   icon: const Icon(Icons.delete, size: 20),
                   color: Colors.red.shade400,
                   style: IconButton.styleFrom(
                     backgroundColor: isDark ? Colors.transparent : Colors.red.shade50,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                   ),
                 ),
               ],
             ),
           ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {GstItem? item}) {
    showDialog(
      context: context,
      builder: (context) => _GstDialog(item: item),
    );
  }

  void _confirmDelete(GstItem item) {
    _deleteConfirmationController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(Icons.warning_amber_rounded, size: 32, color: Colors.red.shade600),
            ),
            const SizedBox(height: 16),
            Text('Delete GST Rate?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to delete the ${item.percentage}% slab? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900.withOpacity(0.5) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('TYPE "DELETE" TO CONFIRM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                   const SizedBox(height: 8),
                   TextField(
                     controller: _deleteConfirmationController,
                     textAlign: TextAlign.center,
                     style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                     decoration: InputDecoration(
                       hintText: 'DELETE',
                       hintStyle: TextStyle(color: Colors.grey.shade400),
                       filled: true,
                       fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.2) : Colors.white,
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade600 : Colors.grey.shade300)),
                       contentPadding: const EdgeInsets.symmetric(vertical: 12),
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                       backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.white,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade300)),
                    ),
                    child: Text('Cancel', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_deleteConfirmationController.text == 'DELETE') {
                        final success = await ref.read(gstProvider.notifier).deleteGstRate(item.id);
                        if (success && context.mounted) {
                          context.pop();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GST Rate Deleted Permanently')));
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please type DELETE to confirm')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.red.shade600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _GstDialog extends ConsumerStatefulWidget {
  final GstItem? item;
  const _GstDialog({this.item});

  @override
  ConsumerState<_GstDialog> createState() => _GstDialogState();
}

class _GstDialogState extends ConsumerState<_GstDialog> {
  final _percentageController = TextEditingController();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _percentageController.text = widget.item!.percentage.toString();
      _isActive = widget.item!.isActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.item != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isEdit ? 'Edit GST Slab' : 'New GST Slab', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.close, color: isDark ? Colors.grey : Colors.grey.shade400),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
             const SizedBox(height: 24),
             Text('PERCENTAGE (%)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
             const SizedBox(height: 8),
             TextField(
                controller: _percentageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter percentage (e.g. 18)',
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  suffixIcon: const Icon(Icons.percent, size: 20, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active Status', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                  Switch.adaptive(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    activeColor: AppColors.primaryBlue,
                  )
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                     final percentage = int.tryParse(_percentageController.text);
                     if (percentage != null) {
                       bool success;
                       if (isEdit) {
                         success = await ref.read(gstProvider.notifier).updateGstRate(
                           widget.item!.id,
                           percentage: percentage,
                           isActive: _isActive,
                         );
                       } else {
                         success = await ref.read(gstProvider.notifier).createGstRate(
                           percentage,
                           isActive: _isActive,
                         );
                       }
                       if (success && context.mounted) {
                         context.pop();
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'GST Rate Updated' : 'GST Rate Created')));
                       }
                     }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isEdit ? 'Save Changes' : 'Create Slab'),
                ),
              )
          ],
        ),
      ),
    );
  }
}
