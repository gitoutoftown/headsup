/// Daily summary model for aggregated posture data
library;

import 'package:uuid/uuid.dart';

class DailySummary {
  final String id;
  final String? userId;
  final DateTime date;
  final int totalTrackedSeconds;
  final int dailyPostureScore;
  final int sessionCount;
  final DateTime createdAt;
  
  DailySummary({
    String? id,
    this.userId,
    required this.date,
    this.totalTrackedSeconds = 0,
    this.dailyPostureScore = 0,
    this.sessionCount = 0,
    DateTime? createdAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();
  
  /// Create a copy with updated values
  DailySummary copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? totalTrackedSeconds,
    int? dailyPostureScore,
    int? sessionCount,
    DateTime? createdAt,
  }) {
    return DailySummary(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      totalTrackedSeconds: totalTrackedSeconds ?? this.totalTrackedSeconds,
      dailyPostureScore: dailyPostureScore ?? this.dailyPostureScore,
      sessionCount: sessionCount ?? this.sessionCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'total_tracked_seconds': totalTrackedSeconds,
      'daily_posture_score': dailyPostureScore,
      'session_count': sessionCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  /// Create from Supabase JSON
  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      date: DateTime.parse(json['date'] as String),
      totalTrackedSeconds: json['total_tracked_seconds'] as int? ?? 0,
      dailyPostureScore: json['daily_posture_score'] as int? ?? 0,
      sessionCount: json['session_count'] as int? ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
  
  /// Format tracked time for display
  String get formattedTime {
    final hours = totalTrackedSeconds ~/ 3600;
    final minutes = (totalTrackedSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
