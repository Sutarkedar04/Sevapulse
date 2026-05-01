// lib/features/user/screens/health_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION

// HealthCamp model class
class HealthCamp {
  final String id;
  final String title;
  final String organization;
  final DateTime date;
  final String time;
  final String location;
  final String description;
  final String imageUrl;
  final int availableSlots;
  final int registeredParticipants;
  final List<String> services;
  final String contact;
  final bool isFree;
  final int? fee;
  final List<String>? participantIds;

  HealthCamp({
    required this.id,
    required this.title,
    required this.organization,
    required this.date,
    required this.time,
    required this.location,
    required this.description,
    required this.imageUrl,
    required this.availableSlots,
    required this.registeredParticipants,
    required this.services,
    required this.contact,
    required this.isFree,
    this.fee,
    this.participantIds,
  });

  factory HealthCamp.fromJson(Map<String, dynamic> json) {
    return HealthCamp(
      id: json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      organization: json['organization'] ?? '',
      date: DateTime.parse(json['date']),
      time: json['time'] ?? '',
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      availableSlots: json['availableSlots'] ?? 0,
      registeredParticipants: json['registeredParticipants'] ?? 0,
      services: List<String>.from(json['services'] ?? []),
      contact: json['contact'] ?? '',
      isFree: json['isFree'] ?? true,
      fee: json['fee'],
      participantIds: json['participants'] != null 
          ? List<String>.from(json['participants'].map((p) => p.toString()))
          : [],
    );
  }
}

class HealthFeedScreen extends StatefulWidget {
  const HealthFeedScreen({Key? key}) : super(key: key);

  @override
  State<HealthFeedScreen> createState() => _HealthFeedScreenState();
}

