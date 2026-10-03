import 'package:flutter/material.dart';

/// Staggered slide and fade entrance animation wrapper
/// Animates children in with a slight delay proportional to their index
class StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delayPerItem;
  final Duration animationDuration;
  final Offset slideOffset;

  const StaggeredEntrance({
    super.key,
    required this.child,
    required this.index,
    this.delayPerItem = const Duration(milliseconds: 40),
    this.animationDuration = const Duration(milliseconds: 400),
    this.slideOffset = const Offset(0.0, 0.08),
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _slideAnimation = Tween<Offset>(begin: widget.slideOffset, end: Offset.zero).animate(curve);

    final delay = widget.delayPerItem * (widget.index.clamp(0, 10));
    Future.delayed(delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
