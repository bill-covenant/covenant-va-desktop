import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Web implementation of ToneService using the Web Audio API (package:web).
class ToneService {
  static final ToneService _instance = ToneService._internal();
  factory ToneService() => _instance;
  ToneService._internal();

  web.AudioContext? _audioCtx;
  web.OscillatorNode? _osc1;
  web.OscillatorNode? _osc2;
  web.GainNode? _gainNode;
  Timer? _onTimer;
  Timer? _offTimer;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  web.AudioContext _getContext() {
    return _audioCtx ??= web.AudioContext();
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

  web.OscillatorNode _createOscillator(web.AudioContext ctx, double freq, web.GainNode gain) {
    final osc = ctx.createOscillator();
    osc.type = 'sine';
    osc.frequency.value = freq;
    osc.connect(gain);
    osc.start(0);
    return osc;
  }

  void _startTone(double freq1, double freq2, double volume) {
    try {
      final ctx = _getContext();

      final gain = ctx.createGain();
      gain.gain.value = volume;
      gain.connect(ctx.destination);
      _gainNode = gain;

      _osc1 = _createOscillator(ctx, freq1, gain);
      _osc2 = _createOscillator(ctx, freq2, gain);
    } catch (e) {
      debugPrint('⚠️ ToneService web: Error starting tone: $e');
    }
  }

  void _stopOscillators() {
    try { _osc1?.stop(0); } catch (_) {}
    try { _osc2?.stop(0); } catch (_) {}
    try { _osc1?.disconnect(); } catch (_) {}
    try { _osc2?.disconnect(); } catch (_) {}
    try { _gainNode?.disconnect(); } catch (_) {}
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
