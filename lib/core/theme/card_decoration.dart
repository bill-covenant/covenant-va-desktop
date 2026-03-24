import 'package:flutter/material.dart';
import 'theme_provider.dart';

BoxDecoration buildCardDecoration({double radius = 24}) {
  final dark = ThemeProvider().isDarkMode;
  final cardBg = dark ? const Color(0xFF1A1D2E) : Colors.white;
  return BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(radius),
    border: dark ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
    boxShadow: dark
        ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))]
        : [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8)),
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
          ],
  );
}

bool isDarkMode() => ThemeProvider().isDarkMode;
Color cardBgColor() => isDarkMode() ? const Color(0xFF1A1D2E) : Colors.white;
Color textPrimary() => isDarkMode() ? Colors.white : const Color(0xFF1F2937);
Color textSecondary() => isDarkMode() ? Colors.white70 : const Color(0xFF6B7280);
Color textTertiary() => isDarkMode() ? Colors.white54 : const Color(0xFF9CA3AF);
