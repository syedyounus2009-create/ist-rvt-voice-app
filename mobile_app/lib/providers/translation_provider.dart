import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../data/models/message_model.dart';
import '../data/services/websocket_service.dart';
import '../data/services/audio_service.dart';
import '../core/constants/app_constants.dart';

enum TranslationState { idle, listening, processing, playing, error }

class TranslationProvider extends ChangeNotifier {
  final WebSocketService _wsService = WebSocketService();
  final AudioService _audioService = AudioService();

  TranslationState _state = TranslationState.idle;
  String _sourceLang = 'en';
  String _targetLang = 'ar';
  String _originalText = '';
  String _translatedText = '';
  double _latencyMs = 0;
  String _ttsEngine = '';
  bool _isConnected = false;
  bool _offlineMode = false;
  String? _error;
  String? _currentUserId;

  // Translation history
  final List<TranslationResult> _history = [];
  StreamSubscription? _audioStreamSub;

  // Getters
  TranslationState get state => _state;
  String get sourceLang => _sourceLang;
  String get targetLang => _targetLang;
  String get originalText => _originalText;
  String get translatedText => _translatedText;
  double get latencyMs => _latencyMs;
  String get ttsEngine => _ttsEngine;
  bool get isConnected => _isConnected;
  bool get isListening => _state == TranslationState.listening;
  bool get offlineMode => _offlineMode;
  String? get error => _error;
  List<TranslationResult> get history => List.unmodifiable(_history);
  AudioService get audioService => _audioService;

  void setLanguages(String src, String tgt) {
    _sourceLang = src;
    _targetLang = tgt;
    if (_isConnected) {
      _wsService.updateLanguages(src, tgt);
    }
    notifyListeners();
  }

  void swapLanguages() {
    final tmp = _sourceLang;
    _sourceLang = _targetLang;
    _targetLang = tmp;
    if (_isConnected) _wsService.updateLanguages(_sourceLang, _targetLang);
    notifyListeners();
  }

  // ── WebSocket Mode (Online Real-time) ─────────────────────────────────────

  /// Connect with a specific user ID (authenticated user)
  Future<void> connectRealtime(String userId) async {
    _currentUserId = userId;
    await _doConnect(userId);
  }

  /// Connect anonymously (generates a random user ID)
  Future<void> connectAnonymous() async {
    _currentUserId ??= const Uuid().v4();
    await _doConnect(_currentUserId!);
  }

  Future<void> _doConnect(String userId) async {
    if (_isConnected) return; // Already connected

    final roomId = 'standalone_$userId';
    final url = AppConstants.audioWs(roomId, userId, _sourceLang, _targetLang);

    debugPrint('[IST-RVT] Connecting WebSocket to: $url');

    _wsService.onTranslation = _onTranslationResult;
    _wsService.onAudio = _onTranslatedAudio;
    _wsService.onStateChange = (s) {
      debugPrint('[IST-RVT] WebSocket state: $s');
      _isConnected = s == WsConnectionState.connected;
      if (s == WsConnectionState.error) {
        _error = 'WebSocket connection failed';
      }
      notifyListeners();
    };

    try {
      await _wsService.connect(url);
      debugPrint('[IST-RVT] WebSocket connect() returned, connected=$_isConnected');
    } catch (e) {
      debugPrint('[IST-RVT] WebSocket connect error: $e');
      _error = 'Connection error: $e';
    }
    notifyListeners();
  }

