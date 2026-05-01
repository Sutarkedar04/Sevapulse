// lib/features/user/widgets/home_content.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION
import '../../../presentation/common/widgets/section_header.dart';
import '../../../presentation/common/widgets/upcoming_visits_card.dart';
import '../../../presentation/common/widgets/canteen_card.dart';
import '../../../presentation/common/widgets/horizontal_card_carousel.dart';
import 'home_welcome_section.dart';
import '../../../data/providers/appointment_provider.dart';
import '../../../data/providers/auth_provider.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with AutomaticKeepAliveClientMixin {
  final List<Color> cardColors = const [
    Color(0xFF3498db), // Blue - Book Appointment
    Color(0xFF2ecc71), // Green - Health Tips
    Color(0xFFe74c3c), // Red - Health Camps
  ];

  late List<Map<String, dynamic>> cardData;
  int _activeCardIndex = 0;
  Color _currentWelcomeColor = const Color(0xFF3498db);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeCardData();
  }

  void _initializeCardData() {
    cardData = [
      {
        'title': 'Book an Appointment',
        'subtitle': 'Schedule with top specialists and get the best medical care.',
        'icon': Icons.calendar_today,
        'buttonText': 'Book Now',
        'color': cardColors[0],
        'animation': 'hospital_animation.json',
        'onPressed': (BuildContext context) {
          Navigator.pushNamed(context, '/specialties');
        },
      },
      {
        'title': 'Health Tips',
        'subtitle': 'Daily Health Tips for Better Living\n• Stay hydrated\n• Exercise daily\n• Get quality sleep',
        'icon': Icons.health_and_safety,
        'buttonText': 'View Tips',
        'color': cardColors[1],
        'animation': 'checkup_with_doctor.json',
        'onPressed': (BuildContext context) {
          Navigator.pushNamed(context, '/health-tips');
        },
      },
      {
        'title': 'Health Camps',
        'subtitle': 'Latest health articles and news about upcoming camps',
        'icon': Icons.feed,
        'buttonText': 'Explore',
        'color': cardColors[2],
        'animation': 'health_camp.json',
        'onPressed': (BuildContext context) {
          Navigator.pushNamed(context, '/health-feed');
        },
      },
    ];
  }

  void _updateActiveCard(int index) {
    setState(() {
      _activeCardIndex = index;
      _currentWelcomeColor = cardColors[index % cardColors.length];
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return RefreshIndicator(
      color: context.primaryColor, // ✅ Theme-aware refresh indicator
      onRefresh: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
        if (authProvider.token != null) {
          appointmentProvider.setToken(authProvider.token!);
          await appointmentProvider.loadAppointments();
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section with dynamic animation based on active card
            HomeWelcomeSection(
              accentColor: _currentWelcomeColor,
              activeCardIndex: _activeCardIndex,
            ),
            const SizedBox(height: 20),
            
            // Carousel with color change callback
            HorizontalCardCarousel(
              cardData: cardData,
              cardColors: cardColors,
              autoSlideInterval: const Duration(seconds: 5),
              onPageChanged: _updateActiveCard,
            ),
            
            const SizedBox(height: 20),
            
            Consumer<AppointmentProvider>(
              builder: (context, appointmentProvider, child) {
                final authProvider = Provider.of<AuthProvider>(context);
                final userId = authProvider.user?.id ?? '';
                
                final userAppointments = appointmentProvider.appointments
                    .where((a) => a.patientId == userId && a.status.toLowerCase() != 'cancelled')
                    .toList();
                
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                
                final upcomingAppointments = userAppointments
                    .where((a) {
                      final localDate = a.date.toLocal();
                      final appointmentDate = DateTime(
                        localDate.year,
                        localDate.month,
                        localDate.day,
                      );
                      return appointmentDate.isAtSameMomentAs(today) || 
                             appointmentDate.isAfter(today);
                    })
                    .toList()
                  ..sort((a, b) => a.date.compareTo(b.date));
                
                return Column(
                  children: [
                    SectionHeader(
                      title: 'My Appointments',
                      icon: Icons.upcoming,
                      showSeeAll: true,
                      onSeeAll: () {
                        Navigator.pushNamed(context, '/appointments');
                      },
                    ),
                    const SizedBox(height: 16),
                    UpcomingVisitsCard(
                      upcomingAppointments: upcomingAppointments,
                      onBookAppointment: () {
                        Navigator.pushNamed(context, '/specialties');
                      },
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            CanteenCard(
              onViewMenu: () => Navigator.pushNamed(context, '/canteen-menu'),
            ),
          ],
        ),
      ),
    );
  }
}