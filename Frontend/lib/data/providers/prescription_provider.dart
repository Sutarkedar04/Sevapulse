// lib/data/providers/prescription_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/services/prescription_service.dart';
import '../models/prescription_model.dart';

class PrescriptionProvider with ChangeNotifier {
  List<Prescription> _prescriptions = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _error;

  List<Prescription> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get error => _error;

  final PrescriptionService _prescriptionService = PrescriptionService();

  void setToken(String token) {
    _prescriptionService.setToken(token);
  }

  // Load my prescriptions (for patient view)
  Future<void> loadMyPrescriptions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Loading my prescriptions...');
      _prescriptions = await _prescriptionService.getMyPrescriptions();
      print('✅ Loaded ${_prescriptions.length} prescriptions');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      print('❌ Error loading prescriptions: $_error');
      _isLoading = false;
      notifyListeners();
    }
  }

  // lib/data/providers/prescription_provider.dart

// ✅ Patient upload prescription (with image)
Future<bool> patientUploadPrescription({
  required File imageFile,
  required String doctorName,
  required List<Map<String, dynamic>> medicines,
  required String advice,
}) async {
  _isUploading = true;
  _error = null;
  notifyListeners();

  try {
    final newPrescriptionData = await _prescriptionService.patientUploadPrescription(
      imageFile: imageFile,
      doctorName: doctorName,
      medicines: medicines,
      advice: advice,
      tests: [],
      followUpDate: null,
    );
    
    print('Received prescription data: $newPrescriptionData');
    
    // Convert to Prescription model - handle different response structures
    Prescription prescription;
    
    if (newPrescriptionData.containsKey('_id')) {
      // Response has _id field
      prescription = Prescription.fromJson(newPrescriptionData);
    } else if (newPrescriptionData.containsKey('id')) {
      // Response has id field
      prescription = Prescription.fromJson(newPrescriptionData);
    } else {
      // Try to wrap or handle gracefully
      prescription = Prescription.fromJson({
        '_id': newPrescriptionData['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        ...newPrescriptionData,
      });
    }
    
    _prescriptions.insert(0, prescription);
    
    _isUploading = false;
    notifyListeners();
    return true;
  } catch (e) {
    _error = e.toString().replaceFirst('Exception: ', '');
    print('❌ Error uploading prescription: $_error');
    _isUploading = false;
    notifyListeners();
    return false;
  }
}
  // Load prescriptions by patient ID (for doctor view)
  Future<void> loadPrescriptionsByPatient(String patientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Loading prescriptions for patient: $patientId');
      _prescriptions = await _prescriptionService.getPrescriptionsByPatient(patientId);
      print('✅ Loaded ${_prescriptions.length} prescriptions');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      print('❌ Error loading prescriptions: $_error');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete prescription
  Future<bool> deletePrescription(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _prescriptionService.deletePrescription(id);
      _prescriptions.removeWhere((p) => p.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get filtered prescriptions
  List<Prescription> getFilteredPrescriptions({String? searchQuery}) {
    if (searchQuery == null || searchQuery.isEmpty) {
      return _prescriptions;
    }
    
    return _prescriptions.where((p) {
      final medicinesText = p.medicines.map((m) => m.name).join(' ').toLowerCase();
      final doctorText = p.doctorName.toLowerCase();
      final searchText = searchQuery.toLowerCase();
      
      return medicinesText.contains(searchText) ||
          doctorText.contains(searchText);
    }).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}