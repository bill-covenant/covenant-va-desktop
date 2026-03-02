import 'dart:async';
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

  // ✅ Stream for real-time incoming messages
  final _newMessageController = StreamController<MessageModel>.broadcast();
  Stream<MessageModel> get onNewMessage => _newMessageController.stream;

  Future<void> initNotifications() async {
    print('📱 Notification system ready');
  }

  void connect(String vaId) {
    print('🔌 Attempting to connect to Socket.io with VA ID: $vaId');
    
    if (_socket != null && _socket!.connected) {
      print('✅ Already connected to Socket.io');
      return;
    }

    final socketUrl = ApiConstants.baseUrl.replaceAll('/api', '');
    print('🌐 Connecting to: $socketUrl');
    
    _socket = IO.io(socketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .enableReconnection()
      .setReconnectionAttempts(20)
      .setReconnectionDelay(2000)
      .build()
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('✅ Connected to Socket.io server');
      print('📤 Sending authenticate-va event with ID: $vaId');
      try {
        final numericId = int.parse(vaId);
        _socket!.emit('authenticate-va', numericId);
        print('👤 Authenticated as VA with numeric ID: $numericId');
      } catch (e) {
        _socket!.emit('authenticate-va', vaId);
        print('👤 Authenticated as VA with string ID: $vaId');
      }
    });

    _socket!.onDisconnect((_) {
      print('❌ Disconnected from Socket.io server');
    });

    _socket!.on('task-created', (data) {
      print('📋 ========== TASK CREATED EVENT RECEIVED ==========');
      print('📋 Raw data: $data');
      print('📋 Task title: ${data['task']['title']}');
      _handleTaskCreated(data);
    });

    _socket!.on('task-updated', (data) {
      print('📝 Task updated: ${data['task']['title']}');
      _handleTaskUpdated(data);
    });

    _socket!.on('task-deleted', (data) {
      print('🗑️ Task deleted: ${data['taskId']}');
      _handleTaskDeleted(data);
    });

    // ✅ Listen for real-time messages
    _socket!.on('new-message', (data) {
      print('💬 ========== NEW MESSAGE RECEIVED ==========');
      print('💬 Raw data: $data');
      _handleNewMessage(data);
    });

    _socket!.onError((error) {
      print('❌ Socket.io error: $error');
    });

    _socket!.onConnectError((error) {
      print('❌ Socket.io connection error: $error');
    });

    _socket!.onReconnect((_) {
      print('🔄 Socket reconnected, re-authenticating...');
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
      
      print('💬 Message from: ${message.senderId}');
      print('💬 Content: ${message.content}');
      print('💬 Conversation: ${message.conversationId}');

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
      print('❌ Error parsing new message: $e');
      print('❌ Raw data was: $data');
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
    
    _showNotification(title: 'Task Updated 📝', body: task['title']);
    
    if (onTaskUpdate != null) {
      print('🔄 Triggering task list refresh');
      onTaskUpdate!();
    }
  }

  void _handleTaskDeleted(Map<String, dynamic> data) {
    _showNotification(title: 'Task Deleted 🗑️', body: 'A task has been removed');
    
    if (onTaskUpdate != null) {
      onTaskUpdate!();
    }
  }

  void _showNotification({
    required String title,
    required String body,
  }) {
    if (onNotification != null) {
      onNotification!(title, body);
    } else {
      print('⚠️ onNotification callback is NULL - notification not shown');
    }
  }

  Future<void> testNotification() async {
    print('🧪 Test notification triggered');
    _showNotification(
      title: 'Test Notification 🧪',
      body: 'If you see this, notifications are working!',
    );
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      print('🔌 Disconnected from Socket.io');
    }
  }

  bool get isConnected => _socket != null && _socket!.connected;
}