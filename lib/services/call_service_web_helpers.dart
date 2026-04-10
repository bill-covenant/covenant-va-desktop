import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Resume AudioContext on web (browsers require user gesture to enable audio)
void resumeAudioContext() {
  try {
    final audioCtx = js_util.callConstructor(
      js_util.getProperty(html.window, 'AudioContext'),
      [],
    );
    js_util.callMethod(audioCtx, 'resume', []);
    js_util.callMethod(audioCtx, 'close', []);
    print('🔊 AudioContext resumed for web audio playback');
  } catch (e) {
    print('⚠️ AudioContext resume failed: $e');
  }
}

/// Attach remote stream to an HTML audio element for reliable audio playback on web
void attachStreamToAudioElement(MediaStream stream) {
  try {
    final audio = html.document.createElement('audio') as html.AudioElement;
    audio.autoplay = true;
    // Use js_util to set srcObject since stream may not expose jsStream
    js_util.setProperty(audio, 'srcObject', js_util.getProperty(stream, 'jsStream'));
    html.document.body?.append(audio);
    audio.play().catchError((e) {
      // Try alternative: set srcObject directly from the stream object
      try {
        js_util.setProperty(audio, 'srcObject', stream);
      } catch (_) {}
      print('⚠️ Audio play retry: $e');
    });
    print('🔊 Web: attached remote stream to HTML audio element');
  } catch (e) {
    print('⚠️ Web audio element fallback failed: $e');
  }
}
