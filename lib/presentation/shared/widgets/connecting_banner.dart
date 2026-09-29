import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/providers/api_provider.dart';

/// Small, non-blocking "Connecting to server…" pill shown at the top of the
/// window while the first API request of the session is slow (> 3s — e.g. the
/// backend waking from a cold start). It ignores pointer events and hides as
/// soon as the server answers.
class ConnectingBanner extends StatelessWidget {
  const ConnectingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<bool>(
        valueListenable: getIt<ApiProvider>().isConnectingSlowly,
        builder: (context, connecting, _) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: connecting
                ? Material(
                    key: const ValueKey('connecting'),
                    color: const Color(0xE61F2937),
                    elevation: 4,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Connecting to server…',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('idle')),
          );
        },
      ),
    );
  }
}
