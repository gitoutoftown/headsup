/// Reusable UI components
library;

import 'package:flutter/material.dart' hide Theme, ThemeData;
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../config/theme.dart';

/// Primary action button
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  
  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ShadButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }
}

/// Secondary/outline button
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  
  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ShadButton.outline(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(text),
          ],
        ),
      ),
    );
  }
}

/// Stat card for displaying metrics
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;
  
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.title,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress bar for good/poor time
class PostureProgressBar extends StatelessWidget {
  final int goodSeconds;
  final int poorSeconds;
  final double height;
  
  const PostureProgressBar({
    super.key,
    required this.goodSeconds,
    required this.poorSeconds,
    this.height = 8,
  });
  
  @override
  Widget build(BuildContext context) {
    final total = goodSeconds + poorSeconds;
    final goodRatio = total > 0 ? goodSeconds / total : 0.5;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                Expanded(
                  flex: (goodRatio * 100).round(),
                  child: Container(color: AppColors.postureGood),
                ),
                Expanded(
                  flex: ((1 - goodRatio) * 100).round(),
                  child: Container(color: AppColors.posturePoor),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Good ${_formatDuration(goodSeconds)}',
              style: AppTypography.body.copyWith(
                color: AppColors.postureGood,
              ),
            ),
            Text(
              'Poor ${_formatDuration(poorSeconds)}',
              style: AppTypography.body.copyWith(
                color: AppColors.posturePoor,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

/// Angle gauge for visual feedback
class AngleGauge extends StatelessWidget {
  final double angle;
  final double maxAngle;
  final double size;
  final Color? color;
  
  const AngleGauge({
    super.key,
    required this.angle,
    this.maxAngle = 90,
    this.size = 120,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    final normalizedAngle = (angle / maxAngle).clamp(0.0, 1.0);
    // Use provided color or fallback to Good (Blue)
    final gaugeColor = color ?? AppColors.postureGood;
    
    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ring
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  progress: normalizedAngle,
                  color: gaugeColor,
                  backgroundColor: ShadTheme.of(context).colorScheme.muted,
                ),
              ),
              // Text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${angle.round()}°',
                    style: AppTypography.scoreDisplay.copyWith(
                      color: gaugeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'TILT',
                    style: AppTypography.caption.copyWith(
                      color: AppTypography.caption.color,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  
  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.12;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = backgroundColor.withValues(alpha: 0.3);
      
    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
      
    // Draw background circle
    canvas.drawCircle(center, radius, bgPaint);
    
    // Draw progress arc (start from top -90 degrees)
    // We map 0-90 degrees of tilt to 0-100% of the circle? 
    // Or maybe just a portion? Let's do full circle for 0-90.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // -90 degrees (top)
      2 * 3.14159 * progress, // Full circle sweep
      false,
      fgPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
