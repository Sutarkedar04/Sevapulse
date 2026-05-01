// lib/features/user/screens/user_home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seva_pulse/data/providers/medicine_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/appointment_provider.dart';
import '../../../presentation/common/widgets/bottom_nav_bar.dart';
import '../widgets/home_content.dart';
import 'my_medicine_screen.dart';
import 'prescriptions_screen.dart';
import 'profile_screen.dart';
import 'government_schemes_screen.dart'; // ✅ ADD THIS IMPORT
import '../widgets/notification_bell.dart';
import '../../../../core/services/socket_service.dart';
import '../../../data/providers/notification_provider.dart';
import '../../../core/theme/theme_extensions.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({Key? key}) : super(key: key);

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;
  final SocketService _socketService = SocketService();

  StreamSubscription<Map<String, dynamic>>? _notifSubscription;

  // ✅ REORDERED: Schemes is now 3rd (index 2)
  final List<Widget> _pages = const [
    HomeContent(),              // 0 - Home
    MyMedicineScreen(),         // 1 - My Medicine  
    GovernmentSchemesScreen(),  // 2 - Schemes (Now in 3rd position!)
    PrescriptionsScreen(),      // 3 - Prescriptions
    ProfileScreen(),            // 4 - Profile
  ];

  // ✅ REORDERED: Schemes is now 3rd
  final List<Map<String, dynamic>> _navItems = const [
    {'icon': Icons.home, 'label': 'Home'},
    {'icon': Icons.medical_services, 'label': 'Medicine'},
    {'icon': Icons.account_balance, 'label': 'Schemes'},  // Now 3rd tab
    {'icon': Icons.medication, 'label': 'Prescriptions'},
    {'icon': Icons.person, 'label': 'Profile'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final apts = Provider.of<AppointmentProvider>(context, listen: false);
      final meds = Provider.of<MedicineProvider>(context, listen: false);
      final notif = Provider.of<NotificationProvider>(context, listen: false);

      if (auth.token != null && auth.token!.isNotEmpty) {
        apts.setToken(auth.token!);
        meds.setToken(auth.token!);
        notif.setToken(auth.token!);

        apts.loadAppointments();
        notif.fetchNotifications();

        _setupWebSocket(auth, notif);
      }
    });
  }

  void _setupWebSocket(AuthProvider auth, NotificationProvider notif) {
    if (auth.user == null) return;

    _socketService.connect(auth.user!.id, auth.user!.userType);

    _notifSubscription = _socketService.notificationStream.listen((notification) {
      notif.addRealtimeNotification(notification);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  notification['title'] ?? 'New Notification',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(notification['message'] ?? ''),
              ],
            ),
            backgroundColor: context.primaryColor,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    _socketService.disconnect();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index != _currentIndex) setState(() => _currentIndex = index);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Logout', style: TextStyle(color: context.primaryText)),
        content: Text(
          'Are you sure you want to logout from Seva Pulse?',
          style: TextStyle(color: context.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: context.primaryColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout(context);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    _notifSubscription?.cancel();
    _socketService.disconnect();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'SEVA PULSE',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          const NotificationBell(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context);
              } else if (value == 'profile') {
                setState(() => _currentIndex = 4); // Profile is now index 4
              } else if (value == 'contact') {
                Navigator.pushNamed(context, '/contact-us');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(children: [
                  Icon(Icons.person, size: 20, color: Color(0xFF3498db)),
                  SizedBox(width: 12),
                  Text('My Profile'),
                ]),
              ),
              const PopupMenuItem(
                value: 'contact',
                child: Row(children: [
                  Icon(Icons.contact_support, size: 20, color: Color(0xFF3498db)),
                  SizedBox(width: 12),
                  Text('Contact Us'),
                ]),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  const Icon(Icons.logout, size: 20, color: Colors.red),
                  const SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/chatbot'),
        backgroundColor: context.primaryColor,
        elevation: 4,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: _navItems,
      ),
    );
  }
}