import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/notification_model.dart';
import '../../core/constants/api_constants.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;
  String? get error => _error;

  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Future<void> fetchNotifications() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _notifications = (data['data'] as List)
              .map((item) => NotificationModel.fromJson(item))
              .toList();
          _unreadCount = data['unreadCount'] ?? 0;
        }
      } else {
        _error = 'Failed to load notifications';
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    if (_token == null) return;

    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1 && !_notifications[index].isRead) {
          _notifications[index].isRead = true;
          _unreadCount--;
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ Error marking as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_token == null) return;

    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/notifications/mark-all-read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        for (var notification in _notifications) {
          notification.isRead = true;
        }
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  // ✅ Add real-time notification from WebSocket
  void addRealtimeNotification(Map<String, dynamic> notificationData) {
    final notification = NotificationModel.fromJson(notificationData);
    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}