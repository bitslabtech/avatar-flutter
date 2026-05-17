/// Custom curved header with blob/wave shape
/// Used at the top of screens for premium, Apple-like design
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CurvedHeader extends StatelessWidget {
  final Widget? child;
  final double height;
  final Color? color;

  const CurvedHeader({
    super.key,
    this.child,
    this.height = 200,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color ?? AppColors.primaryRed.withOpacity(0.2),
              AppColors.surfaceDark,
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Custom clipper for wave/blob shape
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    
    // Start from top-left
    path.moveTo(0, 0);
    
    // Create a smooth wave curve
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.2,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.1,
      size.width,
      size.height * 0.3,
    );
    
    // Complete the shape
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

