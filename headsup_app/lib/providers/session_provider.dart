/// Session provider for managing tracking state
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session.dart';
import '../models/daily_summary.dart';
import '../services/supabase_service.dart';
import '../services/posture_service.dart';
import '../utils/constants.dart';

/// Current session state
class SessionState {
  final Session? currentSession;
  final bool isTracking;
  final bool isPaused;
  final int elapsedSeconds;
  final int goodSeconds;
  final int poorSeconds;
  final double currentAngle;
  final PostureState postureState;
  final List<double> angleHistory;
  
  const SessionState({
    this.currentSession,
    this.isTracking = false,
    this.isPaused = false,
    this.elapsedSeconds = 0,
    this.goodSeconds = 0,
    this.poorSeconds = 0,
    this.currentAngle = 0,
    this.postureState = PostureState.good,
    this.angleHistory = const [],
  });
  
  SessionState copyWith({
    Session? currentSession,
    bool? isTracking,
    bool? isPaused,
    int? elapsedSeconds,
    int? goodSeconds,
    int? poorSeconds,
    double? currentAngle,
    PostureState? postureState,
    List<double>? angleHistory,
  }) {
    return SessionState(
      currentSession: currentSession ?? this.currentSession,
      isTracking: isTracking ?? this.isTracking,
      isPaused: isPaused ?? this.isPaused,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      goodSeconds: goodSeconds ?? this.goodSeconds,
      poorSeconds: poorSeconds ?? this.poorSeconds,
      currentAngle: currentAngle ?? this.currentAngle,
      postureState: postureState ?? this.postureState,
      angleHistory: angleHistory ?? this.angleHistory,
    );
  }
  
  /// Calculate current posture score
  int get currentScore {
    final total = goodSeconds + poorSeconds;
    if (total == 0) return 0;
    return ((goodSeconds / total) * 100).round().clamp(0, 100);
  }
  
  /// Format elapsed time as timer display
  String get timerDisplay {
    final hours = elapsedSeconds ~/ 3600;
    final minutes = (elapsedSeconds % 3600) ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Session notifier for managing tracking
class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier() : super(const SessionState());
  
  Timer? _timer;
  Timer? _sensorTimer;
  StreamSubscription? _angleSubscription;
  final PostureService _postureService = PostureService.instance;
  
  /// Start a new tracking session
  Future<void> startSession() async {
    if (state.isTracking) return;
    
    final session = Session(
      startTime: DateTime.now(),
    );
    
    state = state.copyWith(
      currentSession: session,
      isTracking: true,
      isPaused: false,
      elapsedSeconds: 0,
      goodSeconds: 0,
      poorSeconds: 0,
      angleHistory: [],
    );
    
    // Start timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isPaused) {
        _tick();
      }
    });
    
    // Start sensor listening (now async with CMDeviceMotion)
    await _postureService.startListening(
      intervalSeconds: AppConstants.sensorSampleIntervalSeconds.toDouble() / 1000,
    );
    
    // Listen to angle updates
    _angleSubscription = _postureService.angleStream.listen(_onAngleUpdate);
  }
  
  /// Pause the current session
  void pauseSession() {
    if (!state.isTracking || state.isPaused) return;
    state = state.copyWith(isPaused: true);
  }
  
  /// Resume the current session
  void resumeSession() {
    if (!state.isTracking || !state.isPaused) return;
    state = state.copyWith(isPaused: false);
  }
  
  /// End the current session
  Future<Session?> endSession() async {
    if (!state.isTracking) return null;
    
    _timer?.cancel();
    _sensorTimer?.cancel();
    _angleSubscription?.cancel();
    await _postureService.stopListening();
    
    final session = state.currentSession?.copyWith(
      endTime: DateTime.now(),
      durationSeconds: state.elapsedSeconds,
      goodPostureSeconds: state.goodSeconds,
      poorPostureSeconds: state.poorSeconds,
      averageAngle: _calculateAverageAngle(),
      postureScore: state.currentScore,
    );
    
    if (session != null) {
      // Save to Supabase
      await SupabaseService.instance.saveSession(session);
      
      // Update daily summary
      await SupabaseService.instance.updateDailySummaryFromSessions(DateTime.now());
    }
    
    final completedSession = session;
    
    state = const SessionState();
    
    return completedSession;
  }
  
  /// Handle timer tick
  void _tick() {
    final isGoodPosture = _postureService.isGoodPosture();
    
    state = state.copyWith(
      elapsedSeconds: state.elapsedSeconds + 1,
      goodSeconds: isGoodPosture ? state.goodSeconds + 1 : state.goodSeconds,
      poorSeconds: isGoodPosture ? state.poorSeconds : state.poorSeconds + 1,
    );
  }
  
  /// Handle angle update from sensor
  void _onAngleUpdate(double angle) {
    final newHistory = [...state.angleHistory, angle];
    // Keep last 100 readings for history
    if (newHistory.length > 100) {
      newHistory.removeAt(0);
    }
    
    state = state.copyWith(
      currentAngle: angle,
      postureState: PostureState.fromAngle(angle),
      angleHistory: newHistory,
    );
  }
  
  /// Calculate average angle from history
  double _calculateAverageAngle() {
    if (state.angleHistory.isEmpty) return 0;
    return state.angleHistory.reduce((a, b) => a + b) / state.angleHistory.length;
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _sensorTimer?.cancel();
    _angleSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for session state
final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier();
});

/// Provider for today's summary
final todaySummaryProvider = FutureProvider<DailySummary?>((ref) async {
  return SupabaseService.instance.getDailySummary(DateTime.now());
});

/// Provider for recent sessions
final recentSessionsProvider = FutureProvider<List<Session>>((ref) async {
  return SupabaseService.instance.getTodaySessions();
});

/// Provider for last 7 days summaries
final recentSummariesProvider = FutureProvider<List<DailySummary>>((ref) async {
  return SupabaseService.instance.getRecentSummaries();
});
