import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../services/call_service.dart';

class VideoCallScreen extends StatefulWidget {
  final CallService callService;

  const VideoCallScreen({super.key, required this.callService});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.callService,
      builder: (context, _) {
        final isConnected =
            widget.callService.callState == CallState.connected;
        final isCalling = widget.callService.callState == CallState.calling;
        final isVideo = widget.callService.callType == 'video';
        final remoteName =
            widget.callService.remoteUserName ?? 'Unknown';

        return Material(
          color: const Color(0xFF1A1A2E),
          child: Stack(
            children: [
              // Remote video / avatar background
              if (isVideo && isConnected)
                Positioned.fill(
                  child: widget.callService.remoteRenderer.srcObject != null
                      ? RTCVideoView(
                          widget.callService.remoteRenderer,
                          objectFit:
                              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white54),
                        ),
                )
              else if (!isVideo || !isConnected)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF2D1B69), Color(0xFF1A1A2E)],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Avatar
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF7C3AED),
                                  Color(0xFFEC4899)
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C3AED)
                                      .withOpacity(0.4),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(remoteName),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          Text(
                            remoteName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          if (isCalling)
                            Text(
                              'Calling...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            )
                          else if (isConnected)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.callService.formattedDuration,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Name & status
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              remoteName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (isConnected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.callService.formattedDuration,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Local video PIP (video calls only, when connected, and has video)
              if (isVideo && isConnected && widget.callService.hasLocalVideo)
                Positioned(
                  top: 100,
                  right: 24,
                  child: Container(
                    width: 160,
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: widget.callService.localRenderer.srcObject != null
                        ? RTCVideoView(
                            widget.callService.localRenderer,
                            mirror: true,
                            objectFit:
                                RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          )
                        : const Center(
                            child: Icon(Icons.videocam_off, color: Colors.white38, size: 24),
                          ),
                  ),
                ),

              // Bottom controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mute
                      _buildControlButton(
                        icon: widget.callService.isMuted
                            ? Icons.mic_off_rounded
                            : Icons.mic_rounded,
                        isActive: widget.callService.isMuted,
                        onTap: widget.callService.toggleMute,
                      ),

                      const SizedBox(width: 20),

                      // Camera toggle (video only)
                      if (isVideo) ...[
                        _buildControlButton(
                          icon: widget.callService.isCameraOff
                              ? Icons.videocam_off_rounded
                              : Icons.videocam_rounded,
                          isActive: widget.callService.isCameraOff,
                          onTap: widget.callService.toggleCamera,
                        ),
                        const SizedBox(width: 20),
                      ],

                      // Device settings
                      _buildControlButton(
                        icon: Icons.settings_rounded,
                        isActive: widget.callService.showDeviceSelector,
                        onTap: () => widget.callService.toggleDeviceSelector(),
                      ),

                      const SizedBox(width: 20),

                      // End call
                      GestureDetector(
                        onTap: widget.callService.endCall,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFFEF4444).withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.call_end_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Device selector panel (inline overlay, no Navigator needed)
              if (widget.callService.showDeviceSelector)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => widget.callService.hideDeviceSelector(),
                    child: Container(
                      color: Colors.black54,
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 380,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.settings_rounded, color: Color(0xFF7C3AED), size: 20),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text('Audio & Video Settings',
                                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                  GestureDetector(
                                    onTap: () => widget.callService.hideDeviceSelector(),
                                    child: Icon(Icons.close, color: Colors.white.withOpacity(0.5), size: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildDeviceDropdown(
                                icon: Icons.mic_rounded,
                                iconColor: const Color(0xFF3B82F6),
                                label: 'Microphone',
                                devices: widget.callService.audioInputs,
                                selectedId: widget.callService.selectedAudioInput,
                                onChanged: (id) => widget.callService.switchAudioInput(id),
                              ),
                              const SizedBox(height: 16),
                              _buildDeviceDropdown(
                                icon: Icons.volume_up_rounded,
                                iconColor: const Color(0xFF22C55E),
                                label: 'Speaker',
                                devices: widget.callService.audioOutputs,
                                selectedId: widget.callService.selectedAudioOutput,
                                onChanged: (id) => widget.callService.switchAudioOutput(id),
                              ),
                              if (widget.callService.callType == 'video') ...[
                                const SizedBox(height: 16),
                                _buildDeviceDropdown(
                                  icon: Icons.videocam_rounded,
                                  iconColor: const Color(0xFF7C3AED),
                                  label: 'Camera',
                                  devices: widget.callService.videoInputs,
                                  selectedId: widget.callService.selectedVideoInput,
                                  onChanged: (id) => widget.callService.switchVideoInput(id),
                                ),
                              ],
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => widget.callService.hideDeviceSelector(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C3AED),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.3)
              : Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(isActive ? 0.5 : 0.2),
            width: 1.5,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildDeviceDropdown({
    required IconData icon,
    required Color iconColor,
    required String label,
    required List<dynamic> devices,
    required String? selectedId,
    required Function(String) onChanged,
  }) {
    // Find selected device label
    String selectedLabel = 'Default';
    if (selectedId != null && devices.isNotEmpty) {
      final match = devices.where((d) => d.deviceId == selectedId);
      if (match.isNotEmpty) {
        selectedLabel = match.first.label.isNotEmpty
            ? match.first.label
            : '$label ${devices.indexOf(match.first) + 1}';
      }
    }
    if (devices.isEmpty) selectedLabel = 'No devices found';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 6),
        // List of device options (no dropdown overlay needed)
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: devices.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(
                        'No devices found',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                      ),
                    ),
                  ]
                : devices.asMap().entries.map((entry) {
                    final i = entry.key;
                    final device = entry.value;
                    final isSelected = device.deviceId == selectedId ||
                        (selectedId == null && i == 0);
                    final deviceLabel = device.label.isNotEmpty
                        ? device.label
                        : '$label ${i + 1}';

                    return GestureDetector(
                      onTap: () => onChanged(device.deviceId),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.08) : Colors.transparent,
                          borderRadius: i == 0 && i == devices.length - 1
                              ? BorderRadius.circular(10)
                              : i == 0
                                  ? const BorderRadius.vertical(top: Radius.circular(10))
                                  : i == devices.length - 1
                                      ? const BorderRadius.vertical(bottom: Radius.circular(10))
                                      : BorderRadius.zero,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle : Icons.circle_outlined,
                              size: 16,
                              color: isSelected ? iconColor : Colors.white24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                deviceLabel,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }
}