import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// A widget that renders an avatar from an `asset:` path, a base64 data URI,
/// or a network URL (e.g. `https://…/api/avatars/<id>?v=…`).
///
/// Data URIs are decoded once and kept in a small LRU cache keyed by the
/// source string, so rebuilds never re-run base64 decoding. Images are
/// decoded at display size ([Image.cacheWidth]) to keep memory low.
class AvatarImage extends StatelessWidget {
  final String source;
  final double size;
  final Widget? fallback;
  final BoxFit fit;

  const AvatarImage({
    super.key,
    required this.source,
    required this.size,
    this.fallback,
    this.fit = BoxFit.cover,
  });

  static const int _maxCachedDataUris = 64;
  static final LinkedHashMap<String, Uint8List?> _dataUriCache =
      LinkedHashMap<String, Uint8List?>();

  /// Decoded bytes for a `data:` URI, or null if it can't be decoded.
  /// Results (including failures) are cached so decoding happens once.
  static Uint8List? decodeDataUri(String source) {
    if (_dataUriCache.containsKey(source)) {
      // Re-insert to mark as most recently used.
      final bytes = _dataUriCache.remove(source);
      _dataUriCache[source] = bytes;
      return bytes;
    }
    Uint8List? bytes;
    try {
      final comma = source.indexOf(',');
      bytes = base64Decode(comma >= 0 ? source.substring(comma + 1) : source);
    } catch (_) {
      bytes = null;
    }
    _dataUriCache[source] = bytes;
    while (_dataUriCache.length > _maxCachedDataUris) {
      _dataUriCache.remove(_dataUriCache.keys.first);
    }
    return bytes;
  }

  static bool isNetworkUrl(String source) =>
      source.startsWith('http://') || source.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final fallbackWidget = fallback ?? const SizedBox();
    // Decode at (roughly) physical display size — avatars are tiny.
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final cacheWidth = (size * dpr).round().clamp(1, 1024);

    if (source.startsWith('asset:')) {
      // Local asset
      final assetPath = source.substring(6);
      return ClipOval(
        child: Image.asset(
          assetPath,
          fit: fit,
          width: size,
          height: size,
          cacheWidth: cacheWidth,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => fallbackWidget,
        ),
      );
    } else if (source.startsWith('data:')) {
      // Base64 data URI (legacy) — decoded once, cached by source.
      final bytes = decodeDataUri(source);
      if (bytes == null) return fallbackWidget;
      return ClipOval(
        child: Image.memory(
          bytes,
          fit: fit,
          width: size,
          height: size,
          cacheWidth: cacheWidth,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => fallbackWidget,
        ),
      );
    } else {
      // Network URL — Flutter's ImageCache keeps it across rebuilds; the
      // `?v=` query changes when the avatar changes, busting the cache.
      return ClipOval(
        child: Image.network(
          source,
          fit: fit,
          width: size,
          height: size,
          cacheWidth: cacheWidth,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            // Placeholder while the first frame loads.
            return SizedBox(width: size, height: size, child: fallbackWidget);
          },
          errorBuilder: (_, __, ___) => fallbackWidget,
        ),
      );
    }
  }
}
