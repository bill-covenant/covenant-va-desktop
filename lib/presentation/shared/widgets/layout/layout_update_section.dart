import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../services/update_service.dart';

class LayoutUpdateSection extends StatefulWidget {
  final String apiBaseUrl;

  const LayoutUpdateSection({super.key, required this.apiBaseUrl});

  @override
  State<LayoutUpdateSection> createState() => _LayoutUpdateSectionState();
}

class _LayoutUpdateSectionState extends State<LayoutUpdateSection> {
  UpdateInfo? _updateInfo;
  bool _isCheckingUpdate = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    setState(() => _isCheckingUpdate = true);
    try {
      final info = await UpdateService.checkForUpdate(widget.apiBaseUrl);
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
          _updateInfo = info?.updateAvailable == true ? info : null;
        });
        if (info != null && info.updateAvailable) {
          _downloadAndInstall(info);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
      }
    }
  }

  Future<void> _downloadAndInstall(UpdateInfo info) async {
    if (kIsWeb || info.downloadUrl.isEmpty) return;
    await UpdateService.openDownloadLink(info.downloadUrl);
  }

  @override
  Widget build(BuildContext context) {
    return _buildUpdateButton();
  }

  Widget _buildUpdateButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
        Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: (_isDownloading || _updateInfo == null) ? null : _checkForUpdate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _updateInfo != null
                  ? const Color(0xFF10B981).withOpacity(0.15)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _updateInfo != null
                    ? const Color(0xFF10B981).withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
              ),
            ),
            child: _isDownloading
                ? _buildDownloadProgress()
                : _updateInfo != null
                    ? _buildUpdateAvailable()
                    : _buildCheckForUpdates(),
          ),
        ),
      ),
      if (_updateInfo != null)
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0xFFEF4444), blurRadius: 6, spreadRadius: 0)],
            ),
            child: const Center(
              child: Text('1', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildCheckForUpdates() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.info_outline_rounded, color: Colors.white.withOpacity(0.5), size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CVA Desktop',
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text('v${UpdateService.currentVersion}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateAvailable() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: const Icon(Icons.download_rounded, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Update v${_updateInfo!.version}', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w700)),
              if (_updateInfo!.releaseNotes.isNotEmpty)
                Text(_updateInfo!.releaseNotes, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981))),
      ],
    );
  }

  Widget _buildDownloadProgress() {
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Downloading... ${(_downloadProgress * 100).toInt()}%', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _downloadProgress,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
