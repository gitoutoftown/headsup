/// App-wide constants
library;

class AppConstants {
  // Posture thresholds (in degrees) - 5-tier system
  static const double excellentMaxAngle = 15.0;  // 0-15°
  static const double goodMaxAngle = 25.0;       // 16-25°
  static const double okayMaxAngle = 40.0;       // 26-40°
  static const double badMaxAngle = 65.0;        // 41-65°
  // Poor: 66°+
  
  // Legacy alias for backward compatibility
  static const double goodPostureMaxAngle = okayMaxAngle;
  static const double poorPostureMinAngle = badMaxAngle;
  
  // Score thresholds (0-100)
  static const int excellentScoreMin = 95;
  static const int goodScoreMin = 80;
  static const int okayScoreMin = 55;
  static const int badScoreMin = 25;
  // Poor: 0-24
  
  // Points per minute by zone
  static const int excellentPointsPerMinute = 5;
  static const int goodPointsPerMinute = 3;
  static const int okayPointsPerMinute = 1;
  static const int badPointsPerMinute = 0;
  static const int poorPointsPerMinute = 0;
  
  // Session limits
  static const int minSessionMinutes = 15;
  static const int maxSessionHours = 8;
  
  // Sensor sampling
  static const int sensorSampleIntervalSeconds = 5;
  static const int autoSaveIntervalSeconds = 60;
  static const int characterUpdateIntervalSeconds = 30;
  
  // Alerts - graduated by zone severity
  static const int badPostureAlertMinutes = 20;   // After 20 min in Bad zone
  static const int poorPostureAlertMinutes = 10;  // After 10 min in Poor zone
  static const int alertCooldownMinutes = 15;
  
  // Auto-pause thresholds
  static const int faceDownMinutes = 2;
  static const int stillMinutes = 10;
  static const int chargingStillMinutes = 5;
  
  // Temporal smoothing
  static const int sustainedPoorPostureSeconds = 5;
  
  // Daily reset
  static const int dailyResetHour = 6;
  
  // App info
  static const String appName = 'HeadsUp';
  static const String appVersion = '1.0.0';
}

/// Posture state enumeration - 5 tiers
enum PostureState {
  excellent,
  good,
  okay,
  bad,
  poor;
  
  static PostureState fromScore(int score) {
    if (score >= AppConstants.excellentScoreMin) return PostureState.excellent;
    if (score >= AppConstants.goodScoreMin) return PostureState.good;
    if (score >= AppConstants.okayScoreMin) return PostureState.okay;
    if (score >= AppConstants.badScoreMin) return PostureState.bad;
    return PostureState.poor;
  }
  
  static PostureState fromAngle(double angle) {
    if (angle <= AppConstants.excellentMaxAngle) return PostureState.excellent;
    if (angle <= AppConstants.goodMaxAngle) return PostureState.good;
    if (angle <= AppConstants.okayMaxAngle) return PostureState.okay;
    if (angle <= AppConstants.badMaxAngle) return PostureState.bad;
    return PostureState.poor;
  }
  
  /// Calculate score based on angle with smooth gradual transitions
  static int scoreFromAngle(double angle) {
    if (angle <= 15) {
      return (95 + (15 - angle) * 0.33).round().clamp(95, 100);
    } else if (angle <= 25) {
      return (80 + (25 - angle) * 1.4).round().clamp(80, 94);
    } else if (angle <= 40) {
      return (55 + (40 - angle) * 1.7).round().clamp(55, 79);
    } else if (angle <= 65) {
      return (25 + (65 - angle) * 1.2).round().clamp(25, 54);
    } else {
      return (25 - (angle - 65) * 1.0).round().clamp(0, 24);
    }
  }
  
  /// Points earned per minute in this state
  int get pointsPerMinute {
    switch (this) {
      case PostureState.excellent:
        return AppConstants.excellentPointsPerMinute;
      case PostureState.good:
        return AppConstants.goodPointsPerMinute;
      case PostureState.okay:
        return AppConstants.okayPointsPerMinute;
      case PostureState.bad:
        return AppConstants.badPointsPerMinute;
      case PostureState.poor:
        return AppConstants.poorPointsPerMinute;
    }
  }
  
  /// Score value for averaging (per minute)
  int get scoreValue {
    switch (this) {
      case PostureState.excellent:
        return 100;
      case PostureState.good:
        return 75;
      case PostureState.okay:
        return 40;
      case PostureState.bad:
        return 10;
      case PostureState.poor:
        return 0;
    }
  }
  
  String get displayName {
    switch (this) {
      case PostureState.excellent:
        return 'Excellent';
      case PostureState.good:
        return 'Good';
      case PostureState.okay:
        return 'Okay';
      case PostureState.bad:
        return 'Bad';
      case PostureState.poor:
        return 'Poor';
    }
  }
  
  String get feedback {
    switch (this) {
      case PostureState.excellent:
        return 'Excellent posture! 🌟';
      case PostureState.good:
        return 'Good posture';
      case PostureState.okay:
        return 'Okay - try raising phone a bit';
      case PostureState.bad:
        return 'Bad posture - please adjust';
      case PostureState.poor:
        return 'Poor posture - raise phone now!';
    }
  }
  
  /// Whether this state should trigger an alert after sustained duration
  bool get shouldAlert {
    return this == PostureState.bad || this == PostureState.poor;
  }
}

// Import-free color codes for PostureState (used with Color class)
// Usage: Color(postureState.colorCode)
extension PostureStateColor on PostureState {
  int get colorCode {
    switch (this) {
      case PostureState.excellent:
        return 0xFF00C853;  // Vibrant green
      case PostureState.good:
        return 0xFF007AFF;  // Blue
      case PostureState.okay:
        return 0xFFFFD60A;  // Yellow
      case PostureState.bad:
        return 0xFFFF9500;  // Orange
      case PostureState.poor:
        return 0xFFFF3B30;  // Red
    }
  }
}
