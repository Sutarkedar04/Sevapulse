// lib/core/services/appointment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../data/models/appointment_model.dart';

class AppointmentService {
  String? _token;
  List<Appointment> _appointments = [];

  void setToken(String token) {
    _token = token;
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final data = json.decode(response.body);
    print('📡 Response status: ${response.statusCode}');
    print('📡 Response body: ${response.body}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Something went wrong');
    }
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Helper to normalize IDs for comparison
  String _normalizeId(String? id) {
    if (id == null) return '';
    String normalized = id.trim();
    // Remove ObjectId() wrapper if present
    if (normalized.startsWith('ObjectId(')) {
      normalized = normalized.replaceAll('ObjectId(', '').replaceAll(')', '');
    }
    // Remove quotes
    normalized = normalized.replaceAll('"', '').replaceAll("'", '');
    return normalized;
  }

  // Get all appointments from API
  Future<List<Appointment>> getAppointments() async {
    try {
      print('\n=== 📋 GETTING APPOINTMENTS FROM API ===');
      print('URL: ${ApiConstants.appointments}');
      print('Headers: ${_getHeaders()}');
      
      final response = await http.get(
        Uri.parse(ApiConstants.appointments),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      final data = await _handleResponse(response);
      
      if (data['success'] && data['data'] != null) {
        print('✅ Received ${data['data'].length} appointments from API');
        
        _appointments = (data['data'] as List).map((json) {
          return Appointment.fromJson(json);
        }).toList();
        
        print('\n📊 All appointments after parsing:');
        for (var apt in _appointments) {
          print('   - ${apt.doctorName} (ID: ${apt.doctorId}) -> Patient: ${apt.patientName}');
        }
        
        return _appointments;
      }
      print('⚠️ No appointments found in response');
      return [];
    } catch (e) {
      print('❌ Error in getAppointments: $e');
      rethrow;
    }
  }

  // Get appointments for a specific doctor (with ID normalization)
  List<Map<String, dynamic>> getAppointmentsForDoctor(String doctorId) {
    final normalizedDoctorId = _normalizeId(doctorId);
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    
    print('\n=== 🔍 GETTING APPOINTMENTS FOR DOCTOR ===');
    print('Looking for doctor ID: "$normalizedDoctorId"');
    print('Total appointments in cache: ${_appointments.length}');
    
    if (_appointments.isEmpty) {
      print('⚠️ No appointments in cache. Call getAppointments() first.');
      return [];
    }
    
    // Debug: Print all appointment doctor IDs
    print('\n📋 All appointment doctor IDs in cache:');
    for (var apt in _appointments) {
      final normalizedAptId = _normalizeId(apt.doctorId);
      print('   - "${normalizedAptId}" (${apt.doctorName})');
    }
    
    final filteredAppointments = _appointments
        .where((appointment) {
          final normalizedAppointmentDoctorId = _normalizeId(appointment.doctorId);
          final appointmentDate = DateTime(
            appointment.date.year,
            appointment.date.month,
            appointment.date.day,
          );
          final dateMatch = appointmentDate.isAtSameMomentAs(todayDate);
          final doctorMatch = normalizedAppointmentDoctorId == normalizedDoctorId;
          
          if (!doctorMatch && normalizedAppointmentDoctorId.isNotEmpty) {
            print('   ❌ ID mismatch: "$normalizedAppointmentDoctorId" vs "$normalizedDoctorId"');
          }
          
          return dateMatch && doctorMatch;
        })
        .map((appointment) => {
          'id': appointment.id,
          'patientId': appointment.patientId,
          'name': appointment.patientName,
          'patientName': appointment.patientName,
          'email': appointment.patientEmail,
          'patientEmail': appointment.patientEmail,
          'date': appointment.date.toIso8601String().split('T')[0],
          'time': appointment.time,
          'status': appointment.status,
          'type': appointment.type,
          'symptoms': appointment.symptoms,
          'priority': appointment.status == 'confirmed' ? 'normal' : 'normal',
          'doctorName': appointment.doctorName,
        })
        .toList();
    
    print('\n✅ Found ${filteredAppointments.length} appointments for today');
    for (var apt in filteredAppointments) {
      print('   - ${apt['patientName']} at ${apt['time']} (${apt['status']})');
    }
    
    return filteredAppointments;
  }

  // Get all patients for a doctor
  List<Map<String, dynamic>> getAllPatientsForDoctor(String doctorId) {
    final normalizedDoctorId = _normalizeId(doctorId);
    final patientMap = <String, Map<String, dynamic>>{};
    
    print('\n=== 👥 GETTING PATIENTS FOR DOCTOR ===');
    print('Doctor ID: "$normalizedDoctorId"');
    
    for (final appointment in _appointments) {
      final normalizedAppointmentDoctorId = _normalizeId(appointment.doctorId);
      if (normalizedAppointmentDoctorId == normalizedDoctorId) {
        if (!patientMap.containsKey(appointment.patientId)) {
          patientMap[appointment.patientId] = {
            'id': appointment.patientId,
            'name': appointment.patientName,
            'email': appointment.patientEmail ?? 'N/A',
            'lastVisit': appointment.date.toIso8601String(),
            'condition': appointment.symptoms,
            'emergencyContact': false,
          };
        }
      }
    }
    
    print('✅ Found ${patientMap.length} unique patients');
    return patientMap.values.toList();
  }

  // Add new appointment locally
  void addAppointment(Appointment appointment) {
    _appointments.add(appointment);
    print('➕ Added new appointment: ${appointment.patientName} with Dr. ${appointment.doctorName}');
  }

  // Update appointment status locally
  void updateAppointmentStatus(String appointmentId, String status) {
    print('🔄 Updating appointment status locally: $appointmentId to $status');
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index != -1) {
      final appointment = _appointments[index];
      final updatedAppointment = Appointment(
        id: appointment.id,
        patientId: appointment.patientId,
        doctorId: appointment.doctorId,
        patientName: appointment.patientName,
        doctorName: appointment.doctorName,
        date: appointment.date,
        time: appointment.time,
        status: status,
        type: appointment.type,
        symptoms: appointment.symptoms,
        prescription: appointment.prescription,
        notes: appointment.notes,
        patientEmail: appointment.patientEmail,
        specialty: appointment.specialty,
      );
      _appointments[index] = updatedAppointment;
    }
  }

