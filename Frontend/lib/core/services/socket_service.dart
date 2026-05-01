// lib/core/services/socket_service.dart
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  
  final StreamController<Map<String, dynamic>> _notificationStream = 
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get notificationStream => _notificationStream.stream;

  bool get isConnected => _isConnected;

  void connect(String userId, String userType) {
    if (_socket != null && _isConnected) {
      print('🔌 Socket already connected');
      return;
    }

    try {
      // Extract base URL from ApiConstants (remove /api)
      String baseUrl = ApiConstants.baseUrl.replaceAll('/api', '');
      print('🔌 Connecting to WebSocket: $baseUrl');
      
      _socket = IO.io(baseUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
        'forceNew': true,
      });

      _socket!.onConnect((_) {
        _isConnected = true;
        print('✅ WebSocket Connected to $baseUrl');
        _socket!.emit('join', [userId, userType]);
        print('📱 Joined room: ${userType}_$userId');
      });

      // Listen for health camp notifications
      _socket!.on('health_camp_notification', (data) {
        print('📢 Received health camp notification: $data');
        if (data is Map) {
          final notification = Map<String, dynamic>.from(data);
          _notificationStream.add(notification);
        }
      });

      // Listen for appointment/general notifications
      _socket!.on('notification', (data) {
        print('📢 Received notification: $data');
        if (data is Map) {
          final notification = Map<String, dynamic>.from(data);
          _notificationStream.add(notification);
        }
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        print('🔌 WebSocket Disconnected');
      });

      _socket!.onConnectError((error) {
        print('❌ WebSocket Connection Error: $error');
        _isConnected = false;
      });

      _socket!.onError((error) {
        print('❌ WebSocket error: $error');
      });

      _socket!.connect();
    } catch (e) {
      print('❌ Socket initialization error: $e');
      _isConnected = false;
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _notificationStream.close();
  }
}