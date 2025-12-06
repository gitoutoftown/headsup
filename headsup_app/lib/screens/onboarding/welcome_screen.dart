/// Onboarding welcome screen
library;

import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../widgets/character/posture_character.dart';
import '../../widgets/common/widgets.dart';
import '../../utils/constants.dart';
import 'permissions_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            children: [
              const Spacer(),
              
              // Character illustration
              const PostureCharacter(
                state: PostureState.good,
                size: 150,
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Welcome text
              Text(
                'Welcome to HeadsUp',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              Text(
                'Build better posture habits with gentle awareness. Our friendly character reflects your posture throughout the day.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              // Features list
              _FeatureItem(
                icon: Icons.track_changes_rounded,
                title: 'Continuous Tracking',
                description: 'Works in the background while you use other apps',
              ),
              const SizedBox(height: AppSpacing.md),
              _FeatureItem(
                icon: Icons.person_outline_rounded,
                title: 'Visual Feedback',
                description: 'Character mirrors your posture in real-time',
              ),
              const SizedBox(height: AppSpacing.md),
              _FeatureItem(
                icon: Icons.notifications_off_rounded,
                title: 'Gentle Reminders',
                description: 'No nagging alerts, just subtle awareness',
              ),
              
              const Spacer(),
              
              // Continue button
              PrimaryButton(
                text: 'Continue',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PermissionsScreen(),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
