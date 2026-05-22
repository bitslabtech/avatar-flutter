import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/product_management_provider.dart';
import '../../../models/product.dart';
import '../widgets/product_list_skeleton.dart';
import 'product_add_edit_screen.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productManagementProvider.notifier).loadProducts(showSkeleton: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(productManagementProvider.notifier).loadMoreProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _showFilterModal(BuildContext context, bool isDark, FilterOptions currentOptions) {
    FilterOptions tempOptions = currentOptions;
    
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
                    'Filter Products',
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
              
              // Status Filter - Radio buttons (mutually exclusive)
              Text(
                'Product Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF92A0C9) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              _buildFilterRadio(isDark, 'All Products', tempOptions.statusFilter == StatusFilter.all, () {
                setModalState(() => tempOptions = tempOptions.copyWith(statusFilter: StatusFilter.all));
              }),
              _buildFilterRadio(isDark, 'Active Products Only', tempOptions.statusFilter == StatusFilter.active, () {
                setModalState(() => tempOptions = tempOptions.copyWith(statusFilter: StatusFilter.active));
              }),
              _buildFilterRadio(isDark, 'Inactive Products Only', tempOptions.statusFilter == StatusFilter.inactive, () {
                setModalState(() => tempOptions = tempOptions.copyWith(statusFilter: StatusFilter.inactive));
              }),
              
              const Divider(height: 24),
              
              // Additional Filters - Checkboxes (can be combined)
              Text(
                'Additional Filters',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF92A0C9) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              _buildFilterCheckbox(isDark, 'Category Unassigned Only', tempOptions.showCategoryUnassigned, (val) {
                setModalState(() => tempOptions = tempOptions.copyWith(showCategoryUnassigned: val));
              }),
              _buildFilterCheckbox(isDark, 'Brand Unassigned Only', tempOptions.showBrandUnassigned, (val) {
                setModalState(() => tempOptions = tempOptions.copyWith(showBrandUnassigned: val));
              }),
              _buildFilterCheckbox(isDark, 'GST Unassigned Only', tempOptions.showGstUnassigned, (val) {
                setModalState(() => tempOptions = tempOptions.copyWith(showGstUnassigned: val));
              }),
              
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(productManagementProvider.notifier).clearFilterOptions();
                        Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: isDark ? Colors.grey : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Clear All', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(productManagementProvider.notifier).setFilterOptions(tempOptions);
                        Navigator.pop(ctx);
                        if (tempOptions.hasActiveFilters) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Filters applied'),
                              backgroundColor: const Color(0xFF1349EC),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1349EC),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildFilterCheckbox(bool isDark, String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF1349EC),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildFilterRadio(bool isDark, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF1349EC) : (isDark ? Colors.grey : Colors.grey.shade400),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1349EC),
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
    final productState = ref.watch(productManagementProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101522) : const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            
            // Active filter notification
            if (productState.statCardFilter != StatCardFilter.none)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFF1349EC).withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(Icons.filter_alt, size: 18, color: const Color(0xFF1349EC)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Showing: ${_getFilterLabel(productState.statCardFilter)}',
                        style: const TextStyle(
                          color: Color(0xFF1349EC),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(productManagementProvider.notifier).clearStatCardFilter(),
                      child: const Icon(Icons.close, size: 18, color: Color(0xFF1349EC)),
                    ),
                  ],
                ),
              ),
            
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(productManagementProvider.notifier).loadProducts();
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (productState.isLoading && productState.products.isEmpty)
                      const SliverToBoxAdapter(child: ProductListSkeleton())
                    else ...[
                      // Stats Carousel
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildStatsCarousel(isDark, productState.stats, productState.statCardFilter),
                        ),
                      ),
                      
                      // Search Bar
                      SliverToBoxAdapter(
                        child: Container(
                          color: isDark ? const Color(0xFF101522) : const Color(0xFFF6F6F8),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: _buildSearchBar(isDark, productState.filterOptions),
                        ),
                      ),
                      
                      // Category Filter Chips
                      SliverToBoxAdapter(
                        child: _buildCategoryFilterList(isDark, productState.uniqueCategories, productState.selectedCategory),
                      ),
                      
                      // Product List Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Product List',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '${productState.filteredProducts.length} loaded / ${productState.totalProducts} total',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF92A0C9) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Product List Items
                      if (productState.error != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('Error: ${productState.error}', style: const TextStyle(color: Colors.red)),
                            ),
                          ),
                        )
                      else if (productState.filteredProducts.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 64,
                                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No products found',
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF92A0C9) : const Color(0xFF64748B),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final product = productState.filteredProducts[index];
                                return _buildProductCard(context, isDark, product);
                              },
                              childCount: productState.filteredProducts.length,
                            ),
                          ),
                        ),
                      
                      // Load More Indicator
                      if (productState.isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),

                      // End of list label
                      if (!productState.hasMore && productState.products.isNotEmpty && !productState.isLoading)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                'All ${productState.totalProducts} products loaded',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF92A0C9) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Bottom Spacer
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFilterLabel(StatCardFilter filter) {
    switch (filter) {
      case StatCardFilter.total: return 'All Products';
      case StatCardFilter.active: return 'Active Products';
      case StatCardFilter.inactive: return 'Inactive Products';
      case StatCardFilter.categoryUnassigned: return 'Category Unassigned';
      case StatCardFilter.brandUnassigned: return 'Brand Unassigned';
      case StatCardFilter.gstUnassigned: return 'GST Unassigned';
      case StatCardFilter.none: return '';
    }
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF101522).withOpacity(0.95) 
            : Colors.white.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Manage Products',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductAddEditScreen()),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('New Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1349EC),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCarousel(bool isDark, ProductStats stats, StatCardFilter activeFilter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard(isDark, 'Total\nProducts', stats.totalProducts.toString(), Icons.inventory_2, 
              const Color(0xFF1349EC), const Color(0xFFDBEAFE), const Color(0xFF1E3A5F),
              StatCardFilter.total, activeFilter),
          const SizedBox(width: 8),
          _buildStatCard(isDark, 'Active\nProducts', stats.activeProducts.toString(), Icons.check_circle, 
              const Color(0xFF10B981), const Color(0xFFD1FAE5), const Color(0xFF064E3B),
              StatCardFilter.active, activeFilter),
          const SizedBox(width: 8),
          _buildStatCard(isDark, 'Inactive\nProducts', stats.inactiveProducts.toString(), Icons.cancel, 
              const Color(0xFF6B7280), const Color(0xFFE5E7EB), const Color(0xFF374151),
              StatCardFilter.inactive, activeFilter),
          const SizedBox(width: 8),
          _buildStatCard(isDark, 'Category\nUnassigned', stats.categoryUnassigned.toString(), Icons.folder_off, 
              const Color(0xFFF59E0B), const Color(0xFFFEF3C7), const Color(0xFF78350F),
              StatCardFilter.categoryUnassigned, activeFilter),
          const SizedBox(width: 8),
          _buildStatCard(isDark, 'Brand\nUnassigned', stats.brandUnassigned.toString(), Icons.branding_watermark, 
              const Color(0xFF8B5CF6), const Color(0xFFEDE9FE), const Color(0xFF4C1D95),
              StatCardFilter.brandUnassigned, activeFilter),
          const SizedBox(width: 8),
          _buildStatCard(isDark, 'GST\nUnassigned', stats.gstUnassigned.toString(), Icons.receipt_long, 
              const Color(0xFFF43F5E), const Color(0xFFFFE4E6), const Color(0xFF881337),
              StatCardFilter.gstUnassigned, activeFilter),
        ],
      ),
    );
  }

  Widget _buildStatCard(bool isDark, String label, String value, IconData icon, Color iconColor, Color lightBg, Color darkBg, StatCardFilter filterType, StatCardFilter activeFilter) {
    final isActive = activeFilter == filterType;
    
    return GestureDetector(
      onTap: () {
        ref.read(productManagementProvider.notifier).setStatCardFilter(filterType);
        if (activeFilter != filterType) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Filtering by: ${_getFilterLabel(filterType)}'),
              backgroundColor: iconColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 106,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF232C48) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? iconColor : (isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFE2E8F0)),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: iconColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? darkBg.withOpacity(0.3) : lightBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF92A0C9) : const Color(0xFF64748B),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, FilterOptions filterOptions) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232C48) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.transparent : const Color(0xFFE2E8F0),
        ),
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
        onChanged: (val) => ref.read(productManagementProvider.notifier).setSearchQuery(val),
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: 'Search by name, SKU, or brand...',
          hintStyle: TextStyle(
            color: isDark ? const Color(0xFF92A0C9) : const Color(0xFF64748B),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 24,
            color: isDark ? const Color(0xFF92A0C9) : const Color(0xFF64748B),
          ),
          suffixIcon: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune,
                  size: 24,
                  color: filterOptions.hasActiveFilters 
                      ? const Color(0xFF1349EC) 
                      : (isDark ? const Color(0xFF92A0C9) : const Color(0xFF64748B)),
                ),
                onPressed: () => _showFilterModal(context, isDark, filterOptions),
              ),
              if (filterOptions.hasActiveFilters)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1349EC),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterList(bool isDark, List<String> categories, String? selectedCategory) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Row(
        children: [
          _buildFilterChip(isDark, 'All Categories', selectedCategory == null, () {
            ref.read(productManagementProvider.notifier).clearCategoryFilter();
          }, showDropdown: true),
          const SizedBox(width: 8),
          ...categories.map((category) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildFilterChip(
              isDark,
              category,
              selectedCategory == category,
              () => ref.read(productManagementProvider.notifier).setCategoryFilter(category),
              showClose: selectedCategory == category,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFilterChip(bool isDark, String label, bool isSelected, VoidCallback onTap, {bool showDropdown = false, bool showClose = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF1349EC) 
              : (isDark ? const Color(0xFF232C48) : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF1349EC) 
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected 
                    ? Colors.white 
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
            if (showDropdown) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: isSelected 
                    ? Colors.white 
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ],
            if (showClose) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, bool isDark, Product product) {
    final isInactive = !product.isActive;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232C48) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.transparent : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: isInactive ? 0.8 : 1.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: product.resolvedImageUrls != null && product.resolvedImageUrls!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ColorFiltered(
                        colorFilter: isInactive
                            ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                            : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                        child: Image.network(
                          product.resolvedImageUrls!.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image_not_supported,
                            size: 32,
                            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    )
                  : Icon(
                      Icons.image_not_supported,
                      size: 32,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
            ),
            const SizedBox(width: 16),
            
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.brand.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1349EC),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: isDark ? const Color(0xFF92A0C9) : const Color(0xFF64748B),
                        ),
                        padding: EdgeInsets.zero,
                        onSelected: (val) {
                          final user = ref.read(authProvider).user;
                          if (val == 'edit') {
                            if (user?.hasPermission('products', 'update') != true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Permission Denied: Cannot edit products')),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProductAddEditScreen(product: product)),
                            );
                          } else if (val == 'delete') {
                            if (user?.hasPermission('products', 'delete') != true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Permission Denied: Cannot delete products')),
                              );
                              return;
                            }
                            _showDeleteDialog(context, product);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SKU: ${product.sku}',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: isDark ? const Color(0xFF92A0C9) : const Color(0xFF64748B),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.9,
                        child: Switch(
                          value: product.isActive,
                          onChanged: (val) {
                            final user = ref.read(authProvider).user;
                            if (user?.hasPermission('products', 'update') != true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Permission Denied: Cannot update product status')),
                              );
                              return;
                            }
                            ref.read(productManagementProvider.notifier).toggleProductStatus(product.id, val);
                          },
                          activeColor: const Color(0xFF1349EC),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Product product) {
    final TextEditingController deleteController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDeleteEnabled = deleteController.text.toUpperCase() == 'DELETE';
          
          return AlertDialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Delete Product',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete:',
                  style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Text(
                  '"${product.name}"',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'This action cannot be undone. Type DELETE to confirm.',
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deleteController,
                  onChanged: (_) => setDialogState(() {}),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type DELETE',
                    hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDeleteEnabled ? Colors.red : Theme.of(context).colorScheme.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                onPressed: isDeleteEnabled
                    ? () {
                        Navigator.of(ctx).pop();
                        ref.read(productManagementProvider.notifier).deleteProduct(product.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Product "${product.name}" deleted'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  disabledForegroundColor: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      ),
    );
  }
}
