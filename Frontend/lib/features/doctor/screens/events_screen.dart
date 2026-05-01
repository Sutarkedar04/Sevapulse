// lib/features/doctor/screens/events_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _error;
  String _filterType = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Please login to view events';
          _isLoading = false;
        });
        return;
      }

      print('📡 Fetching health camps from: ${ApiConstants.healthCamps}');

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
          setState(() {
            _events = List<Map<String, dynamic>>.from(data['data']);
            _isLoading = false;
          });
          print('✅ Loaded ${_events.length} events');
        } else {
          setState(() {
            _error = data['message'] ?? 'No events found';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load events';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching events: $e');
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _createEvent(Map<String, dynamic> newEvent) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        throw Exception('Please login to create event');
      }

      print('📝 Creating health camp: $newEvent');

      final response = await http.post(
        Uri.parse(ApiConstants.healthCamps),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(newEvent),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          await _fetchEvents();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Event created successfully!'),
                backgroundColor: Color(0xFF27ae60),
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to create event');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to create event');
      }
    } catch (e) {
      print('Error creating event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateEvent(String id, Map<String, dynamic> updatedEvent) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        throw Exception('Please login to update event');
      }

      print('📝 Updating health camp: $id');

      final response = await http.put(
        Uri.parse('${ApiConstants.healthCamps}/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updatedEvent),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          await _fetchEvents();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Event updated successfully!'),
                backgroundColor: Color(0xFF27ae60),
              ),
            );
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to update event');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to update event');
      }
    } catch (e) {
      print('Error updating event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteEvent(String id) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        throw Exception('Please login to delete event');
      }

      print('🗑️ Deleting health camp: $id');

      final response = await http.delete(
        Uri.parse('${ApiConstants.healthCamps}/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          await _fetchEvents();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Event deleted successfully'),
                backgroundColor: Color(0xFF27ae60),
              ),
            );
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to delete event');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to delete event');
      }
    } catch (e) {
      print('Error deleting event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewParticipants(Map<String, dynamic> event) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token == null) {
        _showSnackBar('Please login to view participants', Colors.red);
        return;
      }
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      final response = await http.get(
        Uri.parse('${ApiConstants.healthCamps}/${event['_id']}/participants'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      
      // Close loading dialog
      Navigator.pop(context);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          if (data['data'].isEmpty) {
            _showSnackBar('No participants registered yet', Colors.orange);
          } else {
            _showParticipantsDialog(data['data'], event['title']);
          }
        } else {
          _showSnackBar('No participants found', Colors.orange);
        }
      } else if (response.statusCode == 404) {
        _showSnackBar('Participants endpoint not found. Please contact support.', Colors.red);
      } else {
        final data = json.decode(response.body);
        _showSnackBar(data['message'] ?? 'Failed to load participants', Colors.red);
      }
    } catch (e) {
      print('Error fetching participants: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        _showSnackBar('Error: Unable to load participants. Please try again.', Colors.red);
      }
    }
  }

  void _showParticipantsDialog(List<dynamic> participants, String eventTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.secondaryText.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Registered Participants',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              eventTitle,
              style: TextStyle(
                fontSize: 14,
                color: context.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, size: 16, color: context.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Total: ${participants.length} registered',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: participants.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: context.secondaryText.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text(
                            'No participants registered yet',
                            style: TextStyle(color: context.secondaryText),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: participants.length,
                      itemBuilder: (context, index) {
                        final participant = participants[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: context.cardColor,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: context.primaryColor.withOpacity(0.1),
                              child: Text(
                                (participant['name']?.toString().substring(0, 1) ?? 'P').toUpperCase(),
                                style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              participant['name'] ?? 'Unknown',
                              style: TextStyle(fontWeight: FontWeight.bold, color: context.primaryText),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (participant['email'] != null && participant['email'].isNotEmpty)
                                  Text('📧 ${participant['email']}', style: TextStyle(fontSize: 12, color: context.secondaryText)),
                                if (participant['phone'] != null && participant['phone'].isNotEmpty)
                                  Text('📱 ${participant['phone']}', style: TextStyle(fontSize: 12, color: context.secondaryText)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (participant['phone'] != null && participant['phone'].isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.call, size: 20, color: Color(0xFF27ae60)),
                                    onPressed: () {
                                      _showSnackBar('Calling ${participant['phone']}', const Color(0xFF27ae60));
                                    },
                                  ),
                                IconButton(
                                  icon: Icon(Icons.message, size: 20, color: context.primaryColor),
                                  onPressed: () {
                                    _showSnackBar('Message to ${participant['name']}', context.primaryColor);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _sendReminder(Map<String, dynamic> event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminders sent to ${event['registeredParticipants'] ?? 0} registered patients'),
        backgroundColor: const Color(0xFF27ae60),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredEvents {
    List<Map<String, dynamic>> filtered = _events.where((event) {
      final matchesSearch = event['title']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      
      if (_filterType == 'upcoming') {
        final eventDate = DateTime.tryParse(event['date'] ?? '');
        final isUpcoming = eventDate != null && 
            eventDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));
        return matchesSearch && isUpcoming;
      } else if (_filterType == 'past') {
        final eventDate = DateTime.tryParse(event['date'] ?? '');
        final isPast = eventDate != null && 
            eventDate.isBefore(DateTime.now());
        return matchesSearch && isPast;
      }
      
      return matchesSearch;
    }).toList();

    filtered.sort((a, b) {
      final dateA = DateTime.tryParse(a['date'] ?? '');
      final dateB = DateTime.tryParse(b['date'] ?? '');
      
      if (dateA == null || dateB == null) return 0;
      return dateA.compareTo(dateB);
    });

    return filtered;
  }

  void _createNewEvent() {
    showDialog(
      context: context,
      builder: (context) => EventDialog(
        onSave: (newEvent) async {
          await _createEvent(newEvent);
        },
      ),
    );
  }

  void _editEvent(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => EventDialog(
        event: event,
        onSave: (updatedEvent) async {
          await _updateEvent(event['_id'], updatedEvent);
        },
      ),
    );
  }

  void _deleteEventConfirm(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Event', style: TextStyle(color: context.primaryText)),
        content: Text('Are you sure you want to delete "${event['title']}"?', style: TextStyle(color: context.secondaryText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: context.primaryColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent(event['_id']);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFe74c3c),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewEvent,
        backgroundColor: const Color(0xFF27ae60),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
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
                      ElevatedButton(
                        onPressed: _fetchEvents,
                        style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: context.surfaceColor,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Medical Events & Camps',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: context.primaryText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          TextField(
                            style: TextStyle(color: context.primaryText),
                            decoration: InputDecoration(
                              hintText: 'Search events...',
                              hintStyle: TextStyle(color: context.secondaryText),
                              prefixIcon: Icon(Icons.search, color: context.secondaryText),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: context.cardColor,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          
                          Row(
                            children: [
                              FilterChip(
                                label: Text('All Events', style: TextStyle(color: _filterType == 'all' ? Colors.white : context.primaryText)),
                                selected: _filterType == 'all',
                                onSelected: (selected) {
                                  setState(() {
                                    _filterType = selected ? 'all' : _filterType;
                                  });
                                },
                                selectedColor: context.primaryColor,
                                backgroundColor: context.cardColor,
                                checkmarkColor: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: Text('Upcoming', style: TextStyle(color: _filterType == 'upcoming' ? Colors.white : context.primaryText)),
                                selected: _filterType == 'upcoming',
                                onSelected: (selected) {
                                  setState(() {
                                    _filterType = selected ? 'upcoming' : _filterType;
                                  });
                                },
                                selectedColor: const Color(0xFF27ae60),
                                backgroundColor: context.cardColor,
                                checkmarkColor: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: Text('Past', style: TextStyle(color: _filterType == 'past' ? Colors.white : context.primaryText)),
                                selected: _filterType == 'past',
                                onSelected: (selected) {
                                  setState(() {
                                    _filterType = selected ? 'past' : _filterType;
                                  });
                                },
                                selectedColor: const Color(0xFFe67e22),
                                backgroundColor: context.cardColor,
                                checkmarkColor: Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(16),
                      color: context.backgroundColor,
                      child: Row(
                        children: [
                          _buildStatCard('Total Events', _events.length, context.primaryColor),
                          const SizedBox(width: 12),
                          _buildStatCard('Upcoming', 
                            _events.where((e) {
                              final date = DateTime.tryParse(e['date'] ?? '');
                              return date != null && date.isAfter(DateTime.now());
                            }).length, 
                            const Color(0xFF27ae60)),
                          const SizedBox(width: 12),
                          _buildStatCard('Total Registrations', 
                            _events.fold<int>(0, (sum, event) => sum + ((event['registeredParticipants'] as int?) ?? 0)),
                            const Color(0xFFe67e22)),
                        ],
                      ),
                    ),

                    Expanded(
                      child: _filteredEvents.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredEvents.length,
                              itemBuilder: (context, index) => _buildEventCard(_filteredEvents[index]),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDuration(DateTime startDate, DateTime endDate) {
    final difference = endDate.difference(startDate).inDays;
    if (difference == 0) return 'Single day event';
    if (difference == 1) return '2 days event';
    return '${difference + 1} days event';
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final eventDate = DateTime.tryParse(event['date'] ?? '');
    final endDate = event['endDate'] != null 
        ? DateTime.tryParse(event['endDate']) 
        : eventDate;
    final isPast = eventDate != null && eventDate.isBefore(DateTime.now());
    final isToday = eventDate != null && 
        eventDate.year == DateTime.now().year &&
        eventDate.month == DateTime.now().month &&
        eventDate.day == DateTime.now().day;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: context.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    event['title'] ?? 'Untitled Event',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.primaryText,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFe74c3c).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'TODAY',
                            style: TextStyle(
                              color: Color(0xFFe74c3c),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (isPast)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.secondaryText.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'PAST',
                            style: TextStyle(
                              color: context.secondaryText,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF27ae60).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'UPCOMING',
                            style: TextStyle(
                              color: Color(0xFF27ae60),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${event['registeredParticipants'] ?? 0} Registered',
                          style: TextStyle(
                            color: context.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Timeline Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: eventDate != null && eventDate.isAfter(DateTime.now())
                    ? const Color(0xFF27ae60).withOpacity(0.1)
                    : context.secondaryText.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timeline,
                    size: 16,
                    color: eventDate != null && eventDate.isAfter(DateTime.now())
                        ? const Color(0xFF27ae60)
                        : context.secondaryText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventDate != null && endDate != null && eventDate != endDate
                              ? '${DateFormat('MMM dd').format(eventDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}'
                              : (eventDate != null 
                                  ? DateFormat('MMM dd, yyyy').format(eventDate)
                                  : 'Date not set'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: eventDate != null && eventDate.isAfter(DateTime.now())
                                ? const Color(0xFF27ae60)
                                : context.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          event['time'] ?? 'Time not specified',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (eventDate != null && endDate != null && eventDate != endDate)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getDuration(eventDate, endDate),
                        style: TextStyle(
                          fontSize: 10,
                          color: context.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            _buildEventDetail(Icons.location_on, event['location'] ?? 'No location'),
            const SizedBox(height: 8),
            if (event['description'] != null && event['description'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventDetail(Icons.description, event['description']),
                  const SizedBox(height: 8),
                ],
              ),
            
            // Services
            if (event['services'] != null && (event['services'] as List).isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: (event['services'] as List).take(3).map((service) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    service.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: context.primaryColor,
                    ),
                  ),
                )).toList(),
              ),
            
            const SizedBox(height: 12),
            
            // Button Row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                if (!isPast) ...[
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () => _viewParticipants(event),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27ae60),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text('View Participants'),
                      ),
                      ElevatedButton(
                        onPressed: () => _sendReminder(event),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text('Send Reminder'),
                      ),
                    ],
                  ),
                ],
                Wrap(
                  children: [
                    IconButton(
                      onPressed: () => _editEvent(event),
                      icon: Icon(Icons.edit, color: context.primaryColor),
                      tooltip: 'Edit Event',
                    ),
                    IconButton(
                      onPressed: () => _deleteEventConfirm(event),
                      icon: const Icon(Icons.delete, color: Color(0xFFe74c3c)),
                      tooltip: 'Delete Event',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetail(IconData icon, String text, [String? subText]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: context.secondaryText),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(color: context.primaryText),
              ),
              if (subText != null)
                Text(
                  subText,
                  style: TextStyle(
                    color: context.secondaryText,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event,
            size: 80,
            color: context.secondaryText.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Events Created',
            style: TextStyle(
              fontSize: 18,
              color: context.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Create your first medical event or health camp to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.secondaryText.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _createNewEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27ae60),
              foregroundColor: Colors.white,
            ),
            child: const Text('Create First Event'),
          ),
        ],
      ),
    );
  }
}

// Updated Event Dialog with Timeline (Start Date and End Date)
class EventDialog extends StatefulWidget {
  final Map<String, dynamic>? event;
  final Function(Map<String, dynamic>) onSave;

  const EventDialog({
    Key? key,
    this.event,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _servicesController = TextEditingController();
  final _contactController = TextEditingController();
  final _slotsController = TextEditingController();
  final _feeController = TextEditingController();
  
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  bool _isFree = true;
  bool _isMultiDay = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!['title'] ?? '';
      _descriptionController.text = widget.event!['description'] ?? '';
      _locationController.text = widget.event!['location'] ?? '';
      _servicesController.text = (widget.event!['services'] as List? ?? []).join(', ');
      _contactController.text = widget.event!['contact'] ?? '';
      _slotsController.text = (widget.event!['availableSlots'] ?? 100).toString();
      _selectedStartDate = DateTime.tryParse(widget.event!['date'] ?? '');
      _isFree = widget.event!['isFree'] ?? true;
      if (!_isFree && widget.event!['fee'] != null) {
        _feeController.text = widget.event!['fee'].toString();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _servicesController.dispose();
    _contactController.dispose();
    _slotsController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedStartDate) {
      setState(() {
        _selectedStartDate = picked;
        if (!_isMultiDay && _selectedEndDate == null) {
          _selectedEndDate = picked;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? (_selectedStartDate ?? DateTime.now()),
      firstDate: _selectedStartDate ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedEndDate) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null && picked != _selectedStartTime) {
      setState(() {
        _selectedStartTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? const TimeOfDay(hour: 17, minute: 0),
    );
    if (picked != null && picked != _selectedEndTime) {
      setState(() {
        _selectedEndTime = picked;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return 'Not set';
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate()) {
      if (_selectedStartDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select start date'), backgroundColor: Colors.red),
        );
        return;
      }

      final services = _servicesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      
      final timeString = _selectedStartTime != null && _selectedEndTime != null
          ? '${_formatTimeOfDay(_selectedStartTime)} - ${_formatTimeOfDay(_selectedEndTime)}'
          : (_selectedStartTime != null ? _formatTimeOfDay(_selectedStartTime) : '9:00 AM - 5:00 PM');
      
      final event = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'date': _selectedStartDate!.toIso8601String(),
        'endDate': _selectedEndDate != null ? _selectedEndDate!.toIso8601String() : _selectedStartDate!.toIso8601String(),
        'time': timeString,
        'services': services,
        'contact': _contactController.text,
        'availableSlots': int.parse(_slotsController.text),
        'isFree': _isFree,
        'organization': 'Seva Pulse Hospital',
        'isMultiDay': _isMultiDay,
      };
      
      if (!_isFree && _feeController.text.isNotEmpty) {
        event['fee'] = int.parse(_feeController.text);
      }
      
      widget.onSave(event);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(widget.event == null ? 'Create New Event' : 'Edit Event', style: TextStyle(color: context.primaryText)),
      backgroundColor: context.surfaceColor,
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: context.primaryText),
                decoration: InputDecoration(
                  labelText: 'Event Title *',
                  labelStyle: TextStyle(color: context.secondaryText),
                  border: const OutlineInputBorder(),
                  hintText: 'e.g., Free Diabetes Screening Camp',
                  hintStyle: TextStyle(color: context.secondaryText),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: context.primaryText),
                decoration: InputDecoration(
                  labelText: 'Description *',
                  labelStyle: TextStyle(color: context.secondaryText),
                  border: const OutlineInputBorder(),
                  hintText: 'Describe the event purpose and activities...',
                  hintStyle: TextStyle(color: context.secondaryText),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                style: TextStyle(color: context.primaryText),
                decoration: InputDecoration(
                  labelText: 'Location *',
                  labelStyle: TextStyle(color: context.secondaryText),
                  border: const OutlineInputBorder(),
                  hintText: 'e.g., Hospital Campus, Conference Hall',
                  hintStyle: TextStyle(color: context.secondaryText),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Multi-day toggle
              Row(
                children: [
                  Text('Multi-day event?', style: TextStyle(color: context.primaryText)),
                  const SizedBox(width: 16),
                  Switch(
                    value: _isMultiDay,
                    onChanged: (value) {
                      setState(() {
                        _isMultiDay = value;
                        if (!value && _selectedEndDate != null && _selectedStartDate != null) {
                          _selectedEndDate = _selectedStartDate;
                        }
                      });
                    },
                    activeColor: context.primaryColor,
                  ),
                  Text(_isMultiDay ? 'Yes' : 'No', style: TextStyle(color: context.primaryText)),
                ],
              ),
              const SizedBox(height: 16),
              
              // Start Date
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      style: TextStyle(color: context.primaryText),
                      decoration: InputDecoration(
                        labelText: 'Start Date *',
                        labelStyle: TextStyle(color: context.secondaryText),
                        border: const OutlineInputBorder(),
                        hintText: _selectedStartDate == null 
                            ? 'Select start date' 
                            : DateFormat('MMM dd, yyyy').format(_selectedStartDate!),
                        hintStyle: TextStyle(color: context.primaryText),
                        suffixIcon: IconButton(
                          onPressed: _selectStartDate,
                          icon: Icon(Icons.calendar_today, color: context.primaryColor),
                        ),
                      ),
                      validator: (value) {
                        if (_selectedStartDate == null) {
                          return 'Please select start date';
                        }
                        return null;
                      },
                    ),
                  ),
                  if (_isMultiDay) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        style: TextStyle(color: context.primaryText),
                        decoration: InputDecoration(
                          labelText: 'End Date',
                          labelStyle: TextStyle(color: context.secondaryText),
                          border: const OutlineInputBorder(),
                          hintText: _selectedEndDate == null 
                              ? 'Select end date' 
                              : DateFormat('MMM dd, yyyy').format(_selectedEndDate!),
                          hintStyle: TextStyle(color: context.primaryText),
                          suffixIcon: IconButton(
                            onPressed: _selectEndDate,
                            icon: Icon(Icons.calendar_today, color: context.primaryColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              
              // Start Time and End Time
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      style: TextStyle(color: context.primaryText),
                      decoration: InputDecoration(
                        labelText: 'Start Time',
                        labelStyle: TextStyle(color: context.secondaryText),
                        border: const OutlineInputBorder(),
                        hintText: _selectedStartTime == null 
                            ? 'Select start time' 
                            : _formatTimeOfDay(_selectedStartTime),
                        hintStyle: TextStyle(color: context.primaryText),
                        suffixIcon: IconButton(
                          onPressed: _selectStartTime,
                          icon: Icon(Icons.access_time, color: context.primaryColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      style: TextStyle(color: context.primaryText),
                      decoration: InputDecoration(
                        labelText: 'End Time',
                        labelStyle: TextStyle(color: context.secondaryText),
                        border: const OutlineInputBorder(),
                        hintText: _selectedEndTime == null 
                            ? 'Select end time' 
                            : _formatTimeOfDay(_selectedEndTime),
                        hintStyle: TextStyle(color: context.primaryText),
                        suffixIcon: IconButton(
                          onPressed: _selectEndTime,
                          icon: Icon(Icons.access_time, color: context.primaryColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _servicesController,
                style: TextStyle(color: context.primaryText),
                decoration: InputDecoration(
                  labelText: 'Services (comma separated) *',
                  labelStyle: TextStyle(color: context.secondaryText),
                  border: const OutlineInputBorder(),
                  hintText: 'e.g., ECG, BP Check, Blood Test',
                  hintStyle: TextStyle(color: context.secondaryText),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter at least one service';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                style: TextStyle(color: context.primaryText),
                decoration: InputDecoration(
                  labelText: 'Contact Number *',
                  labelStyle: TextStyle(color: context.secondaryText),
                  border: const OutlineInputBorder(),
                  hintText: 'e.g., +91-9876543210',
                  hintStyle: TextStyle(color: context.secondaryText),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _slotsController,
                style: TextStyle(color: context.primaryText),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Available Slots *',
                  labelStyle: TextStyle(color: context.secondaryText),
                  border: const OutlineInputBorder(),
                  hintText: 'e.g., 100',
                  hintStyle: TextStyle(color: context.secondaryText),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter available slots';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Is this camp free?', style: TextStyle(color: context.primaryText)),
                  const SizedBox(width: 16),
                  Switch(
                    value: _isFree,
                    onChanged: (value) {
                      setState(() {
                        _isFree = value;
                      });
                    },
                    activeColor: const Color(0xFF27ae60),
                  ),
                  const SizedBox(width: 8),
                  Text(_isFree ? 'FREE' : 'PAID', style: TextStyle(color: context.primaryText)),
                ],
              ),
              if (!_isFree) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _feeController,
                  style: TextStyle(color: context.primaryText),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Fee (in ₹) *',
                    labelStyle: TextStyle(color: context.secondaryText),
                    border: const OutlineInputBorder(),
                    hintText: 'e.g., 500',
                    hintStyle: TextStyle(color: context.secondaryText),
                  ),
                  validator: (value) {
                    if (!_isFree && (value == null || value.isEmpty)) {
                      return 'Please enter fee amount';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: context.primaryColor)),
        ),
        ElevatedButton(
          onPressed: _saveEvent,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF27ae60),
          ),
          child: Text(widget.event == null ? 'Create Event' : 'Update Event'),
        ),
      ],
    );
  }
}