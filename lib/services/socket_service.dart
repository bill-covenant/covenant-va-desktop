import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/constants/api_constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  
  // Callback for showing in-app notifications
  Function(String title, String body)? onNotification;
  
  // ✅ Add callback for task updates
  Function()? onTaskUpdate;

  Future<void> initNotifications() async {
    print('📱 Notification system ready');
  }

  void connect(String vaId) {
    print('🔌 Attempting to connect to Socket.io with VA ID: $vaId');
    
    if (_socket != null && _socket!.connected) {
      print('✅ Already connected to Socket.io');
      return;
    }

    // ✅ Use production URL from ApiConstants
    final socketUrl = ApiConstants.baseUrl.replaceAll('/api', '');
    print('🌐 Connecting to: $socketUrl');
    
    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

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

    _socket!.onError((error) {
      print('❌ Socket.io error: $error');
    });

    _socket!.onConnectError((error) {
      print('❌ Socket.io connection error: $error');
    });
  }

  void _handleTaskCreated(Map<String, dynamic> data) {
    final task = data['task'];
    final title = 'New Task Assigned! 📋';
    final body = task['title'];
    
    print('🔔 Preparing to show notification');
    print('🔔 Title: $title');
    print('🔔 Body: $body');
    print('🔔 onNotification callback is null? ${onNotification == null}');
    
    _showNotification(
      title: title,
      body: body,
    );
    
    // ✅ Trigger task list refresh
    if (onTaskUpdate != null) {
      onTaskUpdate!();
    }
  }

  void _handleTaskUpdated(Map<String, dynamic> data) {
    final task = data['task'];
    
    // ✅ Show notification for updates
    _showNotification(
      title: 'Task Updated 📝',
      body: task['title'],
    );
    
    // ✅ Trigger task list refresh
    if (onTaskUpdate != null) {
      print('🔄 Triggering task list refresh');
      onTaskUpdate!();
    }
  }

  void _handleTaskDeleted(Map<String, dynamic> data) {
    _showNotification(
      title: 'Task Deleted 🗑️',
      body: 'A task has been removed',
    );
    
    // ✅ Trigger task list refresh
    if (onTaskUpdate != null) {
      onTaskUpdate!();
    }
  }

  void _showNotification({
    required String title,
    required String body,
  }) {
    print('✅ _showNotification called');
    print('✅ Title: $title');
    print('✅ Body: $body');
    print('✅ Callback exists: ${onNotification != null}');
    
    if (onNotification != null) {
      print('✅ Calling onNotification callback...');
      onNotification!(title, body);
      print('✅ Callback executed');
    } else {
      print('❌ ERROR: onNotification callback is NULL!');
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