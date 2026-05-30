import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:async';
import 'package:just_audio/just_audio.dart';

Future<AudioSource> getPlatformAudioSource(Uint8List bytes, String mimeType) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  return AudioSource.uri(Uri.parse(url));
}

Future<bool> platformPlayBytesDirectly(Uint8List bytes, String mimeType) async {
  try {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final audio = html.AudioElement(url);
    
    audio.volume = 1.0;
    
    final completer = Completer<void>();
    audio.onEnded.listen((_) {
      html.Url.revokeObjectUrl(url);
      if (!completer.isCompleted) completer.complete();
    });
    audio.onError.listen((e) {
      html.Url.revokeObjectUrl(url);
      if (!completer.isCompleted) completer.completeError(e);
    });
    
    await audio.play();
    await completer.future;
    return true;
  } catch (e) {
    print('[IST-RVT] Native HTML5 Audio play error: $e');
    return false;
  }
}
