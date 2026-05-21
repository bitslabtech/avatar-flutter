import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user.dart';
import '../providers/user_management_provider.dart';

class UserAddEditScreen extends ConsumerStatefulWidget {
  final User? user; // Null means creating new user (though user creation logic might differ)

  const UserAddEditScreen({super.key, this.user});

  @override
  ConsumerState<UserAddEditScreen> createState() => _UserAddEditScreenState();
}

class _UserAddEditScreenState extends ConsumerState<UserAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _isActive = widget.user?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (widget.user != null) {
        // Update existing user
        final data = {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'status': _isActive 
            ? (widget.user != null && widget.user!.role == 'dealer' ? 'approved' : 'active') 
            : 'inactive', // inactive doesn't trigger rejection msg, but disables login.
        };

        await ref.read(userManagementProvider.notifier).updateUser(widget.user!.id, data);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User profile updated successfully'), backgroundColor: Colors.green),
          );
          context.pop(); 
        }
      } else {
        // Create new user (Not yet implemented, future proofing)
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create user not implemented yet')),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDisableDialog() {
    final TextEditingController disableController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDisableEnabled = disableController.text == 'DISABLE';

          return AlertDialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Disable Account',
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
                  'To disable this account, please type DISABLE below:',
                  style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: disableController,
                  onChanged: (_) => setDialogState(() {}),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'DISABLE',
                    hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDisableEnabled ? Colors.orange : AppColors.primaryBlue, width: 2),
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
                onPressed: isDisableEnabled
                    ? () {
                        Navigator.of(ctx).pop();
                        setState(() => _isActive = false);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  disabledForegroundColor: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Disable'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog() {
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
                  'Delete User',
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
                  '"${widget.user!.name}"',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'This action cannot be undone. Type DELETE to confirm.',
                  style: TextStyle(color: Colors.red.shade400, fontSize: 13),
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
                      borderSide: BorderSide(color: isDeleteEnabled ? Colors.red : AppColors.primaryBlue, width: 2),
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
                    ? () async {
                        Navigator.of(ctx).pop(); // Close dialog
                        await ref.read(userManagementProvider.notifier).deleteUser(widget.user!.id);
                        if (mounted) {
                           context.pop(); // Close edit screen
                           ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('User "${widget.user!.name}" deleted'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditMode = widget.user != null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundBlack : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit User Profile' : 'New User', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isEditMode) ...[
                _buildProfileHeader(isDark),
                const SizedBox(height: 32),
              ],
              _buildSectionTitle(isDark, 'Basic Info'),
              const SizedBox(height: 16),
              _buildTextField(isDark, 'Full Name', _nameController, Icons.person, validator: (v) => v == null || v.isEmpty ? 'Name is required' : null),
              const SizedBox(height: 16),
              _buildTextField(isDark, 'Phone Number', _phoneController, Icons.phone, keyboardType: TextInputType.phone, validator: (v) => v == null || v.length < 10 ? 'Valid phone required' : null),
              const SizedBox(height: 16),
              _buildTextField(isDark, 'Email Address', _emailController, Icons.email, keyboardType: TextInputType.emailAddress, validator: (v) {
                if (v == null || v.isEmpty) return null; // Optional
                if (!v.contains('@') || !v.contains('.')) return 'Invalid email';
                return null;
              }),
              
              const SizedBox(height: 32),
              _buildSectionTitle(isDark, 'Account Status'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isActive ? AppColors.primaryBlue.withOpacity(0.5) : Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isActive ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isActive ? Icons.check_circle : Icons.block,
                        color: _isActive ? Colors.green : Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isActive ? 'Account Enabled' : 'Account Disabled',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isActive 
                              ? 'User has full access to the app' 
                              : 'User cannot login. Contact admin to resolve.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                      Switch(
                      value: _isActive,
                      onChanged: (v) {
                        if (!v) {
                          _showDisableDialog();
                        } else {
                          setState(() => _isActive = v);
                        }
                      },
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              if (isEditMode) ...[
                const SizedBox(height: 24),
                // Delete Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _showDeleteDialog,
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    label: const Text('Delete Account', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    // Determine color based on role for visual consistency with list
    Color roleColor;
    if (widget.user!.role == 'admin') {
      roleColor = Colors.blue;
    } else if (widget.user!.role == 'dealer') {
      roleColor = Colors.purple;
    } else {
      roleColor = AppColors.primaryBlue;
    }
    
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: roleColor.withOpacity(0.1),
                  border: Border.all(color: roleColor.withOpacity(0.3), width: 2),
                  image: (widget.user!.resolvedAvatarUrl != null && widget.user!.resolvedAvatarUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(widget.user!.resolvedAvatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (widget.user!.resolvedAvatarUrl != null && widget.user!.resolvedAvatarUrl!.isNotEmpty)
                    ? null
                    : Center(
                        child: Text(
                          (widget.user!.name.isNotEmpty ? widget.user!.name[0] : '?').toUpperCase(),
                          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: roleColor),
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.edit, size: 16, color: roleColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.user!.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'ID: #${widget.user!.id.substring(0, 8)}',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Courier',
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(bool isDark, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTextField(
    bool isDark,
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        prefixIcon: Icon(icon, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      ),
    );
  }
}
