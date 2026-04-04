import 'dart:async';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

// Windows PlaySound flags
const int SND_ASYNC = 0x0001;
const int SND_MEMORY = 0x0004;
const int SND_LOOP = 0x0008;
const int SND_PURGE = 0x0040;

// PlaySound function signature from winmm.dll
typedef PlaySoundNative = Int32 Function(Pointer<Uint8> pszSound, IntPtr hmod, Uint32 fdwSound);
typedef PlaySoundDart = int Function(Pointer<Uint8> pszSound, int hmod, int fdwSound);

/// Generates and plays ringtone/ringback tones using Windows native audio.
class ToneService {
  static final ToneService _instance = ToneService._internal();
  factory ToneService() => _instance;
  ToneService._internal();

  PlaySoundDart? _playSound;
  Pointer<Uint8>? _currentBuffer;
  bool _isPlaying = false;

  PlaySoundDart _getPlaySound() {
    if (_playSound != null) return _playSound!;
    final winmm = DynamicLibrary.open('winmm.dll');
    _playSound = winmm.lookupFunction<PlaySoundNative, PlaySoundDart>('PlaySoundW');
    return _playSound!;
  }

  /// Play incoming call ringtone (receiver hears this)
  /// Two-tone ring: 440Hz + 480Hz, 1s on, 0.5s silence, looped
  Future<void> playRingtone() async {
    await stop();
    _isPlaying = true;

    final wavData = _generateDualTone(
      freq1: 440,
      freq2: 480,
      durationMs: 1000,
      silenceMs: 2000,
      volume: 0.35,
    );

    _playWavLooped(wavData);
  }

  /// Play ringback tone (caller hears this while waiting)
  /// Standard US ringback: 440Hz + 480Hz, 2s on, 4s silence, looped
  Future<void> playRingback() async {
    await stop();
    _isPlaying = true;

    final wavData = _generateDualTone(
      freq1: 440,
      freq2: 480,
      durationMs: 2000,
      silenceMs: 4000,
      volume: 0.2,
    );

    _playWavLooped(wavData);
  }

  /// Stop any playing tone
  Future<void> stop() async {
    _isPlaying = false;
    try {
      final playSound = _getPlaySound();
      playSound(nullptr.cast<Uint8>(), 0, SND_PURGE);
    } catch (e) {
      print('⚠️ ToneService: Error stopping: $e');
    }
    _freeBuffer();
  }

  bool get isPlaying => _isPlaying;

  void _playWavLooped(Uint8List wavData) {
    try {
      _freeBuffer();
      final playSound = _getPlaySound();

      // Allocate native memory and copy WAV data
      _currentBuffer = calloc<Uint8>(wavData.length);
      for (int i = 0; i < wavData.length; i++) {
        _currentBuffer![i] = wavData[i];
      }

      // Play from memory, async, looping
      playSound(_currentBuffer!, 0, SND_MEMORY | SND_ASYNC | SND_LOOP);
    } catch (e) {
      print('⚠️ ToneService: Error playing tone: $e');
    }
  }

  void _freeBuffer() {
    if (_currentBuffer != null && _currentBuffer != nullptr.cast<Uint8>()) {
      try {
        calloc.free(_currentBuffer!);
      } catch (_) {}
      _currentBuffer = null;
    }
  }

  /// Generate WAV with dual sine tones followed by silence
  Uint8List _generateDualTone({
    required double freq1,
    required double freq2,
    required int durationMs,
    int silenceMs = 0,
    double volume = 0.3,
    int sampleRate = 44100,
  }) {
    final toneSamples = (sampleRate * durationMs / 1000).round();
    final silenceSamples = (sampleRate * silenceMs / 1000).round();
    final totalSamples = toneSamples + silenceSamples;
    final samples = Int16List(totalSamples);

    final fadeInSamples = (sampleRate * 0.015).round();

    for (int i = 0; i < toneSamples; i++) {
      final t = i / sampleRate;
      final sample = (sin(2 * pi * freq1 * t) + sin(2 * pi * freq2 * t)) / 2.0;

      // Fade in/out to avoid clicks
      final fadeOutStart = toneSamples - fadeInSamples;
      double envelope = 1.0;
      if (i < fadeInSamples) {
        envelope = i / fadeInSamples;
      } else if (i > fadeOutStart) {
        envelope = (toneSamples - i) / fadeInSamples;
      }

      samples[i] = (sample * volume * envelope * 32767).round().clamp(-32768, 32767);
    }
    // Silence samples are already 0

    return _createWavFile(samples, sampleRate);
  }

  /// Create a valid WAV file from 16-bit PCM samples
  Uint8List _createWavFile(Int16List samples, int sampleRate) {
    final dataSize = samples.length * 2;
    final fileSize = 44 + dataSize;
    final buffer = ByteData(fileSize);
    int offset = 0;

    // RIFF header
    buffer.setUint8(offset++, 0x52); // R
    buffer.setUint8(offset++, 0x49); // I
    buffer.setUint8(offset++, 0x46); // F
    buffer.setUint8(offset++, 0x46); // F
    buffer.setUint32(offset, fileSize - 8, Endian.little); offset += 4;
    buffer.setUint8(offset++, 0x57); // W
    buffer.setUint8(offset++, 0x41); // A
    buffer.setUint8(offset++, 0x56); // V
    buffer.setUint8(offset++, 0x45); // E

    // fmt chunk
    buffer.setUint8(offset++, 0x66); // f
    buffer.setUint8(offset++, 0x6D); // m
    buffer.setUint8(offset++, 0x74); // t
    buffer.setUint8(offset++, 0x20); // space
    buffer.setUint32(offset, 16, Endian.little); offset += 4;
    buffer.setUint16(offset, 1, Endian.little); offset += 2; // PCM
    buffer.setUint16(offset, 1, Endian.little); offset += 2; // mono
    buffer.setUint32(offset, sampleRate, Endian.little); offset += 4;
    buffer.setUint32(offset, sampleRate * 2, Endian.little); offset += 4; // byte rate
    buffer.setUint16(offset, 2, Endian.little); offset += 2; // block align
    buffer.setUint16(offset, 16, Endian.little); offset += 2; // bits per sample

    // data chunk
    buffer.setUint8(offset++, 0x64); // d
    buffer.setUint8(offset++, 0x61); // a
    buffer.setUint8(offset++, 0x74); // t
    buffer.setUint8(offset++, 0x61); // a
    buffer.setUint32(offset, dataSize, Endian.little); offset += 4;

    for (int i = 0; i < samples.length; i++) {
      buffer.setInt16(offset, samples[i], Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }
}
