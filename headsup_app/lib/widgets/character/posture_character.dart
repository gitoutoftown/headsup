/// Animated posture character widget
/// Implementation using SVG paths
/// Hybrid Approach: Static Body (SVG Path) + Dynamic Head (Programmatic)
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../utils/constants.dart';

class PostureCharacter extends StatefulWidget {
  final PostureState state;
  final double currentAngle; // Actual sensor angle passed from parent
  final double size;
  
  const PostureCharacter({
    super.key,
    this.state = PostureState.good,
    this.currentAngle = 0.0,
    this.size = 280,
  });

  @override
  State<PostureCharacter> createState() => _PostureCharacterState();
}

class _PostureCharacterState extends State<PostureCharacter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Physics state
  double _displayedAngle = 0.0;
  
  // Smoothing state
  double _smoothedSensorAngle = 0.0;
  static const double _smoothingFactor = 0.15;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _controller.addListener(() {
      // No-op, setState handled by animation listener
    });
    
    _smoothedSensorAngle = widget.currentAngle;
    _displayedAngle = widget.currentAngle;
  }

  @override
  void didUpdateWidget(PostureCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Exponential Smoothing
    _smoothedSensorAngle = (_smoothedSensorAngle * (1.0 - _smoothingFactor)) + 
                          (widget.currentAngle * _smoothingFactor);
    
    // Trigger animation
    if ((_smoothedSensorAngle - _displayedAngle).abs() > 0.5) {
      _animateToAngle(_smoothedSensorAngle);
    }
  }

  void _animateToAngle(double targetAngle) {
    _controller.stop();
    
    final animation = Tween<double>(
      begin: _displayedAngle,
      end: targetAngle,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    animation.addListener(() {
      setState(() {
        _displayedAngle = animation.value;
      });
    });
    
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Color logic based on zones
    Color tintColor;
    if (_displayedAngle <= 10) {
      tintColor = Colors.green;
    } else if (_displayedAngle <= 20) {
      tintColor = Colors.blue;
    } else if (_displayedAngle <= 40) {
      tintColor = isDark ? Colors.white : Colors.black; // Neutral
    } else if (_displayedAngle <= 65) {
      tintColor = Colors.orange;
    } else {
      tintColor = Colors.red;
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _SvgCharacterPainter(
          angle: _displayedAngle,
          color: tintColor,
        ),
      ),
    );
  }
}

class _SvgCharacterPainter extends CustomPainter {
  final double angle;
  final Color color;
  
  _SvgCharacterPainter({
    required this.angle,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // SVG ViewBox is 0 0 128 128
    final scale = size.width / 128.0;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // --- 1. DRAW STATIC BODY ---
    // This includes the Arms/Phone (Path 2) and Torso/Chair (Path 3)
    // We EXCLUDE the ellipse (Head) from the static drawing
    
    canvas.save();
    canvas.scale(scale, scale);
    
    // Path 2 (Arms/Phone) - EXACT copy from SVG
    final armPath = Path();
    armPath.moveTo(120.4, 64.1);
    armPath.lineTo(93.4, 73.9);
    armPath.cubicTo(92.0, 74.5, 90.2, 73.6, 89.7, 72.2);
    armPath.lineTo(89.7, 72.2);
    armPath.cubicTo(89.1, 70.8, 90.0, 69.0, 91.4, 68.5);
    armPath.lineTo(118.4, 58.7);
    armPath.cubicTo(119.8, 58.1, 121.6, 59.0, 122.1, 60.4);
    armPath.lineTo(122.1, 60.4);
    armPath.cubicTo(122.7, 62.1, 121.9, 63.5, 120.4, 64.1);
    armPath.close();
    canvas.drawPath(armPath, paint);
    
    // Path 3 (Body/Chair) - EXACT copy from SVG
    final bodyPath = Path();
    bodyPath.moveTo(121.0, 78.8);
    bodyPath.cubicTo(119.0, 73.6, 113.2, 70.7, 108.1, 72.8);
    bodyPath.lineTo(73.6, 85.5);
    bodyPath.lineTo(64.7, 61.0);
    bodyPath.cubicTo(62.4, 51.2, 54.3, 43.2, 43.7, 41.1);
    bodyPath.cubicTo(29.6, 38.5, 17.9, 52.2, 15.3, 66.3);
    bodyPath.lineTo(1.9, 128.0);
    bodyPath.lineTo(57.7, 128.0);
    bodyPath.lineTo(57.7, 115.7);
    bodyPath.lineTo(41.0, 71.6);
    bodyPath.cubicTo(40.4, 70.2, 41.3, 68.4, 42.7, 67.9);
    bodyPath.cubicTo(44.1, 67.3, 45.9, 68.2, 46.4, 69.6);
    bodyPath.lineTo(58.0, 101.2);
    bodyPath.cubicTo(58.9, 103.8, 60.6, 105.8, 63.2, 107.2);
    bodyPath.cubicTo(65.5, 108.4, 68.1, 108.4, 70.4, 107.8);
    bodyPath.lineTo(115.0, 91.7);
    bodyPath.cubicTo(120.1, 89.7, 123.0, 84.0, 121.0, 78.8);
    bodyPath.close();
    canvas.drawPath(bodyPath, paint);
    
    // --- 1.5. PATCH SHOULDER GAP ---
    // The original SVG body path has a cutout where the neck was.
    // We draw a small circle to fill this "socket" so the body looks solid.
    // Position estimated around (58, 45) based on neck connection point.
    
    final patchX = 58.0;
    final patchY = 45.0;
    final patchRadius = 12.0; // Large enough to cover the dip
    
    canvas.drawCircle(Offset(patchX, patchY), patchRadius, paint);
    
    canvas.restore(); // Done with static body
    
    // --- 2. DRAW DYNAMIC HEAD (Circle) ---
    // Replacing SVG Ellipse <ellipse id="_x33_" cx="67.5" cy="23" rx="23" ry="23"/>
    
    final headRadius = 23.0 * scale;
    final originalHeadX = 67.5 * scale;
    final originalHeadY = 23.0 * scale;
    
    // Movement Logic:
    // Forward (Right) and Down based on angle
    final bendFactor = (angle / 90.0).clamp(0.0, 1.0);
    final ease = bendFactor; // Linear for now to match direct tilt feel
    
    // Exaggerated movement range to be visible
    final maxForward = 45.0 * scale; 
    final maxDown = 30.0 * scale;
    
    final headX = originalHeadX + (maxForward * ease);
    final headY = originalHeadY + (maxDown * ease);
    
    // Draw Head Circle
    canvas.drawCircle(Offset(headX, headY), headRadius, paint);
  }
  
  @override
  bool shouldRepaint(covariant _SvgCharacterPainter old) {
    return old.angle != angle || old.color != color;
  }
}
