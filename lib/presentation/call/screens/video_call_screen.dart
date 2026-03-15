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
                        isActive: false,
                        onTap: () => _showDeviceSelector(context),
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

  void _showDeviceSelector(BuildContext context) {
    widget.callService.refreshDevices();
    showDialog(
      context: context,
      builder: (ctx) => ListenableBuilder(
        listenable: widget.callService,
        builder: (context, _) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.settings_rounded, color: Color(0xFF7C3AED), size: 20),
                SizedBox(width: 8),
                Text('Audio & Video Settings',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: const Color(0xFF2A2A3E),
              value: selectedId,
              hint: Text(
                devices.isEmpty ? 'No devices found' : 'Default',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
              ),
              icon: Icon(Icons.expand_more, color: Colors.white.withOpacity(0.5), size: 18),
              items: devices.map<DropdownMenuItem<String>>((device) {
                return DropdownMenuItem<String>(
                  value: device.deviceId,
                  child: Text(
                    device.label.isNotEmpty ? device.label : '$label ${devices.indexOf(device) + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: devices.isEmpty ? null : (value) {
                if (value != null) onChanged(value);
              },
            ),
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