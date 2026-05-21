import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user.dart';
import '../providers/user_management_provider.dart';

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userManagementProvider.notifier).loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userState = ref.watch(userManagementProvider);

    // Local filtering: Exclude dealers and super_admin from THIS screen
    // (Provider returns all users so other screens can use them)
    final manageableUsers = userState.users.where((u) => u.role != 'dealer' && u.role != 'super_admin').toList();
    
    final displayStats = UserStats(
      totalUsers: manageableUsers.length,
      activeUsers: manageableUsers.where((u) => u.isActive).length,
      inactiveUsers: manageableUsers.where((u) => !u.isActive).length,
    );

    final displayUsers = userState.filteredUsers.where((u) => u.role != 'dealer' && u.role != 'super_admin').toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundBlack : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Expanded(
              child: userState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : userState.error != null
                      ? Center(child: Text('Error: ${userState.error}', style: const TextStyle(color: Colors.red)))
                      : RefreshIndicator(
                          onRefresh: () => ref.read(userManagementProvider.notifier).loadUsers(),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStatsCards(isDark, displayStats),
                                const SizedBox(height: 16),
                                _buildSearchBar(isDark, userState),
                                const SizedBox(height: 16),
                                _buildActiveFilters(isDark, userState),
                                const SizedBox(height: 12),
                                Text(
                                  'Users',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...displayUsers.map((user) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildUserCard(context, isDark, user),
                                )),
                                if (displayUsers.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Text(
                                        'No users found',
                                        style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
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
        color: isDark ? AppColors.backgroundBlack : AppColors.backgroundLight,
        border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Manage Users',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(bool isDark, UserStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            isDark,
            'Total',
            '${stats.totalUsers}',
            Icons.people,
            AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            isDark,
            'Active',
            '${stats.activeUsers}',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            isDark,
            'Inactive',
            '${stats.inactiveUsers}',
            Icons.cancel,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(bool isDark, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, UserManagementState state) {
    final hasFilter = state.statusFilter != UserStatusFilter.all || state.roleFilter != UserRoleFilter.all;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        onChanged: (v) => ref.read(userManagementProvider.notifier).setSearchQuery(v),
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: 'Search by name, email, or phone...',
          hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
          prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
          suffixIcon: Stack(
            children: [
              IconButton(
                icon: Icon(Icons.tune, color: hasFilter ? AppColors.primaryBlue : (isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
                onPressed: () => _showFilterOptions(context, isDark, state),
              ),
              if (hasFilter)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
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

  Widget _buildActiveFilters(bool isDark, UserManagementState state) {
    final statusFilter = state.statusFilter;
    final roleFilter = state.roleFilter;
    
    if (statusFilter == UserStatusFilter.all && roleFilter == UserRoleFilter.all) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (statusFilter != UserStatusFilter.all)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                isDark, 
                statusFilter == UserStatusFilter.active ? 'Active' : 'Inactive',
                () => ref.read(userManagementProvider.notifier).setStatusFilter(UserStatusFilter.all),
              ),
            ),
          if (roleFilter != UserRoleFilter.all)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                isDark, 
                roleFilter == UserRoleFilter.admin ? 'Admin' : 'Consumer',
                () => ref.read(userManagementProvider.notifier).setRoleFilter(UserRoleFilter.all),
              ),
            ),
          GestureDetector(
            onTap: () => ref.read(userManagementProvider.notifier).clearFilters(),
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'Clear All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(bool isDark, String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 14, color: AppColors.primaryBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 16, color: AppColors.primaryBlue),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions(BuildContext context, bool isDark, UserManagementState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Users',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(userManagementProvider.notifier).clearFilters();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Filters
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        'STATUS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    _buildFilterRadio(ctx, isDark, 'All Statuses', state.statusFilter == UserStatusFilter.all, () {
                      ref.read(userManagementProvider.notifier).setStatusFilter(UserStatusFilter.all);
                      Navigator.pop(ctx);
                    }),
                    _buildFilterRadio(ctx, isDark, 'Active Only', state.statusFilter == UserStatusFilter.active, () {
                      ref.read(userManagementProvider.notifier).setStatusFilter(UserStatusFilter.active);
                      Navigator.pop(ctx);
                    }),
                    _buildFilterRadio(ctx, isDark, 'Inactive Only', state.statusFilter == UserStatusFilter.inactive, () {
                      ref.read(userManagementProvider.notifier).setStatusFilter(UserStatusFilter.inactive);
                      Navigator.pop(ctx);
                    }),
                    
                    const Divider(height: 32),

                    // Role Filters
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        'ROLE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          letterSpacing: 1
                        ),
                      ),
                    ),
                    _buildFilterRadio(ctx, isDark, 'All Roles', state.roleFilter == UserRoleFilter.all, () {
                      ref.read(userManagementProvider.notifier).setRoleFilter(UserRoleFilter.all);
                      Navigator.pop(ctx);
                    }),
                    _buildFilterRadio(ctx, isDark, 'Admins', state.roleFilter == UserRoleFilter.admin, () {
                      ref.read(userManagementProvider.notifier).setRoleFilter(UserRoleFilter.admin);
                      Navigator.pop(ctx);
                    }),
                    _buildFilterRadio(ctx, isDark, 'Consumers', state.roleFilter == UserRoleFilter.consumer, () {
                      ref.read(userManagementProvider.notifier).setRoleFilter(UserRoleFilter.consumer);
                      Navigator.pop(ctx);
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRadio(BuildContext ctx, bool isDark, String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryBlue : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                  width: 2,
                ),
                color: isSelected ? AppColors.primaryBlue : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, bool isDark, User user) {
    // Helper for role badge colors
    Color roleColor;
    String roleLabel;
    
    if (user.role == 'admin') {
      roleColor = Colors.blue;
      roleLabel = 'Admin';
    } else if (user.role == 'dealer') {
      roleColor = Colors.purple;
      roleLabel = 'Dealer';
    } else {
      roleColor = Colors.grey;
      roleLabel = 'Consumer';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: roleColor.withOpacity(0.2),
                  image: (user.resolvedAvatarUrl != null && user.resolvedAvatarUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(user.resolvedAvatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (user.resolvedAvatarUrl != null && user.resolvedAvatarUrl!.isNotEmpty)
                    ? null
                    : Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: roleColor,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Name and email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      user.email ?? user.phone,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons
              IconButton(
                icon: Icon(Icons.edit, size: 20, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                onPressed: () {
                   final currentUser = ref.read(authProvider).user;
                   if (currentUser?.hasPermission('users', 'update') != true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Permission Denied: Cannot edit users')),
                      );
                      return;
                   }
                  context.pushNamed('admin-user-edit', extra: user);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Role badge and phone
              Row(
                children: [
                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: roleColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.phone, size: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    user.phone,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              // Active Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: user.isActive ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: user.isActive ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
