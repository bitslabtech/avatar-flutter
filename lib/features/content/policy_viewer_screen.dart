import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../providers/content_provider.dart';

class PolicyViewerScreen extends ConsumerWidget {
  final String contentKey;

  const PolicyViewerScreen({super.key, required this.contentKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentsAsync = ref.watch(contentListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final backgroundColor = isDark ? const Color(0xFF101522) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
      ),
      body: contentsAsync.when(
        data: (contents) {
          final content = contents.cast<dynamic>().firstWhere(
            (c) => c.key == contentKey,
            orElse: () => null,
          );

          if (content == null) {
            return Center(child: Text('Policy not found.', style: TextStyle(color: textColor)));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last updated: ${content.updatedAt.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 24),
                Html(
                  data: content.body,
                  style: {
                    "body": Style(
                      color: textColor,
                      fontSize: FontSize(16.0),
                      lineHeight: const LineHeight(1.6),
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                    ),
                    "a": Style(
                      color: Theme.of(context).colorScheme.primary,
                      textDecoration: TextDecoration.none,
                    ),
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: Colors.red))),
      ),
    );
  }
}
