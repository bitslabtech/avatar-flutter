import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/category.dart';

class CategoryChips extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategory;
  final Function(String?) onCategorySelected;

  const CategoryChips({
    super.key,
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  IconData _getCategoryIcon(String category) {
    if (category.toLowerCase().contains('kitchen') || category == 'Home Appliances') return Icons.kitchen;
    if (category.toLowerCase().contains('laundry') || category == 'Washing Machines') return Icons.local_laundry_service;
    if (category.toLowerCase().contains('smart') || category == 'Smart Home') return Icons.smart_toy;
    if (category.toLowerCase().contains('climate') || category.toLowerCase().contains('air') || category == 'Air Conditioners') return Icons.ac_unit;
    return Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          // "All" Category Item
          _buildCategoryItem(
            context: context,
            label: 'All',
            icon: Icons.grid_view_rounded,
            imageUrl: null,
            isSelected: selectedCategory == null,
            onTap: () => onCategorySelected(null),
            isAllItem: true,
          ),
          
          // Category Items
          ...categories.map((category) => _buildCategoryItem(
                context: context,
                label: category.name,
                icon: category.icon != null ? null : _getCategoryIcon(category.name),
                imageUrl: category.resolvedImageUrl,
                isSelected: selectedCategory == category.name,
                onTap: () => onCategorySelected(category.name),
                isAllItem: false,
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required BuildContext context,
    required String label,
    IconData? icon,
    String? imageUrl,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isAllItem,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 76,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image/Icon Container with Animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSelected 
                    ? primaryColor.withOpacity(isDark ? 0.2 : 0.1) 
                    : (isAllItem ? (isDark ? Colors.white10 : Colors.black.withOpacity(0.03)) : Colors.transparent),
                borderRadius: BorderRadius.circular(16),
                border: isSelected 
                    ? Border.all(color: primaryColor.withOpacity(0.5), width: 1.5)
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          icon ?? Icons.category_rounded,
                          color: isSelected ? primaryColor : (isDark ? Colors.grey[500] : Colors.grey[400]),
                        ),
                      )
                    : Center(
                        child: Icon(
                          icon ?? Icons.category_rounded,
                          size: 28,
                          color: isSelected 
                              ? primaryColor 
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            
            // Label with Animated Style
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                fontSize: 12,
                height: 1.1,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected 
                    ? primaryColor 
                    : (isDark ? Colors.grey[300] : Colors.grey[800]),
                letterSpacing: -0.2,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
