import 'package:flutter/material.dart';
import '../../services/update_service.dart';

class UpdateBanner extends StatefulWidget {
  final String apiBaseUrl;

  const UpdateBanner({super.key, required this.apiBaseUrl});

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  UpdateInfo? _updateInfo;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    final info = await UpdateService.checkForUpdate(widget.apiBaseUrl);
    if (info != null && info.updateAvailable && mounted) {
      setState(() => _updateInfo = info);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_updateInfo == null || _dismissed) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.system_update, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Update Available — v${_updateInfo!.version}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (_updateInfo!.releaseNotes.isNotEmpty)
                  Text(
                    _updateInfo!.releaseNotes,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => UpdateService.openDownloadLink(_updateInfo!.downloadUrl),
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Download', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
          if (!_updateInfo!.forceUpdate) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => setState(() => _dismissed = true),
              icon: Icon(Icons.close, color: Colors.white.withOpacity(0.8), size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}