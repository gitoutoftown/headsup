/// Flutter platform channel for Live Activity (Dynamic Island)
library;

import 'package:flutter/services.dart';

class LiveActivityChannel {
  static const MethodChannel _channel = MethodChannel('com.headsup.live_activity');
  
  static bool _isActive = false;
  static DateTime? _lastUpdate;
  static const _throttleDuration = Duration(milliseconds: 500);
  
  /// Check if Live Activity is supported (iOS 16.1+)
  static Future<bool> isSupported() async {
    try {
      await _channel.invokeMethod('isSupported');
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Start Live Activity when session begins
  static Future<bool> start({
    required String sessionId,
    required String currentState,
    required int totalPoints,
    required int pointsPerMinute,
    required double angle,
    bool isPaused = false,
  }) async {
    if (!await isSupported()) return false;
    
    // Check throttle
    final now = DateTime.now();
    if (_lastUpdate != null && now.difference(_lastUpdate!) < _throttleDuration) {
      return false;
    }
    _lastUpdate = now;
    
    try {
      final result = await _channel.invokeMethod<bool>('startLiveActivity', {
        'sessionId': sessionId,
        'currentState': currentState,
        'totalPoints': totalPoints,
        'pointsPerMinute': pointsPerMinute,
        'angle': angle,
        'isPaused': isPaused,
      });
      
      _isActive = result ?? false;
      if (_isActive) {
        print('✅ Live Activity started - Dynamic Island active');
      }
      return _isActive;
    } catch (e) {
      print('❌ Failed to start Live Activity: $e');
      return false;
    }
  }
  
  /// Update Live Activity state (throttled to avoid spam)
  static Future<bool> update({
    required int elapsedSeconds,
    required String currentState,
    required int totalPoints,
    required int pointsPerMinute,
    required double angle,
    bool isPaused = false,
  }) async {
    if (!_isActive) return false;
    
    // Check throttle
    final now = DateTime.now();
    if (_lastUpdate != null && now.difference(_lastUpdate!) < _throttleDuration) {
      return true; // Skip this update
    }
    _lastUpdate = now;
    
    try {
      final result = await _channel.invokeMethod<bool>('updateLiveActivity', {
        'elapsedSeconds': elapsedSeconds,
        'currentState': currentState,
        'totalPoints': totalPoints,
        'pointsPerMinute': pointsPerMinute,
        'angle': angle,
        'isPaused': isPaused,
      });
      
      _lastUpdate = now;
      return result ?? false;
    } catch (e) {
      print('❌ Failed to update Live Activity: $e');
      return false;
    }
  }
  
  /// End Live Activity when session ends
  static Future<bool> end() async {
    if (!_isActive) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('endLiveActivity');
      _isActive = false;
      _lastUpdate = null;
      
      if (result ?? false) {
        print('✅ Live Activity ended - Dynamic Island dismissed');
      }
      return result ?? false;
    } catch (e) {
      print('❌ Failed to end Live Activity: $e');
      _isActive = false;
      return false;
    }
  }
  
  /// Check if Live Activity is currently active
  static bool get isActive => _isActive;
}
