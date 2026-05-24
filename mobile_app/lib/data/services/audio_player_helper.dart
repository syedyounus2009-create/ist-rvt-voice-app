import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';

import 'audio_player_helper_fallback.dart'
    if (dart.library.html) 'audio_player_helper_web.dart'
    if (dart.library.io) 'audio_player_helper_mobile.dart';

abstract class AudioPlayerHelper {
  static Future<AudioSource> getAudioSource(Uint8List bytes, String mimeType) {
    return getPlatformAudioSource(bytes, mimeType);
  }
}
