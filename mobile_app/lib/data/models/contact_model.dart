import 'package:equatable/equatable.dart';

class ContactModel extends Equatable {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String preferredLanguage;
  final bool isOnline;
  final int totalCalls;

  const ContactModel({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.preferredLanguage = 'en',
    this.isOnline = false,
    this.totalCalls = 0,
  });

  String get displayTitle => displayName ?? username;
  String get initials {
    final name = displayTitle.trim();
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  factory ContactModel.fromJson(Map<String, dynamic> json) => ContactModel(
        id: json['id'] ?? '',
        username: json['username'] ?? '',
        displayName: json['display_name'],
        avatarUrl: json['avatar_url'],
        preferredLanguage: json['preferred_language'] ?? 'en',
        isOnline: json['is_online'] ?? false,
        totalCalls: json['total_calls'] ?? 0,
      );

  @override
  List<Object?> get props => [id, username, isOnline];
}

class CallHistoryModel {
  final String id;
  final String roomId;
  final String callType;
  final String status;
  final String sourceLang;
  final String targetLang;
  final int durationSeconds;
  final int totalTranslations;
  final double avgLatencyMs;
  final DateTime startedAt;
  final DateTime? endedAt;

  const CallHistoryModel({
    required this.id,
    required this.roomId,
    required this.callType,
    required this.status,
    required this.sourceLang,
    required this.targetLang,
    required this.durationSeconds,
    required this.totalTranslations,
    required this.avgLatencyMs,
    required this.startedAt,
    this.endedAt,
  });

  String get durationFormatted {
    if (durationSeconds < 60) return '${durationSeconds}s';
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m}m ${s}s';
  }

  bool get isMissed => status == 'missed';
  bool get isVideo => callType == 'video';

  factory CallHistoryModel.fromJson(Map<String, dynamic> json) => CallHistoryModel(
        id: json['id'] ?? '',
        roomId: json['room_id'] ?? '',
        callType: json['call_type'] ?? 'voice',
        status: json['status'] ?? 'ended',
        sourceLang: json['source_language'] ?? 'en',
        targetLang: json['target_language'] ?? 'ar',
        durationSeconds: json['duration_seconds'] ?? 0,
        totalTranslations: json['total_translations'] ?? 0,
        avgLatencyMs: (json['avg_latency_ms'] ?? 0).toDouble(),
        startedAt: DateTime.tryParse(json['started_at'] ?? '') ?? DateTime.now(),
        endedAt: json['ended_at'] != null ? DateTime.tryParse(json['ended_at']) : null,
      );
}
