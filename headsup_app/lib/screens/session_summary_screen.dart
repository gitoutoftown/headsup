/// Session summary screen - Post-session stats display
library;

import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/session.dart';
import '../utils/constants.dart';
import '../widgets/character/posture_character_svg.dart';
import '../widgets/common/widgets.dart';

class SessionSummaryScreen extends StatelessWidget {
  final Session session;
  
  const SessionSummaryScreen({
    super.key,
    required this.session,
  });
  
  @override
  Widget build(BuildContext context) {
    final characterState = PostureState.fromScore(session.postureScore);

    // Derive angle from session's average angle or score
    final displayAngle = session.averageAngle > 0
        ? session.averageAngle
        : (session.postureScore >= 95 ? 10.0 :
           session.postureScore >= 80 ? 20.0 :
           session.postureScore >= 55 ? 30.0 :
           session.postureScore >= 25 ? 50.0 : 70.0);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              
              // Title
              Text(
                'Session Complete',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              
              const SizedBox(height: AppSpacing.xl),

              // Character
              PostureCharacterSvg(
                state: characterState,
                currentAngle: displayAngle,
                size: MediaQuery.of(context).size.width * 0.35,
              ),

              const SizedBox(height: AppSpacing.lg),
              
              // Score
              Text(
                '${session.postureScore}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: _getScoreColor(session.postureScore),
                ),
              ),
              Text(
                'Session Score',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Stats cards
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      value: session.formattedDuration,
                      label: 'Duration',
                      icon: Icons.timer_outlined,
                      iconColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: StatCard(
                      value: '${_calculateGoodPercentage()}%',
                      label: 'Good Posture',
                      icon: Icons.check_circle_outline,
                      iconColor: AppColors.postureGood,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Average angle card
              StatCard(
                value: '${session.averageAngle.round()}°',
                label: 'Average Angle',
                icon: Icons.straighten_outlined,
                iconColor: AppColors.postureFair,
              ),
              
              const Spacer(),
              
              // Done button
              PrimaryButton(
                text: 'Done',
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
              
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
  
  int _calculateGoodPercentage() {
    final total = session.goodPostureSeconds + session.poorPostureSeconds;
    if (total == 0) return 0;
    return ((session.goodPostureSeconds / total) * 100).round();
  }
  
  Color _getScoreColor(int score) {
    if (score >= 70) return AppColors.postureGood;
    if (score >= 40) return AppColors.postureFair;
    return AppColors.posturePoor;
  }
}
