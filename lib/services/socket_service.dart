import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/constants/api_constants.dart';
import '../data/models/message_model.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  // Callback for showing in-app notifications
  Function(String title, String body)? onNotification;

  // Callback for task updates
  Function()? onTaskUpdate;

  // Callback for announcement updates
  Function()? onAnnouncementUpdate;

  // Callback for assignment changes (assign/unassign)
  Function()? onAssignmentUpdate;

  // ✅ Stream for real-time incoming messages
  final _newMessageController = StreamController<MessageModel>.broadcast();
  Stream<MessageModel> get onNewMessage => _newMessageController.stream;

  // ✅ Track online users
  final Set<String> _onlineUsers = {};
  final _userStatusController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onUserStatusChanged => _userStatusController.stream;

  bool isUserOnline(String userId) => _onlineUsers.contains(userId);

  // ═══════════════════════════════════════
  // Call signaling callbacks (set by CallService)
  // ═══════════════════════════════════════
  Function(String callerId, String callerName, String callType)? onIncomingCall;
  Function()? onCallAccepted;
  Function()? onCallDeclined;
  Function()? onCallEnded;
  Function(String reason)? onCallUnavailable;
  Function(Map<String, dynamic> offer)? onWebRTCOffer;
  Function(Map<String, dynamic> answer)? onWebRTCAnswer;
  Function(Map<String, dynamic> candidate)? onICECandidate;

  Future<void> initNotifications() async {
    _log('📱 Notification system ready');
  }

  void connect(String vaId, String token) {
    _log('🔌 Attempting to connect to Socket.io with VA ID: $vaId');

    if (_socket != null) {
      if (_socket!.connected &&
          _authenticatedUserId == vaId &&
          _authenticatedToken == token) {
        _log('✅ Already connected to Socket.io');
        return;
      }
      // Different user/token (or a dead socket) — tear down before reconnecting
      disconnect();
    }
    _authenticatedUserId = vaId;
    _authenticatedToken = token;

    final socketUrl = ApiConstants.baseUrl.replaceAll('/api', '');
    _log('🌐 Connecting to: $socketUrl');

    // The server requires the JWT in the handshake auth payload.
    // forceNew: socket_io_client caches managers per URL, which would otherwise
    // reuse a previous session's auth after logout/login.
    _socket = IO.io(socketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .enableForceNew()
      .disableAutoConnect()
      .enableReconnection()
      .setReconnectionAttempts(20)
      .setReconnectionDelay(2000)
      .build()
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _log('✅ Connected to Socket.io server');
      _log('📤 Sending authenticate-va event with ID: $vaId');
      try {
        final numericId = int.parse(vaId);
        _socket!.emit('authenticate-va', numericId);
        _log('👤 Authenticated as VA with numeric ID: $numericId');
      } catch (e) {
        _socket!.emit('authenticate-va', vaId);
        _log('👤 Authenticated as VA with string ID: $vaId');
      }
    });

    _socket!.onDisconnect((_) {
      _log('❌ Disconnected from Socket.io server');
    });

    _socket!.on('task-created', (data) {
      _log('📋 ========== TASK CREATED EVENT RECEIVED ==========');
      _handleTaskCreated(data);
    });

    _socket!.on('task-updated', (data) {
      _log('📝 Task updated');
      _handleTaskUpdated(data);
    });

    _socket!.on('task-deleted', (data) {
      _log('🗑️ Task deleted: ${data['taskId']}');
      _handleTaskDeleted(data);
    });

    // ✅ Listen for real-time messages
    _socket!.on('new-message', (data) {
      _log('💬 ========== NEW MESSAGE RECEIVED ==========');
      _handleNewMessage(data);
    });

    // ✅ Listen for new announcements
    _socket!.on('new-announcement', (data) {
      _log('📢 ========== NEW ANNOUNCEMENT ==========');
      _handleNewAnnouncement(data);
    });

    // ✅ Listen for real-time notifications (assignments, system alerts, etc.)
    _socket!.on('notification', (data) {
      _log('🔔 ========== NOTIFICATION RECEIVED ==========');
      try {
        final Map<String, dynamic> notification =
            data['notification'] is Map<String, dynamic>
                ? data['notification']
                : {};
        final title = notification['title']?.toString() ?? 'Notification';
        final message = notification['message']?.toString() ?? '';
        _showNotification(title: title, body: message);

        // Trigger assignment update callback for assign/unassign notifications
        if (title.contains('Assigned') || title.contains('Unassigned')) {
          onAssignmentUpdate?.call();
        }
      } catch (e) {
        _log('❌ Error parsing notification: $e');
      }
    });

    // ✅ Receive full list of currently online users on connect
    _socket!.on('online-users', (data) {
      if (data is List) {
        _onlineUsers.clear();
        for (final userId in data) {
          _onlineUsers.add(userId.toString());
        }
        _userStatusController.add({'type': 'bulk', 'users': data});
      }
    });

    // ✅ Listen for user online/offline status changes
    _socket!.on('user-status-changed', (data) {
      final userId = data['userId']?.toString() ?? '';
      final status = data['status']?.toString() ?? 'offline';
      if (userId.isNotEmpty) {
        if (status == 'online') {
          _onlineUsers.add(userId);
        } else {
          _onlineUsers.remove(userId);
        }
        _userStatusController.add({'userId': userId, 'status': status});
      }
    });

    // ═══════════════════════════════════════
    // Call signaling socket events (fallback for HTTP polling)
    // ═══════════════════════════════════════

    _socket!.on('call-incoming', (data) {
      _log('📞 ========== INCOMING CALL (Socket) ==========');
      final callerId = data['callerId']?.toString() ?? '';
      final callerName = data['callerName']?.toString() ?? '';
      final callType = data['callType']?.toString() ?? 'audio';
      onIncomingCall?.call(callerId, callerName, callType);
    });

    _socket!.on('call-accepted', (data) {
      _log('✅ Call accepted (Socket)');
      onCallAccepted?.call();
    });

    _socket!.on('call-declined', (data) {
      _log('❌ Call declined (Socket)');
      onCallDeclined?.call();
    });

    _socket!.on('call-ended', (data) {
      _log('📴 Call ended (Socket)');
      onCallEnded?.call();
    });

    _socket!.on('call-unavailable', (data) {
      _log('📵 Call unavailable (Socket)');
      final reason = data['reason']?.toString() ?? 'User unavailable';
      onCallUnavailable?.call(reason);
    });

    _socket!.on('call-ended-by-disconnect', (data) {
      _log('📴 Call ended by disconnect (Socket)');
      onCallEnded?.call();
    });

    _socket!.on('webrtc-offer', (data) {
      _log('📨 WebRTC offer received (Socket)');
      if (data['offer'] != null) {
        onWebRTCOffer?.call(Map<String, dynamic>.from(data['offer']));
      }
    });

    _socket!.on('webrtc-answer', (data) {
      _log('📨 WebRTC answer received (Socket)');
      if (data['answer'] != null) {
        onWebRTCAnswer?.call(Map<String, dynamic>.from(data['answer']));
      }
    });

    _socket!.on('webrtc-ice-candidate', (data) {
      _log('📨 ICE candidate received (Socket)');
      if (data['candidate'] != null) {
        onICECandidate?.call(Map<String, dynamic>.from(data['candidate']));
      }
    });

    _socket!.onError((error) {
      _log('❌ Socket.io error: $error');
    });

    _socket!.onConnectError((error) {
      _log('❌ Socket.io connection error: $error');
    });

    _socket!.onReconnect((_) {
      _log('🔄 Socket reconnected, re-authenticating...');
      try {
        final numericId = int.parse(vaId);
        _socket!.emit('authenticate-va', numericId);
      } catch (e) {
        _socket!.emit('authenticate-va', vaId);
      }
    });
  }

  // ✅ Handle incoming real-time message
  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      final messageData = data['message'] as Map<String, dynamic>;
      final message = MessageModel.fromJson(messageData);
      
      _log('💬 Message from: ${message.senderId}');
      _log('💬 Conversation: ${message.conversationId}');

      // Push to stream (MessagesBloc listens to this)
      _newMessageController.add(message);

      // Show notification
      _showNotification(
        title: 'New Message 💬',
        body: message.content.length > 50 
            ? '${message.content.substring(0, 50)}...' 
            : message.content,
      );
    } catch (e) {
      _log('❌ Error parsing new message: $e');
    }
  }

  void _handleTaskCreated(Map<String, dynamic> data) {
    final task = data['task'];
    final title = 'New Task Assigned! 📋';
    final body = task['title'];
    
    _showNotification(title: title, body: body);
    
    if (onTaskUpdate != null) {
      onTaskUpdate!();
    }
  }

  void _handleTaskUpdated(Map<String, dynamic> data) {
    final task = data['task'];
    final title = task['title'] ?? 'Unknown Task';
    final priority = task['priority']?.toString().toUpperCase() ?? '';
    final status = task['status']?.toString() ?? '';

    String notifTitle = 'Task Updated 📝';
    String notifBody = title;

    if (priority.isNotEmpty) {
      notifBody = '$title — Priority: $priority';
    }
    if (status.isNotEmpty) {
      notifBody = '$title — Status: $status';
    }

    _showNotification(title: notifTitle, body: notifBody);

    if (onTaskUpdate != null) {
      _log('🔄 Triggering task list refresh');
      onTaskUpdate!();
    }
  }

  void _handleTaskDeleted(Map<String, dynamic> data) {
    _showNotification(title: 'Task Deleted 🗑️', body: 'A task has been removed');

    if (onTaskUpdate != null) {
      onTaskUpdate!();
    }
  }

  void _handleNewAnnouncement(Map<String, dynamic> data) {
    try {
      final announcement = data['announcement'] ?? data;
      final title = announcement['title'] ?? 'New Announcement';

      _showNotification(
        title: 'New Announcement 📢',
        body: title,
      );

      if (onAnnouncementUpdate != null) {
        onAnnouncementUpdate!();
      }
    } catch (e) {
      _log('❌ Error parsing announcement: $e');
    }
  }

  void _showNotification({
    required String title,
    required String body,
  }) {
    if (onNotification != null) {
      onNotification!(title, body);
    } else {
      _log('⚠️ onNotification callback is NULL - notification not shown');
    }
  }

  Future<void> testNotification() async {
    _log('🧪 Test notification triggered');
    _showNotification(
      title: 'Test Notification 🧪',
      body: 'If you see this, notifications are working!',
    );
  }

  // ═══════════════════════════════════════
  // Call signaling emit methods
  // ═══════════════════════════════════════

  void initiateCall(String recipientId, String callerName, String callType) {
    if (_socket == null || !_socket!.connected) {
      _log('⚠️ Socket not connected, skipping initiateCall emit');
      return;
    }
    _socket!.emit('call-initiate', {
      'callerId': _authenticatedUserId ?? '',
      'callerName': callerName,
      'recipientId': recipientId,
      'callType': callType,
    });
    _log('📞 Emitted call-initiate to $recipientId');
  }

  void acceptCall(String callerId) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('call-accept', {
      'callerId': callerId,
      'recipientId': _authenticatedUserId ?? '',
    });
    _log('✅ Emitted call-accept for caller $callerId');
  }

  void declineCall(String callerId) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('call-decline', {
      'callerId': callerId,
      'recipientId': _authenticatedUserId ?? '',
    });
    _log('❌ Emitted call-decline for caller $callerId');
  }

  void endCall(String remoteUserId) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('call-end', {
      'remoteUserId': remoteUserId,
    });
    _log('📴 Emitted call-end for $remoteUserId');
  }

  void sendWebRTCOffer(String recipientId, Map<String, dynamic> offer) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('webrtc-offer', {
      'recipientId': recipientId,
      'offer': offer,
    });
  }

  void sendWebRTCAnswer(String callerId, Map<String, dynamic> answer) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('webrtc-answer', {
      'callerId': callerId,
      'answer': answer,
    });
  }

  void sendICECandidate(String remoteUserId, Map<String, dynamic> candidate) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('webrtc-ice-candidate', {
      'remoteUserId': remoteUserId,
      'candidate': candidate,
    });
  }

  // ═══════════════════════════════════════

  // Track the authenticated user ID for socket emit payloads
  String? _authenticatedUserId;
  String? _authenticatedToken;

  // Debug-only logging — never log payloads (messages, tokens) in release.
  static void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _authenticatedToken = null;
      _log('🔌 Disconnected from Socket.io');
    }
  }

  bool get isConnected => _socket != null && _socket!.connected;
}
