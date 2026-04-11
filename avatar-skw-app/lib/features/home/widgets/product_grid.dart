/// Product grid widget for home screen
/// Responsive 2-column grid with product cards
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/product.dart';
import '../../../widgets/common/product_card.dart';

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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No products found',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: !enableScrolling,
      physics: enableScrolling 
          ? const AlwaysScrollableScrollPhysics() 
          : const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          showPrice: showPrice,
          onTap: () {
            context.push('/product/${product.id}');
          },
          onAddToCart: onAddToCart != null
              ? () => onAddToCart!(product)
              : null,
        );
      },
    );
  }
}

