import 'package:avatar_app/core/theme/app_colors.dart';
import 'package:avatar_app/models/user.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';

class AdminPermissionsScreen extends ConsumerStatefulWidget {
  final User admin;
  const AdminPermissionsScreen({super.key, required this.admin});

  @override
  ConsumerState<AdminPermissionsScreen> createState() => _AdminPermissionsScreenState();
}

class _AdminPermissionsScreenState extends ConsumerState<AdminPermissionsScreen> {
  bool _isLoading = false;
  late Map<String, List<dynamic>> _perms;
  late Map<String, List<dynamic>> _initialPerms;
  late String _currentStatus;

  // Map of Resource ID -> Friendly Info
  final Map<String, _ResourceInfo> _resources = {
    'products': _ResourceInfo('Products', Icons.inventory_2, Colors.indigo),
    'orders': _ResourceInfo('Orders', Icons.shopping_cart, Colors.green),
    'dealers': _ResourceInfo('Dealers', Icons.store, Colors.orange),
    'users': _ResourceInfo('Users', Icons.group, Colors.pink),
    'ecommerce': _ResourceInfo('Ecommerce', Icons.shopping_bag, Colors.purple),
    'reports': _ResourceInfo('Reports', Icons.bar_chart, Colors.teal),
    'configurations': _ResourceInfo('Configurations', Icons.settings, Colors.blueGrey),
  };

  final List<String> _actions = ['read', 'create', 'update', 'delete'];


  @override
  void initState() {
    super.initState();
    // Deep copy for initial state to allow reset
    _initialPerms = Map.from(widget.admin.permissions ?? {}).map((k, v) => MapEntry(k, List.from(v)));
    _perms = Map.from(widget.admin.permissions ?? {}).map((k, v) => MapEntry(k, List.from(v)));
    _currentStatus = widget.admin.status;
  }

  // --- Logic Helpers ---

  void _togglePermission(String resource, String action) {
    setState(() {
      final currentActions = List<String>.from(_perms[resource] ?? []);
      if (currentActions.contains(action)) {
        currentActions.remove(action);
      } else {
        currentActions.add(action);
      }
      _perms[resource] = currentActions;
    });
  }

  void _toggleResourceAll(String resource, bool value) {
    setState(() {
      if (value) {
        // Enable: Grant 'read' permission by default as requested
        _perms[resource] = ['read'];
      } else {
        // Disable: Remove all permissions
        _perms[resource] = [];
      }
    });
  }

  void _resetChanges() {
    setState(() {
      _perms = Map.from(_initialPerms).map((k, v) => MapEntry(k, List.from(v)));
      _currentStatus = widget.admin.status;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes reset'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      // 1. Update Permissions
      await ref.read(adminServiceProvider).updateAdminPermissions(widget.admin.id, _perms);
      
      // 2. Update Status if changed (Optional, usually handled separately but good to sync)
      if (_currentStatus != widget.admin.status) {
         await ref.read(adminServiceProvider).updateAdminStatus(widget.admin.id, _currentStatus);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissions saved successfully'), backgroundColor: AppColors.successGreen),
        );
        Navigator.pop(context, true); // Return true to refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final TextEditingController confirmController = TextEditingController();
    
    // Show confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This action cannot be undone. This will permanently delete the admin account.'),
            const SizedBox(height: 16),
            const Text('Please type "delete" to confirm:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
      await ref.read(adminServiceProvider).deleteAdmin(widget.admin.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin account deleted successfully')),
        );
        Navigator.pop(context, true); // Return true to refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgLight = const Color(0xFFF6F7F8);
    final bgDark = const Color(0xFF101822);
    final textDark = const Color(0xFF111827);

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // --- Sticky Header ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: (isDark ? bgDark : bgLight).withOpacity(0.95), // Slight transparency for glass effect if needed
              child: Row(
                children: [
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
                  const Expanded(
                    child: Text(
                      'Admin Permissions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Delete Button
                  IconButton(
                    onPressed: _deleteAccount,
                    icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                    tooltip: 'Delete Account',
                  ),
                ],
              ),
            ),

            // --- Scrollable Content ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 1. User Card
                    _buildUserCard(isDark),
                    
                    const SizedBox(height: 24),
                    


                    // 3. Module Access
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          'MODULE ACCESS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    
                    ..._resources.entries.map((entry) => _buildPermissionCard(entry.key, entry.value, isDark)),

                    const SizedBox(height: 100), // Spacing for bottom bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // --- Bottom Fixed Bar ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2430) : Colors.white,
          border: Border(top: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Reset Button
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetChanges,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey[300]!),
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              // Save Button
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1C2430) : Colors.white;
    final isActive = _currentStatus == 'active';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200]),
             child: widget.admin.resolvedAvatarUrl != null && widget.admin.resolvedAvatarUrl!.isNotEmpty
                 ? ClipOval(child: CachedNetworkImage(imageUrl: widget.admin.resolvedAvatarUrl!, fit: BoxFit.cover))
                 : Center(child: Text(widget.admin.name[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey))),
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.admin.name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                   widget.admin.phone,
                   style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                   maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                if (widget.admin.email != null && widget.admin.email!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                     widget.admin.email!,
                     style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                     maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'ID: #${widget.admin.id.substring(0, 8)}',
                   style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                ),
              ],
            ),
          ),

          // Status Toggle
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Switch(
                value: isActive, 
                onChanged: (val) {
                  setState(() {
                    _currentStatus = val ? 'active' : 'inactive';
                  });
                },
                activeColor: Colors.green,
              ),
              Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.green : Colors.grey,
                ),
              )
            ],
          )
        ],
      ),
    );
  }



  Widget _buildPermissionCard(String resourceKey, _ResourceInfo info, bool isDark) {
    final currentActions = _perms[resourceKey] ?? [];
    // Actions to show: standard CRUD
    final actionsToShow = _actions;
    final cardColor = isDark ? const Color(0xFF1C2430) : Colors.white;
    final isModuleActive = currentActions.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: info.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(info.icon, size: 20, color: info.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    info.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                  // Switch: Normal
                Switch(
                  value: isModuleActive,
                  onChanged: (val) => _toggleResourceAll(resourceKey, val),
                  activeColor: AppColors.primaryBlue,
                ),
              ],
            ),
          ),
          
          if (isModuleActive) ...[
            Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[100]),
            
            // Body (Checkboxes)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.02),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              children: actionsToShow.map((action) {
                final isChecked = currentActions.contains(action);
                return InkWell(
                  onTap: () => _togglePermission(resourceKey, action),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20, 
                          height: 20,
                          child: Checkbox(
                            value: isChecked,
                            onChanged: (_) => _togglePermission(resourceKey, action),
                            activeColor: AppColors.primaryBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isAdminActionName(action),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
         ],
        ],
      ),
    );
  }

  String _isAdminActionName(String action) {
    switch (action) {
      case 'read': return 'View';
      case 'create': return 'Add';
      case 'update': return 'Edit';
      case 'delete': return 'Delete';
      default: return action;
    }
  }
}

class _ResourceInfo {
  final String title;
  final IconData icon;
  final Color color;

  _ResourceInfo(this.title, this.icon, this.color);
}
