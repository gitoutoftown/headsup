/// Posture service for angle calculation and state management
/// Uses CMDeviceMotion via platform channel for accurate sensor fusion
library;

import 'dart:async';
import 'dart:math' as math;

import 'motion_channel.dart';
import '../utils/constants.dart';

class PostureService {
  static PostureService? _instance;
  
  PostureService._();
  
  static PostureService get instance {
    _instance ??= PostureService._();
    return _instance!;
  }
  
  final MotionChannel _motionChannel = MotionChannel.instance;
  StreamSubscription<MotionData>? _motionSubscription;
  
  final _angleController = StreamController<double>.broadcast();
  final _stateController = StreamController<PostureState>.broadcast();
  final _contextController = StreamController<PostureContext>.broadcast();
  
  double _currentAngle = 0;
  PostureState _currentState = PostureState.good;
  PostureContext _currentContext = PostureContext.normal;
  
  // Moving average filter
  final List<double> _angleBuffer = [];
  static const int _bufferSize = 5;
  
  // Outlier rejection
  double? _previousAngle;
  static const double _maxInstantChange = 30.0; // degrees
  
  // Temporal smoothing
  DateTime? _poorPostureStart;
  static const Duration _poorPostureThreshold = Duration(seconds: 5);
  bool _sustainedPoorPosture = false;
  
  // Context detection
  int _faceDownCount = 0;
  int _landscapeCount = 0;
  static const int _contextThreshold = 10; // readings before triggering
  
  /// Stream of current angle in degrees (filtered)
  Stream<double> get angleStream => _angleController.stream;
  
  /// Stream of current posture state
  Stream<PostureState> get stateStream => _stateController.stream;
  
  /// Stream of context changes (face-down, landscape, etc.)
  Stream<PostureContext> get contextStream => _contextController.stream;
  
  /// Current angle
  double get currentAngle => _currentAngle;
  
  /// Current state
  PostureState get currentState => _currentState;
  
  /// Current context
  PostureContext get currentContext => _currentContext;
  
  /// Is currently in sustained poor posture
  bool get isSustainedPoorPosture => _sustainedPoorPosture;
  
  /// Check if device motion is available
  Future<bool> isDeviceMotionAvailable() async {
    return await _motionChannel.isAvailable();
  }
  
  /// Start listening to sensors
  Future<void> startListening({double intervalSeconds = 0.2}) async {
    await _motionSubscription?.cancel();
    
    // Clear buffers
    _angleBuffer.clear();
    _previousAngle = null;
    _poorPostureStart = null;
    _sustainedPoorPosture = false;
    _faceDownCount = 0;
    _landscapeCount = 0;
    
    // Start motion updates from native iOS
    await _motionChannel.startUpdates(intervalSeconds: intervalSeconds);
    
    _motionSubscription = _motionChannel.motionStream.listen(
      _processMotionData,
      onError: (error) {
        _angleController.addError(error);
      },
    );
  }
  
  /// Stop listening to sensors
  Future<void> stopListening() async {
    await _motionSubscription?.cancel();
    _motionSubscription = null;
    await _motionChannel.stopUpdates();
  }
  
  /// Process motion data from CMDeviceMotion
  void _processMotionData(MotionData data) {
    // 1. Context detection
    _detectContext(data);
    
    // If in auto-pause context, don't process angles
    if (_currentContext == PostureContext.faceDown ||
        _currentContext == PostureContext.autoPaused) {
      return;
    }
    
    // 2. Calculate 3D tilt angle
    double rawAngle = _calculate3DTiltAngle(data.pitch, data.roll);
    
    // Adjust for landscape mode
    if (_currentContext == PostureContext.landscape) {
      rawAngle = math.max(0, rawAngle - 20); // More lenient in landscape
    }
    
    // 3. Outlier rejection
    if (!_isValidReading(rawAngle)) {
      return; // Reject this reading
    }
    
    // 4. Moving average filter
    double smoothedAngle = _applyMovingAverage(rawAngle);
    
    // 5. Update current angle
    _previousAngle = smoothedAngle;
    _updateAngle(smoothedAngle);
    
    // 6. Temporal smoothing for state changes
    _applyTemporalSmoothing();
  }
  
  /// Calculate 3D tilt angle from pitch and roll
  double _calculate3DTiltAngle(double pitch, double roll) {
    // Convert to absolute values (we care about magnitude, not direction)
    final pitchAbs = pitch.abs();
    final rollAbs = roll.abs();
    
    // Pythagorean formula for combined tilt
    // sqrt(pitch² + roll²) gives total tilt from vertical
    final tiltAngle = math.sqrt(pitchAbs * pitchAbs + rollAbs * rollAbs);
    
    // Clamp to reasonable range
    return tiltAngle.clamp(0, 90);
  }
  
