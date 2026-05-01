// lib/data/providers/appointment_provider.dart
import 'package:flutter/foundation.dart';
import '../models/appointment_model.dart';
import '../../core/services/appointment_service.dart';
import '../../core/services/local_notification_service.dart';

class AppointmentProvider with ChangeNotifier {
  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _error;

  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final AppointmentService _appointmentService = AppointmentService();
  final LocalNotificationService _notifService = LocalNotificationService();

  void setToken(String token) {
    _appointmentService.setToken(token);
  }

  // ─── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadAppointments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _appointments = await _appointmentService.getAppointments();
      debugPrint('✅ Loaded ${_appointments.length} appointments');

      // Schedule reminders for every upcoming/today appointment
      await _notifService.initialize();
      await _rescheduleAllReminders();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('❌ Error loading appointments: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Book ──────────────────────────────────────────────────────────────────

  Future<bool> bookAppointmentWithData(
      Map<String, dynamic> appointmentData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newAppt =
          await _appointmentService.bookAppointment(appointmentData);
      _appointments.add(newAppt);

      // Schedule reminders for the newly booked appointment
      await _notifService.initialize();
      await _notifService
          .scheduleAppointmentReminders(_appointmentToMap(newAppt));

      debugPrint('✅ Appointment booked: ${newAppt.id}');
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('❌ Error booking appointment: $_error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Update status ─────────────────────────────────────────────────────────

  Future<bool> updateAppointmentStatus(String id, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated =
          await _appointmentService.updateAppointmentStatusAPI(id, status);
      final index = _appointments.indexWhere((a) => a.id == id);
      if (index != -1) {
        _appointments[index] = updated;
      }

      // If appointment is now cancelled/completed, remove its reminders
      if (status.toLowerCase() == 'cancelled' ||
          status.toLowerCase() == 'completed') {
        await _notifService.cancelAppointmentReminders(id);
      }

      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('❌ Error updating appointment: $_error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // In appointment_provider.dart, update the cancelAppointment method:

Future<bool> cancelAppointment(String id) async {
  print('🔄 Provider.cancelAppointment called with ID: $id');
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    print('🔄 Calling appointmentService.cancelAppointment for ID: $id');
    await _appointmentService.cancelAppointment(id);
    final beforeCount = _appointments.length;
    _appointments.removeWhere((a) => a.id == id);
    final afterCount = _appointments.length;
    print('✅ Provider: Appointment cancelled, removed ${beforeCount - afterCount} appointment(s)');
    print('✅ Provider: Remaining appointments: ${_appointments.length}');
    _isLoading = false;
    notifyListeners();
    return true;
  } catch (e) {
    _error = e.toString().replaceFirst('Exception: ', '');
    print('❌ Provider Error cancelling appointment: $_error');
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Convert an [Appointment] to the map shape expected by
  /// [LocalNotificationService.scheduleAppointmentReminders].
  Map<String, dynamic> _appointmentToMap(Appointment a) => {
        'id':         a.id,
        'doctorName': a.doctorName,
        'date':       a.date.toIso8601String(),
        'time':       a.time,
        'status':     a.status,
      };

  /// (Re)schedule reminders for all appointments that are still pending/confirmed
  /// and whose date is today or in the future.
  Future<void> _rescheduleAllReminders() async {
    final now       = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    final upcoming = _appointments.where((a) {
      final status = a.status.toLowerCase();
      if (status == 'cancelled' || status == 'completed') return false;
      final aDate = DateTime(a.date.year, a.date.month, a.date.day);
      return !aDate.isBefore(todayDate);
    }).toList();

    for (final a in upcoming) {
      await _notifService.scheduleAppointmentReminders(_appointmentToMap(a));
    }

    debugPrint('✅ Scheduled reminders for ${upcoming.length} upcoming appointments');
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}