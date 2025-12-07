/// Animated posture character widget
/// Displays a stylized head figure with expressive face that reflects posture state
/// Updated for 5-tier posture system (Excellent/Good/Okay/Bad/Poor)
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../utils/constants.dart';

class PostureCharacter extends StatefulWidget {
  final PostureState state;
  final double size;
  final Duration transitionDuration;
  
  const PostureCharacter({
    super.key,
    this.state = PostureState.good,
    this.size = 200,
    this.transitionDuration = const Duration(milliseconds: 800),
  });

  @override
  State<PostureCharacter> createState() => _PostureCharacterState();
}

class _PostureCharacterState extends State<PostureCharacter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Animated values
  late Animation<double> _neckAngle;
  late Animation<double> _headForward;
  late Animation<double> _headDrop;
  late Animation<double> _mouthCurvature; // 1.0 = Smile, 0.0 = Neutral, -1.0 = Frown

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.transitionDuration,
      vsync: this,
    );

    // Initialize with current state values
    final targets = _getTargets(widget.state);
    _neckAngle = AlwaysStoppedAnimation(targets.angle);
    _headForward = AlwaysStoppedAnimation(targets.fwd);
    _headDrop = AlwaysStoppedAnimation(targets.drop);
    _mouthCurvature = AlwaysStoppedAnimation(targets.mouth);
  }

  @override
  void didUpdateWidget(PostureCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _animateToState(widget.state);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ({double angle, double fwd, double drop, double mouth}) _getTargets(PostureState state) {
    switch (state) {
      case PostureState.excellent:
        return (angle: 0.0, fwd: 0.0, drop: 0.0, mouth: 1.0);
      case PostureState.good:
        return (angle: 5.0, fwd: 5.0, drop: 2.0, mouth: 0.5);
      case PostureState.okay:
        return (angle: 15.0, fwd: 15.0, drop: 5.0, mouth: 0.0);
      case PostureState.bad:
        return (angle: 30.0, fwd: 30.0, drop: 12.0, mouth: -0.5);
      case PostureState.poor:
        return (angle: 45.0, fwd: 50.0, drop: 25.0, mouth: -1.0);
    }
  }

  void _animateToState(PostureState newState) {
    final targets = _getTargets(newState);
    
    // Create new animations starting from current value
    _neckAngle = Tween<double>(
      begin: _neckAngle.value,
      end: targets.angle,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _headForward = Tween<double>(
      begin: _headForward.value,
      end: targets.fwd,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _headDrop = Tween<double>(
      begin: _headDrop.value,
      end: targets.drop,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _mouthCurvature = Tween<double>(
      begin: _mouthCurvature.value,
      end: targets.mouth,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.characterDark : AppColors.characterLight;
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _HeadPainter(
              neckAngle: _neckAngle.value,
              headForward: _headForward.value,
              headDrop: _headDrop.value,
              mouthCurvature: _mouthCurvature.value,
              color: color,
              strokeWidth: widget.size * 0.03,
            ),
          );
        },
      ),
    );
  }
}

class _HeadPainter extends CustomPainter {
  final double neckAngle;
  final double headForward;
  final double headDrop;
  final double mouthCurvature;
  final Color color;
  final double strokeWidth;
  
  _HeadPainter({
    required this.neckAngle,
    required this.headForward,
    required this.headDrop,
    required this.mouthCurvature,
    required this.color,
    required this.strokeWidth,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    // Base parameters
    final centerX = size.width / 2;
    final bottomY = size.height * 0.9;
    final scale = size.width / 100.0;
    
    // Convert angle to radians
    final angleRad = neckAngle * math.pi / 180.0;
    
    // Draw Shoulder Line (Base)
    final shoulderPath = Path();
    shoulderPath.moveTo(centerX - 30 * scale, bottomY);
    shoulderPath.quadraticBezierTo(
      centerX, bottomY - 5 * scale, 
      centerX + 30 * scale, bottomY
    );
    canvas.drawPath(shoulderPath, paint);
    
    // Pivot point (Base of neck)
    final pivotX = centerX;
    final pivotY = bottomY - 5 * scale;
    
    // Neck End Point
    final neckLength = 25.0 * scale;
    final neckX = pivotX + (headForward * scale);
    final neckY = pivotY - neckLength + (headDrop * scale);
    
    // Draw Neck
    final neckPath = Path();
    neckPath.moveTo(pivotX, pivotY);
    neckPath.quadraticBezierTo(
      (pivotX + neckX) / 2, pivotY - 10 * scale,
      neckX, neckY
    );
    canvas.drawPath(neckPath, paint);
    
    // Transform for Head
    canvas.save();
    canvas.translate(neckX, neckY);
    canvas.rotate(angleRad);
    
    // Draw Head (Rounded Rectangle / Squircle)
    final headW = 45.0 * scale;
    final headH = 50.0 * scale;
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, -headH / 2), width: headW, height: headH),
      Radius.circular(15 * scale),
    );
    canvas.drawRRect(headRect, paint);
    
    // Draw Face Features
    // Eyes
    final eyeY = -headH * 0.55;
    final eyeX = headW * 0.25;
    final eyeRadius = 2.5 * scale;
    
    // Left Eye
    canvas.drawCircle(Offset(-eyeX, eyeY), eyeRadius, paint..style = PaintingStyle.fill);
    // Right Eye
    canvas.drawCircle(Offset(eyeX, eyeY), eyeRadius, paint..style = PaintingStyle.fill);
    
    // Reset paint style for mouth
    paint.style = PaintingStyle.stroke;
    
    // Mouth
    final mouthY = -headH * 0.3;
    final mouthW = headW * 0.4;
    final mouthPath = Path();
    mouthPath.moveTo(-mouthW/2, mouthY);
    
    // Curvature determines smile vs frown
    // Max curve depth = 5 units
    final curveDepth = 8.0 * scale * mouthCurvature;
    
    mouthPath.quadraticBezierTo(
      0, mouthY + curveDepth,
      mouthW/2, mouthY
    );
    canvas.drawPath(mouthPath, paint);
    
    canvas.restore();
  }
  
  @override
  bool shouldRepaint(covariant _HeadPainter old) {
    return old.neckAngle != neckAngle ||
           old.headForward != headForward ||
           old.headDrop != headDrop ||
           old.mouthCurvature != mouthCurvature ||
           old.color != color;
  }
}
