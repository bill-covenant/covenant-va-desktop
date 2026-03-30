import 'dart:convert';
import 'package:flutter/material.dart';

/// A widget that renders an avatar from either a base64 data URI or a network URL.
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

  @override
  Widget build(BuildContext context) {
    if (source.startsWith('asset:')) {
      // Local asset
      final assetPath = source.substring(6);
      return ClipOval(
        child: Image.asset(
          assetPath,
          fit: fit,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => fallback ?? const SizedBox(),
        ),
      );
    } else if (source.startsWith('data:')) {
      // Base64 data URI
      try {
        final base64Str = source.split(',').last;
        final bytes = base64Decode(base64Str);
        return ClipOval(
          child: Image.memory(
            bytes,
            fit: fit,
            width: size,
            height: size,
            errorBuilder: (_, __, ___) => fallback ?? const SizedBox(),
          ),
        );
      } catch (_) {
        return fallback ?? const SizedBox();
      }
    } else {
      // Network URL
      return ClipOval(
        child: Image.network(
          source,
          fit: fit,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => fallback ?? const SizedBox(),
        ),
      );
    }
  }
}
