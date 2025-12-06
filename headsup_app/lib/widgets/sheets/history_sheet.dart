/// History bottom sheet - Last 7 days of sessions
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../providers/session_provider.dart';

class HistorySheet extends ConsumerWidget {
  const HistorySheet({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(recentSummariesProvider);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: AppRadius.sheetRadius,
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: AppSpacing.pagePadding,
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    
                    // Title
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'History',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Last 7 days',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // List
              Expanded(
                child: summaries.when(
                  data: (data) {
                    if (data.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_outlined,
                              size: 48,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No tracking history yet',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Start a session to see your progress',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      itemCount: data.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final summary = data[index];
                        final isToday = _isToday(summary.date);
                        
                        return Container(
                          padding: AppSpacing.cardPadding,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: AppRadius.cardRadius,
                            boxShadow: AppShadows.card,
                          ),
                          child: Row(
                            children: [
                              // Date
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isToday ? 'Today' : DateFormat('EEE, MMM d').format(summary.date),
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    Text(
                                      '${summary.sessionCount} ${summary.sessionCount == 1 ? 'session' : 'sessions'}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Time
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      summary.formattedTime,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    Text(
                                      'tracked',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(width: AppSpacing.md),
                              
                              // Score
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _getScoreColor(summary.dailyPostureScore).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '${summary.dailyPostureScore}',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: _getScoreColor(summary.dailyPostureScore),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => Center(
                    child: Text('Error loading history: $error'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  Color _getScoreColor(int score) {
    if (score >= 70) return AppColors.postureGood;
    if (score >= 40) return AppColors.postureFair;
    return AppColors.posturePoor;
  }
}
