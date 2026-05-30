import 'dart:io';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

Future<AudioSource> getPlatformAudioSource(Uint8List bytes, String mimeType) async {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/temp_translation_speech.mp3');
  await file.writeAsBytes(bytes);
  return AudioSource.file(file.path);
}

Future<bool> platformPlayBytesDirectly(Uint8List bytes, String mimeType) async {
  return false;
}
