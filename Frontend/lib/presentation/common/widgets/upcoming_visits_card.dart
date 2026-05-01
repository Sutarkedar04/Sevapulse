// lib/presentation/common/widgets/upcoming_visits_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION
import '../../../data/models/appointment_model.dart';
import '../../../data/providers/appointment_provider.dart';
import 'appointment_item.dart';

class UpcomingVisitsCard extends StatelessWidget {
  final List<Appointment> upcomingAppointments;
  final VoidCallback? onBookAppointment;

  const UpcomingVisitsCard({
    Key? key,
    required this.upcomingAppointments,
    this.onBookAppointment,
  }) : super(key: key);

  void _showAppointmentDetails(BuildContext context, Appointment appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              color: context.surfaceColor.withOpacity(0.85),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    'Dr. ${appointment.doctorName}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appointment.specialty ?? 'General',
                    style: TextStyle(
                      fontSize: 16,
                      color: context.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildGlassDetailRow(context, 'Date', DateFormat('EEEE, MMMM d, yyyy').format(appointment.date.toLocal())),
                  _buildGlassDetailRow(context, 'Time', appointment.time),
                  _buildGlassDetailRow(context, 'Status', appointment.status.toUpperCase()),
                  _buildGlassDetailRow(context, 'Type', appointment.type),
                  if (appointment.symptoms.isNotEmpty)
                    _buildGlassDetailRow(context, 'Symptoms', appointment.symptoms),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Close', style: TextStyle(color: context.primaryColor)),
                        ),
                      ),
                      if (appointment.status == 'pending')
                        const SizedBox(width: 12),
                      if (appointment.status == 'pending')
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _cancelAppointment(context, appointment);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel Appointment'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.primaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: context.secondaryText),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(BuildContext context, Appointment appointment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('Cancel Appointment', style: TextStyle(color: context.primaryText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel your appointment with:', style: TextStyle(color: context.secondaryText)),
            const SizedBox(height: 8),
            Text(
              'Dr. ${appointment.doctorName}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.primaryText),
            ),
            Text('Date: ${DateFormat('EEEE, MMMM d, yyyy').format(appointment.date.toLocal())}', style: TextStyle(color: context.secondaryText)),
            Text('Time: ${appointment.time}', style: TextStyle(color: context.secondaryText)),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No, Keep It', style: TextStyle(color: context.primaryColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Cancelling appointment...'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final appointmentProvider = Provider.of<AppointmentProvider>(
        context,
        listen: false,
      );
      
      print('🔄 Attempting to cancel appointment with ID: ${appointment.id}');
      final success = await appointmentProvider.cancelAppointment(appointment.id);
      
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).clearSnackBars();
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment with Dr. ${appointment.doctorName} cancelled successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appointmentProvider.error ?? 'Failed to cancel appointment'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final upcoming = upcomingAppointments.where((apt) {
      final localDate = apt.date.toLocal();
      final aptDate = DateTime(localDate.year, localDate.month, localDate.day);
      final isNotCancelled = apt.status.toLowerCase() != 'cancelled';
      return (aptDate.isAtSameMomentAs(today) || aptDate.isAfter(today)) && isNotCancelled;
    }).toList();
    
    final past = upcomingAppointments.where((apt) {
      final localDate = apt.date.toLocal();
      final aptDate = DateTime(localDate.year, localDate.month, localDate.day);
      final isNotCancelled = apt.status.toLowerCase() != 'cancelled';
      return aptDate.isBefore(today) && isNotCancelled;
    }).toList();

    final sortedUpcoming = [...upcoming]..sort((a, b) => a.date.compareTo(b.date));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.surfaceColor.withOpacity(0.9),
                  context.surfaceColor.withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: context.surfaceColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              context.primaryColor,
                              const Color(0xFF2980b9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.upcoming,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'My Appointments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.primaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Upcoming Appointments Section
                  if (sortedUpcoming.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF27ae60).withOpacity(0.1),
                            const Color(0xFF27ae60).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Upcoming',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF27ae60),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...sortedUpcoming.map((appointment) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassAppointmentCard(
                          appointment: appointment,
                          onTap: () => _showAppointmentDetails(context, appointment),
                          showCancelButton: appointment.status == 'pending',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Past Appointments Section
                  if (past.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.secondaryText.withOpacity(0.1),
                            context.secondaryText.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Past Appointments',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.secondaryText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...past.map((appointment) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassAppointmentCard(
                          appointment: appointment,
                          onTap: () => _showAppointmentDetails(context, appointment),
                          showCancelButton: false,
                        ),
                      ),
                    ),
                  ],
                  
                  // Empty State
                  if (upcomingAppointments.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: context.surfaceColor.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 48,
                                  color: context.secondaryText.withOpacity(0.6),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No appointments found',
                                  style: TextStyle(
                                    color: context.secondaryText,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Book an appointment to see it here',
                                  style: TextStyle(
                                    color: context.secondaryText.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (onBookAppointment != null)
                                  SizedBox(
                                    width: 200,
                                    child: ElevatedButton(
                                      onPressed: onBookAppointment,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: context.primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text('Book Appointment'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Glass effect appointment card widget
class GlassAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onTap;
  final bool showCancelButton;

  const GlassAppointmentCard({
    Key? key,
    required this.appointment,
    this.onTap,
    this.showCancelButton = true,
  }) : super(key: key);

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final appointmentDate = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
    );
    
    if (appointmentDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (appointmentDate.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow';
    } else {
      return DateFormat('dd MMM yyyy').format(localDate);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF27ae60);
      case 'pending':
        return const Color(0xFFf39c12);
      case 'completed':
        return const Color(0xFF3498db);
      case 'cancelled':
        return const Color(0xFFe74c3c);
      default:
        return const Color(0xFF7f8c8d);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localDate = appointment.date.toLocal();
    final isPast = localDate.isBefore(DateTime.now());
    final statusColor = _getStatusColor(appointment.status);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.surfaceColor.withOpacity(0.95),
              context.surfaceColor.withOpacity(0.85),
            ],
          ),
          border: Border.all(
            color: isPast ? context.secondaryText.withOpacity(0.3) : statusColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Status indicator
                  Container(
                    width: 4,
                    height: 50,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Dr. ${appointment.doctorName}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: context.primaryText,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                appointment.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: context.secondaryText.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(appointment.date),
                              style: TextStyle(
                                color: context.secondaryText,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: context.secondaryText.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              appointment.time,
                              style: TextStyle(
                                color: context.secondaryText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        if (appointment.symptoms.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.medical_information,
                                size: 12,
                                color: context.secondaryText.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  appointment.symptoms,
                                  style: TextStyle(
                                    color: context.secondaryText,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Arrow
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: context.secondaryText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}