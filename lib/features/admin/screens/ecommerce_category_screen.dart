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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // Premium Header Banner
               Container(
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(
                   gradient: LinearGradient(
                     colors: [
                       Theme.of(context).colorScheme.primary, 
                       Theme.of(context).colorScheme.primary.withOpacity(0.7)
                     ],
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                   ),
                   borderRadius: BorderRadius.circular(20),
                   boxShadow: [
                     BoxShadow(
                       color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                       blurRadius: 20,
                       offset: const Offset(0, 8),
                     ),
                   ],
                 ),
                 child: Row(
                   children: [
                     Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: Colors.white.withOpacity(0.2),
                         shape: BoxShape.circle,
                       ),
                       child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 32),
                     ),
                     const SizedBox(width: 20),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text(
                             'Organize Home Categories',
                             style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                           ),
                           const SizedBox(height: 6),
                           Text(
                             'Drag to reorder how they appear. Toggle visibility on the customer home screen instantly.',
                             style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.4),
                           ),
                         ],
                       ),
                     ),
                   ],
                 ),
               ),
               
               const SizedBox(height: 32),
               
               if (categories.isEmpty)
                 Center(
                   child: Padding(
                     padding: const EdgeInsets.symmetric(vertical: 40),
                     child: Text('No categories found', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 16)),
                   )
                 ),

               if (categories.isNotEmpty)
                  ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), 
                    itemCount: categories.length,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (BuildContext context, Widget? child) {
                          final double animValue = Curves.easeInOut.transform(animation.value);
                          return Material(
                            elevation: 12.0 * animValue,
                            color: Colors.transparent,
                            shadowColor: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            child: Transform.scale(
                              scale: 1.0 + (animValue * 0.02),
                              child: child,
                            ),
                          );
                        },
                        child: child,
                      );
                    },
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
                      return Container(
                        key: ValueKey(category.id),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                             color: category.isActive 
                                 ? Theme.of(context).colorScheme.primary.withOpacity(0.3) 
                                 : borderColor,
                             width: category.isActive ? 1.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          leading: ReorderableDragStartListener(
                            index: index,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.drag_indicator, size: 20, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category.name, 
                                  style: TextStyle(
                                    color: textColor, 
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (category.isActive)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('VISIBLE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                ),
                            ],
                          ),
                          subtitle: category.description != null && category.description!.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    category.description!, 
                                    maxLines: 1, 
                                    overflow: TextOverflow.ellipsis, 
                                    style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13),
                                  ),
                                )
                              : null,
                          trailing: Switch(
                            value: category.isActive,
                            activeColor: Colors.green,
                            inactiveTrackColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                            onChanged: (val) {
                              ref.read(adminCategoriesProvider.notifier).toggleCategoryStatus(category);
                            },
                          ),
                        ),
                      );
                    },
                  ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}
