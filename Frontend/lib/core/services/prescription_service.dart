// lib/core/services/prescription_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/api_constants.dart';
import '../../data/models/prescription_model.dart';

class PrescriptionService {
  String? _token;

  void setToken(String token) {
    _token = token;
    print('✅ PrescriptionService token set');
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Get all prescriptions (admin only)
  Future<List<Prescription>> getAllPrescriptions() async {
    try {
      print('📡 Fetching all prescriptions from: ${ApiConstants.prescriptions}');
      
      final response = await http.get(
        Uri.parse(ApiConstants.prescriptions),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          final prescriptions = (data['data'] as List)
              .map((json) => Prescription.fromJson(json))
              .toList();
          print('✅ Loaded ${prescriptions.length} prescriptions');
          return prescriptions;
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching prescriptions: $e');
      throw Exception('Failed to load prescriptions: $e');
    }
  }

  // Get my prescriptions (for patient)
  Future<List<Prescription>> getMyPrescriptions() async {
    try {
      print('📡 Fetching my prescriptions from: ${ApiConstants.myPrescriptions}');
      
      final response = await http.get(
        Uri.parse(ApiConstants.myPrescriptions),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          final prescriptions = (data['data'] as List)
              .map((json) => Prescription.fromJson(json))
              .toList();
          print('✅ Loaded ${prescriptions.length} prescriptions');
          return prescriptions;
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching my prescriptions: $e');
      throw Exception('Failed to load prescriptions: $e');
    }
  }

  // Get prescriptions by patient ID (for doctors)
  Future<List<Prescription>> getPrescriptionsByPatient(String patientId) async {
    try {
      print('📡 Fetching prescriptions for patient: $patientId');
      
      final response = await http.get(
        Uri.parse('${ApiConstants.prescriptions}/patient/$patientId'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          final prescriptions = (data['data'] as List)
              .map((json) => Prescription.fromJson(json))
              .toList();
          print('✅ Loaded ${prescriptions.length} prescriptions');
          return prescriptions;
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching prescriptions: $e');
      throw Exception('Failed to load prescriptions: $e');
    }
  }

  // Upload prescription image only
  Future<String> uploadPrescriptionImage(File imageFile) async {
    try {
      print('📤 Uploading prescription image...');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/prescriptions/upload'),
      );
      
      request.headers.addAll({
        'Authorization': 'Bearer $_token',
      });
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'prescription',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);
      
      if (response.statusCode == 200 && data['success']) {
        print('✅ Image uploaded: ${data['imageUrl']}');
        return data['imageUrl'];
      } else {
        throw Exception(data['message'] ?? 'Image upload failed');
      }
    } catch (e) {
      print('❌ Image upload error: $e');
      rethrow;
    }
  }

 // lib/core/services/prescription_service.dart - Fix the patientUploadPrescription method

// ✅ Patient upload prescription (with image + data, no appointment/doctor required)
Future<Map<String, dynamic>> patientUploadPrescription({
  required File imageFile,
  required String doctorName,
  required List<Map<String, dynamic>> medicines,
  required String advice,
  List<Map<String, dynamic>> tests = const [],
  DateTime? followUpDate,
}) async {
  try {
    print('📤 Patient uploading prescription...');
    
    // Create multipart request
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/prescriptions/patient-upload'),
    );
    
    request.headers.addAll({
      'Authorization': 'Bearer $_token',
    });
    
    // Add image file
    request.files.add(
      await http.MultipartFile.fromPath(
        'prescription',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );
    
    // Add prescription data as JSON
    final prescriptionData = {
      'doctorName': doctorName,
      'medicines': medicines,
      'tests': tests,
      'advice': advice,
      'followUpDate': followUpDate?.toIso8601String(),
    };
    
    request.fields['data'] = json.encode(prescriptionData);
    
    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    print('Response status: ${response.statusCode}');
    print('Response data: $responseData');
    
    final data = json.decode(responseData);
    
    if (response.statusCode == 201 && data['success']) {
      print('✅ Patient prescription uploaded successfully');
      // Return the data directly - it already contains the prescription object
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Failed to upload prescription');
    }
  } catch (e) {
    print('❌ Error in patientUploadPrescription: $e');
    rethrow;
  }
}
  // Create prescription from doctor (requires appointment, doctor, patient)
  Future<Prescription> createPrescription(Map<String, dynamic> prescriptionData) async {
    try {
      print('📝 Creating prescription: $prescriptionData');
      
      final response = await http.post(
        Uri.parse(ApiConstants.prescriptions),
        headers: _getHeaders(),
        body: json.encode(prescriptionData),
      ).timeout(const Duration(seconds: 30));
      
      print('Create prescription response: ${response.statusCode}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          return Prescription.fromJson(data['data']);
        }
        throw Exception(data['message'] ?? 'Failed to create prescription');
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to create prescription');
      }
    } catch (e) {
      print('❌ Error creating prescription: $e');
      rethrow;
    }
  }

  // Update prescription
  Future<Prescription> updatePrescription(String id, Map<String, dynamic> updates) async {
    try {
      print('📝 Updating prescription: $id');
      
      final response = await http.put(
        Uri.parse('${ApiConstants.prescriptions}/$id'),
        headers: _getHeaders(),
        body: json.encode(updates),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          return Prescription.fromJson(data['data']);
        }
        throw Exception(data['message'] ?? 'Failed to update prescription');
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to update prescription');
      }
    } catch (e) {
      print('❌ Error updating prescription: $e');
      rethrow;
    }
  }

  // Delete prescription
  Future<void> deletePrescription(String id) async {
    try {
      print('🗑️ Deleting prescription: $id');
      
      final response = await http.delete(
        Uri.parse('${ApiConstants.prescriptions}/$id'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to delete prescription');
      }
      
      print('✅ Prescription deleted successfully');
    } catch (e) {
      print('❌ Error deleting prescription: $e');
      rethrow;
    }
  }
}