import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Lazily registers the bundled Noto Color Emoji font used by chat.
///
/// The font is ~24MB, so it is shipped as a plain asset rather than declared
/// under `fonts:` in pubspec (which the web engine downloads at startup).
/// Call [ensureLoaded] when chat opens; until it finishes, emoji render with
/// the platform's own emoji font, then re-render with Noto once registered.
class EmojiFont {
  EmojiFont._();

  static const String family = 'NotoColorEmoji';
  static const List<String> fallback = [family];
  static const String _asset = 'assets/fonts/NotoColorEmoji-Regular.ttf';

  static Future<void>? _loading;

  static Future<void> ensureLoaded() {
    return _loading ??= _load();
  }

  static Future<void> _load() async {
    try {
      final loader = FontLoader(family)..addFont(rootBundle.load(_asset));
      await loader.load();
    } catch (e) {
      debugPrint('Emoji font failed to load: $e');
      _loading = null; // allow a retry next time chat opens
    }
  }
}
