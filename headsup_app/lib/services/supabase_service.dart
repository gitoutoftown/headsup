/// Supabase service for database operations
library;

import '../config/supabase_config.dart';
import '../models/session.dart';
import '../models/daily_summary.dart';
import '../models/user_settings.dart';

class SupabaseService {
  static SupabaseService? _instance;
  
  SupabaseService._();
  
  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }
  
  // ============== Sessions ==============
  
  /// Save a new session or update existing
  Future<void> saveSession(Session session) async {
    await SupabaseConfig.client
        .from('sessions')
        .upsert(session.toJson());
  }
  
  /// Get sessions for date range
  Future<List<Session>> getSessionsForDateRange(
    DateTime start, 
    DateTime end,
  ) async {
    final response = await SupabaseConfig.client
        .from('sessions')
        .select()
        .gte('start_time', start.toIso8601String())
        .lte('start_time', end.toIso8601String())
        .order('start_time', ascending: false);
    
    return (response as List)
        .map((json) => Session.fromJson(json))
        .toList();
  }
  
  /// Get sessions for today
  Future<List<Session>> getTodaySessions() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 6); // Reset at 6 AM
    final adjustedStart = now.hour < 6 
        ? startOfDay.subtract(const Duration(days: 1))
        : startOfDay;
    
    return getSessionsForDateRange(adjustedStart, now);
  }
  
  /// Get last 7 days of sessions
  Future<List<Session>> getRecentSessions() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return getSessionsForDateRange(weekAgo, now);
  }
  
  /// Delete a session
  Future<void> deleteSession(String sessionId) async {
    await SupabaseConfig.client
        .from('sessions')
        .delete()
        .eq('id', sessionId);
  }
  
  // ============== Daily Summaries ==============
  
  /// Save or update daily summary
  Future<void> saveDailySummary(DailySummary summary) async {
    await SupabaseConfig.client
        .from('daily_summaries')
        .upsert(summary.toJson());
  }
  
  /// Get daily summary for a specific date
  Future<DailySummary?> getDailySummary(DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    final response = await SupabaseConfig.client
        .from('daily_summaries')
        .select()
        .eq('date', dateStr)
        .maybeSingle();
    
    if (response == null) return null;
    return DailySummary.fromJson(response);
  }
  
  /// Get last 7 days of summaries
  Future<List<DailySummary>> getRecentSummaries() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekAgoStr = '${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}';
    
    final response = await SupabaseConfig.client
        .from('daily_summaries')
        .select()
        .gte('date', weekAgoStr)
        .order('date', ascending: false);
    
    return (response as List)
        .map((json) => DailySummary.fromJson(json))
        .toList();
  }
  
  // ============== User Settings ==============
  
  /// Get user settings
  Future<UserSettings?> getUserSettings(String userId) async {
    final response = await SupabaseConfig.client
        .from('user_settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    
    if (response == null) return null;
    return UserSettings.fromJson(response);
  }
  
  /// Save user settings
  Future<void> saveUserSettings(UserSettings settings) async {
    await SupabaseConfig.client
        .from('user_settings')
        .upsert(settings.toJson());
  }
  
  // ============== Aggregations ==============
  
  /// Calculate and update daily summary from sessions
  Future<DailySummary> updateDailySummaryFromSessions(DateTime date) async {
    final sessions = await getSessionsForDateRange(
      DateTime(date.year, date.month, date.day),
      DateTime(date.year, date.month, date.day, 23, 59, 59),
    );
    
    int totalSeconds = 0;
    int totalGoodSeconds = 0;
    
    for (final session in sessions) {
      totalSeconds += session.durationSeconds;
      totalGoodSeconds += session.goodPostureSeconds;
    }
    
    final score = totalSeconds > 0 
        ? ((totalGoodSeconds / totalSeconds) * 100).round()
        : 0;
    
    final summary = DailySummary(
      date: date,
      totalTrackedSeconds: totalSeconds,
      dailyPostureScore: score,
      sessionCount: sessions.length,
    );
    
    await saveDailySummary(summary);
    return summary;
  }
}
