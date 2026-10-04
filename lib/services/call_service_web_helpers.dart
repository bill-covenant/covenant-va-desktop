import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Resume AudioContext on web (browsers require user gesture to enable audio)
void resumeAudioContext() {
  try {
    final ctor = globalContext['AudioContext'] as JSFunction;
    final audioCtx = ctor.callAsConstructor<JSObject>();
    audioCtx.callMethod('resume'.toJS);
    audioCtx.callMethod('close'.toJS);
    print('🔊 AudioContext resumed for web audio playback');
  } catch (e) {
    print('⚠️ AudioContext resume failed: $e');
  }
}

/// Attach remote stream to an HTML audio element for reliable audio playback on web
void attachStreamToAudioElement(MediaStream stream) {
  try {
    // Create audio element via DOM
    final document = globalContext['document'] as JSObject;
    final audio = document.callMethod<JSObject>('createElement'.toJS, 'audio'.toJS);
    audio['autoplay'] = true.toJS;
    audio.callMethod('setAttribute'.toJS, 'playsinline'.toJS, 'true'.toJS);

    // MediaStreamWeb (flutter_webrtc on web) exposes the underlying JS
    // MediaStream as its `jsStream` field
    final JSObject jsStream = (stream as dynamic).jsStream as JSObject;
    audio['srcObject'] = jsStream;

    // Append to body (hidden) so browser keeps it alive
    (audio['style'] as JSObject)['display'] = 'none'.toJS;
    (document['body'] as JSObject?)?.callMethod('append'.toJS, audio);

    final playPromise = audio.callMethod<JSPromise>('play'.toJS);
    playPromise.toDart.catchError((e) {
      print('⚠️ Audio autoplay blocked, retrying: $e');
      return null;
    });

    print('🔊 Web: attached remote stream to HTML audio element');
  } catch (e) {
    print('⚠️ Web audio element fallback failed: $e');
  }
}
