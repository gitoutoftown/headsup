/// Session provider for managing tracking state
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session.dart';
import '../models/daily_summary.dart';
import '../services/supabase_service.dart';
import '../services/posture_service.dart';
import '../services/live_activity_channel.dart';
import '../services/motion_channel.dart';
import '../utils/constants.dart';

/// Current session state
class SessionState {
  final Session? currentSession;
  final bool isTracking;
  final bool isPaused;
  final int elapsedSeconds;
  final int totalPoints;  // Accumulated points (additive only - never decreases)
  final int excellentSeconds;
  final int goodSeconds;
  final int okaySeconds;
  final int badSeconds;
  final int poorSeconds;
  final double currentAngle;
  final PostureState postureState;
  final List<double> angleHistory;
  
  const SessionState({
    this.currentSession,
    this.isTracking = false,
    this.isPaused = false,
    this.elapsedSeconds = 0,
    this.totalPoints = 0,
    this.excellentSeconds = 0,
    this.goodSeconds = 0,
    this.okaySeconds = 0,
    this.badSeconds = 0,
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
    int? totalPoints,
    int? excellentSeconds,
    int? goodSeconds,
    int? okaySeconds,
    int? badSeconds,
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
      totalPoints: totalPoints ?? this.totalPoints,
      excellentSeconds: excellentSeconds ?? this.excellentSeconds,
      goodSeconds: goodSeconds ?? this.goodSeconds,
      okaySeconds: okaySeconds ?? this.okaySeconds,
      badSeconds: badSeconds ?? this.badSeconds,
      poorSeconds: poorSeconds ?? this.poorSeconds,
      currentAngle: currentAngle ?? this.currentAngle,
      postureState: postureState ?? this.postureState,
      angleHistory: angleHistory ?? this.angleHistory,
    );
  }
  
  /// Current score is just the total accumulated points
  /// Points are ONLY added, never subtracted:
  /// - Excellent: +5/min, Good: +3/min, Okay: +1/min, Bad/Poor: +0/min
  int get currentScore => totalPoints;
  
  /// Calculate a "posture quality" percentage for display
  /// This shows what % of time was spent in good+ posture
  int get postureQuality {
    final goodTotal = excellentSeconds + goodSeconds + okaySeconds;
    final total = elapsedSeconds;
    if (total == 0) return 100;
    return ((goodTotal / total) * 100).round().clamp(0, 100);
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
  final _postureService = PostureService.instance;
  final _motionChannel = MotionChannel.instance;
  
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
      totalPoints: 0,
      excellentSeconds: 0,
      goodSeconds: 0,
      okaySeconds: 0,
      badSeconds: 0,
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
    
    // Start Live Activity for Dynamic Island
    await LiveActivityChannel.start(
      sessionId: session.id,
      currentState: state.postureState.name,
      totalPoints: 0,
      pointsPerMinute: state.postureState.pointsPerMinute,
      angle: 0,
    );
  }
  
