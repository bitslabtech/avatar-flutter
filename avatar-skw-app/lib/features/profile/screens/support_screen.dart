import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/contact_settings_provider.dart';
import '../../../widgets/common/loading_indicator.dart';

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  Future<void> _launchEmail(BuildContext context, String email) async {
    try {
      print('🔍 DEBUG: Attempting to launch email: $email');
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
      );
      print('🔍 DEBUG: Email URI: $emailUri');
      final canLaunch = await canLaunchUrl(emailUri);
      print('🔍 DEBUG: Can launch email: $canLaunch');
      
      if (canLaunch) {
        await launchUrl(emailUri);
        print('✅ Email launched successfully');
      } else {
        print('❌ Cannot launch email');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open email app. Please check if you have an email app installed.')),
          );
        }
      }
    } catch (e) {
      print('❌ ERROR launching email: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(BuildContext context, String number) async {
    try {
      print('🔍 DEBUG: Attempting to launch WhatsApp: $number');
      final Uri whatsappUri = Uri.parse('whatsapp://send?phone=$number');
      print('🔍 DEBUG: WhatsApp URI: $whatsappUri');
      final canLaunch = await canLaunchUrl(whatsappUri);
      print('🔍 DEBUG: Can launch WhatsApp: $canLaunch');
      
      if (canLaunch) {
        await launchUrl(whatsappUri);
        print('✅ WhatsApp launched successfully');
      } else {
        print('❌ Cannot launch WhatsApp');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open WhatsApp. Please check if WhatsApp is installed.')),
          );
        }
      }
    } catch (e) {
      print('❌ ERROR launching WhatsApp: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _launchCall(BuildContext context, String number) async {
    try {
      print('🔍 DEBUG: Attempting to launch call: $number');
      final Uri callUri = Uri(scheme: 'tel', path: number);
      print('🔍 DEBUG: Call URI: $callUri');
      final canLaunch = await canLaunchUrl(callUri);
      print('🔍 DEBUG: Can launch call: $canLaunch');
      
      if (canLaunch) {
        await launchUrl(callUri);
        print('✅ Call launched successfully');
      } else {
        print('❌ Cannot launch call');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not initiate call. Please check your phone permissions.')),
          );
        }
      }
    } catch (e) {
      print('❌ ERROR launching call: $e');
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                    Colors.blue.shade100.withOpacity(0.3),
                    Colors.blue.shade50.withOpacity(0.1),
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
                    Colors.purple.shade100.withOpacity(0.3),
                    Colors.purple.shade50.withOpacity(0.1),
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
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, size: 20),
                          color: const Color(0xFF64748B),
                          padding: EdgeInsets.zero,
                          onPressed: () => context.pop(),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Support',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 40), // Placeholder for balance
                    ],
                  ),
                ),
                // Hero Section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      // Illustration - reduced by 30%
                      Container(
                        width: 126,
                        height: 126,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.shade50,
                        ),
                        child: Center(
                          child: Container(
                            width: 105,
                            height: 105,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryBlue.withOpacity(0.1),
                            ),
                            child: const Icon(
                              Icons.headset_mic_rounded,
                              size: 56,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Title
                      const Text(
                        'How can we',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                          height: 1.2,
                        ),
                      ),
                      const Text(
                        'help you today?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryBlue,
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
                        return const Center(
                          child: Text(
                            'Support contact information is currently unavailable.',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'QUICK CONTACT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // WhatsApp Card
                            if (settings.whatsappNumber != null)
                              _buildContactCard(
                                icon: Icons.chat_rounded,
                                iconColor: const Color(0xFF22C55E),
                                iconBgColor: const Color(0xFFF0FDF4),
                                title: 'WhatsApp',
                                subtitle: 'Wait time: ~2 mins',
                                buttonText: 'Chat Now',
                                buttonColor: Colors.white,
                                buttonTextColor: const Color(0xFF22C55E),
                                buttonBorderColor: const Color(0xFFDCFCE7),
                                onTap: () => _launchWhatsApp(context, settings.whatsappNumber!),
                                isPrimary: false,
                              ),
                            const SizedBox(height: 16),
                            // Voice Call Card
                            if (settings.callNumber != null)
                              _buildContactCard(
                                icon: Icons.call_rounded,
                                iconColor: AppColors.primaryBlue,
                                iconBgColor: AppColors.primaryBlue.withOpacity(0.1),
                                title: 'Voice Call',
                                subtitle: 'Wait time: Instant',
                                buttonText: 'Call Us',
                                buttonColor: AppColors.primaryBlue,
                                buttonTextColor: Colors.white,
                                onTap: () => _launchCall(context, settings.callNumber!),
                                isPrimary: true,
                              ),
                            const SizedBox(height: 16),
                            // Email Card
                            if (settings.supportEmail != null)
                              _buildContactCard(
                                icon: Icons.mail_rounded,
                                iconColor: const Color(0xFF64748B),
                                iconBgColor: const Color(0xFFF1F5F9),
                                title: 'Email Inquiry',
                                subtitle: 'Response: 24h',
                                buttonText: 'Send Email',
                                buttonColor: Colors.white,
                                buttonTextColor: const Color(0xFF64748B),
                                buttonBorderColor: const Color(0xFFE2E8F0),
                                onTap: () => _launchEmail(context, settings.supportEmail!),
                                isPrimary: false,
                              ),
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(child: LoadingIndicator()),
                    error: (err, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          const Text('Error loading support information', style: TextStyle(color: Color(0xFF1E293B))),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPrimary ? AppColors.primaryBlue.withOpacity(0.2) : const Color(0xFFE2E8F0),
          width: isPrimary ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isPrimary ? 0.08 : 0.05),
            blurRadius: isPrimary ? 12 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                        color: iconColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
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
                              color: AppColors.primaryBlue.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