  // Also update the updateAppointmentStatusAPI method to handle cancellation properly:
Future<Appointment> updateAppointmentStatusAPI(String id, String status) async {
  try {
    print('🔄 Updating appointment via API: $id to status: $status');
    
    // If status is cancelled, we should delete the appointment instead of updating
    if (status.toLowerCase() == 'cancelled') {
      await cancelAppointment(id);
      // Return a dummy appointment that will be filtered out
      return Appointment(
        id: id,
        patientId: '',
        doctorId: '',
        patientName: '',
        doctorName: '',
        date: DateTime.now(),
        time: '',
        status: 'cancelled',
        type: '',
        symptoms: '',
      );
    }
    
    final response = await http.put(
      Uri.parse('${ApiConstants.appointments}/$id'),
      headers: _getHeaders(),
      body: json.encode({'status': status}),
    ).timeout(const Duration(seconds: 30));

    final data = await _handleResponse(response);
    
    if (data['success'] && data['data'] != null) {
      final updatedAppointment = Appointment.fromJson(data['data']);
      final index = _appointments.indexWhere((a) => a.id == id);
      if (index != -1) {
        _appointments[index] = updatedAppointment;
      }
      return updatedAppointment;
    } else {
      throw Exception(data['message'] ?? 'Failed to update appointment');
    }
  } catch (e) {
    print('❌ Error in updateAppointmentStatusAPI: $e');
    rethrow;
  }
}

  // Book appointment via API
  Future<Appointment> bookAppointment(Map<String, dynamic> appointmentData) async {
    try {
      print('📝 Booking appointment with data: $appointmentData');
      
      final response = await http.post(
        Uri.parse(ApiConstants.appointments),
        headers: _getHeaders(),
        body: json.encode(appointmentData),
      ).timeout(const Duration(seconds: 30));

      final data = await _handleResponse(response);
      
      if (data['success'] && data['data'] != null) {
        final appointment = Appointment.fromJson(data['data']);
        _appointments.add(appointment);
        print('✅ Appointment booked successfully: ${appointment.id}');
        return appointment;
      } else {
        throw Exception(data['message'] ?? 'Failed to book appointment');
      }
    } catch (e) {
      print('❌ Error in bookAppointment: $e');
      rethrow;
    }
  }
// In appointment_service.dart, update the cancelAppointment method:

Future<void> cancelAppointment(String id) async {
  try {
    print('🗑️ Service.cancelAppointment called for ID: $id');
    print('🗑️ URL: ${ApiConstants.appointments}/$id');
    
    final response = await http.delete(
      Uri.parse('${ApiConstants.appointments}/$id'),
      headers: _getHeaders(),
    ).timeout(const Duration(seconds: 30));

    print('Cancel response status: ${response.statusCode}');
    print('Cancel response body: ${response.body}');
    
    if (response.statusCode == 200 || response.statusCode == 204) {
      final data = json.decode(response.body);
      if (data['success']) {
        final beforeCount = _appointments.length;
        _appointments.removeWhere((a) => a.id == id);
        final afterCount = _appointments.length;
        print('✅ Service: Appointment cancelled successfully');
        print('   Removed from local cache: ${beforeCount - afterCount} appointment(s)');
      } else {
        throw Exception(data['message'] ?? 'Failed to cancel appointment');
      }
    } else {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Failed to cancel appointment');
    }
  } catch (e) {
    print('❌ Service Error in cancelAppointment: $e');
    rethrow;
  }
}

  // Cancel appointment locally
  void cancelAppointmentLocal(String appointmentId) {
    _appointments.removeWhere((a) => a.id == appointmentId);
    print('🗑️ Removed appointment locally: $appointmentId');
  }

  // Get appointments for patient
  List<Appointment> getAppointmentsForPatient(String patientId) {
    final normalizedPatientId = _normalizeId(patientId);
    return _appointments.where((a) => _normalizeId(a.patientId) == normalizedPatientId).toList();
  }

  // Get upcoming appointments for patient
  List<Appointment> getUpcomingAppointmentsForPatient(String patientId) {
    final normalizedPatientId = _normalizeId(patientId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _appointments.where((appointment) {
      if (_normalizeId(appointment.patientId) != normalizedPatientId) return false;
      
      final appointmentDate = DateTime(
        appointment.date.year,
        appointment.date.month,
        appointment.date.day,
      );
      return appointmentDate.isAtSameMomentAs(today) || appointmentDate.isAfter(today);
    }).toList();
  }

  // Get all appointments
  List<Appointment> getAllAppointments() {
    return List.from(_appointments);
  }

  // Clear all appointments
  void clearAppointments() {
    _appointments.clear();
    print('🧹 Cleared all appointments from cache');
  }
}