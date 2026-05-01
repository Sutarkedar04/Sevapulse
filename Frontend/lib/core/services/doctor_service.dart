// lib/core/services/doctor_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/api_constants.dart';

class DoctorService {
  String? _token;

  void setToken(String token) {
    _token = token;
    print('✅ DoctorService token set');
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Get doctor profile
  Future<Map<String, dynamic>> getDoctorProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.doctors}/me'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          return data['data'];
        }
      }
      return {};
    } catch (e) {
      print('Error fetching doctor profile: $e');
      return {};
    }
  }

  // Create doctor profile (for registration)
  Future<Map<String, dynamic>> createDoctorProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.doctors}/profile'),
        headers: _getHeaders(),
        body: json.encode(profileData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          return data['data'];
        }
        throw Exception(data['message'] ?? 'Failed to create doctor profile');
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to create doctor profile');
      }
    } catch (e) {
      print('Error creating doctor profile: $e');
      rethrow;
    }
  }

  // Update doctor profile
  Future<Map<String, dynamic>> updateDoctorProfile(Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.doctors}/me'),
        headers: _getHeaders(),
        body: json.encode(updateData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          return data['data'];
        }
        throw Exception(data['message'] ?? 'Failed to update profile');
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      print('Error updating doctor profile: $e');
      rethrow;
    }
  }

  // Send prescription and complete appointment
  Future<Map<String, dynamic>> sendPrescriptionAndCompleteAppointment({
    required String appointmentId,
    required String patientId,
    required List<Map<String, dynamic>> medicines,
    required String advice,
    required String notes,
    required List<File> images,
  }) async {
    try {
      print('📤 Doctor sending prescription...');
      print('Appointment ID: $appointmentId');
      print('Patient ID: $patientId');
      print('Medicines: $medicines');
      print('Advice: $advice');
      print('Images count: ${images.length}');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/prescriptions/doctor-create'),
      );
      
      request.headers.addAll({
        'Authorization': 'Bearer $_token',
      });
      
      // Add fields
      request.fields['appointmentId'] = appointmentId;
      request.fields['patientId'] = patientId;
      request.fields['medicines'] = json.encode(medicines);
      request.fields['advice'] = advice;
      request.fields['notes'] = notes;
      
      // Add images
      for (var i = 0; i < images.length; i++) {
        var file = await http.MultipartFile.fromPath(
          'images',
          images[i].path,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(file);
        print('Added image ${i + 1}: ${images[i].path}');
      }
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      print('Response status: ${response.statusCode}');
      print('Response data: $responseData');
      
      var data = json.decode(responseData);
      
      if (response.statusCode == 201 && data['success']) {
        print('✅ Prescription sent successfully');
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to send prescription');
      }
    } catch (e) {
      print('❌ Error sending prescription: $e');
      rethrow;
    }
  }
}