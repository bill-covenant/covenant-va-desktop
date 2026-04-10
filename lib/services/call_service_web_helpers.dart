import 'dart:js_util' as js_util;
import 'dart:html' as html;
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
    // Create audio element via DOM
    final audio = html.document.createElement('audio') as html.AudioElement;
    audio.autoplay = true;
    audio.setAttribute('playsinline', 'true');

    // Access the underlying JS MediaStream via js_util
    // MediaStreamWeb has a jsStream field, access it dynamically
    dynamic jsStream;
    try {
      jsStream = js_util.getProperty(stream, 'jsStream');
    } catch (_) {
      // Fallback: the stream itself might be usable
      jsStream = stream;
    }

    js_util.setProperty(audio, 'srcObject', jsStream);

    // Append to body (hidden) so browser keeps it alive
    audio.style.display = 'none';
    html.document.body?.append(audio);

    final playPromise = audio.play();
    playPromise.catchError((e) {
      print('⚠️ Audio autoplay blocked, retrying: $e');
    });

    print('🔊 Web: attached remote stream to HTML audio element');
  } catch (e) {
    print('⚠️ Web audio element fallback failed: $e');
  }
}
