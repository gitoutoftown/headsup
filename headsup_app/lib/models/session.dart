/// Session model representing a tracking session
library;

import 'package:uuid/uuid.dart';

class Session {
  final String id;
  final String? userId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final int goodPostureSeconds;
  final int poorPostureSeconds;
  final double averageAngle;
  final int postureScore;
  final DateTime createdAt;
  
  Session({
    String? id,
    this.userId,
    required this.startTime,
    this.endTime,
    this.durationSeconds = 0,
    this.goodPostureSeconds = 0,
    this.poorPostureSeconds = 0,
    this.averageAngle = 0.0,
    this.postureScore = 0,
    DateTime? createdAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();
  
  /// Calculate posture score from good/total time
  static int calculateScore(int goodSeconds, int totalSeconds) {
    if (totalSeconds == 0) return 0;
    return ((goodSeconds / totalSeconds) * 100).round().clamp(0, 100);
  }
  
  /// Create a copy with updated values
  Session copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    int? goodPostureSeconds,
    int? poorPostureSeconds,
    double? averageAngle,
    int? postureScore,
    DateTime? createdAt,
  }) {
    return Session(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      goodPostureSeconds: goodPostureSeconds ?? this.goodPostureSeconds,
      poorPostureSeconds: poorPostureSeconds ?? this.poorPostureSeconds,
      averageAngle: averageAngle ?? this.averageAngle,
      postureScore: postureScore ?? this.postureScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'good_posture_seconds': goodPostureSeconds,
      'poor_posture_seconds': poorPostureSeconds,
      'average_angle': averageAngle,
      'posture_score': postureScore,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  /// Create from Supabase JSON
  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time'] as String)
          : null,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      goodPostureSeconds: json['good_posture_seconds'] as int? ?? 0,
      poorPostureSeconds: json['poor_posture_seconds'] as int? ?? 0,
      averageAngle: (json['average_angle'] as num?)?.toDouble() ?? 0.0,
      postureScore: json['posture_score'] as int? ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
  
  /// Format duration for display
  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
  
  /// Format duration as timer HH:MM:SS
  String get timerDisplay {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
