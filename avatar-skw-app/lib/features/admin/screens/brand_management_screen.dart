import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/brand_provider.dart';

class BrandManagementScreen extends ConsumerStatefulWidget {
  const BrandManagementScreen({super.key});

  @override
  ConsumerState<BrandManagementScreen> createState() => _BrandManagementScreenState();
}

class _BrandManagementScreenState extends ConsumerState<BrandManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(brandProvider.notifier).loadBrands();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal(BuildContext context, bool isDark, BrandFilter currentFilter) {
    BrandFilter tempFilter = currentFilter;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF232C48) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Brands',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                _buildFilterRadio(isDark, 'All Brands', tempFilter == BrandFilter.all, () {
                  setModalState(() => tempFilter = BrandFilter.all);
                }),
                _buildFilterRadio(isDark, 'Active Only', tempFilter == BrandFilter.active, () {
                  setModalState(() => tempFilter = BrandFilter.active);
                }),
                _buildFilterRadio(isDark, 'Inactive Only', tempFilter == BrandFilter.inactive, () {
                  setModalState(() => tempFilter = BrandFilter.inactive);
                }),
                _buildFilterRadio(isDark, 'Unassigned Only', tempFilter == BrandFilter.unassigned, () {
                  setModalState(() => tempFilter = BrandFilter.unassigned);
                }),
                
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(brandProvider.notifier).setFilter(BrandFilter.all);
                          Navigator.pop(ctx);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: isDark ? Colors.grey : Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Clear', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(brandProvider.notifier).setFilter(tempFilter);
                          Navigator.pop(ctx);
                          if (tempFilter != BrandFilter.all) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Filtering: ${tempFilter.name}'),
                                backgroundColor: AppColors.primaryBlue,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
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
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryBlue : (isDark ? Colors.grey : Colors.grey.shade400),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandState = ref.watch(brandProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundBlack : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Expanded(
              child: brandState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : brandState.error != null
                      ? Center(child: Text('Error: ${brandState.error}'))
                      : _buildContent(context, isDark, brandState),
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
                icon: Icon(Icons.arrow_back, color: isDark ? Colors.grey.shade300 : Colors.grey.shade600),
                style: IconButton.styleFrom(
                   padding: EdgeInsets.zero,
                   visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Brands',
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
            label: const Text('New'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.primaryBlue.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, BrandState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OVERVIEW', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          _buildStatsRow(isDark, state),
          const SizedBox(height: 24),
          _buildSearchBar(isDark),
          const SizedBox(height: 16),
          _buildBrandList(isDark, state.filteredBrands),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, BrandState state) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(isDark, 'Total Brands', state.totalCount.toString(), Icons.dataset, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(isDark, 'Active Brands', state.activeCount.toString(), Icons.verified, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(isDark, 'Inactive Brands', state.inactiveCount.toString(), Icons.unpublished, Colors.grey)),
      ],
    );
  }

  Widget _buildStatCard(bool isDark, String label, String value, IconData icon, MaterialColor color) {
    final bgColor = isDark ? color.shade900.withOpacity(0.2) : color.shade50;
    final iconColor = isDark ? color.shade400 : color.shade600;
    final borderColor = isDark ? color.shade900.withOpacity(0.3) : color.shade100;

    return Container(
       // height: 100, // Removed fixed height to prevent overflow
       constraints: const BoxConstraints(minHeight: 100),
       padding: const EdgeInsets.all(12),
       decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final currentFilter = ref.watch(brandProvider).filter;
    final hasActiveFilter = currentFilter != BrandFilter.all;
    
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
              onChanged: (value) => ref.read(brandProvider.notifier).setSearchQuery(value),
              decoration: InputDecoration(
                hintText: 'Search brands...',
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
                icon: Icon(
                  Icons.tune,
                  color: hasActiveFilter ? AppColors.primaryBlue : (isDark ? Colors.grey.shade300 : Colors.grey.shade600),
                ),
                onPressed: () => _showFilterModal(context, isDark, currentFilter),
              ),
              if (hasActiveFilter)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrandList(bool isDark, List<BrandItem> brands) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('BRAND NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
              Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
            ],
          ),
        ),
        ...brands.map((b) => _buildBrandItem(isDark, b)),
      ],
    );
  }

  Widget _buildBrandItem(bool isDark, BrandItem item) {
    // Generate an icon/color hash based on ID if no logo (placeholder)
    final colors = [Colors.blue, Colors.orange, Colors.teal, Colors.purple, Colors.pink];
    final color = colors[item.name.length % colors.length];
    final icon = [Icons.diamond, Icons.ac_unit, Icons.soup_kitchen, Icons.water_drop, Icons.smart_toy][item.name.length % 5];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Expanded(
             child: Row(
               children: [
                 Container(
                   width: 40, height: 40,
                   decoration: BoxDecoration(
                     color: isDark ? color.withOpacity(0.1) : color.shade50,
                     borderRadius: BorderRadius.circular(8),
                     border: Border.all(color: isDark ? color.withOpacity(0.3) : color.withOpacity(0.1)),
                   ),
                   child: Icon(icon, color: color, size: 20),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         item.name,
                         style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                         overflow: TextOverflow.ellipsis,
                       ),
                       const SizedBox(height: 4),
                       Row(
                         children: [
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                             decoration: BoxDecoration(
                               color: item.isActive 
                                   ? (isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50)
                                   : (isDark ? Colors.grey.withOpacity(0.2) : Colors.grey.shade100),
                               borderRadius: BorderRadius.circular(4),
                             ),
                             child: Text(
                               item.isActive ? 'Active' : 'Inactive',
                               style: TextStyle(
                                 fontSize: 10, 
                                 fontWeight: FontWeight.w600,
                                 color: item.isActive ? Colors.green : Colors.grey,
                               ),
                             ),
                           ),
                           const SizedBox(width: 8),
                           Text(
                             '${item.productCount} Products',
                             style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                           ),
                         ],
                       ),
                     ],
                   ),
                 ),
               ],
             ),
           ),
           Row(
             children: [
               IconButton(
                 onPressed: () => context.pushNamed('admin-brand-edit', pathParameters: {'id': item.id}),
                 icon: const Icon(Icons.edit_outlined, size: 20),
                 color: Colors.grey,
                 visualDensity: VisualDensity.compact,
                 style: IconButton.styleFrom(
                   backgroundColor: isDark ? Colors.transparent : Colors.grey.shade50,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                 ),
               ),
             ],
           ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {BrandItem? brand}) {
    showDialog(
      context: context,
      builder: (context) => _BrandDialog(brand: brand),
    );
  }

  void _confirmDelete(BrandItem item) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Brand?'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
               final success = await ref.read(brandProvider.notifier).deleteBrand(item.id);
               if (success && context.mounted) {
                 context.pop();
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Brand Deleted')));
               }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _BrandDialog extends ConsumerStatefulWidget {
  final BrandItem? brand;
  const _BrandDialog({this.brand});

  @override
  ConsumerState<_BrandDialog> createState() => _BrandDialogState();
}

