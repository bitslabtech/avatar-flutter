import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/content_provider.dart';
import '../../../../widgets/common/loading_indicator.dart';

class AdminPolicyListScreen extends ConsumerWidget {
  const AdminPolicyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentsAsync = ref.watch(contentListProvider); // Assuming contentListProvider is a Future/Stream provider or StateNotifier
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Theme Colors
    final surfaceColor = isDark ? const Color(0xFF1C2333) : Colors.white;
    final backgroundColor = isDark ? const Color(0xFF101522) : const Color(0xFFF6F6F8);
    final borderColor = isDark ? const Color(0xFF323F67) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Policy Management', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: contentsAsync.when(
        data: (contents) {
          if (contents.isEmpty) {
            return Center(child: Text('No policies found.', style: TextStyle(color: subTextColor)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: contents.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final content = contents[index];
              return Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                   boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    content.title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  subtitle: Text(
                    content.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      color: content.isActive ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit, size: 20, color: Theme.of(context).colorScheme.primary),
                  ),
                  onTap: () {
                    context.pushNamed('admin-policy-edit', pathParameters: {'key': content.key});
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}
