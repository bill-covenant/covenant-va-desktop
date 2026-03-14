import 'package:flutter/material.dart';
import '../../../services/call_service.dart';
import 'incoming_call_dialog.dart';
import '../screens/video_call_screen.dart';

/// Wraps the app and shows incoming call dialog or active call screen
/// as overlays based on CallService state.
class CallOverlay extends StatelessWidget {
  final Widget child;
  final CallService callService;

  const CallOverlay({
    super.key,
    required this.child,
    required this.callService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: callService,
      builder: (context, _) {
        final state = callService.callState;

        return Stack(
          children: [
            // The normal app content
            child,

            // Incoming call overlay
            if (state == CallState.ringing)
              Positioned.fill(
                child: IncomingCallDialog(callService: callService),
              ),

            // Active call screen (calling or connected)
            if (state == CallState.calling || state == CallState.connected)
              Positioned.fill(
                child: VideoCallScreen(callService: callService),
              ),
          ],
        );
      },
    );
  }
}