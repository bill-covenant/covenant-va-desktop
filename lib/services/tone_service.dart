import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';

/// Generates ringtone and ringback tones for calls using synthesized audio.
class ToneService {
  static final ToneService _instance = ToneService._internal();
  factory ToneService() => _instance;
  ToneService._internal();

  AudioPlayer? _player;
  Timer? _patternTimer;
  bool _isPlaying = false;

  /// Play incoming call ringtone (receiver hears this)
  /// Two-tone ring: 440Hz + 480Hz, 1s on, 2s off
  Future<void> playRingtone() async {
    await stop();
    _isPlaying = true;

    // Generate 1 second of dual-tone ring
    final audioData = _generateDualTone(
      freq1: 440,
      freq2: 480,
      durationMs: 1000,
      volume: 0.35,
    );

    await _playPattern(audioData, onDurationMs: 1000, offDurationMs: 2000);
  }

  /// Play ringback tone (caller hears this while waiting)
  /// Standard US ringback: 440Hz + 480Hz, 2s on, 4s off
  Future<void> playRingback() async {
    await stop();
    _isPlaying = true;

    // Generate 2 seconds of dual-tone ringback
    final audioData = _generateDualTone(
      freq1: 440,
      freq2: 480,
      durationMs: 2000,
      volume: 0.2,
    );

    await _playPattern(audioData, onDurationMs: 2000, offDurationMs: 4000);
  }

  /// Stop any playing tone
  Future<void> stop() async {
    _isPlaying = false;
    _patternTimer?.cancel();
    _patternTimer = null;

    if (_player != null) {
      await _player!.stop();
      await _player!.dispose();
      _player = null;
    }
  }

  bool get isPlaying => _isPlaying;

  Future<void> _playPattern(
    Uint8List wavData, {
    required int onDurationMs,
    required int offDurationMs,
  }) async {
    Future<void> playOnce() async {
      if (!_isPlaying) return;
      try {
        _player = AudioPlayer();
        final source = _WavAudioSource(wavData);
        await _player!.setAudioSource(source);
        await _player!.play();
      } catch (e) {
        print('⚠️ ToneService: Error playing tone: $e');
      }
    }

    // Play immediately
    await playOnce();

    // Repeat pattern
    final totalCycle = onDurationMs + offDurationMs;
    _patternTimer = Timer.periodic(Duration(milliseconds: totalCycle), (_) async {
      await playOnce();
    });
  }

  /// Generate a WAV file bytes with two mixed sine wave tones
  Uint8List _generateDualTone({
    required double freq1,
    required double freq2,
    required int durationMs,
    double volume = 0.3,
    int sampleRate = 44100,
  }) {
    final numSamples = (sampleRate * durationMs / 1000).round();
    final samples = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      // Mix two sine waves
      final sample = (sin(2 * pi * freq1 * t) + sin(2 * pi * freq2 * t)) / 2.0;
      // Apply fade in/out to avoid clicks (20ms ramps)
      final fadeInSamples = (sampleRate * 0.02).round();
      final fadeOutStart = numSamples - fadeInSamples;
      double envelope = 1.0;
      if (i < fadeInSamples) {
        envelope = i / fadeInSamples;
      } else if (i > fadeOutStart) {
        envelope = (numSamples - i) / fadeInSamples;
      }
      samples[i] = (sample * volume * envelope * 32767).round().clamp(-32768, 32767);
    }

    return _createWavFile(samples, sampleRate);
  }

  /// Create a valid WAV file from 16-bit PCM samples
  Uint8List _createWavFile(Int16List samples, int sampleRate) {
    final dataSize = samples.length * 2; // 16-bit = 2 bytes per sample
    final fileSize = 44 + dataSize; // WAV header is 44 bytes

    final buffer = ByteData(fileSize);
    int offset = 0;

    // RIFF header
    buffer.setUint8(offset++, 0x52); // R
    buffer.setUint8(offset++, 0x49); // I
    buffer.setUint8(offset++, 0x46); // F
    buffer.setUint8(offset++, 0x46); // F
    buffer.setUint32(offset, fileSize - 8, Endian.little);
    offset += 4;
    buffer.setUint8(offset++, 0x57); // W
    buffer.setUint8(offset++, 0x41); // A
    buffer.setUint8(offset++, 0x56); // V
    buffer.setUint8(offset++, 0x45); // E

    // fmt chunk
    buffer.setUint8(offset++, 0x66); // f
    buffer.setUint8(offset++, 0x6D); // m
    buffer.setUint8(offset++, 0x74); // t
    buffer.setUint8(offset++, 0x20); // (space)
    buffer.setUint32(offset, 16, Endian.little); // chunk size
    offset += 4;
    buffer.setUint16(offset, 1, Endian.little); // PCM format
    offset += 2;
    buffer.setUint16(offset, 1, Endian.little); // mono
    offset += 2;
    buffer.setUint32(offset, sampleRate, Endian.little); // sample rate
    offset += 4;
    buffer.setUint32(offset, sampleRate * 2, Endian.little); // byte rate
    offset += 4;
    buffer.setUint16(offset, 2, Endian.little); // block align
    offset += 2;
    buffer.setUint16(offset, 16, Endian.little); // bits per sample
    offset += 2;

    // data chunk
    buffer.setUint8(offset++, 0x64); // d
    buffer.setUint8(offset++, 0x61); // a
    buffer.setUint8(offset++, 0x74); // t
    buffer.setUint8(offset++, 0x61); // a
    buffer.setUint32(offset, dataSize, Endian.little);
    offset += 4;

    // PCM data
    for (int i = 0; i < samples.length; i++) {
      buffer.setInt16(offset, samples[i], Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }
}

/// Custom AudioSource that plays from in-memory WAV bytes
class _WavAudioSource extends StreamAudioSource {
  final Uint8List _wavData;

  _WavAudioSource(this._wavData);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final effectiveStart = start ?? 0;
    final effectiveEnd = end ?? _wavData.length;

    return StreamAudioResponse(
      sourceLength: _wavData.length,
      contentLength: effectiveEnd - effectiveStart,
      offset: effectiveStart,
      stream: Stream.value(_wavData.sublist(effectiveStart, effectiveEnd)),
      contentType: 'audio/wav',
    );
  }
}