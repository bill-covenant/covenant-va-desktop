/// Web stub for ToneService — no-op on web platform
class ToneService {
  static final ToneService _instance = ToneService._internal();
  factory ToneService() => _instance;
  ToneService._internal();

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Future<void> playRingtone() async {}
  Future<void> playRingback() async {}
  Future<void> stop() async { _isPlaying = false; }
}
