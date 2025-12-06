/// Reusable UI components
library;

import 'package:flutter/material.dart';

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
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
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
      child: OutlinedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
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
    final theme = Theme.of(context);
    
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.bodySmall,
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.postureGood,
              ),
            ),
            Text(
              'Poor ${_formatDuration(poorSeconds)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
  
  const AngleGauge({
    super.key,
    required this.angle,
    this.maxAngle = 90,
    this.size = 120,
  });
  
  @override
  Widget build(BuildContext context) {
    final normalizedAngle = (angle / maxAngle).clamp(0.0, 1.0);
    final color = normalizedAngle <= 0.5 
        ? AppColors.postureGood
        : normalizedAngle <= 0.7 
            ? AppColors.postureFair
            : AppColors.posturePoor;
    
    return Column(
      children: [
        Text(
          '${angle.round()}°',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: size,
          height: size / 3,
          child: CustomPaint(
            painter: _ArcPainter(
              progress: normalizedAngle,
              color: color,
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  
  _ArcPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    
    // Background arc
    paint.color = backgroundColor;
    canvas.drawArc(rect, 3.14159, 3.14159, false, paint);
    
    // Progress arc
    paint.color = color;
    canvas.drawArc(rect, 3.14159, 3.14159 * progress, false, paint);
  }
  
  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
