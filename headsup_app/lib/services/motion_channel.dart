/// Flutter platform channel for accessing native iOS CMDeviceMotion
/// Provides fused sensor data (pitch, roll, yaw) for accurate posture tracking
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Data from CMDeviceMotion sensor fusion
class MotionData {
  final double pitch;     // Forward/backward tilt (degrees)
  final double roll;      // Left/right tilt (degrees)
  final double yaw;       // Compass direction (degrees)
  final double gravityX;
  final double gravityY;
  final double gravityZ;
  final double accelerationMagnitude;
  final double timestamp;
  
  MotionData({
    required this.pitch,
    required this.roll,
    required this.yaw,
    required this.gravityX,
    required this.gravityY,
    required this.gravityZ,
    required this.accelerationMagnitude,
    required this.timestamp,
  });
  
  factory MotionData.fromMap(Map<dynamic, dynamic> map) {
    return MotionData(
      pitch: (map['pitch'] as num?)?.toDouble() ?? 0.0,
      roll: (map['roll'] as num?)?.toDouble() ?? 0.0,
      yaw: (map['yaw'] as num?)?.toDouble() ?? 0.0,
      gravityX: (map['gravityX'] as num?)?.toDouble() ?? 0.0,
      gravityY: (map['gravityY'] as num?)?.toDouble() ?? 0.0,
      gravityZ: (map['gravityZ'] as num?)?.toDouble() ?? 0.0,
      accelerationMagnitude: (map['accelerationMagnitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: (map['timestamp'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  /// Calculate 3D tilt angle from vertical
  /// 0° = vertical, 90° = horizontal
  double get tiltAngle {
    return (pitch.abs().clamp(0, 90) + roll.abs().clamp(0, 90)) / 2;
    // Simplified: average of pitch and roll for tilt estimation
    // More accurate would be: sqrt(pitch² + roll²) but capped appropriately
  }
  
  /// Calculate accurate 3D tilt using Pythagorean formula
  double get tiltAngle3D {
    final pitchClamped = pitch.abs().clamp(0, 90);
    final rollClamped = roll.abs().clamp(0, 90);
    return (pitchClamped * pitchClamped + rollClamped * rollClamped).clamp(0, 8100).toDouble();
  }
  
  /// Check if phone is face down
  bool get isFaceDown {
    return gravityZ > 0.8; // Z pointing up means screen facing down
  }
  
  /// Check if phone is in landscape orientation
  bool get isLandscape {
    return roll.abs() > 60; // Roll > 60° indicates landscape
  }
  
  /// Check if phone is relatively still (not being moved around)
  bool get isStationary {
    return accelerationMagnitude < 0.1;
  }
}

/// Service for accessing CMDeviceMotion via platform channel
class MotionChannel {
  static const MethodChannel _methodChannel = MethodChannel('com.headsup/motion');
  static const EventChannel _eventChannel = EventChannel('com.headsup/motion_stream');
  
  static MotionChannel? _instance;
  
  MotionChannel._();
  
  static MotionChannel get instance {
    _instance ??= MotionChannel._();
    return _instance!;
  }
  
  StreamSubscription? _subscription;
  final _motionController = StreamController<MotionData>.broadcast();
  
  /// Stream of motion data updates
  Stream<MotionData> get motionStream => _motionController.stream;
  
  /// Check if device motion is available
  Future<bool> isAvailable() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isDeviceMotionAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
  
  /// Start receiving motion updates
  /// [intervalSeconds] - How often to sample (default 0.2 = 5Hz)
  Future<void> startUpdates({double intervalSeconds = 0.2}) async {
    try {
      await _methodChannel.invokeMethod('startMotionUpdates', {
        'interval': intervalSeconds,
      });
      
      _subscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            final motionData = MotionData.fromMap(event);
            _motionController.add(motionData);
          }
        },
        onError: (error) {
          _motionController.addError(error);
        },
      );
    } catch (e) {
      _motionController.addError(e);
    }
  }
  
  /// Stop listening to motion updates
  Future<void> stopMotionUpdates() async {
    try {
      await _subscription?.cancel(); // Keep subscription cancellation
      _subscription = null;
      await _methodChannel.invokeMethod('stopMotionUpdates');
    } catch (e) {
      debugPrint('Error stopping motion updates: $e');
    }
  }

  /// Trigger device vibration (works in background on iOS)
  Future<void> vibrate() async {
    try {
      await _methodChannel.invokeMethod('vibrate');
    } catch (e) {
      debugPrint('Error triggering vibration: $e');
    }
  }
  
  /// Dispose resources
  void dispose() {
    stopMotionUpdates();
    _motionController.close();
  }
}
