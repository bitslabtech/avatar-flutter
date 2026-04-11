/// Category chips widget for home screen
/// Horizontally scrollable category filter chips
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
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "All" chip
          _buildChip(
            label: 'All',
            icon: Icons.grid_view,
            imageUrl: null,
            isSelected: selectedCategory == null,
            onTap: () => onCategorySelected(null),
          ),
          const SizedBox(width: 8),
          // Category chips
          ...categories.map((category) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildChip(
                  label: category.name,
                  icon: category.icon != null ? null : _getCategoryIcon(category.name), // Use stored icon or fallback
                  imageUrl: category.imageUrl, // Use uploaded image if available
                  isSelected: selectedCategory == category.name,
                  onTap: () => onCategorySelected(category.name),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    IconData? icon,
    String? imageUrl,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: isSelected 
              ? [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Removed image/icon as per user request
            // if (imageUrl != null) ...
            // else if (icon != null) ...
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

