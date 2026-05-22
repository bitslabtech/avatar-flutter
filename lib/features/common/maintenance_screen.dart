import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundBlack : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.engineering,
                size: 80,
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
              const SizedBox(height: 32),
              Text(
                'We are upgrading!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Avatar Home Appliances is currently undergoing scheduled maintenance to improve your experience. Please try again after some time.',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Hidden Admin Access or Login/Logout options
              TextButton.icon(
                onPressed: () async {
                   final auth = ref.read(authProvider);
                   if (auth.isAuthenticated) {
                     await ref.read(authProvider.notifier).logout();
                     if (context.mounted) context.go('/login');
                   } else {
                     context.go('/login');
                   }
                },
                icon: const Icon(Icons.login),
                label: const Text('Back to Login'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
