import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class SwipeToActionButton extends StatefulWidget {
  final VoidCallback onSwiped;
  final String text;
  final double height;
  final Color? trackColor;
  final Color? thumbColor;
  final Color? textColor;
  final IconData icon;

  const SwipeToActionButton({
    super.key,
    required this.onSwiped,
    this.text = 'Swipe to Login & View Price',
    this.height = 56.0,
    this.trackColor,
    this.thumbColor,
    this.textColor,
    this.icon = Icons.arrow_forward_rounded,
  });

  @override
  State<SwipeToActionButton> createState() => _SwipeToActionButtonState();
}

class _SwipeToActionButtonState extends State<SwipeToActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Animation<double>? _dragAnimation;
  double _dragPosition = 0.0;
  bool _isCompleted = false;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _animController.addListener(() {
      if (_dragAnimation != null) {
        setState(() {
          _dragPosition = _dragAnimation!.value;
        });
      }
    });

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isCompleted) {
        HapticFeedback.mediumImpact();
        widget.onSwiped();
        // Reset position after navigation
        _resetTimer?.cancel();
        _resetTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            _animateTo(0.0);
            setState(() {
              _isCompleted = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _dragAnimation = Tween<double>(
      begin: _dragPosition,
      end: target,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.duration = const Duration(milliseconds: 200);
    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final thumbSize = widget.height - 8;
    final trackBg = widget.trackColor ??
        (isDark ? const Color(0xFF262A2E) : AppColors.surfaceDark);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = (constraints.maxWidth - thumbSize - 8).clamp(0.0, double.infinity);
        final progress = maxDrag > 0 ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

        return GestureDetector(
          onTap: () {
            // Support direct tap as accessible fallback
            if (!_animController.isAnimating && !_isCompleted) {
              _isCompleted = true;
              _animateTo(maxDrag);
            }
          },
          onHorizontalDragUpdate: (details) {
            if (_animController.isAnimating || _isCompleted) return;
            setState(() {
              _dragPosition = (_dragPosition + details.primaryDelta!).clamp(0.0, maxDrag);
            });
          },
          onHorizontalDragEnd: (details) {
            if (_animController.isAnimating || _isCompleted) return;
            final velocity = details.primaryVelocity ?? 0.0;
            final isFling = velocity > 300;
            final isFarEnough = _dragPosition >= (maxDrag * 0.65);

            if (isFling || isFarEnough) {
              _isCompleted = true;
              _animateTo(maxDrag);
            } else {
              _animateTo(0.0);
            }
          },
          child: Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: trackBg,
              borderRadius: BorderRadius.circular(widget.height / 2),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFF343A40),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Expanding background fill behind thumb
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: _dragPosition + thumbSize + 8,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(widget.height / 2),
                    ),
                  ),
                ),

                // Center Label
                Positioned.fill(
                  child: Center(
                    child: Opacity(
                      opacity: (1.0 - (progress * 1.5)).clamp(0.0, 1.0),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 48, right: 16),
                        child: Text(
                          widget.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: widget.textColor ?? Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Draggable Circular Thumb with Arrow
                Positioned(
                  left: 4 + _dragPosition,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: widget.thumbColor ?? AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
