import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../services/call_service.dart';
import 'incoming_call_dialog.dart';
import '../screens/video_call_screen.dart';

/// Wraps the app and shows incoming call dialog or active call screen
/// as overlays based on CallService state.
/// Supports full-screen and floating/draggable PIP mode.
class CallOverlay extends StatefulWidget {
  final Widget child;
  final CallService callService;

  const CallOverlay({
    super.key,
    required this.child,
    required this.callService,
  });

  @override
  State<CallOverlay> createState() => _CallOverlayState();
}

class _CallOverlayState extends State<CallOverlay> {
  bool _isMinimized = false;
  Offset _pipPosition = const Offset(20, 80);

  // PIP dimensions
  static const double _pipWidth = 320;
  static const double _pipHeight = 200;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.callService,
      builder: (context, _) {
        final state = widget.callService.callState;
        final isActive = state == CallState.calling || state == CallState.connected;

        // Reset minimized state when call ends
        if (state == CallState.idle && _isMinimized) {
          _isMinimized = false;
        }

        return Stack(
          children: [
            // The normal app content (always visible)
            widget.child,

            // Incoming call overlay (always full-screen)
            if (state == CallState.ringing)
              Positioned.fill(
                child: IncomingCallDialog(callService: widget.callService),
              ),

            // Active call — full-screen mode
            if (isActive && !_isMinimized)
              Positioned.fill(
                child: Stack(
                  children: [
                    VideoCallScreen(callService: widget.callService),
                    // Minimize button (top-right)
                    Positioned(
                      top: 48,
                      right: 24,
                      child: GestureDetector(
                        onTap: () => setState(() => _isMinimized = true),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: const Icon(
                            Icons.picture_in_picture_alt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Active call — minimized / floating PIP mode
            if (isActive && _isMinimized)
              Positioned(
                left: _pipPosition.dx,
                top: _pipPosition.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      final screenSize = MediaQuery.of(context).size;
                      _pipPosition = Offset(
                        (_pipPosition.dx + details.delta.dx)
                            .clamp(0, screenSize.width - _pipWidth),
                        (_pipPosition.dy + details.delta.dy)
                            .clamp(0, screenSize.height - _pipHeight),
                      );
                    });
                  },
                  onDoubleTap: () => setState(() => _isMinimized = false),
                  child: _buildMinimizedCall(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMinimizedCall() {
    final isConnected = widget.callService.callState == CallState.connected;
    final isVideo = widget.callService.callType == 'video';
    final remoteName = widget.callService.remoteUserName ?? 'Unknown';

    return Container(
      width: _pipWidth,
      height: _pipHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Video or avatar background
          if (isVideo && isConnected && widget.callService.remoteRenderer.srcObject != null)
            Positioned.fill(
              child: RTCVideoViewWidget(callService: widget.callService),
            )
          else
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2D1B69), Color(0xFF1A1A2E)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            remoteName.isNotEmpty ? remoteName[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        remoteName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Top bar with name and duration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  if (isConnected) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.callService.formattedDuration,
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ] else
                    const Text(
                      'Calling...',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  const Spacer(),
                  // Expand button
                  GestureDetector(
                    onTap: () => setState(() => _isMinimized = false),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  _buildMiniButton(
                    icon: widget.callService.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    isActive: widget.callService.isMuted,
                    onTap: widget.callService.toggleMute,
                  ),
                  const SizedBox(width: 12),
                  // Camera (video only)
                  if (isVideo) ...[
                    _buildMiniButton(
                      icon: widget.callService.isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                      isActive: widget.callService.isCameraOff,
                      onTap: widget.callService.toggleCamera,
                    ),
                    const SizedBox(width: 12),
                  ],
                  // End call
                  GestureDetector(
                    onTap: widget.callService.endCall,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

/// Separate widget to avoid RTCVideoView rebuild issues
class RTCVideoViewWidget extends StatelessWidget {
  final CallService callService;
  const RTCVideoViewWidget({super.key, required this.callService});

  @override
  Widget build(BuildContext context) {
    return RTCVideoView(
      callService.remoteRenderer,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    );
  }
}