import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';

class ApprovalPendingScreen extends ConsumerWidget {
  final bool isRejected;

  const ApprovalPendingScreen({super.key, this.isRejected = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final bgColor = isDark ? const Color(0xFF101822) : const Color(0xFFF6F7F8);
    final cardColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111418);
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Container(
      color: bgColor,
      width: double.infinity,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon Section
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: isRejected 
                              ? Colors.red.withOpacity(isDark ? 0.1 : 0.05)
                              : Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.1 : 0.05),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isRejected 
                                ? Colors.red.withOpacity(0.2)
                                : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          isRejected ? Icons.cancel_outlined : Icons.hourglass_top,
                          size: 48,
                          color: isRejected ? Colors.red : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Text Content
                      Text(
                        isRejected ? 'Application Rejected' : 'Almost There!',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 320,
                        child: Text(
                          isRejected 
                              ? 'We are sorry, but your dealer application has been rejected. Please contact support for more information or to re-apply.'
                              : 'Your account is currently waiting for admin approval. We typically review new registrations within 24 hours. Thank you for your patience.',
                          style: TextStyle(
                            fontSize: 16,
                            color: subTextColor,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Support Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.support_agent,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Need assistance?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Our support team is here to help with your application.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: subTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        context.pushNamed('support');
                                      },
                                      icon: const Icon(Icons.mail_outline, size: 18),
                                      label: const Text('Contact Support'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Theme.of(context).colorScheme.primary,
                                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom Actions (Logout & Home)
            // Bottom Actions (Logout & Home)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                   SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.home),
                      label: const Text('Go to Home'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: TextButton.icon(
                      onPressed: () async {
                         await ref.read(authProvider.notifier).logout();
                         if (context.mounted) context.go('/auth-choice');
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Log Out'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red[400],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
