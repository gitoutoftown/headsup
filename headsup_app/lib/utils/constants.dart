/// App-wide constants
library;

class AppConstants {
  // Posture thresholds (in degrees)
  static const double goodPostureMaxAngle = 45.0;
  static const double poorPostureMinAngle = 46.0;
  
  // Score thresholds
  static const int goodScoreMin = 70;
  static const int fairScoreMin = 40;
  
  // Session limits
  static const int minSessionMinutes = 15;
  static const int maxSessionHours = 8;
  
  // Sensor sampling
  static const int sensorSampleIntervalSeconds = 5;
  static const int autoSaveIntervalSeconds = 60;
  static const int characterUpdateIntervalSeconds = 30;
  
  // Alerts
  static const int poorPostureAlertMinutes = 30;
  static const int alertCooldownMinutes = 30;
  
  // Auto-pause thresholds
  static const int faceDownMinutes = 2;
  static const int stillMinutes = 10;
  static const int chargingStillMinutes = 5;
  
  // Daily reset
  static const int dailyResetHour = 6;
  
  // App info
  static const String appName = 'HeadsUp';
  static const String appVersion = '1.0.0';
}

/// Posture state enumeration
enum PostureState {
  good,
  fair,
  poor;
  
  static PostureState fromScore(int score) {
    if (score >= AppConstants.goodScoreMin) return PostureState.good;
    if (score >= AppConstants.fairScoreMin) return PostureState.fair;
    return PostureState.poor;
  }
  
  static PostureState fromAngle(double angle) {
    if (angle <= AppConstants.goodPostureMaxAngle) return PostureState.good;
    if (angle <= 60) return PostureState.fair;
    return PostureState.poor;
  }
  
  String get displayName {
    switch (this) {
      case PostureState.good:
        return 'Good';
      case PostureState.fair:
        return 'Fair';
      case PostureState.poor:
        return 'Poor';
    }
  }
}
