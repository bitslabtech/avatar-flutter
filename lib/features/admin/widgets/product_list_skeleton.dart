import 'package:flutter/material.dart';

/// A shimmer effect widget that animates a gradient highlight across its child.
class ShimmerEffect extends StatefulWidget {
  final Widget child;

  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isDark
                  ? [
                      const Color(0xFF232C48),
                      const Color(0xFF2D3A5C),
                      const Color(0xFF232C48),
                    ]
                  : [
                      const Color(0xFFE2E8F0),
                      const Color(0xFFF1F5F9),
                      const Color(0xFFE2E8F0),
                    ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single rounded rectangle placeholder box with shimmer.
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D3A5C) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Full skeleton loading widget for the Product List screen.
/// Mimics the real layout: stats carousel, search bar, category chips, product cards.
class ProductListSkeleton extends StatelessWidget {
  const ProductListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ShimmerEffect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Carousel Skeleton
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: List.generate(
                  5,
                  (index) => Padding(
                    padding: EdgeInsets.only(right: index < 4 ? 8 : 0),
                    child: _buildStatCardSkeleton(isDark),
                  ),
                ),
              ),
            ),
          ),

          // Search Bar Skeleton
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF232C48) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.transparent
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  _SkeletonBox(width: 24, height: 24, borderRadius: 4),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SkeletonBox(
                      width: double.infinity,
                      height: 14,
                      borderRadius: 4,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _SkeletonBox(width: 24, height: 24, borderRadius: 4),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),

          // Category Chips Skeleton
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Row(
              children: [
                _SkeletonBox(width: 100, height: 36, borderRadius: 18),
                const SizedBox(width: 8),
                _SkeletonBox(width: 80, height: 36, borderRadius: 18),
                const SizedBox(width: 8),
                _SkeletonBox(width: 90, height: 36, borderRadius: 18),
                const SizedBox(width: 8),
                _SkeletonBox(width: 70, height: 36, borderRadius: 18),
              ],
            ),
          ),

          // Product List Header Skeleton
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SkeletonBox(width: 120, height: 18, borderRadius: 4),
                _SkeletonBox(width: 100, height: 12, borderRadius: 4),
              ],
            ),
          ),

          // Product Card Skeletons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            child: Column(
              children: List.generate(
                6,
                (index) => _buildProductCardSkeleton(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardSkeleton(bool isDark) {
    return Container(
      width: 106,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232C48) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: 32, height: 32, borderRadius: 16),
          const SizedBox(height: 8),
          _SkeletonBox(width: 60, height: 11, borderRadius: 4),
          const SizedBox(height: 6),
          _SkeletonBox(width: 40, height: 11, borderRadius: 4),
          const SizedBox(height: 4),
          _SkeletonBox(width: 30, height: 18, borderRadius: 4),
        ],
      ),
    );
  }

  Widget _buildProductCardSkeleton(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232C48) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.transparent : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          _SkeletonBox(width: 80, height: 80, borderRadius: 8),
          const SizedBox(width: 16),

          // Details placeholder
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SkeletonBox(
                            width: double.infinity,
                            height: 16,
                            borderRadius: 4,
                          ),
                          const SizedBox(height: 6),
                          _SkeletonBox(width: 80, height: 12, borderRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SkeletonBox(width: 24, height: 24, borderRadius: 4),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SkeletonBox(width: 100, height: 12, borderRadius: 4),
                    _SkeletonBox(width: 40, height: 20, borderRadius: 10),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
