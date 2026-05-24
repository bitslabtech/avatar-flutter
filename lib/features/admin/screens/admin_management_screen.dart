import 'package:avatar_app/models/user.dart';
import 'package:avatar_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/loading_indicator.dart';
import 'admin_permissions_screen.dart';
import 'admin_logs_screen.dart';
import 'admin_log_screen.dart'; // Import the new individual log screen
import '../providers/audit_logs_provider.dart';

class AdminManagementScreen extends ConsumerStatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  ConsumerState<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends ConsumerState<AdminManagementScreen> {
  bool _isLoading = true;
  List<User> _admins = [];
  List<User> _filteredAdmins = [];
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAdmins());
    _searchController.addListener(_filterAdmins);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterAdmins() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredAdmins = _admins);
    } else {
      setState(() {
        _filteredAdmins = _admins.where((admin) {
          return admin.name.toLowerCase().contains(query) || 
                 admin.phone.toLowerCase().contains(query) ||
                 (admin.email?.toLowerCase().contains(query) ?? false);
        }).toList();
      });
    }
  }

  Future<void> _loadAdmins() async {
    setState(() => _isLoading = true);
    try {
      final adminService = ref.read(adminServiceProvider);
      final data = await adminService.getAdmins();
      setState(() {
        _admins = data.map((e) => User.fromJson(e)).toList();
        _filteredAdmins = _admins;
        _isLoading = false;
        _errorMessage = null; // Clear error on success
      });
    } catch (e) {
      if (mounted) {
        setState(() {
           _errorMessage = e.toString();
           _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleStatus(User admin) async {
    final newStatus = admin.status == 'active' ? 'inactive' : 'active';
    try {
      await ref.read(adminServiceProvider).updateAdminStatus(admin.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Admin marked as $newStatus'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
      _loadAdmins();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error updating status: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  void _showCreateAdminDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateAdminSheet(),
    ).then((val) {
      if (val == true) _loadAdmins();
    });
  }

  void _navigateToPermissions(User admin) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminPermissionsScreen(admin: admin)),
    ).then((val) {
      if (val == true) _loadAdmins();
    });
  }

  void _navigateToLogs({String? adminId}) {
     if (adminId != null) {
       ref.read(auditLogsProvider.notifier).setAdminFilter(adminId);
     } else {
       ref.read(auditLogsProvider.notifier).setAdminFilter(null);
     }
     
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminLogsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgLight = const Color(0xFFF6F7F8);
    final bgDark = const Color(0xFF101822);
    final cardLight = Colors.white;
    final cardDark = const Color(0xFF1C2430);
    final textDark = const Color(0xFF111827);

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back_ios_new, size: 20, color: isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  
                  // Title
                  Text(
                    'Admin Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : textDark,
                    ),
                  ),

                  // Logs Button (Global)
                  InkWell(
                    onTap: () => _navigateToLogs(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.history, size: 20, color: isDark ? Colors.white : Colors.black),
                    ),
                  ),

                  // Add Button
                  InkWell(
                     onTap: () {
                        final user = ref.read(authProvider).user;
                        if (user?.hasPermission('users', 'create') != true) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('You do not have permission to create admins')),
                           );
                           return;
                        }
                        _showCreateAdminDialog();
                     },
                     borderRadius: BorderRadius.circular(20),
                     child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary, size: 28),
                    ),
                  ),
                ],
              ),
            ),
            
            // 2. Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                    hintText: 'Search by name or phone...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400], 
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            
            // 3. Grid Content
            Expanded(
              child: _isLoading 
                ? const Center(child: LoadingIndicator())
                : _errorMessage != null
                   ? Center(
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           const Icon(Icons.error_outline, color: AppColors.errorRed, size: 48),
                           const SizedBox(height: 16),
                           Text('Error: $_errorMessage', style: TextStyle(color: isDark ? Colors.white : textDark)),
                           const SizedBox(height: 16),
                           ElevatedButton(onPressed: _loadAdmins, child: const Text('Retry')),
                         ],
                       ),
                   )
                   : _filteredAdmins.isEmpty
                       ? Center(
                           child: Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               Icon(Icons.people_outline, size: 60, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                               const SizedBox(height: 16),
                               Text(
                                 'No team members found',
                                 style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                               ),
                             ],
                           ),
                         )
                       : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredAdmins.length,
                          itemBuilder: (context, index) {
                            final admin = _filteredAdmins[index];
                            return _buildAdminCard(context, admin, isDark, cardDark, cardLight);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, User admin, bool isDark, Color cardDark, Color cardLight) {
    final isActive = admin.status == 'active';
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? cardDark : cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with Status
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: admin.resolvedAvatarUrl != null && admin.resolvedAvatarUrl!.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: admin.resolvedAvatarUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: Colors.grey[300]),
                                errorWidget: (_, __, ___) => _buildFallbackAvatar(admin.name),
                              ),
                            )
                          : _buildFallbackAvatar(admin.name),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.successGreen : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? cardDark : Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              admin.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (admin.role == 'super_admin' ? 'Super Admin' : 'Admin').toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            admin.phone,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (admin.email != null && admin.email!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.email, size: 14, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                admin.email!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[100]),
            const SizedBox(height: 16),
            
            // Actions
            Row(
              children: [
                // Edit Button
                Expanded(
                  child: _buildActionBtn(
                    context,
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    color: isDark ? Colors.grey[300]! : Colors.grey[700]!,
                    bgColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]!,
                    onTap: () {
                      final user = ref.read(authProvider).user;
                      if (user?.hasPermission('users', 'update') != true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('You do not have permission to manage admins')),
                        );
                        return;
                      }
                      _navigateToPermissions(admin);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Logs Button
                Expanded(
                  child: _buildActionBtn(
                    context,
                    icon: Icons.history,
                    label: 'Logs',
                    color: primaryColor,
                    bgColor: primaryColor.withOpacity(0.1),
                    onTap: () {
                      final user = ref.read(authProvider).user;
                      if (user?.hasPermission('users', 'update') != true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Permission Denied: Cannot view logs')),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminLogScreen(
                            userId: admin.id,
                            userName: admin.name,
                            userRole: admin.role,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Delete Button
                Expanded(
                  child: _buildActionBtn(
                    context,
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: AppColors.errorRed,
                    bgColor: AppColors.errorRed.withOpacity(0.1),
                    onTap: () => _deleteAdmin(admin),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAdmin(User admin) async {
    final user = ref.read(authProvider).user;
    if (user?.hasPermission('users', 'delete') != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission Denied: Cannot delete admin')),
      );
      return;
    }

    final confirmController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Admin', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This action will permanently delete the admin account.'),
            const SizedBox(height: 16),
            const Text('Type "delete" to confirm:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'delete',
                isDense: true,
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: confirmController,
            builder: (context, value, child) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: value.text.toLowerCase() == 'delete' 
                    ? () => Navigator.pop(context, true)
                    : null, 
                child: const Text('Delete', style: TextStyle(color: Colors.white)),
              );
            },
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(adminServiceProvider).deleteAdmin(admin.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin account deleted successfully'), backgroundColor: AppColors.successGreen),
        );
      }
      _loadAdmins();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed));
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildActionBtn(BuildContext context, {required IconData icon, required String label, required Color color, required Color bgColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(String name) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'A',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
    );
  }
}

class _CreateAdminSheet extends ConsumerStatefulWidget {
  const _CreateAdminSheet();
  @override
  ConsumerState<_CreateAdminSheet> createState() => _CreateAdminSheetState();
}

class _CreateAdminSheetState extends ConsumerState<_CreateAdminSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _submitting = false;
  bool _obscurePass = true;
  final Map<String, List<dynamic>> _perms = {};

  final Map<String, IconData> _modules = {
    'products': Icons.inventory_2,
    'orders': Icons.shopping_cart,
    'dealers': Icons.store,
    'users': Icons.group,
    'ecommerce': Icons.shopping_bag,
    'reports': Icons.bar_chart,
    'configurations': Icons.settings,
  };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(adminServiceProvider).createAdmin({
        'name': _nameCtrl.text,
        'phone': _phoneCtrl.text,
        'password': _passCtrl.text,
        'permissions': _perms
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Team Member',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Grant access to a new admin',
                      style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Form Fields
            _buildStyledField(
              controller: _nameCtrl, 
              label: 'Full Name', 
              icon: Icons.person_outline,
              isDark: isDark,
              borderColor: borderColor,
            ),
            const SizedBox(height: 16),
            _buildStyledField(
              controller: _phoneCtrl, 
              label: 'Phone Number', 
              icon: Icons.phone_iphone,
              isDark: isDark,
              borderColor: borderColor,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildStyledField(
              controller: _passCtrl, 
              label: 'Password', 
              icon: Icons.lock_outline,
              isDark: isDark,
              borderColor: borderColor,
              isPassword: true,
              obscure: _obscurePass,
              onToggleObscure: () => setState(() => _obscurePass = !_obscurePass),
            ),
            
            const SizedBox(height: 24),
            Text(
              'Module Access (Full Access)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Select modules to grant full access. You can fine-tune specific permissions (Read, Add, Edit, Delete) later.',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: _modules.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: borderColor, indent: 48),
                itemBuilder: (context, index) {
                  final module = _modules.keys.elementAt(index);
                  final icon = _modules.values.elementAt(index);
                  final hasAccess = _perms.containsKey(module) && _perms[module]!.isNotEmpty;
                  return Theme(
                    data: Theme.of(context).copyWith(
                      checkboxTheme: CheckboxThemeData(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    child: CheckboxListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(
                        module[0].toUpperCase() + module.substring(1), 
                        style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
                      ),
                      value: hasAccess,
                      activeColor: Theme.of(context).colorScheme.primary,
                      checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _perms[module] = ['read', 'create', 'update', 'delete'];
                          } else {
                            _perms.remove(module);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 32),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ).copyWith(
                  backgroundColor: MaterialStateProperty.resolveWith((states) => null), // Clear default bg
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1349EC), Color(0xFF4F46E5)], // Primary Blue -> Indigo
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: _submitting 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'Grant Access', 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required Color borderColor,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
  }) {
    final fillColor = isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50];
    
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscure : false,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        prefixIcon: Icon(icon, color: isDark ? Colors.grey[500] : Colors.grey[400], size: 22),
        suffixIcon: isPassword 
          ? IconButton(
              icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
              onPressed: onToggleObscure,
            ) 
          : null,
        filled: true,
        fillColor: fillColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: (v) => v!.isEmpty ? 'This field is required' : null,
    );
  }
}
