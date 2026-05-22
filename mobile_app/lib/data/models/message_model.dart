import 'package:equatable/equatable.dart';

class MessageModel extends Equatable {
  final String id;
  final String roomId;
  final String senderId;
  final String? receiverId;
  final String messageType; // text, voice, image, file
  final String? content;
  final String? translatedContent;
  final String sourceLang;
  final String targetLang;
  final String? audioUrl;
  final String? translatedAudioUrl;
  final String? fileUrl;
  final double? durationSeconds;
  final bool isRead;
  final bool isDeleted;
  final bool isMine;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    this.receiverId,
    this.messageType = 'text',
    this.content,
    this.translatedContent,
    this.sourceLang = 'en',
    this.targetLang = 'ar',
    this.audioUrl,
    this.translatedAudioUrl,
    this.fileUrl,
    this.durationSeconds,
    this.isRead = false,
    this.isDeleted = false,
    this.isMine = false,
    required this.createdAt,
  });

  String get displayContent => translatedContent ?? content ?? '';
  bool get isVoice => messageType == 'voice';
  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';

  factory MessageModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) =>
      MessageModel(
        id: json['id'] ?? '',
        roomId: json['room_id'] ?? '',
        senderId: json['sender_id'] ?? '',
        receiverId: json['receiver_id'],
        messageType: json['message_type'] ?? 'text',
        content: json['content'],
        translatedContent: json['translated_content'],
        sourceLang: json['source_language'] ?? 'en',
        targetLang: json['target_language'] ?? 'ar',
        audioUrl: json['audio_url'],
        translatedAudioUrl: json['translated_audio_url'],
        fileUrl: json['file_url'],
        durationSeconds: json['duration_seconds']?.toDouble(),
        isRead: json['is_read'] ?? false,
        isDeleted: json['is_deleted'] ?? false,
        isMine: currentUserId != null && json['sender_id'] == currentUserId,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
            : DateTime.now(),
      );

  // Create a local text message (before server confirmation)
  factory MessageModel.local({
    required String senderId,
    required String roomId,
    required String content,
    required String sourceLang,
    required String targetLang,
    String? translatedContent,
  }) =>
      MessageModel(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        roomId: roomId,
        senderId: senderId,
        content: content,
        translatedContent: translatedContent,
        sourceLang: sourceLang,
        targetLang: targetLang,
        isMine: true,
        createdAt: DateTime.now(),
      );

  @override
  List<Object?> get props => [id, content, translatedContent, createdAt];
}

class TranslationResult {
  final String original;
  final String translated;
  final String sourceLang;
  final String targetLang;
  final double latencyMs;
  final String? audioBase64;
  final String? engine;

  const TranslationResult({
    required this.original,
    required this.translated,
    required this.sourceLang,
    required this.targetLang,
    this.latencyMs = 0,
    this.audioBase64,
    this.engine,
  });

  factory TranslationResult.fromJson(Map<String, dynamic> json) =>
      TranslationResult(
        original: json['original'] ?? json['text'] ?? '',
        translated: json['translated'] ?? '',
        sourceLang: json['source_lang'] ?? 'en',
        targetLang: json['target_lang'] ?? 'ar',
        latencyMs: (json['latency_ms'] ?? 0).toDouble(),
        audioBase64: json['audio_base64'],
        engine: json['tts_engine'] ?? json['engine'],
      );
}