  /// Check if reading is valid (outlier rejection)
  bool _isValidReading(double angle) {
    // Rule 1: Reject physically impossible angles
    if (angle > 95) {
      return false;
    }
    
    // Rule 2: Reject instant large changes (likely drops or gestures)
    if (_previousAngle != null) {
      final change = (angle - _previousAngle!).abs();
      if (change > _maxInstantChange) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Apply moving average filter
  double _applyMovingAverage(double newAngle) {
    _angleBuffer.add(newAngle);
    
    // Keep buffer at fixed size
    while (_angleBuffer.length > _bufferSize) {
      _angleBuffer.removeAt(0);
    }
    
    // Calculate average
    final sum = _angleBuffer.fold(0.0, (prev, angle) => prev + angle);
    return sum / _angleBuffer.length;
  }
  
  /// Detect context (face-down, landscape, etc.)
  void _detectContext(MotionData data) {
    PostureContext newContext = PostureContext.normal;
    
    // Check face-down
    if (data.isFaceDown) {
      _faceDownCount++;
      if (_faceDownCount >= _contextThreshold) {
        newContext = PostureContext.faceDown;
      }
    } else {
      _faceDownCount = 0;
    }
    
    // Check landscape
    if (data.isLandscape && newContext == PostureContext.normal) {
      _landscapeCount++;
      if (_landscapeCount >= _contextThreshold) {
        newContext = PostureContext.landscape;
      }
    } else {
      _landscapeCount = 0;
    }
    
    // Update context if changed
    if (newContext != _currentContext) {
      _currentContext = newContext;
      _contextController.add(newContext);
    }
  }
  
  /// Apply temporal smoothing - only count sustained poor posture
  void _applyTemporalSmoothing() {
    final rawState = PostureState.fromAngle(_currentAngle);
    
    if (rawState == PostureState.poor) {
      // Start or continue poor posture timer
      _poorPostureStart ??= DateTime.now();
      
      final duration = DateTime.now().difference(_poorPostureStart!);
      if (duration >= _poorPostureThreshold) {
        _sustainedPoorPosture = true;
        _updateState(PostureState.poor);
      }
    } else {
      // Reset poor posture timer
      _poorPostureStart = null;
      _sustainedPoorPosture = false;
      _updateState(rawState);
    }
  }
  
  /// Update angle and notify listeners
  void _updateAngle(double angle) {
    _currentAngle = angle;
    _angleController.add(angle);
  }
  
  /// Update state and notify listeners
  void _updateState(PostureState state) {
    if (state != _currentState) {
      _currentState = state;
      _stateController.add(state);
    }
  }
  
  /// Manually set angle (for testing or calibration)
  void setAngle(double angle) {
    _updateAngle(angle);
    _updateState(PostureState.fromAngle(angle));
  }
  
  /// Determine if current posture is good
  bool isGoodPosture({double? customThreshold}) {
    final threshold = customThreshold ?? AppConstants.goodPostureMaxAngle;
    return _currentAngle <= threshold;
  }
  
  /// Reset buffers and timers
  void reset() {
    _angleBuffer.clear();
    _previousAngle = null;
    _poorPostureStart = null;
    _sustainedPoorPosture = false;
    _faceDownCount = 0;
    _landscapeCount = 0;
    _currentContext = PostureContext.normal;
  }
  
  /// Dispose resources
  void dispose() {
    _motionSubscription?.cancel();
    _motionChannel.dispose();
    _angleController.close();
    _stateController.close();
    _contextController.close();
  }
}

/// Context states for posture tracking
enum PostureContext {
  normal,      // Normal tracking
  faceDown,    // Phone face down (auto-pause)
  landscape,   // Landscape orientation (adjusted thresholds)
  autoPaused,  // Auto-paused due to inactivity
}

/// Angle calculator utilities
class AngleCalculator {
  /// Calculate angle between two vectors
  static double angleBetweenVectors(
    List<double> v1,
    List<double> v2,
  ) {
    final dotProduct = v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2];
    final magnitude1 = math.sqrt(v1[0] * v1[0] + v1[1] * v1[1] + v1[2] * v1[2]);
    final magnitude2 = math.sqrt(v2[0] * v2[0] + v2[1] * v2[1] + v2[2] * v2[2]);
    
    if (magnitude1 == 0 || magnitude2 == 0) return 0;
    
    final cosAngle = (dotProduct / (magnitude1 * magnitude2)).clamp(-1.0, 1.0);
    return math.acos(cosAngle) * 180 / math.pi;
  }
  
  /// Smooth angle readings using exponential moving average
  static double smoothAngle(double newAngle, double previousAngle, {double alpha = 0.3}) {
    return alpha * newAngle + (1 - alpha) * previousAngle;
  }
}