class _HealthFeedScreenState extends State<HealthFeedScreen> {
  List<HealthCamp> _upcomingCamps = [];
  bool _isLoading = true;
  String? _error;
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _fetchHealthCamps();
    _setupRealtimeUpdates();
  }

  void _setupRealtimeUpdates() {
    _socketService.notificationStream.listen((notification) {
      if (notification['type']?.contains('HEALTH_CAMP') == true ||
          notification['campId'] != null) {
        _fetchHealthCamps();
      }
    });
  }

  Future<void> _fetchHealthCamps() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Please login to view health camps';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConstants.healthCamps),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          final camps = List<Map<String, dynamic>>.from(data['data']);
          setState(() {
            _upcomingCamps = camps.map((camp) => HealthCamp.fromJson(camp)).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'No health camps found';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load health camps';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _registerForCamp(HealthCamp camp) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        _showSnackBar('Please login to register', Colors.red);
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.registerCamp}/${camp.id}/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          await _fetchHealthCamps();
          _showSnackBar('Registered successfully for ${camp.title}!', Colors.green);
        } else {
          _showSnackBar(data['message'] ?? 'Registration failed', Colors.red);
        }
      } else {
        _showSnackBar('Registration failed', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Registration failed', Colors.red);
    }
  }

  Future<void> _cancelRegistration(HealthCamp camp) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Registration', style: TextStyle(color: context.primaryText)),
        content: Text('Cancel registration for "${camp.title}"?', style: TextStyle(color: context.secondaryText)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('No', style: TextStyle(color: context.primaryColor))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('${ApiConstants.registerCamp}/${camp.id}/register'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        await _fetchHealthCamps();
        _showSnackBar('Registration cancelled', Colors.orange);
      } else {
        _showSnackBar('Failed to cancel', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Failed to cancel', Colors.red);
    }
  }

  bool _isUserRegistered(HealthCamp camp) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    return camp.participantIds?.contains(userId) ?? false;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Health Feed & Camps', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchHealthCamps)],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: context.secondaryText)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _fetchHealthCamps, child: const Text('Retry')),
                    ],
                  ),
                )
              : _upcomingCamps.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medical_services, size: 64, color: context.secondaryText.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text('No health camps available', style: TextStyle(color: context.secondaryText)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _buildHeaderStats(),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _upcomingCamps.length,
                            itemBuilder: (context, index) => _buildCampCard(_upcomingCamps[index]),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildHeaderStats() {
    int freeCamps = _upcomingCamps.where((c) => c.isFree).length;
    int totalSlots = _upcomingCamps.fold(0, (s, c) => s + c.availableSlots);
    int registered = _upcomingCamps.fold(0, (s, c) => s + c.registeredParticipants);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF3498db), Color(0xFF2980b9)]),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(freeCamps, 'Free', Icons.medical_services),
          _buildStatItem(totalSlots, 'Slots', Icons.people),
          _buildStatItem(registered, 'Joined', Icons.how_to_reg),
        ],
      ),
    );
  }

  Widget _buildStatItem(int count, String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 2),
        Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9)),
      ],
    );
  }

  Widget _buildCampCard(HealthCamp camp) {
    final isRegistered = _isUserRegistered(camp);
    final daysLeft = camp.date.difference(DateTime.now()).inDays;
    final percent = camp.availableSlots > 0 ? (camp.registeredParticipants / camp.availableSlots) * 100 : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: context.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
                  color: context.primaryColor.withOpacity(0.1),
                ),
                child: camp.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
                        child: Image.network(camp.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.medical_services, size: 40, color: context.secondaryText)),
                      )
                    : Icon(Icons.medical_services, size: 40, color: context.secondaryText),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: camp.isFree ? Colors.green : Colors.red, borderRadius: BorderRadius.circular(12)),
                  child: Text(camp.isFree ? 'FREE' : '₹${camp.fee}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                  child: Text('$daysLeft d left', style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
              if (isRegistered)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.9), borderRadius: BorderRadius.circular(10)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 10, color: Colors.white),
                        SizedBox(width: 2),
                        Text('Joined', style: TextStyle(color: Colors.white, fontSize: 9)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(camp.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.primaryText), maxLines: 1),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: context.secondaryText),
                    const SizedBox(width: 4),
                    Text(DateFormat('MMM dd').format(camp.date), style: TextStyle(fontSize: 11, color: context.secondaryText)),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 12, color: context.secondaryText),
                    const SizedBox(width: 4),
                    Expanded(child: Text(camp.time, style: TextStyle(fontSize: 11, color: context.secondaryText), maxLines: 1)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: context.secondaryText),
                    const SizedBox(width: 4),
                    Expanded(child: Text(camp.location, style: TextStyle(fontSize: 11, color: context.secondaryText), maxLines: 1)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: percent / 100,
                  backgroundColor: context.secondaryText.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF27ae60)),
                  minHeight: 3,
                ),
                const SizedBox(height: 8),
                Text('${camp.registeredParticipants}/${camp.availableSlots} registered', style: TextStyle(fontSize: 10, color: context.secondaryText)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showCampDetails(camp),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(color: context.primaryColor),
                        ),
                        child: Text('Details', style: TextStyle(fontSize: 12, color: context.primaryColor)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: isRegistered
                          ? ElevatedButton(
                              onPressed: () => _cancelRegistration(camp),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 8)),
                              child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                            )
                          : ElevatedButton(
                              onPressed: () => _registerForCamp(camp),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27ae60), padding: const EdgeInsets.symmetric(vertical: 8)),
                              child: const Text('Register', style: TextStyle(fontSize: 12)),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCampDetails(HealthCamp camp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
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
              decoration: BoxDecoration(color: context.secondaryText.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: context.cardColor,
                      ),
                      child: camp.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(camp.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.medical_services, size: 60, color: context.secondaryText)),
                            )
                          : Icon(Icons.medical_services, size: 60, color: context.secondaryText),
                    ),
                    const SizedBox(height: 16),
                    Text(camp.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.primaryText)),
                    const SizedBox(height: 4),
                    Text('by ${camp.organization}', style: TextStyle(color: context.primaryColor, fontSize: 14)),
                    const SizedBox(height: 16),
                    // Info chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _infoChip(Icons.calendar_today, DateFormat('MMM dd, yyyy').format(camp.date)),
                        _infoChip(Icons.access_time, camp.time),
                        _infoChip(Icons.location_on, camp.location),
                        _infoChip(Icons.people, '${camp.registeredParticipants}/${camp.availableSlots} slots'),
                        _infoChip(Icons.attach_money, camp.isFree ? 'Free' : '₹${camp.fee}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.primaryText)),
                    const SizedBox(height: 4),
                    Text(camp.description, style: TextStyle(fontSize: 14, color: context.primaryText.withOpacity(0.8))),
                    const SizedBox(height: 16),
                    Text('Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.primaryText)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: camp.services.map((s) => Chip(
                        label: Text(s, style: TextStyle(fontSize: 12, color: context.primaryText)),
                        backgroundColor: context.primaryColor.withOpacity(0.1),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text('Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.primaryText)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.secondaryText.withOpacity(0.2)),
                      ),
                      child: Text(camp.contact, style: TextStyle(color: context.primaryText)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.secondaryText.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.primaryColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: context.primaryText)),
        ],
      ),
    );
  }
}