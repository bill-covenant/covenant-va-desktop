import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;
  final bool updateAvailable;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.forceUpdate,
    required this.updateAvailable,
  });
}

class UpdateService {
  // ⚠️ Update this every time you release a new version
  static const String currentVersion = '1.0.10';
  static const int currentBuildNumber = 11;

  static Future<UpdateInfo?> checkForUpdate(String apiBaseUrl) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/version/latest'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final latestVersion = data['version'] as String;
          final latestBuild = data['buildNumber'] as int;
          final updateAvailable = _isNewerVersion(latestVersion, latestBuild);

          return UpdateInfo(
            version: latestVersion,
            buildNumber: latestBuild,
            downloadUrl: data['downloadUrl'] ?? '',
            releaseNotes: data['releaseNotes'] ?? '',
            forceUpdate: data['forceUpdate'] ?? false,
            updateAvailable: updateAvailable,
          );
        }
      }
      return null;
    } catch (e) {
      print('⚠️ Update check failed: $e');
      return null;
    }
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
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}