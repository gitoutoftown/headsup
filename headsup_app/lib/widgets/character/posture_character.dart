/// Animated posture character widget
/// Displays a side-profile silhouette emulating the reference design
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
  late Animation<double> _strainIntensity; // 0.0 (None) to 1.0 (High)

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
    _strainIntensity = AlwaysStoppedAnimation(targets.strain);
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

  ({double angle, double fwd, double strain}) _getTargets(PostureState state) {
    // Angle in degrees
    switch (state) {
      case PostureState.excellent:
        return (angle: 0.0, fwd: 0.0, strain: 0.0);
      case PostureState.good:
        return (angle: 10.0, fwd: 5.0, strain: 0.2);
      case PostureState.okay:
        return (angle: 25.0, fwd: 15.0, strain: 0.5);
      case PostureState.bad:
        return (angle: 45.0, fwd: 30.0, strain: 0.8);
      case PostureState.poor:
        return (angle: 60.0, fwd: 50.0, strain: 1.0);
    }
  }

  void _animateToState(PostureState newState) {
    final targets = _getTargets(newState);
    
    _neckAngle = Tween<double>(
      begin: _neckAngle.value,
      end: targets.angle,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _headForward = Tween<double>(
      begin: _headForward.value,
      end: targets.fwd,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _strainIntensity = Tween<double>(
      begin: _strainIntensity.value,
      end: targets.strain,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.characterDark : AppColors.characterLight;
    
    // Strain color (interpolates from transparent/base to Red/Orange)
    final strainColor = Color.lerp(
      color.withValues(alpha: 0.0), 
      Colors.redAccent, 
      _strainIntensity.value
    ) ?? Colors.red;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _ProfilePainter(
              neckAngle: _neckAngle.value,
              headForward: _headForward.value,
              strainIntensity: _strainIntensity.value,
              color: color,
              strainColor: strainColor,
              strokeWidth: widget.size * 0.025,
            ),
          );
        },
      ),
    );
  }
}

class _ProfilePainter extends CustomPainter {
  final double neckAngle;
  final double headForward;
  final double strainIntensity;
  final Color color;
  final Color strainColor;
  final double strokeWidth;
  
  _ProfilePainter({
    required this.neckAngle,
    required this.headForward,
    required this.strainIntensity,
    required this.color,
    required this.strainColor,
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
    
    final scale = size.width / 100.0;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Pivot point (C7 Vertebrae area)
    final pivotX = centerX + 10 * scale;
    final pivotY = centerY + 20 * scale;
    
    // 1. Draw Static Body/Shoulder (Left side of image)
    final bodyPath = Path();
    // Start at bottom left
    bodyPath.moveTo(centerX - 40 * scale, pivotY + 40 * scale);
    // Shoulder curve up
    bodyPath.quadraticBezierTo(
      centerX - 35 * scale, pivotY + 10 * scale, // Control
      centerX - 10 * scale, pivotY + 5 * scale   // Top of shoulder near neck
    );
    // Neck connection (front)
    // bodyPath.lineTo(centerX, pivotY); 
    canvas.drawPath(bodyPath, paint);
    
    // 2. Draw Back Body (Right side)
    final backPath = Path();
    backPath.moveTo(pivotX + 10 * scale, pivotY + 40 * scale);
    backPath.quadraticBezierTo(
      pivotX + 15 * scale, pivotY + 20 * scale,
      pivotX + 5 * scale, pivotY + 5 * scale
    );
    canvas.drawPath(backPath, paint);


    // 3. Draw Head & Neck (Rotated)
    canvas.save();
    // Rotate around pivot
    canvas.translate(pivotX, pivotY);
    canvas.rotate(neckAngle * math.pi / 180.0);
    canvas.translate(-pivotX, -pivotY);
    
    final headPath = Path();
    
    // Neck Base Back (Connects to pivot area)
    final neckBackX = pivotX;
    final neckBackY = pivotY;
    
    headPath.moveTo(neckBackX, neckBackY);
    
    // Back of Head Curve
    headPath.cubicTo(
      neckBackX - 5 * scale, neckBackY - 20 * scale, // Neck up
      neckBackX - 25 * scale, neckBackY - 40 * scale, // Back of skull
      neckBackX - 25 * scale, neckBackY - 60 * scale  // Top back
    );
    
    // Top of Head
    headPath.cubicTo(
      neckBackX - 25 * scale, neckBackY - 80 * scale, // Top dome
      neckBackX - 60 * scale, neckBackY - 70 * scale, // Forehead start
      neckBackX - 60 * scale, neckBackY - 45 * scale  // Forehead/Eye level
    );
    
    // Face Profile
    // Nose
    headPath.lineTo(neckBackX - 65 * scale, neckBackY - 40 * scale); // Nose tip
    headPath.lineTo(neckBackX - 55 * scale, neckBackY - 35 * scale); // Under nose
    
    // Chin
    headPath.quadraticBezierTo(
      neckBackX - 55 * scale, neckBackY - 25 * scale, // Mouth area
      neckBackX - 45 * scale, neckBackY - 20 * scale  // Chin tip
    );
    
    // Jaw/Neck Front
    headPath.quadraticBezierTo(
      neckBackX - 30 * scale, neckBackY - 15 * scale, // Jawline
      neckBackX - 20 * scale, neckBackY // Neck front base
    );
    
    canvas.drawPath(headPath, paint);
    
    // 4. Draw Strain Pill (Indicator)
    // Located at the back of the neck pivot
    if (strainIntensity > 0.1) {
      final pillPaint = Paint()
        ..color = Color.lerp(Colors.transparent, Colors.red, strainIntensity) ?? Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.5; // Thicker
        
      final pillPath = Path();
      // An oval shape at the pivot
      final pillRect = Rect.fromCenter(
        center: Offset(neckBackX + 5 * scale, neckBackY - 5 * scale),
        width: 15 * scale,
        height: 25 * scale
      );
      // Rotate pill slightly less than head? Or with head?
      // Let's draw it relative to the rotated canvas
      // Actually, typically the strain is between static body and moving head.
      // So maybe draw it AFTER restore?
      // Or draw it here on the neck itself.
      
      canvas.drawOval(pillRect, pillPaint);
    }

    canvas.restore();
  }
  
  @override
  bool shouldRepaint(covariant _ProfilePainter old) {
    return old.neckAngle != neckAngle ||
           old.strainIntensity != strainIntensity ||
           old.color != color;
  }
}
