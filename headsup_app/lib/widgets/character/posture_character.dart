/// Animated posture character widget
/// Displays a minimalist line-art figure that reflects posture state
/// Updated for 5-tier posture system (Excellent/Good/Okay/Bad/Poor)
library;

import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../utils/constants.dart';

class PostureCharacter extends StatelessWidget {
  final PostureState state;
  final double size;
  final Duration transitionDuration;
  
  const PostureCharacter({
    super.key,
    this.state = PostureState.good,
    this.size = 200,
    this.transitionDuration = const Duration(milliseconds: 1000),
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.characterDark : AppColors.characterLight;
    
    return SizedBox(
      width: size,
      height: size * 1.5,
      child: AnimatedSwitcher(
        duration: transitionDuration,
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: CustomPaint(
          key: ValueKey(state),
          size: Size(size, size * 1.5),
          painter: _CharacterPainter(
            state: state,
            color: color,
            strokeWidth: size * 0.02,
          ),
        ),
      ),
    );
  }
}

class _CharacterPainter extends CustomPainter {
  final PostureState state;
  final Color color;
  final double strokeWidth;
  
  _CharacterPainter({
    required this.state,
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
    
    // Center point
    final centerX = size.width / 2;
    final headRadius = size.width * 0.08;
    
    // State-dependent offsets (5 tiers)
    double headForwardOffset;
    double shoulderDrop;
    double spineControlOffset;
    
    switch (state) {
      case PostureState.excellent:
        headForwardOffset = 0;
        shoulderDrop = 0;
        spineControlOffset = 0;
        break;
      case PostureState.good:
        headForwardOffset = 0;
        shoulderDrop = 0;
        spineControlOffset = 0;
        break;
      case PostureState.okay:
        headForwardOffset = size.width * 0.06;
        shoulderDrop = size.height * 0.015;
        spineControlOffset = size.width * 0.04;
        break;
      case PostureState.bad:
        headForwardOffset = size.width * 0.12;
        shoulderDrop = size.height * 0.035;
        spineControlOffset = size.width * 0.08;
        break;
      case PostureState.poor:
        headForwardOffset = size.width * 0.20;
        shoulderDrop = size.height * 0.06;
        spineControlOffset = size.width * 0.14;
        break;
    }
    
    // Key positions
    final headY = size.height * 0.12;
    final headCenterX = centerX + headForwardOffset;
    
    final neckY = headY + headRadius + size.height * 0.02;
    final shoulderY = neckY + size.height * 0.06 + shoulderDrop;
    final shoulderWidth = size.width * 0.25;
    
    final hipY = size.height * 0.55;
    final legEndY = size.height * 0.95;
    final legSpread = size.width * 0.12;
    
    // Draw head (circle)
    canvas.drawCircle(
      Offset(headCenterX, headY),
      headRadius,
      paint,
    );
    
    // Draw neck
    final neckPath = Path();
    neckPath.moveTo(headCenterX, headY + headRadius);
    neckPath.lineTo(centerX + spineControlOffset * 0.5, neckY);
    canvas.drawPath(neckPath, paint);
    
    // Draw spine (curved for poor posture)
    final spinePath = Path();
    spinePath.moveTo(centerX + spineControlOffset * 0.5, neckY);
    
    if (state == PostureState.excellent || state == PostureState.good) {
      // Straight spine
      spinePath.lineTo(centerX, hipY);
    } else {
      // Curved spine
      spinePath.quadraticBezierTo(
        centerX + spineControlOffset,
        (neckY + hipY) / 2,
        centerX,
        hipY,
      );
    }
    canvas.drawPath(spinePath, paint);
    
    // Draw shoulders
    final leftShoulderX = centerX - shoulderWidth;
    final rightShoulderX = centerX + shoulderWidth;
    
    // Left shoulder and arm
    canvas.drawLine(
      Offset(centerX + spineControlOffset * 0.3, shoulderY - size.height * 0.02),
      Offset(leftShoulderX, shoulderY),
      paint,
    );
    canvas.drawLine(
      Offset(leftShoulderX, shoulderY),
      Offset(leftShoulderX - size.width * 0.05, hipY - size.height * 0.08),
      paint,
    );
    
    // Right shoulder and arm
    canvas.drawLine(
      Offset(centerX + spineControlOffset * 0.3, shoulderY - size.height * 0.02),
      Offset(rightShoulderX + spineControlOffset * 0.4, shoulderY + shoulderDrop * 0.3),
      paint,
    );
    canvas.drawLine(
      Offset(rightShoulderX + spineControlOffset * 0.4, shoulderY + shoulderDrop * 0.3),
      Offset(rightShoulderX + size.width * 0.05, hipY - size.height * 0.08),
      paint,
    );
    
    // Draw legs
    // Left leg
    canvas.drawLine(
      Offset(centerX, hipY),
      Offset(centerX - legSpread, legEndY),
      paint,
    );
    
    // Right leg
    canvas.drawLine(
      Offset(centerX, hipY),
      Offset(centerX + legSpread, legEndY),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant _CharacterPainter oldDelegate) {
    return oldDelegate.state != state || 
           oldDelegate.color != color ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Animated character that transitions smoothly between states
class AnimatedPostureCharacter extends StatefulWidget {
  final PostureState state;
  final double size;
  
  const AnimatedPostureCharacter({
    super.key,
    this.state = PostureState.good,
    this.size = 200,
  });
  
  @override
  State<AnimatedPostureCharacter> createState() => _AnimatedPostureCharacterState();
}

class _AnimatedPostureCharacterState extends State<AnimatedPostureCharacter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _headOffset;
  late Animation<double> _shoulderDrop;
  late Animation<double> _spineOffset;
  
  PostureState _currentState = PostureState.good;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.characterTransition,
      vsync: this,
    );
    _currentState = widget.state;
    _updateAnimations();
  }
  
  @override
  void didUpdateWidget(AnimatedPostureCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _animateToState(widget.state);
    }
  }
  
  void _animateToState(PostureState newState) {
    _currentState = newState;
    _updateAnimations();
    _controller.forward(from: 0);
  }
  
  void _updateAnimations() {
    final targetHeadOffset = switch (_currentState) {
      PostureState.excellent => 0.0,
      PostureState.good => 0.0,
      PostureState.okay => 0.06,
      PostureState.bad => 0.12,
      PostureState.poor => 0.20,
    };
    
    final targetShoulderDrop = switch (_currentState) {
      PostureState.excellent => 0.0,
      PostureState.good => 0.0,
      PostureState.okay => 0.015,
      PostureState.bad => 0.035,
      PostureState.poor => 0.06,
    };
    
    final targetSpineOffset = switch (_currentState) {
      PostureState.excellent => 0.0,
      PostureState.good => 0.0,
      PostureState.okay => 0.04,
      PostureState.bad => 0.08,
      PostureState.poor => 0.14,
    };
    
    _headOffset = Tween<double>(
      begin: _headOffset.value,
      end: targetHeadOffset,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    
    _shoulderDrop = Tween<double>(
      begin: _shoulderDrop.value,
      end: targetShoulderDrop,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    
    _spineOffset = Tween<double>(
      begin: _spineOffset.value,
      end: targetSpineOffset,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return PostureCharacter(
      state: widget.state,
      size: widget.size,
    );
  }
}
