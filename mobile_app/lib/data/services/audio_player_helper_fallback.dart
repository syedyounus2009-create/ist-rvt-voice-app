import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';

Future<AudioSource> getPlatformAudioSource(Uint8List bytes, String mimeType) async {
  throw UnsupportedError('Unsupported platform for audio bytes playback');
}