  /// Pause the current session
  void pauseSession() {
    if (!state.isTracking || state.isPaused) return;
    _hapticTimer?.cancel();
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
    _hapticTimer?.cancel();
    await _postureService.stopListening();
    
    // End Live Activity
    await LiveActivityChannel.end();
    
    // Calculate good posture seconds as excellent + good + okay
    final goodPostureTotal = state.excellentSeconds + state.goodSeconds + state.okaySeconds;
    final poorPostureTotal = state.badSeconds + state.poorSeconds;
    
    final session = state.currentSession?.copyWith(
      endTime: DateTime.now(),
      durationSeconds: state.elapsedSeconds,
      goodPostureSeconds: goodPostureTotal,
      poorPostureSeconds: poorPostureTotal,
      averageAngle: _calculateAverageAngle(),
      postureScore: state.postureQuality,  // Store quality % in DB
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
  
  /// Handle timer tick - award points based on posture state
  void _tick() {
    final currentState = state.postureState;
    
    // For smoother accumulation, add points every minute
    // But track seconds for each tier
    final newElapsed = state.elapsedSeconds + 1;
    
    // Add points every minute based on average state
    int newPoints = state.totalPoints;
    if (newElapsed % 60 == 0) {
      // At each minute mark, add points based on dominant posture
      newPoints += currentState.pointsPerMinute;
    }
    
    // Update tier-specific seconds
    state = state.copyWith(
      elapsedSeconds: newElapsed,
      totalPoints: newPoints,
      excellentSeconds: currentState == PostureState.excellent 
          ? state.excellentSeconds + 1 
          : state.excellentSeconds,
      goodSeconds: currentState == PostureState.good 
          ? state.goodSeconds + 1 
          : state.goodSeconds,
      okaySeconds: currentState == PostureState.okay 
          ? state.okaySeconds + 1 
          : state.okaySeconds,
      badSeconds: currentState == PostureState.bad 
          ? state.badSeconds + 1 
          : state.badSeconds,
      poorSeconds: currentState == PostureState.poor 
          ? state.poorSeconds + 1 
          : state.poorSeconds,
    );
    
    // Update Live Activity
    LiveActivityChannel.update(
      elapsedSeconds: newElapsed,
      currentState: currentState.name,
      totalPoints: newPoints,
      pointsPerMinute: currentState.pointsPerMinute,
      angle: state.currentAngle,
    );
  }
  
  /// Handle angle update from sensor
  void _onAngleUpdate(double angle) {
    final newHistory = [...state.angleHistory, angle];
    // Keep last 100 readings for history
    if (newHistory.length > 100) {
      newHistory.removeAt(0);
    }
    
    final newPostureState = PostureState.fromAngle(angle);
    
    // Check for state change and trigger haptics
    if (newPostureState != state.postureState) {
      _handleHapticFeedback(state.postureState, newPostureState);
    }
    
    state = state.copyWith(
      currentAngle: angle,
      postureState: newPostureState,
      angleHistory: newHistory,
    );
  }
  
  Timer? _hapticTimer;

  /// Trigger haptic feedback on state transition
  Future<void> _handleHapticFeedback(PostureState oldState, PostureState newState) async {
    // Only trigger if alerts are enabled globally
    final prefs = await SharedPreferences.getInstance();
    final alertsEnabled = prefs.getBool('alertsEnabled') ?? true;
    if (!alertsEnabled) {
      _hapticTimer?.cancel();
      return;
    }
    
    // Check specific settings
    final vibrateOnBad = prefs.getBool('vibrateOnBadPosture') ?? true;
    final vibrateOnPoor = prefs.getBool('vibrateOnPoorPosture') ?? true;
    final patternName = prefs.getString('hapticPattern');
    
    bool shouldVibrate = false;
    
    // Transition to Bad
    if (newState == PostureState.bad && vibrateOnBad) {
      if (oldState != PostureState.bad && oldState != PostureState.poor) {
        shouldVibrate = true;
      } else if (oldState == PostureState.poor) {
        // Improving from Poor to Bad - maybe don't vibrate? Or vibrate less?
        // For now, let's treat it as "still bad" but maybe stop continuous if it was poor?
        // Actually, if continuous is on, it should keep going if Bad is also enabled.
      }
    }
    
    // Transition to Poor
    if (newState == PostureState.poor && vibrateOnPoor) {
      if (oldState != PostureState.poor) {
        shouldVibrate = true;
      }
    }
    
    // Stop continuous timer if we are back to good/okay
    if (newState == PostureState.excellent || newState == PostureState.good || newState == PostureState.okay) {
      _hapticTimer?.cancel();
    } else if (shouldVibrate) {
      // Start vibration pattern
      _triggerHapticPattern(patternName);
    }
  }
  
  void _triggerHapticPattern(String? patternName) {
    _hapticTimer?.cancel();
    
    if (patternName == 'continuous') {
      // Vibrate immediately, then every 2 seconds
      _vibrate();
      _hapticTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
        // Double check if alerts are still enabled
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getBool('alertsEnabled') == false) {
          _hapticTimer?.cancel();
          return;
        }
        _vibrate();
      });
    } else if (patternName == 'double') {
      _vibrate();
      Future.delayed(const Duration(milliseconds: 300), _vibrate);
    } else if (patternName == 'triple') {
      _vibrate();
      Future.delayed(const Duration(milliseconds: 300), () {
        _vibrate();
        Future.delayed(const Duration(milliseconds: 300), _vibrate);
      });
    } else {
      // Single (default)
      _vibrate();
    }
  }
  
  Future<void> _vibrate() async {
    // Use MotionChannel for background-capable vibration
    await _motionChannel.vibrate();
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
    _hapticTimer?.cancel();
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
