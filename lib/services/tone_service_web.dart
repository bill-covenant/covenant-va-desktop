import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Web implementation of ToneService using Web Audio API via JS interop.
class ToneService {
  static final ToneService _instance = ToneService._internal();
  factory ToneService() => _instance;
  ToneService._internal();

  JSObject? _audioCtx;
  JSObject? _osc1;
  JSObject? _osc2;
  JSObject? _gainNode;
  Timer? _onTimer;
  Timer? _offTimer;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  JSObject _getContext() {
    return _audioCtx ??=
        (globalContext['AudioContext'] as JSFunction).callAsConstructor<JSObject>();
  }

  /// Play incoming call ringtone (receiver hears this)
  Future<void> playRingtone() async {
    await stop();
    _isPlaying = true;
    _playToneLoop(freq1: 440, freq2: 480, onMs: 1000, offMs: 2000, volume: 0.15);
  }

  /// Play ringback tone (caller hears this while waiting)
  Future<void> playRingback() async {
    await stop();
    _isPlaying = true;
    _playToneLoop(freq1: 440, freq2: 480, onMs: 2000, offMs: 4000, volume: 0.08);
  }

  void _playToneLoop({
    required double freq1,
    required double freq2,
    required int onMs,
    required int offMs,
    required double volume,
  }) {
    if (!_isPlaying) return;
    _startTone(freq1, freq2, volume);

    _onTimer?.cancel();
    _onTimer = Timer(Duration(milliseconds: onMs), () {
      _stopOscillators();
      if (!_isPlaying) return;
      _offTimer?.cancel();
      _offTimer = Timer(Duration(milliseconds: offMs), () {
        if (!_isPlaying) return;
        _playToneLoop(freq1: freq1, freq2: freq2, onMs: onMs, offMs: offMs, volume: volume);
      });
    });
  }

  JSObject _createOscillator(JSObject ctx, double freq, JSObject gain) {
    final osc = ctx.callMethod<JSObject>('createOscillator'.toJS);
    osc['type'] = 'sine'.toJS;
    (osc['frequency'] as JSObject)['value'] = freq.toJS;
    osc.callMethod('connect'.toJS, gain);
    osc.callMethod('start'.toJS, 0.toJS);
    return osc;
  }

  void _startTone(double freq1, double freq2, double volume) {
    try {
      final ctx = _getContext();
      final dest = ctx['destination'] as JSObject;

      final gain = ctx.callMethod<JSObject>('createGain'.toJS);
      (gain['gain'] as JSObject)['value'] = volume.toJS;
      gain.callMethod('connect'.toJS, dest);
      _gainNode = gain;

      _osc1 = _createOscillator(ctx, freq1, gain);
      _osc2 = _createOscillator(ctx, freq2, gain);
    } catch (e) {
      print('⚠️ ToneService web: Error starting tone: $e');
    }
  }

  void _stopOscillators() {
    try { _osc1?.callMethod('stop'.toJS, 0.toJS); } catch (_) {}
    try { _osc2?.callMethod('stop'.toJS, 0.toJS); } catch (_) {}
    try { _osc1?.callMethod('disconnect'.toJS); } catch (_) {}
    try { _osc2?.callMethod('disconnect'.toJS); } catch (_) {}
    try { _gainNode?.callMethod('disconnect'.toJS); } catch (_) {}
    _osc1 = null;
    _osc2 = null;
    _gainNode = null;
  }

  /// Stop any playing tone
  Future<void> stop() async {
    _isPlaying = false;
    _onTimer?.cancel();
    _onTimer = null;
    _offTimer?.cancel();
    _offTimer = null;
    _stopOscillators();
  }
}
