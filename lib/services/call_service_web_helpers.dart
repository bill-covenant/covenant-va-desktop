import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web/web.dart' as web;

/// Resume AudioContext on web (browsers require user gesture to enable audio)
void resumeAudioContext() {
  try {
    final audioCtx = web.AudioContext();
    audioCtx.resume();
    audioCtx.close();
    debugPrint('🔊 AudioContext resumed for web audio playback');
  } catch (e) {
    debugPrint('⚠️ AudioContext resume failed: $e');
  }
}

/// Attach remote stream to an HTML audio element for reliable audio playback on web
void attachStreamToAudioElement(MediaStream stream) {
  try {
    // Create audio element via DOM
    final audio = web.HTMLAudioElement();
    audio.autoplay = true;
    audio.setAttribute('playsinline', 'true');

    // On web, flutter_webrtc's MediaStream is a MediaStreamWeb that wraps the
    // underlying JS MediaStream in its `jsStream` field.
    JSObject? jsStream;
    try {
      jsStream = (stream as dynamic).jsStream as JSObject?;
    } catch (_) {
      jsStream = null;
    }
    if (jsStream == null) {
      debugPrint('⚠️ Web: remote stream has no underlying JS MediaStream');
      return;
    }

    audio.srcObject = jsStream;

    // Append to body (hidden) so browser keeps it alive
    audio.style.display = 'none';
    web.document.body?.append(audio);

    audio.play().toDart.catchError((Object e) {
      debugPrint('⚠️ Audio autoplay blocked, retrying: $e');
      return null;
    });

    debugPrint('🔊 Web: attached remote stream to HTML audio element');
  } catch (e) {
    debugPrint('⚠️ Web audio element fallback failed: $e');
  }
}
