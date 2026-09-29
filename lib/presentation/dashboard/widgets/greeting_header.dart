import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';

class GreetingHeader extends StatelessWidget {
  final Widget? trailing;
  const GreetingHeader({super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    // Name comes straight from the auth state (already in memory) instead of
    // re-reading + JSON-decoding SharedPreferences in a FutureBuilder on
    // every build, which briefly showed "Hi, there!" and caused a relayout.
    final vaName = context.select<AuthBloc, String>((bloc) => _nameFrom(bloc.state));
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 12),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              final name = vaName.isNotEmpty ? vaName : 'there';
              final firstName = name.split(' ').first;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, $firstName!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getGreetingSubtitle(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.65),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
          const Spacer(),
          if (trailing != null) ...[
            trailing!,
            const SizedBox(width: 12),
          ],
          // Profile avatar
          Builder(
            builder: (context) {
              final name = vaName.isNotEmpty ? vaName : 'VA';
              final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
              return Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Center(
                  child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getGreetingSubtitle() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning! Ready to be productive?';
    if (hour < 17) return 'Good afternoon! Keep up the great work.';
    return 'Good evening! Wrapping up for the day?';
  }

  static String _nameFrom(AuthState state) {
    if (state is AuthAuthenticated) {
      final firstName = state.user.firstName;
      final lastName = state.user.lastName;
      if (firstName.isNotEmpty) return '$firstName $lastName'.trim();
    }
    return '';
  }
}
