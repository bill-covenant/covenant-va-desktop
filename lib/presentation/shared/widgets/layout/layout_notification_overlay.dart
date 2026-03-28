import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';

// Windows mciSendString for MP3 playback
typedef MciSendStringNative = Int32 Function(
  Pointer<Utf16> lpstrCommand, Pointer<Utf16> lpstrReturnString,
  Uint32 uReturnLength, IntPtr hwndCallback);
typedef MciSendStringDart = int Function(
  Pointer<Utf16> lpstrCommand, Pointer<Utf16> lpstrReturnString,
  int uReturnLength, int hwndCallback);

class LayoutNotificationOverlay {
  static OverlayEntry? _overlayEntry;
  static String? _cachedSoundPath;
  static MciSendStringDart? _mciSendString;

  static MciSendStringDart _getMci() {
    if (_mciSendString != null) return _mciSendString!;
    final winmm = DynamicLibrary.open('winmm.dll');
    _mciSendString = winmm.lookupFunction<MciSendStringNative, MciSendStringDart>('mciSendStringW');
    return _mciSendString!;
  }

  /// Extract notification sound from assets to temp file
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
      print('🔊 Notification sound extracted to: ${file.path}');
      return _cachedSoundPath;
    } catch (e) {
      print('❌ Failed to extract notification sound: $e');
      return null;
    }
  }

  /// Send an MCI command string
  static int _mciCommand(String command) {
    final mci = _getMci();
    final cmdPtr = command.toNativeUtf16();
    final result = mci(cmdPtr, nullptr.cast(), 0, 0);
    calloc.free(cmdPtr);
    return result;
  }

  static bool _mciOpened = false;
  static String? _mciFilePath;

  /// Play MP3 using Windows MCI (Media Control Interface)
  static void _playMp3(String filePath) {
    try {
      // Only open the file once, then reuse
      if (!_mciOpened || _mciFilePath != filePath) {
        _mciCommand('close cva_notif');
        final openResult = _mciCommand('open "$filePath" type mpegvideo alias cva_notif');
        if (openResult != 0) {
          print('❌ MCI open failed with code: $openResult');
          _mciOpened = false;
          return;
        }
        _mciOpened = true;
        _mciFilePath = filePath;
      }

      // Stop current playback, seek to start, and play again
      _mciCommand('stop cva_notif');
      _mciCommand('seek cva_notif to start');
      _mciCommand('play cva_notif');
      print('🔊 Notification MP3 playing via MCI');
    } catch (e) {
      print('❌ MCI playback error: $e');
      _mciOpened = false;
    }
  }

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String body,
  }) async {
    print('🎉 LayoutNotificationOverlay.show called');

    // Play notification sound
    try {
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
    } catch (e) {
      print('❌ Failed to play notification sound: $e');
    }

    // Remove any existing notification
    _overlayEntry?.remove();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 20,
        right: 20,
        width: 380,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset((1 - value) * 400, 0),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    print('✅ Notification banner inserted');

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  static void dismiss() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}