class _BrandDialogState extends ConsumerState<_BrandDialog> {
  final _nameController = TextEditingController();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.brand != null) {
      _nameController.text = widget.brand!.name;
      _isActive = widget.brand!.isActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.brand != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isEdit ? 'Edit Brand' : 'New Brand', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.close, color: isDark ? Colors.grey : Colors.grey.shade400),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
               child: GestureDetector(
                  onTap: () {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image Upload Feature Coming Soon')));
                  },
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, color: AppColors.primaryBlue, size: 24),
                        const SizedBox(height: 4),
                        Text('Add Logo', style: TextStyle(fontSize: 10, color: AppColors.primaryBlue, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
            ),
             const SizedBox(height: 24),
             Text('NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
             const SizedBox(height: 8),
             TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter brand name',
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                     if (_nameController.text.isNotEmpty) {
                       bool success;
                       if (isEdit) {
                         success = await ref.read(brandProvider.notifier).updateBrand(
                           id: widget.brand!.id,
                           name: _nameController.text,
                           isActive: _isActive,
                         );
                       } else {
                         success = await ref.read(brandProvider.notifier).createBrand(
                           name: _nameController.text,
                           isActive: _isActive,
                         );
                       }
                       if (success && context.mounted) {
                         context.pop();
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Brand Updated' : 'Brand Created')));
                       }
                     }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isEdit ? 'Save Changes' : 'Create Brand'),
                ),
              )
          ],
        ),
      ),
    ),
    );
  }
}
