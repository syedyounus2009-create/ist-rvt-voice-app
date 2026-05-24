import 'dart:html' as html;
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';

Future<AudioSource> getPlatformAudioSource(Uint8List bytes, String mimeType) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  return AudioSource.uri(Uri.parse(url));
}
