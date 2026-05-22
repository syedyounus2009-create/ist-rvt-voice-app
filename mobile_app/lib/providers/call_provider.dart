import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../data/models/contact_model.dart';
import '../data/services/websocket_service.dart';
import '../data/services/audio_service.dart';
import '../core/constants/app_constants.dart';

enum CallState { idle, calling, ringing, active, ended, error }
enum CallType { voice, video }

class CallProvider extends ChangeNotifier {
  final WebSocketService _signalWs = WebSocketService();
  final WebSocketService _audioWs  = WebSocketService();
  final AudioService _audioService = AudioService();

  CallState _callState = CallState.idle;
  CallType  _callType  = CallType.voice;
  String?   _roomId;
  String?   _remoteUserId;
  String?   _remoteUserName;
  String    _sourceLang = 'en';
  String    _targetLang = 'ar';
  bool      _isMuted    = false;
  bool      _isSpeaker  = true;
  Duration  _callDuration = Duration.zero;
  Timer?    _callTimer;
  String    _liveOriginal   = '';
  String    _liveTranslated = '';
  double    _lastLatencyMs  = 0;
  StreamSubscription? _audioStreamSub;

  // For in-call transcript
  final List<Map<String, String>> _transcript = [];

  CallState get callState     => _callState;
  CallType  get callType      => _callType;
  String?   get roomId        => _roomId;
  String?   get remoteUserName=> _remoteUserName;
  bool      get isMuted       => _isMuted;
  bool      get isSpeaker     => _isSpeaker;
  Duration  get callDuration  => _callDuration;
  String    get liveOriginal  => _liveOriginal;
  String    get liveTranslated=> _liveTranslated;
  double    get lastLatencyMs => _lastLatencyMs;
  bool      get isActive      => _callState == CallState.active;
  List<Map<String, String>> get transcript => List.unmodifiable(_transcript);

  // ── Initiate Call ──────────────────────────────────────────────────────────
  Future<void> initiateCall({
    required String token,
    required String targetUserId,
    required String targetUserName,
    required String localUserId,
    required String sourceLang,
    required String targetLang,
    CallType type = CallType.voice,
  }) async {
    _callState = CallState.calling;
    _callType  = type;
    _remoteUserId   = targetUserId;
    _remoteUserName = targetUserName;
    _sourceLang = sourceLang;
    _targetLang = targetLang;
    notifyListeners();

    try {
      final resp = await http.post(
        Uri.parse(AppConstants.initiateCall),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'target_user_id': targetUserId,
          'call_type': type == CallType.video ? 'video' : 'voice',
          'source_language': sourceLang,
          'target_language': targetLang,
        }),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        _roomId = data['room_id'];

        // Connect signal WebSocket
        await _connectSignaling(localUserId, targetUserId, targetUserName);
      } else {
        _callState = CallState.error;
        notifyListeners();
      }
    } catch (e) {
      _callState = CallState.error;
      notifyListeners();
    }
  }

  Future<void> _connectSignaling(
      String localUserId, String targetUserId, String targetName) async {
    final url = AppConstants.signalWs(_roomId!, localUserId);

    _signalWs.onSignal = (data) => _handleSignal(data, localUserId);
    _signalWs.onStateChange = (s) {
      if (s == WsConnectionState.connected) {
        // Send call request to peer
        _signalWs.sendJson({
          'type': 'call_request',
          'call_type': _callType == CallType.video ? 'video' : 'voice',
          'target_user': targetUserId,
          'from_name': localUserId,
          'source_lang': _sourceLang,
          'target_lang': _targetLang,
        });
      }
    };

    await _signalWs.connect(url);
  }

  void _handleSignal(Map<String, dynamic> data, String localUserId) {
    final type = data['type'] as String? ?? '';
    switch (type) {
      case 'call_accept':
        _callState = CallState.active;
        _startCallTimer();
        _connectAudioStream(localUserId);
        notifyListeners();
        break;
      case 'call_reject':
      case 'call_busy':
        _callState = CallState.ended;
        notifyListeners();
        break;
      case 'call_end':
        _endCallCleanup();
        break;
      case 'peer_left':
        if (data['user_id'] == _remoteUserId) _endCallCleanup();
        break;
    }
  }

  Future<void> _connectAudioStream(String localUserId) async {
    if (_roomId == null) return;
    final url = AppConstants.audioWs(_roomId!, localUserId, _sourceLang, _targetLang);

    _audioWs.onTranslation = _onTranslation;
    _audioWs.onAudio = (bytes) => _audioService.playBytes(bytes);
    await _audioWs.connect(url);

    if (!_isMuted) {
      final stream = _audioService.startStreaming();
      _audioStreamSub = stream?.listen((chunk) => _audioWs.sendAudio(chunk));
    }
  }

  void _onTranslation(Map<String, dynamic> json) {
    _liveOriginal   = json['original']   ?? '';
    _liveTranslated = json['translated'] ?? '';
    _lastLatencyMs  = (json['latency_ms'] ?? 0).toDouble();
    _transcript.add({
      'original': _liveOriginal,
      'translated': _liveTranslated,
      'time': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  // ── Accept Incoming Call ───────────────────────────────────────────────────
  Future<void> acceptCall({
    required String roomId,
    required String localUserId,
    required String remoteUserId,
    required String remoteUserName,
    required String sourceLang,
    required String targetLang,
  }) async {
    _roomId = roomId;
    _remoteUserId   = remoteUserId;
    _remoteUserName = remoteUserName;
    _sourceLang = sourceLang;
    _targetLang = targetLang;
    _callState  = CallState.active;
    _startCallTimer();
    _connectAudioStream(localUserId);
    notifyListeners();

    // Notify caller
    _signalWs.sendJson({
      'type': 'call_accept',
      'target_user': remoteUserId,
      'room_id': roomId,
    });
  }

  // ── Call Controls ─────────────────────────────────────────────────────────
  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _audioStreamSub?.cancel();
      _audioService.stopStreaming();
    }
    notifyListeners();
  }

  void toggleSpeaker() {
    _isSpeaker = !_isSpeaker;
    notifyListeners();
  }

  Future<void> endCall(String token) async {
    _signalWs.sendJson({'type': 'call_end', 'room_id': _roomId});
    if (_roomId != null) {
      try {
        await http.post(
          Uri.parse('${AppConstants.apiBase}/calls/$_roomId/end'),
          headers: {'Authorization': 'Bearer $token'},
        );
      } catch (_) {}
    }
    _endCallCleanup();
  }

  void _endCallCleanup() {
    _callTimer?.cancel();
    _audioStreamSub?.cancel();
    _audioService.stopStreaming();
    _signalWs.disconnect();
    _audioWs.disconnect();
    _callState    = CallState.ended;
    _callDuration = Duration.zero;
    _transcript.clear();
    notifyListeners();
  }

  void resetCall() {
    _callState    = CallState.idle;
    _roomId       = null;
    _liveOriginal = '';
    _liveTranslated = '';
    notifyListeners();
  }

  void _startCallTimer() {
    _callDuration = Duration.zero;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  String get formattedDuration {
    final m = _callDuration.inMinutes.toString().padLeft(2, '0');
    final s = (_callDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _signalWs.dispose();
    _audioWs.dispose();
    _audioService.dispose();
    super.dispose();
  }
}
