import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/content_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';

class PolicyViewerScreen extends ConsumerWidget {
  final String contentKey;

  const PolicyViewerScreen({super.key, required this.contentKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(contentProvider(contentKey));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Theme Colors
    final surfaceColor = isDark ? const Color(0xFF1C2333) : Colors.white;
    final backgroundColor = isDark ? const Color(0xFF101522) : const Color(0xFFF6F6F8);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: contentAsync.when(
          data: (content) => Text(content.title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          loading: () => const Text('Loading...', style: TextStyle(color: Colors.transparent)),
          error: (_, __) => Text('Error', style: TextStyle(color: textColor)),
        ),
        backgroundColor: surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: isDark ? const Color(0xFF323F67) : const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: contentAsync.when(
        data: (content) {
          if (!content.isActive) {
            return Center(child: Text('This policy is currently unavailable.', style: TextStyle(color: textColor)));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                 boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
              ),
              child: SelectableText(
                content.body,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                  fontSize: 14,
                  height: 1.6,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (err, stack) => AppErrorWidget(message: err.toString(), onRetry: () => ref.refresh(contentProvider(contentKey))),
      ),
    );
  }
}
