import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/contact_settings_provider.dart';
import '../../../widgets/common/loading_indicator.dart';

class SupportScreen extends ConsumerWidget {
  SupportScreen({super.key});

  Future<void> _launchEmail(BuildContext context, String email) async {
    try {
      final Uri emailUri = Uri(scheme: 'mailto', path: email);
      final canLaunch = await canLaunchUrl(emailUri);
      if (canLaunch) {
        await launchUrl(emailUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open email app. Please check if you have an email app installed.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(BuildContext context, String number) async {
    try {
      // Strip any non-numeric characters except leading +
      final cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');

      // Try native deep link first (works on Android & iOS when WhatsApp is installed)
      final Uri nativeUri = Uri.parse('whatsapp://send?phone=$cleanNumber');
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri);
        return;
      }

      // Fallback: wa.me universal link — opens WhatsApp app on iOS/Android,
      // or WhatsApp Web in browser if the app isn't installed.
      final Uri webUri = Uri.parse('https://wa.me/$cleanNumber');
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }

      // Both failed
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open WhatsApp. Please check if WhatsApp is installed.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening WhatsApp: $e')),
        );
      }
    }
  }

  Future<void> _launchCall(BuildContext context, String number) async {
    try {
      final Uri callUri = Uri(scheme: 'tel', path: number);
      final canLaunch = await canLaunchUrl(callUri);
      if (canLaunch) {
        await launchUrl(callUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not initiate call. Please check your phone permissions.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(contactSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Theme-aware color tokens ──────────────────────────────────────────────
    final scaffoldBg        = isDark ? Color(0xFF0F172A) : Color(0xFFF8FAFC);
    final headerBg          = isDark ? Color(0xFF1E293B) : Colors.white;
    final headerBorder      = isDark ? Color(0xFF334155) : Color(0xFFE2E8F0);
    final headerIcon        = isDark ? Color(0xFF94A3B8) : Color(0xFF64748B);
    final titleColor        = isDark ? Colors.white : Color(0xFF1E293B);
    final subtitleColor     = isDark ? Color(0xFF94A3B8) : Color(0xFF64748B);
    final labelColor        = isDark ? Color(0xFF64748B) : Color(0xFF94A3B8);
    final heroBg            = isDark ? AppColors.primaryBlueFor(isDark).withOpacity(0.15) : Colors.blue.shade50;
    final cardBg            = isDark ? Color(0xFF1E293B) : Colors.white;
    final cardBorder        = isDark ? Color(0xFF334155) : Color(0xFFE2E8F0);
    final errorTextColor    = isDark ? Color(0xFF94A3B8) : Color(0xFF1E293B);
    final waButtonBg        = isDark ? Color(0xFF14532D) : Colors.white;
    final waButtonBorder    = isDark ? Color(0xFF166534) : Color(0xFFDCFCE7);
    final emailButtonBg     = isDark ? Color(0xFF1E293B) : Colors.white;
    final emailButtonBorder = isDark ? Color(0xFF334155) : Color(0xFFE2E8F0);
    final emailButtonText   = isDark ? Color(0xFF94A3B8) : Color(0xFF64748B);
    // ─────────────────────────────────────────────────────────────────────────

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          // Background gradient blobs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? Colors.blue.shade900 : Colors.blue.shade100).withOpacity(0.3),
                    (isDark ? Colors.blue.shade900 : Colors.blue.shade50).withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? Colors.purple.shade900 : Colors.purple.shade100).withOpacity(0.3),
                    (isDark ? Colors.purple.shade900 : Colors.purple.shade50).withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: headerBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: headerBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_rounded, size: 20),
                          color: headerIcon,
                          padding: EdgeInsets.zero,
                          onPressed: () => context.pop(),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Support',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 40),
                    ],
                  ),
                ),
                // Hero Section
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      Container(
                        width: 126,
                        height: 126,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: heroBg,
                        ),
                        child: Center(
                          child: Container(
                            width: 105,
                            height: 105,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryBlueFor(isDark).withOpacity(isDark ? 0.2 : 0.1),
                            ),
                            child: Icon(
                              Icons.headset_mic_rounded,
                              size: 56,
                              color: AppColors.primaryBlueFor(isDark),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'How can we',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: titleColor,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        'help you today?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryBlueFor(isDark),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                // Contact Cards
                Expanded(
                  child: settingsAsync.when(
                    data: (settings) {
                      if (!settings.isActive) {
                        return Center(
                          child: Text(
                            'Support contact information is currently unavailable.',
                            style: TextStyle(color: subtitleColor),
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QUICK CONTACT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: labelColor,
                              ),
                            ),
                            SizedBox(height: 16),
                            // WhatsApp Card
                            if (settings.whatsappNumber != null)
                              _buildContactCard(
                                isDark: isDark,
                                cardBg: cardBg,
                                cardBorder: cardBorder,
                                titleColor: titleColor,
                                subtitleColor: subtitleColor,
                                icon: Icons.chat_rounded,
                                iconColor: Color(0xFF22C55E),
                                iconBgColor: isDark ? Color(0xFF052E16) : Color(0xFFF0FDF4),
                                title: 'WhatsApp',
                                subtitle: 'Wait time: ~2 mins',
                                buttonText: 'Chat Now',
                                buttonColor: waButtonBg,
                                buttonTextColor: Color(0xFF22C55E),
                                buttonBorderColor: waButtonBorder,
                                onTap: () => _launchWhatsApp(context, settings.whatsappNumber!),
                                isPrimary: false,
                              ),
                            SizedBox(height: 16),
                            // Voice Call Card
                            if (settings.callNumber != null)
                              _buildContactCard(
                                isDark: isDark,
                                cardBg: cardBg,
                                cardBorder: cardBorder,
                                titleColor: titleColor,
                                subtitleColor: subtitleColor,
                                icon: Icons.call_rounded,
                                iconColor: AppColors.primaryBlueFor(isDark),
                                iconBgColor: AppColors.primaryBlueFor(isDark).withOpacity(isDark ? 0.2 : 0.1),
                                title: 'Voice Call',
                                subtitle: 'Wait time: Instant',
                                buttonText: 'Call Us',
                                buttonColor: AppColors.primaryBlueFor(isDark),
                                buttonTextColor: Colors.white,
                                onTap: () => _launchCall(context, settings.callNumber!),
                                isPrimary: true,
                              ),
                            SizedBox(height: 16),
                            // Email Card
                            if (settings.supportEmail != null)
                              _buildContactCard(
                                isDark: isDark,
                                cardBg: cardBg,
                                cardBorder: cardBorder,
                                titleColor: titleColor,
                                subtitleColor: subtitleColor,
                                icon: Icons.mail_rounded,
                                iconColor: isDark ? Color(0xFF94A3B8) : Color(0xFF64748B),
                                iconBgColor: isDark ? Color(0xFF0F172A) : Color(0xFFF1F5F9),
                                title: 'Email Inquiry',
                                subtitle: 'Response: 24h',
                                buttonText: 'Send Email',
                                buttonColor: emailButtonBg,
                                buttonTextColor: emailButtonText,
                                buttonBorderColor: emailButtonBorder,
                                onTap: () => _launchEmail(context, settings.supportEmail!),
                                isPrimary: false,
                              ),
                          ],
                        ),
                      );
                    },
                    loading: () => Center(child: LoadingIndicator()),
                    error: (err, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                          SizedBox(height: 16),
                          Text(
                            'Error loading support information',
                            style: TextStyle(color: errorTextColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color titleColor,
    required Color subtitleColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String buttonText,
    required Color buttonColor,
    required Color buttonTextColor,
    Color? buttonBorderColor,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPrimary ? AppColors.primaryBlueFor(isDark).withOpacity(0.4) : cardBorder,
          width: isPrimary ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : (isPrimary ? 0.08 : 0.05)),
            blurRadius: isPrimary ? 12 : 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.15),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: buttonColor,
                    borderRadius: BorderRadius.circular(12),
                    border: buttonBorderColor != null
                        ? Border.all(color: buttonBorderColor)
                        : null,
                    boxShadow: isPrimary
                        ? [
                            BoxShadow(
                              color: AppColors.primaryBlueFor(isDark).withOpacity(0.35),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: buttonTextColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
