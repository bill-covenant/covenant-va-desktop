import 'package:flutter/material.dart';
import 'dart:io';

class LayoutNotificationOverlay {
  static OverlayEntry? _overlayEntry;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String body,
  }) async {
    print('🎉 LayoutNotificationOverlay.show called');
    print('🎉 Title: $title');
    print('🎉 Body: $body');

    // ✅ Play system beep sound (Windows only)
    try {
      if (Platform.isWindows) {
        // Use Windows system beep
        await Process.run('powershell', ['-c', '[console]::beep(800,200)']);
        print('🔊 Windows beep played');
      } else if (Platform.isMacOS) {
        // Use macOS system beep
        await Process.run('afplay', ['/System/Library/Sounds/Glass.aiff']);
        print('🔊 macOS beep played');
      } else if (Platform.isLinux) {
        // Use Linux beep
        await Process.run('paplay', ['/usr/share/sounds/freedesktop/stereo/bell.oga']);
        print('🔊 Linux beep played');
      }
    } catch (e) {
      print('❌ Failed to play system sound: $e');
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