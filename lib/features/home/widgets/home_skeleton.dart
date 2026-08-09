// Home screen skeleton loader
// Covers: Banner Slider, Category Rail, New Arrivals (horizontal), Recommended Grid
import 'package:flutter/material.dart';
import '../../../widgets/common/shimmer_box.dart';

class HomeSkeletonLoader extends StatelessWidget {
  const HomeSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _BannerSkeleton(isDark: isDark)),
        SliverToBoxAdapter(child: _CategorySkeleton(isDark: isDark)),
        SliverToBoxAdapter(child: _SectionHeaderSkeleton(isDark: isDark)),
        SliverToBoxAdapter(child: _NewArrivalsSkeleton(isDark: isDark)),
        SliverToBoxAdapter(child: _SectionHeaderSkeleton(isDark: isDark)),
        SliverToBoxAdapter(child: _ProductGridSkeleton(isDark: isDark)),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 1. Hero Banner Skeleton
// ─────────────────────────────────────────────────────────────
class _BannerSkeleton extends StatelessWidget {
  final bool isDark;
  const _BannerSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          // Main banner card
          ShimmerBox(
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.circular(16),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShimmerBox(
                width: 16,
                height: 6,
                borderRadius: BorderRadius.circular(3),
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              ShimmerBox(
                width: 6,
                height: 6,
                borderRadius: BorderRadius.circular(3),
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              ShimmerBox(
                width: 6,
                height: 6,
                borderRadius: BorderRadius.circular(3),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 2. Category Rail Skeleton
// ─────────────────────────────────────────────────────────────
class _CategorySkeleton extends StatelessWidget {
  final bool isDark;
  const _CategorySkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShimmerBox(
              width: 64,
              height: 64,
              borderRadius: BorderRadius.circular(16),
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            ShimmerBox(
              width: 52,
              height: 10,
              borderRadius: BorderRadius.circular(5),
              isDark: isDark,
            ),
            const SizedBox(height: 4),
            ShimmerBox(
              width: 36,
              height: 10,
              borderRadius: BorderRadius.circular(5),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 3. Section Header Skeleton ("New Arrivals" / "Recommended")
// ─────────────────────────────────────────────────────────────
class _SectionHeaderSkeleton extends StatelessWidget {
  final bool isDark;
  const _SectionHeaderSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: ShimmerBox(
        width: 140,
        height: 18,
        borderRadius: BorderRadius.circular(6),
        isDark: isDark,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 4. New Arrivals Horizontal List Skeleton
// ─────────────────────────────────────────────────────────────
class _NewArrivalsSkeleton extends StatelessWidget {
  final bool isDark;
  const _NewArrivalsSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, __) => _HorizontalProductCardSkeleton(isDark: isDark),
      ),
    );
  }
}

class _HorizontalProductCardSkeleton extends StatelessWidget {
  final bool isDark;
  const _HorizontalProductCardSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ShimmerBox(
            width: 160,
            height: 160,
            borderRadius: BorderRadius.circular(12),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          // Product name line 1
          ShimmerBox(
            width: 140,
            height: 12,
            borderRadius: BorderRadius.circular(4),
            isDark: isDark,
          ),
          const SizedBox(height: 6),
          // Product name line 2
          ShimmerBox(
            width: 100,
            height: 12,
            borderRadius: BorderRadius.circular(4),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          // Price
          ShimmerBox(
            width: 80,
            height: 16,
            borderRadius: BorderRadius.circular(4),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 5. Recommended (2-column) Grid Skeleton
// ─────────────────────────────────────────────────────────────
class _ProductGridSkeleton extends StatelessWidget {
  final bool isDark;
  const _ProductGridSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (_, __) => _GridProductCardSkeleton(isDark: isDark),
      ),
    );
  }
}

class _GridProductCardSkeleton extends StatelessWidget {
  final bool isDark;
  const _GridProductCardSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product image (takes most of the card)
        Expanded(
          flex: 5,
          child: ShimmerBox(
            width: double.infinity,
            height: double.infinity,
            borderRadius: BorderRadius.circular(12),
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 8),
        // Brand/subtitle line
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ShimmerBox(
            width: 60,
            height: 10,
            borderRadius: BorderRadius.circular(4),
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 6),
        // Product name line 1
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ShimmerBox(
            width: double.infinity,
            height: 12,
            borderRadius: BorderRadius.circular(4),
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 4),
        // Product name line 2
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ShimmerBox(
            width: 90,
            height: 12,
            borderRadius: BorderRadius.circular(4),
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 8),
        // Price + Add-to-cart button row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(
                width: 70,
                height: 16,
                borderRadius: BorderRadius.circular(4),
                isDark: isDark,
              ),
              ShimmerBox(
                width: 32,
                height: 32,
                borderRadius: BorderRadius.circular(8),
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
