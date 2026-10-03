import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/banner.dart' as models;
import '../../../models/product.dart';

class SwipeCardData {
  final String id;
  final String category;
  final String title;
  final String image;
  final String price;
  final String rating;
  final String reviewCount;
  final String? tag;
  final String? linkUrl;
  final String? btnText;
  final models.Banner? banner;
  final Product? product;

  SwipeCardData({
    required this.id,
    required this.category,
    required this.title,
    required this.image,
    required this.price,
    required this.rating,
    required this.reviewCount,
    this.tag,
    this.linkUrl,
    this.btnText,
    this.banner,
    this.product,
  });

  factory SwipeCardData.fromBanner(models.Banner banner) {
    return SwipeCardData(
      id: banner.id,
      category: (banner.tag != null && banner.tag!.isNotEmpty)
          ? banner.tag!
          : 'FEATURED',
      title: (banner.title != null && banner.title!.isNotEmpty)
          ? banner.title!
          : 'Avatar Kitchenware',
      image: banner.resolvedImageUrl,
      price: (banner.description != null && banner.description!.isNotEmpty)
          ? banner.description!
          : 'Exclusive Collection',
      rating: '4.9',
      reviewCount: 'Avatar SKW',
      tag: banner.tag,
      linkUrl: banner.linkUrl,
      btnText: banner.btnText ?? 'Explore',
      banner: banner,
    );
  }

  factory SwipeCardData.fromProduct(Product product) {
    return SwipeCardData(
      id: product.id,
      category: product.category.isNotEmpty ? product.category : 'Cookware',
      title: product.name,
      image: product.primaryImageUrl,
      price: product.price != null
          ? '₹${product.price!.toStringAsFixed(0)}'
          : 'Premium Quality',
      rating: '4.8',
      reviewCount: product.brand.isNotEmpty ? product.brand : 'Avatar SKW',
      tag: product.badge,
      linkUrl: '/product/${product.id}',
      btnText: 'Shop Now',
      product: product,
    );
  }
}

class SwipeableCardDeck extends StatefulWidget {
  final List<SwipeCardData> items;
  final Function(SwipeCardData item) onTapCard;
  final double height;

  const SwipeableCardDeck({
    super.key,
    required this.items,
    required this.onTapCard,
    this.height = 360,
  });

  @override
  State<SwipeableCardDeck> createState() => _SwipeableCardDeckState();
}

