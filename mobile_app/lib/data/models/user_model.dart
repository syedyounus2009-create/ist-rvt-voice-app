import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? displayName;
  final String? phone;
  final String? avatarUrl;
  final String preferredLanguage;
  final String targetLanguage;
  final bool isOnline;
  final int totalCalls;
  final int totalTranslations;
  final String? token;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.displayName,
    this.phone,
    this.avatarUrl,
    this.preferredLanguage = 'en',
    this.targetLanguage = 'ar',
    this.isOnline = false,
    this.totalCalls = 0,
    this.totalTranslations = 0,
    this.token,
  });

  String get displayTitle => displayName ?? username;
  String get initials {
    final name = displayTitle;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['user_id'] ?? json['id'] ?? '',
        username: json['username'] ?? '',
        email: json['email'] ?? '',
        displayName: json['display_name'],
        phone: json['phone'],
        avatarUrl: json['avatar_url'],
        preferredLanguage: json['preferred_language'] ?? 'en',
        targetLanguage: json['target_language'] ?? 'ar',
        isOnline: json['is_online'] ?? false,
        totalCalls: json['total_calls'] ?? 0,
        totalTranslations: json['total_translations'] ?? 0,
        token: json['access_token'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'display_name': displayName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'preferred_language': preferredLanguage,
        'target_language': targetLanguage,
        'is_online': isOnline,
        'total_calls': totalCalls,
        'total_translations': totalTranslations,
      };

  UserModel copyWith({
    String? displayName,
    String? phone,
    String? avatarUrl,
    String? preferredLanguage,
    String? targetLanguage,
    bool? isOnline,
    String? token,
  }) =>
      UserModel(
        id: id,
        username: username,
        email: email,
        displayName: displayName ?? this.displayName,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        preferredLanguage: preferredLanguage ?? this.preferredLanguage,
        targetLanguage: targetLanguage ?? this.targetLanguage,
        isOnline: isOnline ?? this.isOnline,
        totalCalls: totalCalls,
        totalTranslations: totalTranslations,
        token: token ?? this.token,
      );

  @override
  List<Object?> get props => [id, username, email, preferredLanguage, targetLanguage];
}
