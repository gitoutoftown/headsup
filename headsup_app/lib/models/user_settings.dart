/// User settings model
library;

class UserSettings {
  final String userId;
  final int postureThreshold;
  final bool alertsEnabled;
  final bool reminderEnabled;
  final String? reminderTime;
  final bool autoPauseEnabled;
  final String darkMode;
  final DateTime updatedAt;
  
  UserSettings({
    required this.userId,
    this.postureThreshold = 45,
    this.alertsEnabled = true,
    this.reminderEnabled = true,
    this.reminderTime,
    this.autoPauseEnabled = true,
    this.darkMode = 'system',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();
  
  /// Create default settings for a user
  factory UserSettings.defaults(String userId) {
    return UserSettings(
      userId: userId,
      postureThreshold: 45,
      alertsEnabled: true,
      reminderEnabled: true,
      reminderTime: '09:00',
      autoPauseEnabled: true,
      darkMode: 'system',
    );
  }
  
  /// Create a copy with updated values
  UserSettings copyWith({
    String? userId,
    int? postureThreshold,
    bool? alertsEnabled,
    bool? reminderEnabled,
    String? reminderTime,
    bool? autoPauseEnabled,
    String? darkMode,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      userId: userId ?? this.userId,
      postureThreshold: postureThreshold ?? this.postureThreshold,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      autoPauseEnabled: autoPauseEnabled ?? this.autoPauseEnabled,
      darkMode: darkMode ?? this.darkMode,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
  
  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'posture_threshold': postureThreshold,
      'alerts_enabled': alertsEnabled,
      'reminder_enabled': reminderEnabled,
      'reminder_time': reminderTime,
      'auto_pause_enabled': autoPauseEnabled,
      'dark_mode': darkMode,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  /// Create from Supabase JSON
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      userId: json['user_id'] as String,
      postureThreshold: json['posture_threshold'] as int? ?? 45,
      alertsEnabled: json['alerts_enabled'] as bool? ?? true,
      reminderEnabled: json['reminder_enabled'] as bool? ?? true,
      reminderTime: json['reminder_time'] as String?,
      autoPauseEnabled: json['auto_pause_enabled'] as bool? ?? true,
      darkMode: json['dark_mode'] as String? ?? 'system',
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
