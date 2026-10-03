/// Product grid widget for home screen
/// Responsive 2-column grid with product cards and staggered animation
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/product.dart';
import '../../../widgets/common/product_card.dart';
import '../../../core/animations/staggered_entrance.dart';

class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final Function(Product)? onAddToCart;
  final bool showPrice;
  final bool enableScrolling; // Whether to handle its own scrolling

  const ProductGrid({
    super.key,
    required this.products,
    this.onAddToCart,
    this.showPrice = true,
    this.enableScrolling = false,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_off_rounded, size: 36, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Products Found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Try adjusting your search query or filters',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: !enableScrolling,
      physics: enableScrolling 
          ? const AlwaysScrollableScrollPhysics() 
          : const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.64,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return StaggeredEntrance(
          index: index,
          child: ProductCard(
            product: product,
            showPrice: showPrice,
            onTap: () {
              context.push('/product/${product.id}');
            },
            onAddToCart: onAddToCart != null
                ? () => onAddToCart!(product)
                : null,
          ),
        );
      },
    );
  }
}
