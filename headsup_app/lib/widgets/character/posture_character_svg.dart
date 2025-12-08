/// Alternative posture character using SVG file with transforms
/// Use this if you prefer rendering the original SVG with dynamic transforms
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/theme.dart';
import '../../utils/constants.dart';

class PostureCharacterSvg extends StatefulWidget {
  final PostureState state;
  final double currentAngle;
  final double size;

  const PostureCharacterSvg({
    super.key,
    this.state = PostureState.good,
    this.currentAngle = 0.0,
    this.size = 280,
  });

  @override
  State<PostureCharacterSvg> createState() => _PostureCharacterSvgState();
}

class _PostureCharacterSvgState extends State<PostureCharacterSvg>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _displayedAngle = 0.0;
  double _smoothedSensorAngle = 0.0;
  static const double _smoothingFactor = 0.15;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _smoothedSensorAngle = widget.currentAngle;
    _displayedAngle = widget.currentAngle;
  }

  @override
  void didUpdateWidget(PostureCharacterSvg oldWidget) {
    super.didUpdateWidget(oldWidget);

    _smoothedSensorAngle = (_smoothedSensorAngle * (1.0 - _smoothingFactor)) +
                          (widget.currentAngle * _smoothingFactor);

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

    // Color based on posture state
    Color tintColor;
    if (_displayedAngle <= 10) {
      tintColor = Colors.green;
    } else if (_displayedAngle <= 20) {
      tintColor = Colors.blue;
    } else if (_displayedAngle <= 40) {
      tintColor = isDark ? Colors.white : Colors.black;
    } else if (_displayedAngle <= 65) {
      tintColor = Colors.orange;
    } else {
      tintColor = Colors.red;
    }

    // Calculate bend factor for animation
    final bendFactor = (_displayedAngle / 90.0).clamp(0.0, 1.0);

    // Rotation parameters
    final headRotationDegrees = bendFactor * 45.0;
    final forwardShift = bendFactor * 20.0;
    final downShift = bendFactor * 15.0;

    // Background color for erasing original head
    final backgroundColor = isDark ? Colors.black : Colors.white;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // Full SVG (we'll clip/mask the head later if needed)
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/svg/texting-on-phone-person-message-people-svgrepo-com.svg',
              colorFilter: ColorFilter.mode(tintColor, BlendMode.srcIn),
              fit: BoxFit.contain,
            ),
          ),

          // Animated head overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _AnimatedHeadPainter(
                angle: _displayedAngle,
                color: tintColor,
                backgroundColor: backgroundColor,
                bendFactor: bendFactor,
                headRotation: headRotationDegrees,
                forwardShift: forwardShift,
                downShift: downShift,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedHeadPainter extends CustomPainter {
  final double angle;
  final Color color;
  final Color backgroundColor;
  final double bendFactor;
  final double headRotation;
  final double forwardShift;
  final double downShift;

  _AnimatedHeadPainter({
    required this.angle,
    required this.color,
    required this.backgroundColor,
    required this.bendFactor,
    required this.headRotation,
    required this.forwardShift,
    required this.downShift,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // SVG ViewBox is 0 0 128 128
    final scale = size.width / 128.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Original head position from SVG
    final originalHeadX = 67.5;
    final originalHeadY = 23.0;
    final headRadiusX = 23.0;
    final headRadiusY = 23.0;

    // Neck base (where neck meets shoulders) - pivot point for rotation
    final neckBaseX = 67.5; // Use head center X for simpler rotation
    final neckBaseY = 46.0; // Bottom of head (23 + 23 = 46)

    final headRotationRadians = headRotation * (math.pi / 180.0);

    canvas.save();

    // First, hide the original SVG head with a background-colored circle
    final erasePaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(originalHeadX * scale, originalHeadY * scale),
        width: (headRadiusX + 3) * 2 * scale,
        height: (headRadiusY + 3) * 2 * scale,
      ),
      erasePaint,
    );

    // Now draw the animated head
    // Transform to neck base (bottom of head)
    canvas.translate(neckBaseX * scale, neckBaseY * scale);

    // Rotate around the neck base
    canvas.rotate(headRotationRadians);

    // Calculate head position relative to neck
    // In upright position, head is 23px above neck base
    final headOffsetY = -headRadiusY + downShift;
    final headOffsetX = forwardShift;

    // Draw the animated head ellipse
    final headRect = Rect.fromCenter(
      center: Offset(headOffsetX * scale, headOffsetY * scale),
      width: headRadiusX * 2 * scale,
      height: headRadiusY * 2 * scale,
    );
    canvas.drawOval(headRect, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AnimatedHeadPainter old) {
    return old.angle != angle || old.color != color || old.backgroundColor != backgroundColor;
  }
}
