import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/appointment_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION

class BookAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final String specialty;

  const BookAppointmentScreen({
    Key? key,
    required this.doctor,
    required this.specialty,
  }) : super(key: key);

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime? _selectedDate;
  String? _selectedSlot;
  DateTime _currentMonth = DateTime.now();
  bool _isBooking = false;
  List<String> _availableSlots = [];
  bool _isLoadingSlots = false;
  
  final List<String> _allTimeSlots = [
    '09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM',
    '11:00 AM', '11:30 AM', '12:00 PM', '12:30 PM',
    '02:00 PM', '02:30 PM', '03:00 PM', '03:30 PM',
    '04:00 PM', '04:30 PM', '05:00 PM'
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _selectedDate == null 
          ? _buildDateSelection(user) 
          : _buildTimeSelection(user),
    );
  }

  Widget _buildDateSelection(user) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          color: context.cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: context.primaryColor.withOpacity(0.1),
                  child: Icon(Icons.medical_services, color: context.primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.doctor['name'] ?? 'Doctor Name',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.specialty,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.doctor['hospital'] ?? 'City Hospital',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.all(16),
          color: context.surfaceColor,
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: context.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Select Date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.primaryText,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.all(16),
          color: context.backgroundColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: Icon(Icons.chevron_left, color: context.primaryColor),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_currentMonth),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.primaryText,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: Icon(Icons.chevron_right, color: context.primaryColor),
              ),
            ],
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildCalendar(),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;

    final previousMonthDays = <String>[];
    if (firstWeekday != 1) {
      final prevMonthLastDay = DateTime(_currentMonth.year, _currentMonth.month, 0).day;
      for (int i = firstWeekday - 1; i > 0; i--) {
        previousMonthDays.add((prevMonthLastDay - i + 1).toString());
      }
    }

    final currentMonthDays = List.generate(daysInMonth, (i) => (i + 1).toString());
    final totalCells = ((previousMonthDays.length + daysInMonth) / 7).ceil() * 7;

    return Column(
      children: [
        Row(
          children: [
            _buildDayHeader('M'),
            _buildDayHeader('T'),
            _buildDayHeader('W'),
            _buildDayHeader('T'),
            _buildDayHeader('F'),
            _buildDayHeader('S'),
            _buildDayHeader('S'),
          ],
        ),
        const SizedBox(height: 8),

        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              String dayText = '';
              bool isCurrentMonth = false;
              bool isAvailable = false;

              if (index < previousMonthDays.length) {
                dayText = previousMonthDays[index];
                isCurrentMonth = false;
              } else if (index < previousMonthDays.length + daysInMonth) {
                final day = int.parse(currentMonthDays[index - previousMonthDays.length]);
                dayText = day.toString();
                isCurrentMonth = true;
                
                final date = DateTime(_currentMonth.year, _currentMonth.month, day);
                final today = DateTime.now();
                final localToday = DateTime(today.year, today.month, today.day);
                final localDate = DateTime(date.year, date.month, date.day);
                
                isAvailable = !localDate.isBefore(localToday);
              } else {
                dayText = (index - previousMonthDays.length - daysInMonth + 1).toString();
                isCurrentMonth = false;
              }

              final day = int.tryParse(dayText) ?? 0;

              return GestureDetector(
                onTap: isCurrentMonth && isAvailable
                    ? () {
                        print('📅 Date selected: $day/${_currentMonth.month}/${_currentMonth.year}');
                        final selectedDate = DateTime(
                          _currentMonth.year,
                          _currentMonth.month,
                          day,
                        );
                        _checkAvailableSlots(selectedDate);
                      }
                    : null,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrentMonth && isAvailable
                            ? context.primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          dayText,
                          style: TextStyle(
                            color: isCurrentMonth && isAvailable
                                ? context.primaryColor
                                : context.secondaryText.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayHeader(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: context.primaryText,
          fontSize: 14,
        ),
      ),
    );
  }

  Future<void> _checkAvailableSlots(DateTime date) async {
    print('=== CHECKING SLOTS FOR DATE: $date ===');
    
    setState(() {
      _selectedDate = date;
      _isLoadingSlots = true;
      _availableSlots = [];
      _selectedSlot = null;
    });
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    
    print('Is today: $isToday');
    print('Current time: ${DateFormat('hh:mm a').format(now)}');
    
    final List<String> slots = [];
    
    for (var slot in _allTimeSlots) {
      if (isToday) {
        final slotTime = _parseTimeOfDay(slot);
        final slotDateTime = DateTime(now.year, now.month, now.day, slotTime.hour, slotTime.minute);
        
        // Only add slots that are in the future
        if (slotDateTime.isAfter(now)) {
          slots.add(slot);
          print('✅ Available (future): $slot');
        } else {
          print('❌ Skipped (past): $slot');
        }
      } else {
        // For future dates, show all slots
        slots.add(slot);
        print('✅ Available (future date): $slot');
      }
    }
    
    print('Total available slots: ${slots.length}');
    
    setState(() {
      _availableSlots = slots;
      _isLoadingSlots = false;
    });
    
    print('=== SLOT CHECK COMPLETE ===');
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  Widget _buildTimeSelection(user) {
    if (_isLoadingSlots) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
            ),
            const SizedBox(height: 16),
            Text('Finding available slots...', style: TextStyle(color: context.secondaryText)),
          ],
        ),
      );
    }
    
    if (_availableSlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: context.secondaryText.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No available slots for this date',
              style: TextStyle(fontSize: 16, color: context.secondaryText),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select another date',
              style: TextStyle(color: context.secondaryText.withOpacity(0.7)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedDate = null;
                  _availableSlots = [];
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor),
              child: const Text('Back to Calendar'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: context.surfaceColor,
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = null;
                    _selectedSlot = null;
                    _availableSlots = [];
                  });
                },
                icon: Icon(Icons.arrow_back, color: context.primaryColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Slots',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.primaryText,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Card(
          margin: const EdgeInsets.all(16),
          color: context.cardColor,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: context.primaryColor.withOpacity(0.1),
                  child: Icon(Icons.medical_services, size: 20, color: context.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.doctor['name'] ?? 'Doctor',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: context.primaryText,
                        ),
                      ),
                      Text(
                        widget.specialty,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.0,
            ),
            itemCount: _availableSlots.length,
            itemBuilder: (context, index) {
              final slot = _availableSlots[index];
              final isSelected = _selectedSlot == slot;
              
              return ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedSlot = slot;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected 
                      ? context.primaryColor
                      : context.cardColor,
                  foregroundColor: isSelected ? Colors.white : context.primaryText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: isSelected ? 4 : 0,
                  side: isSelected ? null : BorderSide(color: context.secondaryText.withOpacity(0.2)),
                ),
                child: Text(
                  slot,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _selectedSlot != null && !_isBooking
                ? () => _showConfirmationDialog(user)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27ae60),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _isBooking
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Confirm Appointment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    final format = DateFormat('hh:mm a');
    final date = format.parse(timeString);
    return TimeOfDay.fromDateTime(date);
  }

  void _showConfirmationDialog(user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Appointment', style: TextStyle(color: context.primaryText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doctor: ${widget.doctor['name']}', style: TextStyle(color: context.primaryText)),
            Text('Specialty: ${widget.specialty}', style: TextStyle(color: context.primaryText)),
            Text('Date: ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!)}', style: TextStyle(color: context.primaryText)),
            Text('Time: $_selectedSlot', style: TextStyle(color: context.primaryText)),
            const Divider(),
            Text('Patient: ${user?.name ?? "User"}', style: TextStyle(color: context.primaryText)),
            Text('Email: ${user?.email ?? "N/A"}', style: TextStyle(color: context.primaryText)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: context.primaryColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _bookAppointment(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27ae60),
            ),
            child: const Text('Confirm Booking'),
          ),
        ],
      ),
    );
  }

  Future<void> _bookAppointment(user) async {
    setState(() {
      _isBooking = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token == null || token.isEmpty) {
        throw Exception('Please login again. Token not found.');
      }

      final selectedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        0, 0, 0, 0, 0
      );
      
      final utcDateTime = selectedDateTime.toUtc();

      final appointmentData = {
        'doctorId': widget.doctor['id'],
        'date': utcDateTime.toIso8601String(),
        'time': _selectedSlot,
        'type': 'consultation',
        'symptoms': 'General Consultation',
      };

      print('📝 Booking appointment: $appointmentData');

      final response = await http.post(
        Uri.parse(ApiConstants.appointments),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(appointmentData),
      );

      print('📡 Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success']) {
          await Provider.of<AppointmentProvider>(context, listen: false).loadAppointments();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Appointment booked successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to book appointment');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to book appointment');
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }
}