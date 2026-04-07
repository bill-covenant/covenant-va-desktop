import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_event.dart';
import '../../../auth/bloc/auth_state.dart';

// Cache decoded avatar bytes so they don't re-decode on every navigation
Uint8List? _cachedAvatarBytes;
String? _cachedAvatarSource;

class LayoutSidebarFooter extends StatefulWidget {
  const LayoutSidebarFooter({super.key});

  @override
  State<LayoutSidebarFooter> createState() => _LayoutSidebarFooterState();
}

class _LayoutSidebarFooterState extends State<LayoutSidebarFooter> {
  // Cache the last known user data so it persists through loading states
  String _lastUserName = '';
  String _lastUserEmail = '';
  String _lastUserInitial = '';
  String? _lastAvatarBase64;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String userName = _lastUserName;
        String userEmail = _lastUserEmail;
        String userInitial = _lastUserInitial;
        String? avatarBase64 = _lastAvatarBase64;

        if (state is AuthAuthenticated) {
          final firstName = state.user.firstName ?? '';
          final lastName = state.user.lastName ?? '';

          if (firstName.isNotEmpty && lastName.isNotEmpty) {
            userName = '$firstName $lastName';
            userInitial = firstName.substring(0, 1).toUpperCase();
          } else if (firstName.isNotEmpty) {
            userName = firstName;
            userInitial = firstName.substring(0, 1).toUpperCase();
          } else if (state.user.email.isNotEmpty) {
            userName = state.user.email.split('@')[0];
            userInitial = userName.substring(0, 1).toUpperCase();
          }

          userEmail = state.user.email;
          avatarBase64 = state.user.profile?.avatar;

          // Cache for use during transient states
          _lastUserName = userName;
          _lastUserEmail = userEmail;
          _lastUserInitial = userInitial;
          _lastAvatarBase64 = avatarBase64;
        }

        // Cache decoded avatar bytes
        Uint8List? avatarBytes;
        if (avatarBase64 != null) {
          if (_cachedAvatarSource == avatarBase64) {
            avatarBytes = _cachedAvatarBytes;
          } else {
            try {
              avatarBytes = base64Decode(avatarBase64.split(',')[1]);
              _cachedAvatarBytes = avatarBytes;
              _cachedAvatarSource = avatarBase64;
            } catch (_) {
              avatarBytes = null;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: avatarBase64 == null
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                            )
                          : null,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: avatarBytes != null
                        ? ClipOval(
                            child: Image.memory(
                              avatarBytes,
                              fit: BoxFit.cover,
                              width: 48,
                              height: 48,
                              gaplessPlayback: true,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    userInitial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Text(
                              userInitial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userEmail,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.read<AuthBloc>().add(const LogoutRequested());
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
}