import 'dart:async';
import 'dart:js_util' as js_util;
import 'dart:html' as html;

/// Web implementation of ToneService using Web Audio API via JS interop.
class ToneService {
  static final ToneService _instance = ToneService._internal();
  factory ToneService() => _instance;
  ToneService._internal();

  dynamic _audioCtx;
  dynamic _osc1;
  dynamic _osc2;
  dynamic _gainNode;
  Timer? _loopTimer;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  dynamic _getContext() {
    if (_audioCtx == null) {
      _audioCtx = js_util.callConstructor(
        js_util.getProperty(html.window, 'AudioContext'),
        [],
      );
    }
    return _audioCtx;
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
    _startTone(freq1, freq2, volume);

    Timer(Duration(milliseconds: onMs), () {
      _stopOscillators();
      if (!_isPlaying) return;
      _loopTimer = Timer(Duration(milliseconds: offMs), () {
        if (!_isPlaying) return;
        _playToneLoop(freq1: freq1, freq2: freq2, onMs: onMs, offMs: offMs, volume: volume);
      });
    });
  }

  void _startTone(double freq1, double freq2, double volume) {
    try {
      final ctx = _getContext();
      final dest = js_util.getProperty(ctx, 'destination');

      _gainNode = js_util.callMethod(ctx, 'createGain', []);
      final gainParam = js_util.getProperty(_gainNode, 'gain');
      js_util.setProperty(gainParam, 'value', volume);
      js_util.callMethod(_gainNode, 'connect', [dest]);

      _osc1 = js_util.callMethod(ctx, 'createOscillator', []);
      js_util.setProperty(_osc1, 'type', 'sine');
      final freq1Param = js_util.getProperty(_osc1, 'frequency');
      js_util.setProperty(freq1Param, 'value', freq1);
      js_util.callMethod(_osc1, 'connect', [_gainNode]);
      js_util.callMethod(_osc1, 'start', [0]);

      _osc2 = js_util.callMethod(ctx, 'createOscillator', []);
      js_util.setProperty(_osc2, 'type', 'sine');
      final freq2Param = js_util.getProperty(_osc2, 'frequency');
      js_util.setProperty(freq2Param, 'value', freq2);
      js_util.callMethod(_osc2, 'connect', [_gainNode]);
      js_util.callMethod(_osc2, 'start', [0]);
    } catch (e) {
      print('⚠️ ToneService web: Error starting tone: $e');
    }
  }

  void _stopOscillators() {
    try { js_util.callMethod(_osc1, 'stop', [0]); } catch (_) {}
    try { js_util.callMethod(_osc2, 'stop', [0]); } catch (_) {}
    try { js_util.callMethod(_osc1, 'disconnect', []); } catch (_) {}
    try { js_util.callMethod(_osc2, 'disconnect', []); } catch (_) {}
    try { js_util.callMethod(_gainNode, 'disconnect', []); } catch (_) {}
    _osc1 = null;
    _osc2 = null;
    _gainNode = null;
  }

  /// Stop any playing tone
  Future<void> stop() async {
    _isPlaying = false;
    _loopTimer?.cancel();
    _loopTimer = null;
    _stopOscillators();
  }
}
