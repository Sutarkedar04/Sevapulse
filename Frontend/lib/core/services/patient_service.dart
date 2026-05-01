// lib/core/services/patient_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class PatientService {
  String? _token;

  void setToken(String token) {
    _token = token;
    print('PatientService token set: $_token');
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final data = json.decode(response.body);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Something went wrong');
    }
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Get current patient profile
  Future<Map<String, dynamic>> getCurrentPatientProfile() async {
    try {
      print('📡 Fetching current patient profile from: ${ApiConstants.patients}/me');
      final response = await http.get(
        Uri.parse('${ApiConstants.patients}/me'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      final data = await _handleResponse(response);
      
      if (data['success'] && data['data'] != null) {
        print('✅ Patient profile fetched successfully');
        return data['data'];
      }
      print('⚠️ No patient data found');
      return {};
    } catch (e) {
      print('❌ Error getting patient profile: $e');
      return {};
    }
  }

  // ✅ NEW: Get patient by ID (for doctors to view patient details)
  Future<Map<String, dynamic>> getPatientById(String patientId) async {
    try {
      print('📡 Fetching patient by ID: $patientId');
      final response = await http.get(
        Uri.parse('${ApiConstants.patients}/$patientId'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      final data = await _handleResponse(response);
      
      if (data['success'] && data['data'] != null) {
        print('✅ Patient fetched successfully');
        return data['data'];
      }
      print('⚠️ No patient data found for ID: $patientId');
      return {};
    } catch (e) {
      print('❌ Error getting patient by ID: $e');
      return {};
    }
  }

  // Update current patient profile
  Future<Map<String, dynamic>> updatePatientProfile(Map<String, dynamic> profileData) async {
    try {
      print('📝 Updating patient profile at: ${ApiConstants.patients}/me');
      print('Update data: $profileData');
      
      final response = await http.put(
        Uri.parse('${ApiConstants.patients}/me'),
        headers: _getHeaders(),
        body: json.encode(profileData),
      ).timeout(const Duration(seconds: 30));

      final data = await _handleResponse(response);
      
      if (data['success'] && data['data'] != null) {
        print('✅ Patient profile updated successfully');
        return data['data'];
      }
      throw Exception(data['message'] ?? 'Failed to update profile');
    } catch (e) {
      print('❌ Error updating patient profile: $e');
      rethrow;
    }
  }
}