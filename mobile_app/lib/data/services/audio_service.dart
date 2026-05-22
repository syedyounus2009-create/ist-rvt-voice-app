import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_constants.dart';

enum AudioState { idle, recording, playing, error }

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  AudioState _state = AudioState.idle;
  StreamController<Uint8List>? _chunkController;
  StreamSubscription? _recordStream;
  Timer? _chunkTimer;
  List<int> _buffer = [];

  AudioState get state => _state;
  bool get isRecording => _state == AudioState.recording;

  // ── Permissions ────────────────────────────────────────────────────────────

  Future<bool> requestPermissions() async {
    final mic = await Permission.microphone.request();
    return mic.isGranted;
  }

  // ── Recording ──────────────────────────────────────────────────────────────

  /// Start recording and streaming 100ms PCM16 chunks
  Stream<Uint8List>? startStreaming() {
    _chunkController = StreamController<Uint8List>.broadcast();
    _startRecordLoop();
    _state = AudioState.recording;
    return _chunkController?.stream;
  }

  void _startRecordLoop() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return;

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: AppConstants.audioSampleRate,
          numChannels: AppConstants.audioChannels,
          bitRate: AppConstants.audioBitRate,
        ),
      );

      _recordStream = stream.listen((data) {
        _buffer.addAll(data);
        // Emit chunks every 100ms worth of PCM16 data
        // 16000 samples/s × 2 bytes/sample × 0.1s = 3200 bytes per chunk
        const chunkSize = AppConstants.audioSampleRate *
            2 *
            AppConstants.audioChunkMs ~/
            1000;

        while (_buffer.length >= chunkSize) {
          final chunk = Uint8List.fromList(_buffer.sublist(0, chunkSize));
          _buffer = _buffer.sublist(chunkSize);
          _chunkController?.add(chunk);
        }
      });
    } catch (e) {
      debugPrint('AudioService recording error: $e');
      _state = AudioState.error;
    }
  }

  Future<void> stopStreaming() async {
    await _recordStream?.cancel();
    await _recorder.stop();
    await _chunkController?.close();
    _chunkController = null;
    _buffer.clear();
    _state = AudioState.idle;
  }

  /// Record a single audio file (for voice messages)
  Future<String?> startRecordingFile(String path) async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return null;
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: AppConstants.audioSampleRate,
        numChannels: AppConstants.audioChannels,
      ),
      path: path,
    );
    _state = AudioState.recording;
    return path;
  }

  Future<String?> stopRecordingFile() async {
    _state = AudioState.idle;
    return await _recorder.stop();
  }

  // ── Playback ───────────────────────────────────────────────────────────────

  /// Play audio from bytes (translated speech)
  Future<void> playBytes(Uint8List bytes) async {
    try {
      _state = AudioState.playing;
      final source = _BytesAudioSource(bytes);
      await _player.setAudioSource(source);
      await _player.play();
      _state = AudioState.idle;
    } catch (e) {
      debugPrint('AudioService playback error: $e');
      _state = AudioState.idle;
    }
  }

  /// Play from URL
  Future<void> playUrl(String url) async {
    try {
      _state = AudioState.playing;
      await _player.setUrl(url);
      await _player.play();
      _state = AudioState.idle;
    } catch (e) {
      _state = AudioState.idle;
    }
  }

  Future<void> stopPlayback() async {
    await _player.stop();
    _state = AudioState.idle;
  }

  // ── Amplitude (waveform data) ──────────────────────────────────────────────

  Future<double> getAmplitude() async {
    try {
      final amp = await _recorder.getAmplitude();
      // Normalize from -160..0 dBFS to 0..1
      final normalized = (amp.current + 160) / 160;
      return normalized.clamp(0.0, 1.0);
    } catch (_) {
      return 0.0;
    }
  }

  void dispose() {
    stopStreaming();
    _player.dispose();
    _recorder.dispose();
  }
}

/// Custom AudioSource for playing raw bytes
class _BytesAudioSource extends StreamAudioSource {
  final Uint8List _bytes;
  _BytesAudioSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }
}
