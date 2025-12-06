/// Posture service for angle calculation and state management
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

import '../utils/constants.dart';

class PostureService {
  static PostureService? _instance;
  
  PostureService._();
  
  static PostureService get instance {
    _instance ??= PostureService._();
    return _instance!;
  }
  
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  final _angleController = StreamController<double>.broadcast();
  final _stateController = StreamController<PostureState>.broadcast();
  
  double _currentAngle = 0;
  PostureState _currentState = PostureState.good;
  
  /// Stream of current angle in degrees
  Stream<double> get angleStream => _angleController.stream;
  
  /// Stream of current posture state
  Stream<PostureState> get stateStream => _stateController.stream;
  
  /// Current angle
  double get currentAngle => _currentAngle;
  
  /// Current state
  PostureState get currentState => _currentState;
  
  /// Start listening to sensors
  void startListening({Duration sampleInterval = const Duration(seconds: 5)}) {
    _accelerometerSubscription?.cancel();
    
    // Use accelerometer to calculate phone tilt
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: sampleInterval,
    ).listen(_processAccelerometerEvent);
  }
  
  /// Stop listening to sensors
  void stopListening() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }
  
  /// Process accelerometer event and calculate angle
  void _processAccelerometerEvent(AccelerometerEvent event) {
    // Calculate angle from vertical
    // When phone is vertical (in hand, looking at screen), Y should be dominant
    // When phone is horizontal (lying flat), Z should be dominant
    
    // Gravity vector components
    final x = event.x;
    final y = event.y;
    final z = event.z;
    
    // Calculate the magnitude
    final magnitude = math.sqrt(x * x + y * y + z * z);
    
    if (magnitude < 0.1) return; // Ignore if too small (freefall)
    
    // Calculate angle from vertical (Y-axis when phone is upright)
    // Angle = 0° when phone is vertical (user looking straight ahead)
    // Angle = 90° when phone is horizontal (user looking down)
    
    // Normalize
    final normalizedY = y / magnitude;
    
    // Calculate angle from vertical
    // When y = magnitude (phone vertical), angle = 0
    // When y = 0 (phone horizontal), angle = 90
    final angleRadians = math.acos(normalizedY.clamp(-1.0, 1.0));
    final angleDegrees = angleRadians * 180 / math.pi;
    
    _updateAngle(angleDegrees);
  }
  
  /// Update angle and notify listeners
  void _updateAngle(double angle) {
    _currentAngle = angle;
    _angleController.add(angle);
    
    final newState = PostureState.fromAngle(angle);
    if (newState != _currentState) {
      _currentState = newState;
      _stateController.add(newState);
    }
  }
  
  /// Manually set angle (for testing or calibration)
  void setAngle(double angle) {
    _updateAngle(angle);
  }
  
  /// Determine if current posture is good
  bool isGoodPosture({double? customThreshold}) {
    final threshold = customThreshold ?? AppConstants.goodPostureMaxAngle;
    return _currentAngle <= threshold;
  }
  
  /// Dispose resources
  void dispose() {
    _accelerometerSubscription?.cancel();
    _angleController.close();
    _stateController.close();
  }
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
