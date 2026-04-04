import 'dart:io';
import 'dart:ffi';
import 'package:flutter/services.dart';
import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';

typedef MciSendStringNative = Int32 Function(
  Pointer<Utf16> lpstrCommand, Pointer<Utf16> lpstrReturnString,
  Uint32 uReturnLength, IntPtr hwndCallback);
typedef MciSendStringDart = int Function(
  Pointer<Utf16> lpstrCommand, Pointer<Utf16> lpstrReturnString,
  int uReturnLength, int hwndCallback);

class NotificationSoundPlayer {
  static String? _cachedSoundPath;
  static MciSendStringDart? _mciSendString;
  static bool _mciOpened = false;
  static String? _mciFilePath;

  static MciSendStringDart _getMci() {
    if (_mciSendString != null) return _mciSendString!;
    final winmm = DynamicLibrary.open('winmm.dll');
    _mciSendString = winmm.lookupFunction<MciSendStringNative, MciSendStringDart>('mciSendStringW');
    return _mciSendString!;
  }

  static Future<String?> _getNotificationSoundPath() async {
    if (_cachedSoundPath != null && File(_cachedSoundPath!).existsSync()) {
      return _cachedSoundPath;
    }
    try {
      final byteData = await rootBundle.load('assets/sounds/notification.mp3');
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/cva_notification.mp3');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      _cachedSoundPath = file.path;
      return _cachedSoundPath;
    } catch (e) {
      return null;
    }
  }

  static int _mciCommand(String command) {
    final mci = _getMci();
    final cmdPtr = command.toNativeUtf16();
    final result = mci(cmdPtr, nullptr.cast(), 0, 0);
    calloc.free(cmdPtr);
    return result;
  }

  static void _playMp3(String filePath) {
    try {
      if (!_mciOpened || _mciFilePath != filePath) {
        _mciCommand('close cva_notif');
        final openResult = _mciCommand('open "$filePath" type mpegvideo alias cva_notif');
        if (openResult != 0) {
          _mciOpened = false;
          return;
        }
        _mciOpened = true;
        _mciFilePath = filePath;
      }
      _mciCommand('stop cva_notif');
      _mciCommand('seek cva_notif to start');
      _mciCommand('play cva_notif');
    } catch (e) {
      _mciOpened = false;
    }
  }

  static Future<void> play() async {
    if (Platform.isWindows) {
      final soundPath = await _getNotificationSoundPath();
      if (soundPath != null) {
        _playMp3(soundPath);
      } else {
        await Process.run('powershell', ['-c', '[console]::beep(800,200)']);
      }
    } else if (Platform.isMacOS) {
      await Process.run('afplay', ['/System/Library/Sounds/Glass.aiff']);
    } else if (Platform.isLinux) {
      await Process.run('paplay', ['/usr/share/sounds/freedesktop/stereo/bell.oga']);
    }
  }
}
