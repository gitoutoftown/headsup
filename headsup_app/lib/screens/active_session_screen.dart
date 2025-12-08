/// Active session screen - Real-time tracking display
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../providers/session_provider.dart';
import '../utils/constants.dart';
import '../widgets/character/posture_character_svg.dart';
import '../widgets/common/widgets.dart';
import 'session_summary_screen.dart';

class ActiveSessionScreen extends ConsumerWidget {
  const ActiveSessionScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionProvider);
    final currentState = sessionState.postureState;
    final stateColor = Color(currentState.colorCode);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Stack(
            children: [
              // Main content column - layout stays consistent
              Column(
                children: [
                  // Top spacer
                  const SizedBox(height: AppSpacing.lg),

                  // Character (40% of screen) - stays in same position always
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: PostureCharacterSvg(
                        state: currentState,
                        currentAngle: sessionState.currentAngle,
                        size: MediaQuery.of(context).size.width * 0.4,
                      ),
                    ),
                  ),
              
              // Posture state with color
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  currentState.feedback,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: stateColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Angle display with tier color
              AngleGauge(
                angle: sessionState.currentAngle,
                size: MediaQuery.of(context).size.width * 0.35,
                color: stateColor,
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Timer
              Text(
                sessionState.timerDisplay,
                style: AppTypography.timer.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // 5-tier progress bar
              _TierProgressBar(sessionState: sessionState),
              
              const Spacer(),
              
              // Points earned (additive - never decreases!)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '+${sessionState.currentScore}',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: stateColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Points',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        '+${currentState.pointsPerMinute}/min',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: stateColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // End session button
              PrimaryButton(
                text: 'End Session',
                icon: Icons.stop_rounded,
                onPressed: () => _endSession(context, ref),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Pause button
              TextButton(
                onPressed: () {
                  if (sessionState.isPaused) {
                    ref.read(sessionProvider.notifier).resumeSession();
                  } else {
                    ref.read(sessionProvider.notifier).pauseSession();
                  }
                },
                child: Text(
                  sessionState.isPaused ? 'Resume' : 'Pause',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),

              // Pause banner overlaid on top (doesn't affect layout)
              if (sessionState.isPaused && sessionState.pauseReason != null)
                Positioned(
                  top: AppSpacing.lg,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _PauseReasonBanner(reason: sessionState.pauseReason!),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _endSession(BuildContext context, WidgetRef ref) async {
    final session = await ref.read(sessionProvider.notifier).endSession();
    
    if (context.mounted && session != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SessionSummaryScreen(session: session),
        ),
      );
    }
  }
}

/// Progress bar showing time in each tier
class _TierProgressBar extends StatelessWidget {
  final SessionState sessionState;
  
  const _TierProgressBar({required this.sessionState});
  
  @override
  Widget build(BuildContext context) {
    final total = sessionState.elapsedSeconds;
    if (total == 0) {
      return const SizedBox(height: 12);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  _TierSegment(
                    seconds: sessionState.excellentSeconds,
                    total: total,
                    color: AppColors.postureExcellent,
                  ),
                  _TierSegment(
                    seconds: sessionState.goodSeconds,
                    total: total,
                    color: AppColors.postureGood,
                  ),
                  _TierSegment(
                    seconds: sessionState.okaySeconds,
                    total: total,
                    color: AppColors.postureOkay,
                  ),
                  _TierSegment(
                    seconds: sessionState.badSeconds,
                    total: total,
                    color: AppColors.postureBad,
                  ),
                  _TierSegment(
                    seconds: sessionState.poorSeconds,
                    total: total,
                    color: AppColors.posturePoor,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _LegendDot(color: AppColors.postureExcellent, label: 'Excellent'),
              _LegendDot(color: AppColors.postureGood, label: 'Good'),
              _LegendDot(color: AppColors.postureOkay, label: 'Okay'),
              _LegendDot(color: AppColors.postureBad, label: 'Bad'),
              _LegendDot(color: AppColors.posturePoor, label: 'Poor'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierSegment extends StatelessWidget {
  final int seconds;
  final int total;
  final Color color;
  
  const _TierSegment({
    required this.seconds,
    required this.total,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? seconds / total : 0.0;
    if (fraction == 0) return const SizedBox.shrink();
    
    return Expanded(
      flex: (fraction * 1000).round(),
      child: Container(color: color),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _PauseReasonBanner extends StatelessWidget {
  final PauseReason reason;

  const _PauseReasonBanner({required this.reason});

  @override
  Widget build(BuildContext context) {
    final String icon;
    final String message;
    final Color color;

    switch (reason) {
      case PauseReason.phoneCall:
        icon = '📞';
        message = 'Paused - Phone call detected';
        color = Colors.blue;
        break;
      case PauseReason.pocket:
        icon = '👖';
        message = 'Paused - Phone in pocket';
        color = Colors.purple;
        break;
      case PauseReason.stationary:
        icon = '⏸️';
        message = 'Paused - No movement detected';
        color = Colors.orange;
        break;
      case PauseReason.manual:
        icon = '⏸️';
        message = 'Paused';
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