  Future<void> startListening() async {
    debugPrint('[IST-RVT] startListening called. connected=$_isConnected offlineMode=$_offlineMode');

    // Unlock the browser Web Audio Context synchronously inside this user tap gesture
    _audioService.warmUpWebAudio();

    final granted = await _audioService.requestPermissions();
    if (!granted) {
      _error = 'Microphone permission denied';
      debugPrint('[IST-RVT] Mic permission denied');
      notifyListeners();
      return;
    }

    // Auto-connect if not connected yet
    if (!_isConnected && !_offlineMode) {
      debugPrint('[IST-RVT] Auto-connecting before recording...');
      await connectAnonymous();
      // Give it a moment to establish
      await Future.delayed(const Duration(milliseconds: 800));
    }

    _state = TranslationState.listening;
    _originalText = '';
    _translatedText = '';
    _error = null;
    notifyListeners();

    if (_isConnected && !_offlineMode) {
      debugPrint('[IST-RVT] Starting audio stream to WebSocket...');
      // Stream to backend WebSocket
      final stream = _audioService.startStreaming();
      _audioStreamSub = stream?.listen((chunk) {
        debugPrint('[IST-RVT] Sending audio chunk: ${chunk.length} bytes');
        _wsService.sendAudio(chunk);
      }, onError: (e) {
        debugPrint('[IST-RVT] Audio stream error: $e');
      });
    } else {
      debugPrint('[IST-RVT] WARNING: Not connected. connected=$_isConnected offline=$_offlineMode');
      // Still start recording for waveform display even if not connected
      _audioService.startStreaming();
    }
  }

  Future<void> stopListening() async {
    debugPrint('[IST-RVT] stopListening called');
    await _audioStreamSub?.cancel();
    _audioStreamSub = null;
    await _audioService.stopStreaming();

    if (_state == TranslationState.listening) {
      _state = TranslationState.idle;
    }
    notifyListeners();
  }

  void _onTranslationResult(Map<String, dynamic> json) {
    debugPrint('[IST-RVT] Translation received: ${json['original']?.toString().substring(0, (json['original']?.toString().length ?? 0).clamp(0, 50))}');
    final result = TranslationResult.fromJson(json);
    _originalText = result.original;
    _translatedText = result.translated;
    _latencyMs = result.latencyMs;
    _ttsEngine = result.engine ?? '';
    _state = TranslationState.playing;

    _history.insert(0, result);
    if (_history.length > 100) _history.removeLast();
    notifyListeners();
  }

  void _onTranslatedAudio(Uint8List audioBytes) {
    debugPrint('[IST-RVT] Audio received: ${audioBytes.length} bytes');
    _audioService.playBytes(audioBytes);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_state == TranslationState.playing) {
        _state = TranslationState.idle;
        notifyListeners();
      }
    });
  }

  // ── REST API Translation (offline/text) ──────────────────────────────────

  Future<TranslationResult?> translateText(String text, String? authToken) async {
    if (text.trim().isEmpty) return null;
    _state = TranslationState.processing;
    notifyListeners();

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final resp = await http.post(
        Uri.parse(AppConstants.translateText),
        headers: headers,
        body: jsonEncode({
          'text': text,
          'source_lang': _sourceLang,
          'target_lang': _targetLang,
          'synthesize': true,
        }),
      );

      debugPrint('[IST-RVT] Text translate response: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final result = TranslationResult.fromJson(data);
        _originalText = result.original;
        _translatedText = result.translated;
        _latencyMs = result.latencyMs;
        _history.insert(0, result);

        // Play audio if provided
        if (result.audioBase64 != null) {
          final bytes = Uint8List.fromList(base64Decode(result.audioBase64!));
          await _audioService.playBytes(bytes);
        }

        _state = TranslationState.idle;
        notifyListeners();
        return result;
      }
    } catch (e) {
      debugPrint('[IST-RVT] Text translation error: $e');
      _error = 'Translation failed: $e';
    }

    _state = TranslationState.idle;
    notifyListeners();
    return null;
  }

  Future<double> getAmplitude() => _audioService.getAmplitude();

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  void toggleOfflineMode() {
    _offlineMode = !_offlineMode;
    notifyListeners();
  }

  @override
  void dispose() {
    _wsService.disconnect();
    _audioService.dispose();
    super.dispose();
  }
}
