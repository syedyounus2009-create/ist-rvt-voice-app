import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

  Future<void> connectRealtime(String userId) async {
    final roomId = 'standalone_$userId';
    final url = AppConstants.audioWs(roomId, userId, _sourceLang, _targetLang);

    _wsService.onTranslation = _onTranslationResult;
    _wsService.onAudio = _onTranslatedAudio;
    _wsService.onStateChange = (s) {
      _isConnected = s == WsConnectionState.connected;
      notifyListeners();
    };

    await _wsService.connect(url);
    notifyListeners();
  }

  Future<void> startListening() async {
    final granted = await _audioService.requestPermissions();
    if (!granted) {
      _error = 'Microphone permission denied';
      notifyListeners();
      return;
    }

    _state = TranslationState.listening;
    _originalText = '';
    _translatedText = '';
    _error = null;
    notifyListeners();

    if (_isConnected && !_offlineMode) {
      // Stream to backend WebSocket
      final stream = _audioService.startStreaming();
      _audioStreamSub = stream?.listen((chunk) {
        _wsService.sendAudio(chunk);
      });
    }
  }

  Future<void> stopListening() async {
    await _audioStreamSub?.cancel();
    await _audioService.stopStreaming();

    if (_state == TranslationState.listening) {
      _state = TranslationState.idle;
    }
    notifyListeners();
  }

  void _onTranslationResult(Map<String, dynamic> json) {
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
    _audioService.playBytes(audioBytes);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_state == TranslationState.playing) {
        _state = TranslationState.idle;
        notifyListeners();
      }
    });
  }

  // ── REST API Translation (offline/text) ──────────────────────────────────

  Future<TranslationResult?> translateText(String text, String authToken) async {
    if (text.trim().isEmpty) return null;
    _state = TranslationState.processing;
    notifyListeners();

    try {
      final resp = await http.post(
        Uri.parse(AppConstants.translateText),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'text': text,
          'source_lang': _sourceLang,
          'target_lang': _targetLang,
          'synthesize': true,
        }),
      );

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
