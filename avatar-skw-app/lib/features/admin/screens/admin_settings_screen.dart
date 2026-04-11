import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user.dart';
import '../providers/settings_provider.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  // Local pending display settings (only committed on Save)
  String? _pendingTheme;
  String? _pendingLanguage;

  // ── Change Password bottom sheet ──────────────────────────────────────────
  void _showChangePasswordSheet(BuildContext context, bool isDark) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool isSaving = false;
    bool showCurrent = false;
    bool showNew = false;
    bool showConfirm = false;

    final borderColor = isDark ? const Color(0xFF323F67) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : Colors.black87;
    final surfaceColor = isDark ? const Color(0xFF1C2333) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter your current password and choose a new one.',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  // Current Password
                  _buildPasswordField(
                    controller: currentCtrl,
                    label: 'Current Password',
                    visible: showCurrent,
                    isDark: isDark,
                    borderColor: borderColor,
                    textColor: textColor,
                    onToggle: () => setSheetState(() => showCurrent = !showCurrent),
                  ),
                  const SizedBox(height: 16),

                  // New Password
                  _buildPasswordField(
                    controller: newCtrl,
                    label: 'New Password',
                    visible: showNew,
                    isDark: isDark,
                    borderColor: borderColor,
                    textColor: textColor,
                    onToggle: () => setSheetState(() => showNew = !showNew),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  _buildPasswordField(
                    controller: confirmCtrl,
                    label: 'Confirm New Password',
                    visible: showConfirm,
                    isDark: isDark,
                    borderColor: borderColor,
                    textColor: textColor,
                    onToggle: () => setSheetState(() => showConfirm = !showConfirm),
                  ),
                  const SizedBox(height: 28),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => ctx.pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: borderColor),
                            foregroundColor: textColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final current = currentCtrl.text.trim();
                                  final newPw = newCtrl.text.trim();
                                  final confirm = confirmCtrl.text.trim();

                                  if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('All fields are required')),
                                    );
                                    return;
                                  }
                                  if (newPw.length < 8) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('New password must be at least 8 characters')),
                                    );
                                    return;
                                  }
                                  if (newPw != confirm) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Passwords do not match')),
                                    );
                                    return;
                                  }

                                  setSheetState(() => isSaving = true);
                                  try {
                                    await ref.read(adminSettingsProvider.notifier).changePassword(current, newPw);
                                    if (context.mounted) {
                                      ctx.pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('✅ Password changed successfully'),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setSheetState(() => isSaving = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('❌ ${e.toString().replaceAll('Exception: ', '')}'),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Update', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required bool isDark,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF101522) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: controller,
            obscureText: !visible,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: IconButton(
                icon: Icon(
                  visible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Theme cycle helper ────────────────────────────────────────────────────
  String _nextTheme(String current) {
    switch (current) {
      case 'system': return 'light';
      case 'light': return 'dark';
      default: return 'system';
    }
  }

  String _themeLabel(String mode) {
    switch (mode) {
      case 'light': return 'Light Mode';
      case 'dark': return 'Dark Mode';
      default: return 'System Default';
    }
  }

  // ── Save settings ──────────────────────────────────────────────────────────
  Future<void> _saveSettings(BuildContext context) async {
    final settingsState = ref.read(adminSettingsProvider);
    final theme = _pendingTheme ?? settingsState.themeMode;
    final lang = _pendingLanguage ?? settingsState.language;

    try {
      await ref.read(adminSettingsProvider.notifier).saveDisplaySettings(
        themeMode: theme,
        language: lang,
      );
      setState(() {
        _pendingTheme = null;
        _pendingLanguage = null;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Settings saved'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(adminSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;

    // Effective display values (pending overrides saved)
    final effectiveTheme = _pendingTheme ?? settingsState.themeMode;
    final effectiveLang = _pendingLanguage ?? settingsState.language;
    
    // Theme Colors
    final surfaceColor = isDark ? const Color(0xFF1C2333) : Colors.white;
    final backgroundColor = isDark ? const Color(0xFF101522) : const Color(0xFFF6F6F8);
    final borderColor = isDark ? const Color(0xFF323F67) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
             _buildHeader(context, isDark, surfaceColor, borderColor, textColor),
             if (settingsState.isLoading) const LinearProgressIndicator(),
             Expanded(
               child: SingleChildScrollView(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     _buildSectionHeader('Account', subTextColor),
                       Container(
                         decoration: BoxDecoration(
                           color: surfaceColor,
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(color: borderColor),
                         ),
                         child: Column(
                           children: [
                             // Profile tile → Edit Profile
                             _buildProfileTile(user, isDark, textColor, subTextColor, onTap: () {
                               context.push('/profile/edit');
                             }),
                             
                              // Change Password
                              _buildDivider(borderColor),
                              _buildSettingsTile(
                                title: 'Change Password',
                                icon: Icons.lock_reset,
                                iconColor: Colors.orange,
                                isDark: isDark,
                                textColor: textColor,
                                onTap: () => _showChangePasswordSheet(context, isDark),
                              ),
                           ],
                         ),
                       ),
                       const SizedBox(height: 24),

                      _buildSectionHeader('General', subTextColor),
                       Container(
                         decoration: BoxDecoration(
                           color: surfaceColor,
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(color: borderColor),
                         ),
                         child: Column(
                           children: [
                             _buildValueTile(
                               title: 'App Theme',
                               value: _themeLabel(effectiveTheme),
                               icon: Icons.dark_mode,
                               iconColor: Colors.blueGrey,
                               isDark: isDark,
                               textColor: textColor,
                               subTextColor: subTextColor,
                               onTap: () {
                                 setState(() {
                                   _pendingTheme = _nextTheme(effectiveTheme);
                                 });
                               },
                             ),
                             _buildDivider(borderColor),
                              _buildValueTile(
                               title: 'Language',
                               value: effectiveLang == 'en' ? 'English (US)' : effectiveLang,
                               icon: Icons.language,
                               iconColor: Colors.pink,
                               isDark: isDark,
                               textColor: textColor,
                               subTextColor: subTextColor,
                               onTap: () {},
                             ),
                           ],
                         ),
                       ),


                      const SizedBox(height: 24),

                      _buildSectionHeader('Help & Support', subTextColor),
                      Container(
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            _buildSettingsTile(
                              title: 'Admin Documentation',
                              icon: Icons.article,
                              iconColor: Colors.cyan,
                              isDark: isDark,
                              textColor: textColor,
                              trailing: Icon(Icons.open_in_new, size: 20, color: subTextColor),
                              onTap: () {},
                            ),
                            _buildDivider(borderColor),
                            _buildSettingsTile(
                              title: 'Contact Dev Team',
                              icon: Icons.support_agent,
                              iconColor: Colors.green,
                              isDark: isDark,
                              textColor: textColor,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Logout Button
                     Padding(
                       padding: const EdgeInsets.only(bottom: 32),
                       child: SizedBox(
                         width: double.infinity,
                         child: ElevatedButton(
                            onPressed: () async {
                              await ref.read(authProvider.notifier).logout();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            },
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.red.withValues(alpha: 0.1),
                             foregroundColor: Colors.red,
                             elevation: 0,
                             padding: const EdgeInsets.symmetric(vertical: 16),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                           ),
                           child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                         ),
                       ),
                     ),
                   ],
                 ),
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateRow(String label, TextEditingController nameCtrl, TextEditingController langCtrl, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField('Template Name', nameCtrl, isDark, hint: 'hello_world'),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildTextField('Lang Code', langCtrl, isDark, hint: 'en_US'),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isDark, {String? hint, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: _inputDecoration(label, isDark, hint: hint),
    );
  }

  InputDecoration _inputDecoration(String label, bool isDark, {String? hint}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.grey : Colors.black54),
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color surfaceColor, Color borderColor, Color textColor) {
    return Container(
      color: surfaceColor.withValues(alpha: 0.9),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(Icons.arrow_back, color: textColor),
                style: IconButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                ),
              ),
              Text(
                'App Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              TextButton(
                onPressed: () => _saveSettings(context),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search Bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Search settings...',
                hintStyle: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey : Colors.grey.shade400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                isCollapsed: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Divider(height: 1, thickness: 1, color: color.withValues(alpha: 0.5));
  }

  Widget _buildProfileTile(User? user, bool isDark, Color textColor, Color subTextColor, {required VoidCallback onTap}) {
    final name = user?.name ?? 'Admin';
    final role = (user?.role ?? 'admin').replaceAll('_', ' ').toUpperCase();
    final status = (user?.status ?? 'active').toUpperCase();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
                  ),
                  Text(
                    '$role • $status',
                    style: TextStyle(fontSize: 14, color: subTextColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: subTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required Color textColor,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required bool isDark,
    required Color textColor,
    required Color subTextColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: subTextColor),
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildValueTile({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required Color textColor,
    required Color subTextColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 14, color: subTextColor),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 20, color: subTextColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
