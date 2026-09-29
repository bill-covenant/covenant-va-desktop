import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;
  final bool updateAvailable;

  /// Optional hex SHA-256 of the download, as published by the server.
  /// The app currently hands the URL to the browser rather than downloading
  /// the installer itself, so this is surfaced but not verified in-app.
  final String? sha256;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.forceUpdate,
    required this.updateAvailable,
    this.sha256,
  });
}

class UpdateService {
  // ⚠️ Update this every time you release a new version
  static const String currentVersion = '1.0.34';
  static const int currentBuildNumber = 35;

  static const Duration _timeout = Duration(seconds: 15);

  /// Hosts an update download may come from (GitHub releases).
  static const Set<String> _allowedDownloadHosts = {
    'github.com',
    'objects.githubusercontent.com',
    'release-assets.githubusercontent.com',
  };

  /// True only for https URLs on an allowlisted host.
  static bool isAllowedDownloadUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.scheme == 'https' &&
        uri.userInfo.isEmpty &&
        _allowedDownloadHosts.contains(uri.host.toLowerCase());
  }

  static Future<UpdateInfo?> checkForUpdate(String apiBaseUrl) async {
    try {
      final response = await http
          .get(Uri.parse('$apiBaseUrl/version/latest'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final rawVersion = data['version'] as String;
          final latestVersion = _normalizeVersion(rawVersion);
          final latestBuild = data['buildNumber'] as int;
          final updateAvailable = _isNewerVersion(latestVersion, latestBuild);

          var downloadUrl = kIsWeb ? '' : (data['downloadUrl'] as String? ?? '');
          if (downloadUrl.isNotEmpty && !isAllowedDownloadUrl(downloadUrl)) {
            debugPrint('⚠️ Ignoring update download URL from untrusted host');
            downloadUrl = '';
          }

          final rawSha = data['sha256'];
          final sha256 = rawSha is String &&
                  RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(rawSha)
              ? rawSha.toLowerCase()
              : null;

          return UpdateInfo(
            version: latestVersion,
            buildNumber: latestBuild,
            downloadUrl: downloadUrl,
            releaseNotes: data['releaseNotes'] ?? '',
            forceUpdate: data['forceUpdate'] ?? false,
            updateAvailable: updateAvailable,
            sha256: sha256,
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ Update check failed: $e');
      return null;
    }
  }

  /// Normalize version to semver format (e.g., "1.018" → "1.0.18")
  static String _normalizeVersion(String version) {
    final parts = version.split('.');
    if (parts.length == 2) {
      // "1.018" → major=1, rest=018 → "1.0.18"
      final major = parts[0];
      final rest = parts[1];
      if (rest.length > 2) {
        final minor = rest.substring(0, rest.length - 2);
        final patch = rest.substring(rest.length - 2);
        return '$major.${int.parse(minor)}.${int.parse(patch)}';
      }
      return '$major.0.${int.parse(rest)}';
    }
    return version; // Already in x.y.z format
  }

  static bool _isNewerVersion(String latestVersion, int latestBuild) {
    final currentParts = currentVersion.split('.').map(int.parse).toList();
    final latestParts = latestVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final current = i < currentParts.length ? currentParts[i] : 0;
      final latest = i < latestParts.length ? latestParts[i] : 0;

      if (latest > current) return true;
      if (latest < current) return false;
    }

    // Same version string = no update needed
    return false;
  }

  static Future<void> openDownloadLink(String url) async {
    // Re-check here too: never hand an unvetted URL to the OS.
    if (!isAllowedDownloadUrl(url)) {
      debugPrint('⚠️ Refusing to open update URL from untrusted host');
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
