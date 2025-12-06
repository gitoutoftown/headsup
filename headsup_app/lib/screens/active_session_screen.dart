/// Active session screen - Real-time tracking display
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../providers/session_provider.dart';
import '../widgets/character/posture_character.dart';
import '../widgets/common/widgets.dart';
import 'session_summary_screen.dart';

class ActiveSessionScreen extends ConsumerWidget {
  const ActiveSessionScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            children: [
              // Top spacer
              const SizedBox(height: AppSpacing.lg),
              
              // Character (40% of screen)
              Expanded(
                flex: 4,
                child: Center(
                  child: PostureCharacter(
                    state: sessionState.postureState,
                    size: MediaQuery.of(context).size.width * 0.4,
                  ),
                ),
              ),
              
              // Angle display
              AngleGauge(
                angle: sessionState.currentAngle,
                size: MediaQuery.of(context).size.width * 0.4,
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
              
              // Good/Poor progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: PostureProgressBar(
                  goodSeconds: sessionState.goodSeconds,
                  poorSeconds: sessionState.poorSeconds,
                ),
              ),
              
              const Spacer(),
              
              // Current score
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${sessionState.currentScore}',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Current Score',
                    style: Theme.of(context).textTheme.bodySmall,
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
