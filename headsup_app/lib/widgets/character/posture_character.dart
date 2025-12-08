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
    
    // Color logic based on zones (same as before)
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
    // We need to scale this to fit our widget size
    final scale = size.width / 128.0;
    
    // Debug: Force visible color for body to test visibility
    // If the body appears purple, we know the paths are correct but the color was wrong.
    final bodyPaint = Paint()
      ..color = Colors.purple // DEBUG COLOR
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
      
    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // --- 1. DRAW STATIC BODY (SVG Paths) ---
    // Extracted from provided SVG
    
    canvas.save();
    canvas.scale(scale, scale); // Apply scaling
    
    // Path 2 (Arms/Phone area)
    // <path id="_x32_" d="M120.4,64.1l-27,9.8c-1.4,0.6-3.2-0.3-3.7-1.7l0,0c-0.6-1.4,0.3-3.2,1.7-3.7l27-9.8c1.4-0.6,3.2,0.3,3.7,1.7l0,0 C122.7,62.1,121.9,63.5,120.4,64.1z"/>
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
    canvas.drawPath(armPath, bodyPaint);
    
    // Path 3 (Torso/Legs/Chair)
    // <path d="M121,78.8c-2-5.2-7.8-8.1-12.9-6L73.6,85.5L64.7,61c-2.3-9.8-10.4-17.8-21-19.9c-14.1-2.6-25.8,11.1-28.4,25.2L1.9,128h55.8 v-12.3L41,71.6c-0.6-1.4,0.3-3.2,1.7-3.7c1.4-0.6,3.2,0.3,3.7,1.7L58,101.2c0.9,2.6,2.6,4.6,5.2,6c2.3,1.2,4.9,1.2,7.2,0.6L115,91.7 C120.1,89.7,123,84,121,78.8z"/>
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
    canvas.drawPath(bodyPath, bodyPaint);
    
    canvas.restore(); // Done with static body
    
    // --- 2. DRAW DYNAMIC HEAD (Circle) ---
    // <ellipse id="_x33_" cx="67.5" cy="23" rx="23" ry="23"/>
    
    // Original Center: (67.5, 23.0)
    // Radius: 23.0
    
    final headRadius = 23.0 * scale;
    
    // Calculate movement based on angle
    // Angle 0 = Upright (original position)
    // Angle 90 = Forward/Down
    
    // Max displacement (Forward/Down)
    // EXAGGERATED for visibility
    final maxForward = 45.0 * scale; 
    final maxDown = 30.0 * scale;
    
    // Use bend factor (normalized angle)
    final bendFactor = (angle / 90.0).clamp(0.0, 1.0);
    
    // Apply Spring/Ease curve manually for smoothness
    // E.g. x^2 ease out
    final ease = bendFactor; // Already smoothed by controller
    
    // Calculate head center
    // Default SVG center (67.5, 23)
    final originalHeadX = 67.5 * scale;
    final originalHeadY = 23.0 * scale;
    
    // Dynamic Position
    final headX = originalHeadX + (maxForward * ease);
    final headY = originalHeadY + (maxDown * ease);
    
    // Draw Head
    canvas.drawCircle(Offset(headX, headY), headRadius, headPaint);

    // DEBUG: Draw small dot at original position to see relative movement
    // canvas.drawCircle(Offset(originalHeadX, originalHeadY), 2.0 * scale, Paint()..color = Colors.black);
    
    // Optional: Draw a "Neck" line connecting torso to head?
    // The SVG relies on gestalt/proximity.
    // But we could draw a thick line from (55,45) to center of head.
    final pivotX = 55.0 * scale;
    final pivotY = 45.0 * scale;
    
    final neckPaint = Paint()
      ..color = color // Keep neck matching head color
      ..strokeWidth = 14.0 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    canvas.drawLine(
      Offset(pivotX, pivotY), // Neck base on body
      Offset(headX, headY + (5 * scale)), // Bottom of head
      neckPaint
    );
  }
  
  @override
  bool shouldRepaint(covariant _SvgCharacterPainter old) {
    return old.angle != angle || old.color != color;
  }
}
