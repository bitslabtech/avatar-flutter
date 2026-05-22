import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user.dart';
import '../../../widgets/common/loading_indicator.dart';
import '../providers/dealer_provider.dart';
import 'add_dealer_screen.dart';
import 'dealer_detail_screen.dart';

final dealerFilterProvider = StateProvider.autoDispose<String?>((ref) => null);
final dealerSearchProvider = StateProvider.autoDispose<String>((ref) => '');
final showDeletedDealersProvider = StateProvider.autoDispose<bool>((ref) => false);

class DealersListScreen extends ConsumerStatefulWidget {
  const DealersListScreen({super.key});

  @override
  ConsumerState<DealersListScreen> createState() => _DealersListScreenState();
}

class _DealersListScreenState extends ConsumerState<DealersListScreen> {
  
  void _showFilterModal(BuildContext context, bool isDark, String? currentFilter) {
    String? tempFilter = currentFilter;
    bool tempShowDeleted = ref.read(showDeletedDealersProvider);
    
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
                    Text('Filter Dealers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFilterRadio(isDark, 'All Dealers', tempFilter == null, () => setModalState(() => tempFilter = null)),
                _buildFilterRadio(isDark, 'Approved / Active', tempFilter == 'approved', () => setModalState(() => tempFilter = 'approved')),
                _buildFilterRadio(isDark, 'Pending', tempFilter == 'pending', () => setModalState(() => tempFilter = 'pending')),
                _buildFilterRadio(isDark, 'Rejected', tempFilter == 'rejected', () => setModalState(() => tempFilter = 'rejected')),
                const Divider(height: 32),
                _buildShowDeletedCheckbox(isDark, tempShowDeleted, (value) => setModalState(() => tempShowDeleted = value)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () { 
                          ref.read(dealerFilterProvider.notifier).state = null; 
                          ref.read(showDeletedDealersProvider.notifier).state = false;
                          Navigator.pop(ctx); 
                        },
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: isDark ? Colors.grey : Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: Text('Clear', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(dealerFilterProvider.notifier).state = tempFilter;
                          ref.read(showDeletedDealersProvider.notifier).state = tempShowDeleted;
                          Navigator.pop(ctx);
                          if (tempFilter != null || tempShowDeleted) {
                            final filterMsg = tempFilter != null ? 'Filtering: ${tempFilter!.capitalize()}' : '';
                            final deletedMsg = tempShowDeleted ? 'Including deleted' : '';
                            final message = [filterMsg, deletedMsg].where((s) => s.isNotEmpty).join(' • ');
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.primary, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, padding: EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
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
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : (isDark ? Colors.grey : Colors.grey.shade400), width: 2)),
              child: isSelected ? Center(child: Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.primary))) : null,
            ),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildShowDeletedCheckbox(bool isDark, bool isChecked, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!isChecked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isChecked ? Theme.of(context).colorScheme.primary : (isDark ? Colors.grey : Colors.grey.shade400),
                  width: 2,
                ),
                color: isChecked ? Theme.of(context).colorScheme.primary : Colors.transparent,
              ),
              child: isChecked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              'Show Deleted Dealers',
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dealersState = ref.watch(dealersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showDeleted = ref.watch(showDeletedDealersProvider);

    // Refresh dealers when showDeleted filter changes
    ref.listen<bool>(showDeletedDealersProvider, (previous, next) {
      if (previous != next) {
        ref.read(dealersProvider.notifier).refresh(showDeleted: next);
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundBlack : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, isDark),
            const SizedBox(height: 16),
            _buildSearchBar(isDark),
            const SizedBox(height: 16),
            _buildAddDealerButton(context, isDark),
            const SizedBox(height: 16),
            Expanded(
              child: dealersState.when(
                data: (dealers) => _buildDealersList(context, dealers, isDark),
                loading: () => const Center(child: LoadingIndicator()),
                error: (err, st) => Center(child: Text('Error: $err', style: TextStyle(color: isDark ? Colors.white : Colors.black))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    final iconBgColor = isDark ? AppColors.surfaceDark : Colors.grey.shade100;
    final iconColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back, color: iconColor),
            style: IconButton.styleFrom(
              backgroundColor: iconBgColor,
              shape: const CircleBorder(),
            ),
          ),
          Text(
            'Dealer Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 48), // Placeholder to balance title
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final currentFilter = ref.watch(dealerFilterProvider);
    final hasActiveFilter = currentFilter != null;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderGray : Colors.grey.shade300),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 2, offset: const Offset(0, 1))],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(Icons.search, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      onChanged: (value) => ref.read(dealerSearchProvider.notifier).state = value,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Search by name, ID, or mobile...',
                        hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontWeight: FontWeight.normal),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.borderGray : Colors.grey.shade300),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 2, offset: const Offset(0, 1))],
            ),
            child: Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.tune, color: hasActiveFilter ? Theme.of(context).colorScheme.primary : (isDark ? Colors.grey.shade500 : Colors.grey.shade400)),
                  onPressed: () => _showFilterModal(context, isDark, currentFilter),
                ),
                if (hasActiveFilter)
                  Positioned(top: 8, right: 8, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDealerButton(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddDealerScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 20),
            SizedBox(width: 8),
            Text(
              'Add New Dealer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealersList(BuildContext context, List<User> dealers, bool isDark) {
    final currentFilter = ref.watch(dealerFilterProvider);
    final searchQuery = ref.watch(dealerSearchProvider).toLowerCase();
    
    final filteredDealers = dealers.where((u) {
      final matchesFilter = currentFilter == null || u.status == currentFilter;
      final matchesSearch = searchQuery.isEmpty || 
                            (u.name.toLowerCase().contains(searchQuery)) ||
                            (u.companyName?.toLowerCase().contains(searchQuery) ?? false) ||
                            (u.id.toLowerCase().contains(searchQuery)) ||
                            (u.phone.toLowerCase().contains(searchQuery));
      return matchesFilter && matchesSearch;
    }).toList();

    if (dealers.isEmpty) {
      return Center(child: Text('No dealers found', style: TextStyle(color: isDark ? Colors.white : Colors.black)));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Dealers (${filteredDealers.length})',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (currentFilter != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentFilter.capitalize(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => ref.read(dealerFilterProvider.notifier).state = null,
                        child: Icon(Icons.close, size: 14, color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
               ref.read(dealerFilterProvider.notifier).state = null;
               return ref.read(dealersProvider.notifier).refresh();
            },
            child: filteredDealers.isEmpty
                ? Center(child: Text('No dealers match filter', style: TextStyle(color: isDark ? Colors.white : Colors.black)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredDealers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _DealerCard(user: filteredDealers[index], isDark: isDark);
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _DealerCard extends ConsumerWidget {
  final User user;
  final bool isDark;

  const _DealerCard({required this.user, required this.isDark});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
      case 'approved':
        return isDark ? AppColors.successGreen : Colors.green.shade700;
      case 'pending':
        return isDark ? AppColors.warningOrange : Colors.orange.shade800;
      case 'rejected':
      case 'inactive':
        return isDark ? AppColors.errorRed : Colors.red.shade700;
      default:
        return isDark ? Colors.grey : Colors.grey.shade700;
    }
  }

  Color _getStatusBgColor(String status) {
     if (isDark) return _getStatusColor(status).withOpacity(0.1);

    switch (status) {
      case 'active':
      case 'approved':
        return Colors.green.shade50;
      case 'pending':
        return Colors.orange.shade50;
      case 'rejected':
      case 'inactive':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Color _getStatusBorderColor(String status) {
    if (isDark) return _getStatusColor(status).withOpacity(0.3);

    switch (status) {
      case 'active':
      case 'approved':
        return Colors.green.shade200;
      case 'pending':
        return Colors.orange.shade200;
      case 'rejected':
      case 'inactive':
        return Colors.red.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
    ];
    // Adjust luminance for dark mode to ensure readability if needed, 
    // but these material colors usually work okay. For dark mode, maybe lighter shade.
    final color = colors[name.codeUnits.fold(0, (p, c) => p + c) % colors.length];
    return isDark ? color.withOpacity(0.8) : color;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarColor = _getAvatarColor(user.name);
    final displayName = user.companyName ?? user.name;
    final displayId = 'ID: #D-${user.id.substring(0, 4).toUpperCase()}';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderGray : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DealerDetailScreen(dealer: user),
            ),
          ).then((_) => ref.read(dealersProvider.notifier).refresh());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: avatarColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  image: (user.resolvedAvatarUrl != null && user.resolvedAvatarUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(user.resolvedAvatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: (user.resolvedAvatarUrl != null && user.resolvedAvatarUrl!.isNotEmpty) 
                    ? null 
                    : Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: avatarColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayId,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status & Chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(user.status),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getStatusBorderColor(user.status)),
                    ),
                    child: Text(
                      user.status == 'approved' ? 'Active' : user.status.capitalize(),
                      style: TextStyle(
                        color: _getStatusColor(user.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Icon(Icons.expand_more, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
