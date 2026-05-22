import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import 'whatsapp_config_screen.dart';

class AdminConfigurationsScreen extends ConsumerWidget {
  const AdminConfigurationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsState = ref.watch(adminSettingsProvider);
    
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
                    
                    // Integrations Section
                    _buildSectionHeader('Integrations', subTextColor),
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          _buildSettingsTile(
                            title: 'WhatsApp API Config',
                            subtitle: 'Configure messaging provider',
                            icon: Icons.chat,
                            iconColor: Colors.green.shade600,
                            isDark: isDark,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const WhatsAppConfigScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // System Alerts Section
                    _buildSectionHeader('System Alerts', subTextColor),
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            title: 'New Order Alerts',
                            icon: Icons.shopping_bag,
                            iconColor: Colors.blue,
                            value: settingsState.newOrderAlerts,
                            isDark: isDark,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            onChanged: (val) {
                              ref.read(adminSettingsProvider.notifier).toggleLocalSetting('admin_alert_orders', val);
                            },
                          ),
           _buildDivider(borderColor),
                          _buildSwitchTile(
                            title: 'New Dealer Alert',
                            icon: Icons.storefront,
                            iconColor: Colors.purple,
                            value: settingsState.newDealerAlert,
                            isDark: isDark,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            onChanged: (val) {
                              ref.read(adminSettingsProvider.notifier).toggleLocalSetting('admin_alert_dealer', val);
                            },
                          ),
                           _buildDivider(borderColor),
                          _buildSwitchTile(
                            title: 'New Consumer Alert',
                            icon: Icons.person_add,
                            iconColor: Colors.teal,
                            value: settingsState.newConsumerAlert,
                            isDark: isDark,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            onChanged: (val) {
                              ref.read(adminSettingsProvider.notifier).toggleLocalSetting('admin_alert_consumer', val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Policy Management Section
                    _buildSectionHeader('Content', subTextColor),
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          _buildSettingsTile(
                            title: 'Business Details',
                            subtitle: 'Company name, address, GSTIN for invoices',
                            icon: Icons.business_outlined,
                            iconColor: Colors.indigo,
                            isDark: isDark,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            onTap: () {
                              context.pushNamed('admin-business-details');
                            },
                          ),
                          _buildDivider(borderColor),
                          _buildSettingsTile(
                            title: 'Policy Management',
                            subtitle: 'Terms, Privacy, etc.',
                            icon: Icons.policy,
                            iconColor: Colors.orange,
                            isDark: isDark,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            onTap: () {
                               context.pushNamed('admin-policy-list');
                            },
                          ),
                          _buildDivider(borderColor),
                          _buildSettingsTile(
                            title: 'Contact Settings',
                            subtitle: 'Support contact information',
                            icon: Icons.contact_phone,
                            iconColor: Colors.purple,
                            isDark: isDark,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            onTap: () {
                               context.pushNamed('admin-contact-settings');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // System Controls
                    _buildSectionHeader('System Controls', subTextColor),
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            title: 'Maintenance Mode',
                            subtitle: 'App will be offline for users',
                            icon: Icons.build,
                            iconColor: Colors.redAccent,
                            value: settingsState.maintenanceMode,
                            isDark: isDark,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            onChanged: (val) {
                              ref.read(adminSettingsProvider.notifier).setMaintenanceMode(val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color surfaceColor, Color borderColor, Color textColor) {
    return Container(
      color: surfaceColor.withOpacity(0.9),
      padding: const EdgeInsets.all(16),
      child: Row(
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
            'Configurations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(width: 48), // Placeholder for balance
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
    return Divider(height: 1, thickness: 1, color: color.withOpacity(0.5));
  }

  Widget _buildSettingsTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required Color textColor,
    Color? subTextColor,
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
                color: iconColor.withOpacity(0.1),
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
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
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
              color: iconColor.withOpacity(0.1),
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
            activeColor: AppColors.primaryBlueFor(isDark),
          ),
        ],
      ),
    );
  }
}
