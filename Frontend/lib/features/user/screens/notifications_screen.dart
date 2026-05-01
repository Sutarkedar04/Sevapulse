// lib/features/user/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/notification_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/models/notification_model.dart';
import '../../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadNotifications();
  });
  }

  Future<void> _loadNotifications() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    
    if (authProvider.token != null) {
      notificationProvider.setToken(authProvider.token!);
      await notificationProvider.fetchNotifications();
    }
  }

  Future<void> _markAllAsRead() async {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    await notificationProvider.markAllAsRead();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All notifications marked as read', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF27ae60),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.unreadCount > 0) {
                return TextButton.icon(
                  onPressed: _markAllAsRead,
                  icon: const Icon(Icons.done_all, color: Colors.white, size: 20),
                  label: const Text(
                    'Mark all read',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: context.secondaryText.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: context.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll be notified about health camps and appointments here',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.secondaryText.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return _buildNotificationCard(notification, provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, NotificationProvider provider) {
    final isUnread = !notification.isRead;
    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(notification.createdAt);
    
    // Get icon and color based on notification type
    IconData iconData;
    Color iconColor;
    
    // Check notification type and set appropriate icon
    if (notification.isHealthCampNotification) {
      if (notification.type.contains('CREATE')) {
        iconData = Icons.add_circle_outline;
        iconColor = const Color(0xFF27ae60);
      } else if (notification.type.contains('UPDATE')) {
        iconData = Icons.edit_outlined;
        iconColor = context.primaryColor;
      } else if (notification.type.contains('DELETE')) {
        iconData = Icons.delete_outline;
        iconColor = Colors.red;
      } else {
        iconData = Icons.medical_services;
        iconColor = context.primaryColor;
      }
    } else if (notification.isAppointmentNotification) {
      if (notification.type.contains('BOOKED')) {
        iconData = Icons.calendar_today;
        iconColor = context.primaryColor;
      } else if (notification.type.contains('CONFIRMED')) {
        iconData = Icons.check_circle_outline;
        iconColor = const Color(0xFF27ae60);
      } else if (notification.type.contains('CANCELLED')) {
        iconData = Icons.cancel_outlined;
        iconColor = Colors.red;
      } else {
        iconData = Icons.event_note;
        iconColor = context.primaryColor;
      }
    } else {
      // Fallback for other notification types
      iconData = Icons.notifications;
      iconColor = context.primaryColor;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUnread ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUnread 
            ? BorderSide.none 
            : BorderSide(color: context.secondaryText.withOpacity(0.2)),
      ),
      color: context.cardColor,
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            provider.markAsRead(notification.id);
          }
          _showNotificationDetails(notification);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isUnread ? context.primaryColor.withOpacity(0.05) : context.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconData, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                          fontSize: 15,
                          color: context.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: isUnread ? context.primaryText : context.secondaryText,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.secondaryText.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationDetails(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.secondaryText.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification Title
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: context.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(notification.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.secondaryText,
                      ),
                    ),
                    Divider(height: 24, color: context.secondaryText.withOpacity(0.2)),
                    
                    // Notification Message
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 16,
                        color: context.primaryText.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                    
                    // Health Camp Details Section
                    if (notification.isHealthCampNotification && notification.campData != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.secondaryText.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.medical_services,
                                  color: const Color(0xFF27ae60),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Camp Details:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: context.primaryText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow('📅 Date', _formatDate(notification.campData!['date'])),
                            _buildDetailRow('📍 Location', notification.campData!['location']?.toString()),
                            _buildDetailRow('⏰ Time', notification.campData!['time']?.toString()),
                            _buildDetailRow('🎟️ Available Slots', notification.campData!['availableSlots']?.toString()),
                            _buildDetailRow('💰 Price', notification.campData!['isFree'] == true 
                                ? 'Free' 
                                : '₹${notification.campData!['fee']}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // View Health Camps Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/health-feed');
                          },
                          icon: const Icon(Icons.medical_services),
                          label: const Text('View Health Camps'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF27ae60),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                    // Appointment Details Section
                    if (notification.isAppointmentNotification && notification.appointmentData != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.secondaryText.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.event_note,
                                  color: context.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Appointment Details:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: context.primaryText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow('👨‍⚕️ Doctor', notification.appointmentData!['doctorName']?.toString()),
                            _buildDetailRow('👤 Patient', notification.appointmentData!['patientName']?.toString()),
                            _buildDetailRow('📅 Date', _formatDate(notification.appointmentData!['date'])),
                            _buildDetailRow('⏰ Time', notification.appointmentData!['time']?.toString()),
                            _buildDetailRow('📋 Status', notification.appointmentData!['status']?.toString()?.toUpperCase()),
                            _buildDetailRow('🏥 Type', notification.appointmentData!['type']?.toString()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // View Appointments Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/appointments');
                          },
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('View My Appointments'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: context.primaryColor),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(fontSize: 16, color: context.primaryColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to format date strings
  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'Not specified';
    
    try {
      if (dateValue is String) {
        final date = DateTime.parse(dateValue);
        return DateFormat('EEEE, MMMM d, yyyy').format(date);
      } else if (dateValue is DateTime) {
        return DateFormat('EEEE, MMMM d, yyyy').format(dateValue);
      }
      return dateValue.toString();
    } catch (e) {
      return dateValue.toString();
    }
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}