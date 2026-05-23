/// Profile screen with user info and settings
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import 'screens/approval_pending_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundBlack : Colors.white, // User requested white background
      appBar: AppBar(
        title: Text('Profile', style: theme.textTheme.titleLarge),
        backgroundColor: isDark ? AppColors.backgroundBlack : Colors.white,
        elevation: 0,
        leading: (user?.isDealer == true && user?.status == 'pending')
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
                onPressed: () => context.go('/home'),
              )
            : null,
      ),
      body: user == null
          ? const Center(child: LoadingIndicator())
          : (user.isDealer && (user.status == 'pending' || user.status == 'rejected'))
              ? ApprovalPendingScreen(isRejected: user.status == 'rejected') 
              : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  // 1. Header Section
                  _buildHeader(context, user, isDark),
                  
                  const SizedBox(height: 16),

                  // 2. Quick Actions Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildQuickActionsGrid(context, isDark),
                  ),

                  const SizedBox(height: 20),

                  // 3. Account List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF111418),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildAccountItem(
                          context,
                          isDark,
                          icon: Icons.person_outline,
                          title: 'Edit Profile', // Renamed from "My Profile"
                          onTap: () {
                             context.push('/profile/edit');
                          },
                        ),
                        _buildAccountItem(
                          context,
                          isDark,
                          icon: Icons.location_on_outlined,
                          title: 'My Address',
                          onTap: () {
                             context.push('/profile/addresses');
                          },
                        ),
                        _buildAccountItem(
                          context,
                          isDark,
                          icon: Icons.policy_outlined,
                          title: 'Policies',
                          onTap: () {
                             context.pushNamed('policies');
                          },
                        ),

                        _buildAccountItem(
                          context,
                          isDark,
                          icon: Icons.logout,
                          title: 'Log Out',
                          isDestructive: true,
                          isLast: true,
                          onTap: () async {
                              final shouldLogout = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: theme.cardColor,
                                  title: Text('Logout', style: theme.textTheme.titleLarge),
                                  content: Text('Are you sure you want to logout?', style: theme.textTheme.bodyLarge),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Logout'),
                                    ),
                                  ],
                                ),
                              );

                              if (shouldLogout == true && context.mounted) {
                                await ref.read(authProvider.notifier).logout();
                                if (context.mounted) {
                                  context.go('/auth-choice');
                                }
                              }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      color: isDark ? AppColors.backgroundBlack : Colors.white, // Match design bg
      child: Column(
        children: [
          // Profile Image with Edit Badge
          Stack(
            children: [
              Container(
                width: 112, // 28 * 4 = 112px (h-28 w-28 in tailwind)
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : const Color(0xFFF6F7F8),
                    width: 4,
                  ),
                  color: AppColors.primaryBlueFor(isDark).withOpacity(0.1),
                  image: user.resolvedAvatarUrl != null 
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(user.resolvedAvatarUrl!), 
                          fit: BoxFit.cover
                        )
                      : null,
                ),
                child: user.resolvedAvatarUrl == null
                    ? Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primaryBlueFor(isDark)),
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => context.push('/profile/edit'),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlueFor(isDark),
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? AppColors.backgroundBlack : Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Name and Status
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111418),
            ),
          ),
          const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.isDealer 
                        ? (isDark ? Colors.purple.shade900.withOpacity(0.2) : Colors.purple.shade50)
                        : (isDark ? Colors.blue.shade900.withOpacity(0.2) : Colors.blue.shade50),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: user.isDealer 
                          ? (isDark ? Colors.purple.shade700 : Colors.purple.shade100)
                          : (isDark ? Colors.blue.shade700 : Colors.blue.shade100),
                    ),
                  ),
                  child: Text(
                    user.isDealer ? 'Dealer' : 'Consumer',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: user.isDealer 
                          ? (isDark ? Colors.purple.shade300 : Colors.purple.shade700)
                          : (isDark ? Colors.blue.shade300 : Colors.blue.shade700),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }


  Widget _buildQuickActionsGrid(BuildContext context, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5, // Adjust aspect ratio to match card shape
      children: [
        _buildActionCard(context, isDark, Icons.favorite, 'Wishlist', () => context.push('/profile/wishlist')),
        _buildActionCard(context, isDark, Icons.support_agent, 'Support', () => context.pushNamed('support')),
        _buildActionCard(context, isDark, Icons.receipt_long, 'My Order', () => context.push('/profile/orders')),
        _buildActionCard(context, isDark, Icons.policy, 'Policies', () => context.pushNamed('policies')),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, bool isDark, IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: isDark ? const Color(0xFF1A2634) : Colors.grey.shade100, // Grey cards on White background
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.backgroundBlack : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1)),
                  ],
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF111418),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountItem(BuildContext context, bool isDark, {
    required IconData icon, 
    required String title, 
    required VoidCallback onTap,
    bool description = false,
    bool hasBadge = false,
    bool isDestructive = false,
    bool isLast = false,
  }) {
    final textColor = isDestructive 
        ? (isDark ? Colors.red.shade400 : Colors.red.shade600)
        : (isDark ? Colors.white : const Color(0xFF111418));
    
    final iconBgColor = isDestructive
        ? (isDark ? Colors.red.shade900.withOpacity(0.2) : Colors.red.shade50)
        : (isDark ? Colors.grey.shade800 : Colors.grey.shade100);

    return Column(
      children: [
        if (isDestructive) const SizedBox(height: 8), // Add spacing for logout
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon, 
                    size: 20, 
                    color: isDestructive ? textColor : (isDark ? Colors.grey.shade300 : Colors.grey.shade600)
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                if (hasBadge)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                  ),
                if (!isDestructive)
                  Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ],
    );
  }

}