class _SwipeableCardDeckState extends State<SwipeableCardDeck>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Animation<double>? _slideAnimation;

  double _dragOffset = 0.0;
  int _currentIndex = 0;
  bool _isSwipingOut = false;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _animController.addListener(() {
      if (_slideAnimation != null) {
        setState(() {
          _dragOffset = _slideAnimation!.value;
        });
      }
    });

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _handleAnimationCompleted();
      }
    });

    _startAutoPlay();
  }

  void _startAutoPlay() {
    if (widget.items.length <= 1) return;
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_animController.isAnimating && _dragOffset == 0.0) {
        final screenWidth = MediaQuery.of(context).size.width;
        _animateSwipeOut(-screenWidth * 1.3);
      }
    });
  }

  void _pauseAutoPlay() {
    _autoPlayTimer?.cancel();
  }

  void _handleAnimationCompleted() {
    final swipedOut = _isSwipingOut;
    _slideAnimation = null;
    _animController.reset();

    setState(() {
      if (swipedOut && widget.items.isNotEmpty) {
        _currentIndex = (_currentIndex + 1) % widget.items.length;
      }
      _dragOffset = 0.0;
      _isSwipingOut = false;
    });

    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _pauseAutoPlay();
    if (_animController.isAnimating) {
      _animController.stop();
      _handleAnimationCompleted();
    }
    setState(() {
      _dragOffset = 0.0;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_animController.isAnimating) return;
    setState(() {
      _dragOffset += details.primaryDelta ?? details.delta.dx;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_animController.isAnimating) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final velocity = details.primaryVelocity ?? details.velocity.pixelsPerSecond.dx;

    final isFling = velocity.abs() > 300;
    final isFarEnough = _dragOffset.abs() > 60.0;

    if ((isFling || isFarEnough) && _dragOffset != 0.0) {
      final direction = (velocity.abs() > 200)
          ? (velocity > 0 ? 1.0 : -1.0)
          : (_dragOffset > 0 ? 1.0 : -1.0);
      _animateSwipeOut(direction * screenWidth * 1.3);
    } else {
      _animateSpringBack();
    }
  }

  void _onHorizontalDragCancel() {
    if (!_animController.isAnimating && _dragOffset != 0.0) {
      _animateSpringBack();
    } else if (!_animController.isAnimating) {
      setState(() {
        _dragOffset = 0.0;
      });
      _startAutoPlay();
    }
  }

  void _animateSwipeOut(double targetX) {
    _isSwipingOut = true;
    _slideAnimation = Tween<double>(
      begin: _dragOffset,
      end: targetX,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.duration = const Duration(milliseconds: 220);
    _animController.forward(from: 0.0);
  }

  void _animateSpringBack() {
    _isSwipingOut = false;
    _slideAnimation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.duration = const Duration(milliseconds: 200);
    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final totalItems = widget.items.length;
    if (_currentIndex >= totalItems) {
      _currentIndex = 0;
    }

    final index0 = _currentIndex;
    final index1 = (_currentIndex + 1) % totalItems;
    final index2 = (_currentIndex + 2) % totalItems;

    final screenWidth = MediaQuery.of(context).size.width;
    final rotation = (_dragOffset / screenWidth) * 0.25;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Back Card (peeks right)
          if (totalItems > 2)
            _buildBackCard(
              data: widget.items[index2],
              angle: 0.035,
              offsetX: 14.0,
              offsetY: 6.0,
              scale: 0.95,
              isDark: isDark,
            ),

          // 2. Middle Card (peeks left)
          if (totalItems > 1)
            _buildBackCard(
              data: widget.items[index1],
              angle: -0.035,
              offsetX: -14.0,
              offsetY: 6.0,
              scale: 0.97,
              isDark: isDark,
            ),

          // 3. Active Front Card
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_dragOffset.abs() < 8) {
                  widget.onTapCard(widget.items[index0]);
                }
              },
              onHorizontalDragStart: _onHorizontalDragStart,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              onHorizontalDragCancel: _onHorizontalDragCancel,
              child: Transform.translate(
                offset: Offset(_dragOffset, 0),
                child: Transform.rotate(
                  angle: rotation,
                  child: _buildFrontCard(widget.items[index0], isDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard({
    required SwipeCardData data,
    required double angle,
    required double offsetX,
    required double offsetY,
    required double scale,
    required bool isDark,
  }) {
    return Positioned.fill(
      child: Transform.translate(
        offset: Offset(offsetX, offsetY),
        child: Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: data.image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: isDark ? const Color(0xFF2A2E33) : const Color(0xFFE9ECEF),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: isDark ? const Color(0xFF2A2E33) : const Color(0xFFE9ECEF),
                        child: const Icon(Icons.kitchen_rounded, color: Colors.grey, size: 36),
                      ),
                    ),
                    // Darken background cards to add depth
                    Container(
                      color: Colors.black.withValues(alpha: 0.16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrontCard(SwipeCardData data, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.09),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            CachedNetworkImage(
              imageUrl: data.image,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: isDark ? const Color(0xFF24282D) : const Color(0xFFE9ECEF),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: isDark ? const Color(0xFF24282D) : const Color(0xFFE9ECEF),
                child: const Center(
                  child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 40),
                ),
              ),
            ),

            // Subtle Vignette / Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.58),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Top Left Tag Pill (if present)
            if (data.tag != null && data.tag!.isNotEmpty)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    data.tag!.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),

            // Top Right Favorite / Sparkle Badge
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.88),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
            ),

            // Bottom Floating Card Info
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2226) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${data.category.toUpperCase()} • ${data.price}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: AppColors.dealerGold,
                                size: 16,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                data.rating,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                data.reviewCount,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action button to Details
                    GestureDetector(
                      onTap: () => widget.onTapCard(data),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
