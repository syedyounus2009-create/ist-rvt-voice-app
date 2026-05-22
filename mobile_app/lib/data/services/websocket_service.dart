import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

enum WsConnectionState { disconnected, connecting, connected, error }

typedef OnTranslation = void Function(Map<String, dynamic> result);
typedef OnStateChange = void Function(WsConnectionState state);
typedef OnAudio = void Function(Uint8List audioBytes);
typedef OnSignal = void Function(Map<String, dynamic> signal);

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  WsConnectionState _state = WsConnectionState.disconnected;

  OnTranslation? onTranslation;
  OnStateChange? onStateChange;
  OnAudio? onAudio;
  OnSignal? onSignal;

  // Reconnect logic
  int _reconnectAttempts = 0;
  static const int _maxReconnects = 5;
  Timer? _reconnectTimer;
  String? _lastUrl;

  WsConnectionState get state => _state;
  bool get isConnected => _state == WsConnectionState.connected;

  Future<void> connect(String url) async {
    if (_state == WsConnectionState.connected) return;
    _lastUrl = url;
    _setState(WsConnectionState.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready;
      _setState(WsConnectionState.connected);
      _reconnectAttempts = 0;

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
    } catch (e) {
      _setState(WsConnectionState.error);
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic data) {
    if (data is Uint8List || data is List<int>) {
      final bytes = data is Uint8List ? data : Uint8List.fromList(data);
      // First byte is message type: 0x01 = translated audio
      if (bytes.isNotEmpty && bytes[0] == 0x01) {
        onAudio?.call(bytes.sublist(1));
      } else {
        onAudio?.call(bytes);
      }
    } else if (data is String) {
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        final type = json['type'] as String? ?? '';

        switch (type) {
          case 'translation':
          case 'text_translation':
            onTranslation?.call(json);
            break;
          case 'offer':
          case 'answer':
          case 'ice_candidate':
          case 'call_request':
          case 'call_accept':
          case 'call_reject':
          case 'call_end':
          case 'peer_joined':
          case 'peer_left':
          case 'participants':
            onSignal?.call(json);
            break;
          case 'ping':
            sendJson({'type': 'pong'});
            break;
          default:
            onSignal?.call(json); // Forward everything else as signal
        }
      } catch (_) {}
    }
  }

  void _onError(dynamic error) {
    _setState(WsConnectionState.error);
    _scheduleReconnect();
  }

  void _onDone() {
    if (_state == WsConnectionState.connected) {
      _setState(WsConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnects || _lastUrl == null) return;
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () => connect(_lastUrl!));
  }

  /// Send raw audio bytes (PCM16 chunks)
  void sendAudio(Uint8List audioBytes) {
    if (!isConnected) return;
    try {
      _channel?.sink.add(audioBytes);
    } catch (_) {}
  }

  /// Send JSON control/signal message
  void sendJson(Map<String, dynamic> data) {
    if (!isConnected) return;
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (_) {}
  }

  /// Update language config mid-session
  void updateLanguages(String srcLang, String tgtLang) {
    sendJson({'type': 'config', 'source_lang': srcLang, 'target_lang': tgtLang});
  }

  /// Send text for translation
  void translateText(String text) {
    sendJson({'type': 'translate_text', 'text': text});
  }

  void _setState(WsConnectionState state) {
    _state = state;
    onStateChange?.call(state);
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectAttempts = _maxReconnects; // Prevent auto-reconnect
    _setState(WsConnectionState.disconnected);
    await _subscription?.cancel();
    await _channel?.sink.close(ws_status.goingAway);
    _channel = null;
    _lastUrl = null;
  }

  void dispose() {
    disconnect();
  }
}
