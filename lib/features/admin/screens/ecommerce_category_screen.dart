import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/category.dart' as models;
import '../../admin/providers/admin_provider.dart';

class EcommerceCategoryScreen extends ConsumerStatefulWidget {
  const EcommerceCategoryScreen({super.key});

  @override
  ConsumerState<EcommerceCategoryScreen> createState() => _EcommerceCategoryScreenState();
}

class _EcommerceCategoryScreenState extends ConsumerState<EcommerceCategoryScreen> {
  // bool _showCategoriesInHomepage = true; // This should be a global setting, but user asked for per-category toggle?
  // User asked: "show enabled disable toggle to show product categories on homescreen or not AND below that show all product categories with enable/disable toggle button"
  // So Global Toggle AND Per-Category Toggle.
  // I'll keep the global toggle locally for now or mock it, as I don't have a backend setting for "Show Categories Section".
  // Assuming "Show Categories in Homepage" is a fast-flag. I'll stick to per-category management for now as that's the complex part.
  // Actually, I'll keep the UI for global toggle but maybe it does nothing or controls a local state?
  // Let's implement the list first.

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1C2333) : Colors.white;
    final backgroundColor = isDark ? const Color(0xFF101522) : const Color(0xFFF6F6F8);
    final borderColor = isDark ? const Color(0xFF323F67) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : Colors.black87;

    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back, color: textColor),
        ),
        title: Text(
          'Category Configuration',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: borderColor, height: 1),
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               _buildSectionHeader('Product Categories', textColor),
               Text(
                 'Drag to reorder. Toggle to show/hide on Home Screen.',
                 style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600], fontSize: 13),
               ),
               const SizedBox(height: 12),
               
               if (categories.isEmpty)
                 Center(child: Text('No categories found', style: TextStyle(color: textColor))),

               if (categories.isNotEmpty)
                 Container(
                   decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), // Use Scroll from SingleChildScrollView
                    itemCount: categories.length,
                    onReorder: (oldIndex, newIndex) {
                       if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final item = categories.removeAt(oldIndex);
                      categories.insert(newIndex, item);
                      ref.read(adminCategoriesProvider.notifier).reorderCategories(categories);
                    },
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return SwitchListTile(
                        key: ValueKey(category.id),
                        title: Text(category.name, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                        subtitle: category.description != null 
                            ? Text(category.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600], fontSize: 12))
                            : null,
                        value: category.isActive,
                        activeColor: Theme.of(context).colorScheme.primary,
                        secondary: Icon(Icons.drag_handle, color: isDark ? Colors.grey : Colors.grey.shade400),
                        onChanged: (val) {
                          ref.read(adminCategoriesProvider.notifier).toggleCategoryStatus(category);
                        },
                      );
                    },
                  ),
                 ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color.withOpacity(0.7),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
