import 'package:flutter/foundation.dart' show kIsWeb;

/// IST-RVT App Constants
/// Update BASE_URL to your deployed backend URL
class AppConstants {
  AppConstants._();

  // ── Backend URLs ─────────────────────────────────────────────────────────
  // Local development — web uses laptop WiFi IP, accessible from iPhone on same WiFi
  // ── Backend URLs ─────────────────────────────────────────────────────────
  // Local development — forced to explicit loopback IP for reliable routing
  static String get _localBase => kIsWeb ? 'http://${Uri.base.host}:8000' : 'http://10.0.2.2:8000';
  // Railway / Cloud deployment — replace with your actual URL
  static const String _cloudBase = 'https://ist-rvt-backend.onrender.com';

  // Switch between local and cloud
  static const bool useCloud = true;
  static String get baseUrl => useCloud ? _cloudBase : _localBase;
  static String get wsBase  => useCloud
      ? _cloudBase.replaceFirst('https', 'wss').replaceFirst('http', 'ws')
      : _localBase.replaceFirst('https', 'wss').replaceFirst('http', 'ws');

  // ── API Endpoints ────────────────────────────────────────────────────────
  static String get apiBase       => '$baseUrl/api/v1';
  static String get registerUrl   => '$apiBase/auth/register';
  static String get loginUrl      => '$apiBase/auth/login';
  static String get meUrl         => '$apiBase/auth/me';
  static String get logoutUrl     => '$apiBase/auth/logout';
  static String get profileUrl    => '$apiBase/auth/profile';
  static String get translateText => '$apiBase/translate/text';
  static String get translateVoice=> '$apiBase/translate/voice';
  static String get voiceProfile  => '$apiBase/translate/voice-profile';
  static String get languages     => '$apiBase/translate/languages';
  static String get initiateCall  => '$apiBase/calls/initiate';
  static String get callHistory   => '$apiBase/calls/history';
  static String get searchContacts=> '$apiBase/contacts/search';
  static String get adminStats    => '$apiBase/admin/stats';

  // ── WebSocket URLs ───────────────────────────────────────────────────────
  static String audioWs(String roomId, String userId, String src, String tgt) =>
      '$wsBase/ws/audio/$roomId?user_id=$userId&source_lang=$src&target_lang=$tgt';
  static String signalWs(String roomId, String userId) =>
      '$wsBase/ws/signal/$roomId?user_id=$userId';

  // ── Audio Settings ───────────────────────────────────────────────────────
  static const int audioSampleRate    = 16000;    // Hz
  static const int audioChunkMs       = 100;      // 100ms chunks
  static const int audioBitRate       = 128000;   // bps
  static const int audioChannels      = 1;        // mono

  // ── UI Constants ─────────────────────────────────────────────────────────
  static const double borderRadius    = 20.0;
  static const double cardRadius      = 16.0;
  static const double buttonRadius    = 16.0;
  static const Duration animDuration  = Duration(milliseconds: 300);
  static const Duration longAnimDuration = Duration(milliseconds: 600);

  // ── Storage Keys ─────────────────────────────────────────────────────────
  static const String keyToken        = 'auth_token';
  static const String keyUserId       = 'user_id';
  static const String keyUsername     = 'username';
  static const String keyDisplayName  = 'display_name';
  static const String keySrcLang      = 'source_lang';
  static const String keyTgtLang      = 'target_lang';
  static const String keyOnboarded    = 'onboarded';
  static const String keyVoiceClone   = 'voice_clone_enabled';

  // ── App Info ─────────────────────────────────────────────────────────────
  static const String appName         = 'IST-RVT';
  static const String appTagline      = 'Speak Any Language, Anywhere';
  static const String appVersion      = '1.0.0';
}
