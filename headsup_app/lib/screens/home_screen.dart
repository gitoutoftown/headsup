/// Home screen - Main app screen with character and start button
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../providers/session_provider.dart';
import '../utils/constants.dart';
import '../widgets/character/posture_character.dart';
import '../widgets/common/widgets.dart';
import '../widgets/sheets/settings_sheet.dart';
import '../widgets/sheets/history_sheet.dart';
import 'active_session_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaySummary = ref.watch(todaySummaryProvider);
    
    // Calculate today's stats from sessions
    final todayScore = todaySummary.when(
      data: (summary) => summary?.dailyPostureScore ?? 0,
      loading: () => 0,
      error: (_, __) => 0,
    );
    
    final todayTime = todaySummary.when(
      data: (summary) => summary?.formattedTime ?? '0m',
      loading: () => '0m',
      error: (_, __) => '0m',
    );
    
    // Determine character state from today's score
    final characterState = PostureState.fromScore(todayScore);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            children: [
              // Top bar with settings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // History button
                  IconButton(
                    icon: const Icon(Icons.history_rounded),
                    onPressed: () => _showHistory(context),
                  ),
                  // Settings button
                  IconButton(
                    icon: const Icon(Icons.settings_rounded),
                    onPressed: () => _showSettings(context),
                  ),
                ],
              ),
              
              // Spacer
              const Spacer(),
              
              // Character (60% of remaining space)
              Expanded(
                flex: 6,
                child: Center(
                  child: PostureCharacter(
                    state: characterState,
                    size: MediaQuery.of(context).size.width * 0.5,
                  ),
                ),
              ),
              
              // Score display
              Text(
                '$todayScore',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Posture Score',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Time tracked
              Text(
                '$todayTime tracked today',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              
              const Spacer(),
              
              // Start tracking button
              PrimaryButton(
                text: 'Start Tracking',
                icon: Icons.play_arrow_rounded,
                onPressed: () => _startTracking(context, ref),
              ),
              
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
  
  void _startTracking(BuildContext context, WidgetRef ref) {
    ref.read(sessionProvider.notifier).startSession();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ActiveSessionScreen(),
      ),
    );
  }
  
  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const SettingsSheet(),
    );
  }
  
  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const HistorySheet(),
    );
  }
}
