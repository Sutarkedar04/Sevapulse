// lib/features/doctor/screens/doctor_home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seva_pulse/features/auth/SevaPulseSplashScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'patients_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';
import '../../../core/services/appointment_service.dart';
import '../../../core/services/doctor_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../core/theme/theme_extensions.dart';

class DoctorHomeScreen extends StatefulWidget {
  final User? doctorData;
  
  const DoctorHomeScreen({Key? key, this.doctorData}) : super(key: key);

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isInitialized = false;
  final AppointmentService _appointmentService = AppointmentService();
  final DoctorService _doctorService = DoctorService();
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _todayAppointments = [];
  List<Map<String, dynamic>> _allAppointmentsList = [];
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  Map<String, dynamic> doctorProfile = {};
  bool _isLoadingPatientDetails = false;
  
  // Cache for patient details to avoid repeated API calls
  final Map<String, Map<String, dynamic>> _patientDetailsCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDoctorProfile();
    _initializeScreen();
  }

  Future<void> _loadDoctorProfile() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token != null && token.isNotEmpty) {
        _doctorService.setToken(token);
        final doctorDetails = await _doctorService.getDoctorProfile();
        
        if (doctorDetails.isNotEmpty) {
          doctorProfile = {
            'name': doctorDetails['name'] ?? authProvider.user?.name ?? 'Doctor',
            'specialization': doctorDetails['specialization'] ?? 'General Physician',
            'experience': doctorDetails['experience']?.toString() ?? '5 years',
            'qualification': doctorDetails['qualifications'] != null && doctorDetails['qualifications'].isNotEmpty
                ? doctorDetails['qualifications'][0]['degree'] ?? 'MBBS'
                : 'MBBS',
            'hospital': doctorDetails['hospital'] ?? 'City Hospital',
            'rating': doctorDetails['rating']?.toString() ?? '4.5',
            'patientsCount': doctorDetails['patientsCount'] ?? 0,
            'contact': doctorDetails['phone'] ?? authProvider.user?.phone ?? '',
            'email': doctorDetails['email'] ?? authProvider.user?.email ?? '',
            'bio': doctorDetails['bio'] ?? 'Experienced doctor dedicated to patient care.',
            'consultationFee': doctorDetails['consultationFee']?.toString() ?? '500',
          };
        }
      }
    } catch (e) {
      print('Error loading doctor profile: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isInitialized) {
      _resetToDashboard();
    }
  }

  void _initializeScreen() async {
    setState(() => _isLoading = true);
    _currentIndex = 0;
    await _loadAppointments();
    _isInitialized = true;
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAppointments() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token != null && token.isNotEmpty) {
        _appointmentService.setToken(token);
        await _appointmentService.getAppointments();
        _refreshAppointments();
        await _refreshPatients(); // Changed to async/await
      }
    } catch (e) {
      print('❌ Error loading appointments: $e');
      _todayAppointments = [];
      _patients = [];
      if (mounted) setState(() {});
    }
  }

  void _refreshAppointments() {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final doctorName = authProvider.user?.name;
      
      if (doctorName == null || doctorName.isEmpty) {
        _todayAppointments = [];
        if (mounted) setState(() {});
        return;
      }
      
      final allAppointments = _appointmentService.getAllAppointments();
      final activeAppointments = allAppointments.where((apt) {
        return apt.status.toLowerCase() != 'cancelled';
      }).toList();
      
      final doctorAppointments = activeAppointments.where((apt) {
        return apt.doctorName.toLowerCase() == doctorName.toLowerCase();
      }).toList();
      
      _allAppointmentsList = doctorAppointments.map((apt) => ({
        'id': apt.id,
        'patientUserId': apt.patientId,
        'patientName': apt.patientName,
        'patientEmail': apt.patientEmail,
        'date': apt.date,
        'time': apt.time,
        'status': apt.status,
        'type': apt.type,
        'symptoms': apt.symptoms,
      })).toList();
      
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      
      final todayAppointments = doctorAppointments.where((apt) {
        final localDate = apt.date.toLocal();
        final aptDate = DateTime(localDate.year, localDate.month, localDate.day);
        return aptDate.isAtSameMomentAs(todayDate);
      }).toList();
      
      _todayAppointments = todayAppointments.map((apt) => ({
        'id': apt.id,
        'patientUserId': apt.patientId,
        'name': apt.patientName,
        'patientName': apt.patientName,
        'email': apt.patientEmail,
        'patientEmail': apt.patientEmail,
        'date': apt.date.toLocal().toIso8601String().split('T')[0],
        'time': apt.time,
        'status': apt.status,
        'type': apt.type,
        'symptoms': apt.symptoms,
      })).toList();
      
      if (mounted) setState(() {});
    } catch (e) {
      print('❌ Error refreshing appointments: $e');
      _todayAppointments = [];
      if (mounted) setState(() {});
    }
  }

  // UPDATED: Fetch complete patient details with medical info
  Future<void> _refreshPatients() async {
    try {
      final patientMap = <String, Map<String, dynamic>>{};
      
      for (final apt in _allAppointmentsList) {
        final patientUserId = apt['patientUserId']?.toString() ?? '';
        if (patientUserId.isNotEmpty && !patientMap.containsKey(patientUserId)) {
          // Fetch complete patient details
          final completeDetails = await _fetchCompletePatientDetails(patientUserId);
          
          if (completeDetails.isNotEmpty) {
            patientMap[patientUserId] = {
              'userId': patientUserId,
              'name': completeDetails['name'] ?? apt['patientName'] ?? 'Unknown',
              'email': completeDetails['email'] ?? apt['patientEmail'] ?? 'N/A',
              'lastVisit': apt['date']?.toLocal().toIso8601String() ?? DateTime.now().toIso8601String(),
              'condition': _getPrimaryCondition(completeDetails),
              'medicalHistory': completeDetails['medicalHistory'] ?? [],
              'allergies': completeDetails['allergies'] ?? [],
              'bloodGroup': completeDetails['bloodGroup'] ?? 'Not set',
              'gender': completeDetails['gender'] ?? 'Not set',
              'dateOfBirth': completeDetails['dateOfBirth'] ?? 'Not set',
              'phone': completeDetails['phone'] ?? 'N/A',
              'address': completeDetails['address'] ?? {},
              'emergencyContact': completeDetails['emergencyContact'] ?? {},
            };
          } else {
            // Fallback to appointment data if API fails
            patientMap[patientUserId] = {
              'userId': patientUserId,
              'name': apt['patientName'] ?? 'Unknown',
              'email': apt['patientEmail'] ?? 'N/A',
              'lastVisit': apt['date']?.toLocal().toIso8601String() ?? DateTime.now().toIso8601String(),
              'condition': apt['symptoms'] ?? 'General Consultation',
              'medicalHistory': [],
              'allergies': [],
              'bloodGroup': 'Not set',
              'gender': 'Not set',
              'dateOfBirth': 'Not set',
              'phone': 'N/A',
              'address': {},
              'emergencyContact': {},
            };
          }
        }
      }
      
      _patients = patientMap.values.toList();
      doctorProfile['patientsCount'] = _patients.length;
      if (mounted) setState(() {});
    } catch (e) {
      print('❌ Error refreshing patients: $e');
      _patients = [];
      if (mounted) setState(() {});
    }
  }

  // Helper method to get primary condition from medical history
  String _getPrimaryCondition(Map<String, dynamic> patientDetails) {
    final medicalHistory = List<Map<String, dynamic>>.from(patientDetails['medicalHistory'] ?? []);
    if (medicalHistory.isNotEmpty) {
      // Get the most recent condition
      return medicalHistory.last['condition'] ?? 'Under treatment';
    }
    
    final allergies = List<String>.from(patientDetails['allergies'] ?? []);
    if (allergies.isNotEmpty) {
      return 'Allergies: ${allergies.join(', ')}';
    }
    
    return 'General Consultation';
  }

  Future<Map<String, dynamic>> _fetchCompletePatientDetails(String userId) async {
    if (_patientDetailsCache.containsKey(userId)) {
      return _patientDetailsCache[userId]!;
    }
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token == null) return {};
      
      final response = await http.get(
        Uri.parse('${ApiConstants.patients}/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          final patientData = data['data'];
          final user = patientData['user'] ?? {};
          final address = patientData['address'] ?? {};
          final emergencyContact = patientData['emergencyContact'] ?? {};
          
          final completeDetails = {
            'userId': userId,
            'patientId': patientData['_id'],
            'name': user['name'] ?? 'Unknown',
            'email': user['email'] ?? 'N/A',
            'phone': user['phone'] ?? 'N/A',
            'dateOfBirth': patientData['dateOfBirth'] != null 
                ? DateTime.parse(patientData['dateOfBirth']).toLocal().toString().split(' ')[0]
                : 'Not set',
            'gender': patientData['gender'] ?? 'Not set',
            'bloodGroup': patientData['bloodGroup'] ?? 'Not set',
            'address': {
              'street': address['street']?.toString() ?? '',
              'city': address['city']?.toString() ?? '',
              'state': address['state']?.toString() ?? '',
              'zipCode': address['zipCode']?.toString() ?? '',
            },
            'emergencyContact': {
              'name': emergencyContact['name']?.toString() ?? '',
              'relationship': emergencyContact['relationship']?.toString() ?? '',
              'phone': emergencyContact['phone']?.toString() ?? '',
            },
            'allergies': patientData['allergies'] ?? [],
            'medicalHistory': patientData['medicalHistory'] ?? [],
            'currentMedications': patientData['currentMedications'] ?? [],
          };
          
          _patientDetailsCache[userId] = completeDetails;
          return completeDetails;
        }
      }
      return {};
    } catch (e) {
      print('❌ Error fetching patient details: $e');
      return {};
    }
  }

  Future<void> _completeAppointmentAndPrescribe(Map<String, dynamic> appointment, Map<String, dynamic> patient) async {
    final TextEditingController medicinesController = TextEditingController();
    final TextEditingController adviceController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    List<File> selectedImages = [];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.medical_services, color: Color(0xFF27ae60)),
                const SizedBox(width: 8),
                Text('Complete Appointment & Send Prescription', style: TextStyle(color: context.primaryText)),
              ],
            ),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Patient Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text('Patient: ${patient['name']}', 
                              style: TextStyle(fontWeight: FontWeight.bold, color: context.primaryText)),
                          Text('Appointment: ${appointment['date']} at ${appointment['time']}',
                              style: TextStyle(fontSize: 12, color: context.secondaryText)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Medicines Section
                    Text('Medicines (One per line: Name - Dosage)', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.primaryText)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: medicinesController,
                      style: TextStyle(color: context.primaryText),
                      decoration: InputDecoration(
                        hintText: 'Paracetamol - 500mg twice daily\nAmoxicillin - 250mg three times daily',
                        hintStyle: TextStyle(color: context.secondaryText),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),
                    
                    // Advice Section
                    Text('Doctor\'s Advice', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.primaryText)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: adviceController,
                      style: TextStyle(color: context.primaryText),
                      decoration: InputDecoration(
                        hintText: 'Take plenty of rest, Stay hydrated, Follow up in 5 days',
                        hintStyle: TextStyle(color: context.secondaryText),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Notes Section
                    Text('Additional Notes', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.primaryText)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notesController,
                      style: TextStyle(color: context.primaryText),
                      decoration: InputDecoration(
                        hintText: 'Any additional instructions...',
                        hintStyle: TextStyle(color: context.secondaryText),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    
                    // Image Upload Section
                    Text('Upload Prescription Images', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.primaryText)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () async {
                              final image = await _picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                setDialogState(() {
                                  selectedImages.add(File(image.path));
                                });
                              }
                            },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: context.surfaceColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: context.primaryColor),
                              ),
                              child: Icon(Icons.add_photo_alternate, size: 30, color: context.primaryColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ...selectedImages.map((file) => Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(file),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedImages.remove(file);
                                    });
                                  },
                                ),
                              ),
                            ],
                          )).toList(),
                        ],
                      ),
                    ),
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
                onPressed: () async {
                  Navigator.pop(context);
                  await _sendPrescription(
                    appointment, 
                    patient, 
                    medicinesController.text, 
                    adviceController.text, 
                    notesController.text,
                    selectedImages
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27ae60),
                ),
                child: const Text('Send Prescription & Complete'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sendPrescription(
    Map<String, dynamic> appointment,
    Map<String, dynamic> patient,
    String medicinesText,
    String advice,
    String notes,
    List<File> images
  ) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      print('=== SENDING PRESCRIPTION ===');
      print('Token exists: ${token != null}');
      print('Appointment ID: ${appointment['id']}');
      print('Patient ID: ${patient['userId']}');
      print('Medicines text: $medicinesText');
      print('Advice: $advice');
      print('Images count: ${images.length}');
      
      if (token == null) throw Exception('Not authenticated');
      
      // Parse medicines
      final medicinesList = medicinesText.split('\n').where((m) => m.trim().isNotEmpty).map((m) {
        final parts = m.split('-').map((p) => p.trim()).toList();
        return {
          'name': parts[0],
          'dosage': parts.length > 1 ? parts[1] : 'As directed',
          'frequency': 'As prescribed',
          'duration': 'As prescribed',
          'instructions': ''
        };
      }).toList();
      
      print('Parsed medicines: $medicinesList');
      
      final doctorService = DoctorService();
      doctorService.setToken(token);
      
      final result = await doctorService.sendPrescriptionAndCompleteAppointment(
        appointmentId: appointment['id'],
        patientId: patient['userId'],
        medicines: medicinesList,
        advice: advice,
        notes: notes,
        images: images,
      );
      
      print('Result: $result');
      
      await _refreshData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Prescription sent and appointment completed!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error sending prescription: $e');
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
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildInfoCard({required String title, required IconData icon, Color iconColor = const Color(0xFF3498db), required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.primaryText)),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$label:', style: TextStyle(fontWeight: FontWeight.w500, color: context.secondaryText))),
          Expanded(child: Text(value.isEmpty ? 'Not set' : value, style: TextStyle(color: context.primaryText))),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'Not set';
    try {
      final date = DateTime.parse(dateValue.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateValue.toString().split('T')[0];
    }
  }

  void _showPatientDetails(Map<String, dynamic> patient) async {
    setState(() {
      _isLoadingPatientDetails = true;
    });
    
    final patientUserId = patient['userId']?.toString() ?? '';
    final patientDetails = await _fetchCompletePatientDetails(patientUserId);
    
    final patientAppointments = _allAppointmentsList
        .where((apt) => apt['patientUserId']?.toString() == patientUserId)
        .toList();
    
    setState(() {
      _isLoadingPatientDetails = false;
    });
    
    if (patientDetails.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load patient details. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    final address = patientDetails['address'] ?? {};
    final emergencyContact = patientDetails['emergencyContact'] ?? {};
    final allergies = List<String>.from(patientDetails['allergies'] ?? []);
    final medicalHistory = List<Map<String, dynamic>>.from(patientDetails['medicalHistory'] ?? []);
    final currentMedications = List<Map<String, dynamic>>.from(patientDetails['currentMedications'] ?? []);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.9,
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
            
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: context.primaryColor.withOpacity(0.1),
                  child: Icon(Icons.person, size: 35, color: context.primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientDetails['name'] ?? 'Patient',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.primaryText),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        patientDetails['email'] ?? 'No email',
                        style: TextStyle(color: context.secondaryText),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        patientDetails['phone'] ?? 'No phone',
                        style: TextStyle(color: context.secondaryText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            DefaultTabController(
              length: 4,
              child: Expanded(
                child: Column(
                  children: [
                    TabBar(
                      labelColor: context.primaryColor,
                      unselectedLabelColor: context.secondaryText,
                      indicatorColor: context.primaryColor,
                      isScrollable: true,
                      tabs: const [
                        Tab(text: 'Personal', icon: Icon(Icons.person)),
                        Tab(text: 'Address', icon: Icon(Icons.location_on)),
                        Tab(text: 'Emergency', icon: Icon(Icons.emergency)),
                        Tab(text: 'Medical', icon: Icon(Icons.medical_services)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Personal Info Tab
                          SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildInfoCard(
                                  title: 'Basic Information',
                                  icon: Icons.info,
                                  children: [
                                    _buildDetailRow('Patient ID', patientDetails['patientId'] ?? 'N/A'),
                                    _buildDetailRow('Full Name', patientDetails['name'] ?? 'N/A'),
                                    _buildDetailRow('Email', patientDetails['email'] ?? 'N/A'),
                                    _buildDetailRow('Phone', patientDetails['phone'] ?? 'N/A'),
                                    _buildDetailRow('Date of Birth', patientDetails['dateOfBirth'] ?? 'Not set'),
                                    _buildDetailRow('Gender', patientDetails['gender'] ?? 'Not set'),
                                    _buildDetailRow('Blood Group', patientDetails['bloodGroup'] ?? 'Not set'),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildInfoCard(
                                  title: 'Appointment History',
                                  icon: Icons.history,
                                  children: _buildAppointmentHistoryList(patientAppointments),
                                ),
                              ],
                            ),
                          ),
                          // Address Tab
                          SingleChildScrollView(
                            child: _buildInfoCard(
                              title: 'Complete Address',
                              icon: Icons.location_on,
                              children: [
                                _buildDetailRow('Street', address['street']?.isNotEmpty == true ? address['street'] : 'Not set'),
                                _buildDetailRow('City', address['city']?.isNotEmpty == true ? address['city'] : 'Not set'),
                                _buildDetailRow('State', address['state']?.isNotEmpty == true ? address['state'] : 'Not set'),
                                _buildDetailRow('Zip Code', address['zipCode']?.isNotEmpty == true ? address['zipCode'] : 'Not set'),
                              ],
                            ),
                          ),
                          // Emergency Contact Tab
                          SingleChildScrollView(
                            child: _buildInfoCard(
                              title: 'Emergency Contact',
                              icon: Icons.emergency,
                              iconColor: Colors.red,
                              children: [
                                _buildDetailRow('Contact Name', emergencyContact['name']?.isNotEmpty == true ? emergencyContact['name'] : 'Not set'),
                                _buildDetailRow('Relationship', emergencyContact['relationship']?.isNotEmpty == true ? emergencyContact['relationship'] : 'Not set'),
                                _buildDetailRow('Phone Number', emergencyContact['phone']?.isNotEmpty == true ? emergencyContact['phone'] : 'Not set'),
                              ],
                            ),
                          ),
                          // Medical Info Tab
                          SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildInfoCard(
                                  title: 'Allergies',
                                  icon: Icons.warning,
                                  iconColor: Colors.orange,
                                  children: _buildAllergiesList(allergies),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoCard(
                                  title: 'Medical History',
                                  icon: Icons.history,
                                  children: _buildMedicalHistoryList(medicalHistory),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoCard(
                                  title: 'Current Medications',
                                  icon: Icons.medication,
                                  children: _buildMedicationsList(currentMedications),
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
            
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.primaryColor),
                    ),
                    child: Text('Close', style: TextStyle(color: context.primaryColor)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showPrescriptionDialog(patient);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27ae60)),
                    child: const Text('Write Prescription'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build appointment history list
  List<Widget> _buildAppointmentHistoryList(List<Map<String, dynamic>> appointments) {
    if (appointments.isEmpty) {
      return [Text('No appointment history', style: TextStyle(color: context.secondaryText))];
    }
    return appointments.map((apt) => 
      _buildDetailRow(
        _formatDate(apt['date']), 
        '${apt['time']} - ${apt['status']?.toUpperCase() ?? 'Pending'}'
      )
    ).toList();
  }

  // Helper method to build allergies list
  List<Widget> _buildAllergiesList(List<String> allergies) {
    if (allergies.isEmpty) {
      return [Text('No allergies recorded', style: TextStyle(color: context.secondaryText))];
    }
    return allergies.map((a) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('• $a', style: TextStyle(color: context.primaryText)),
    )).toList();
  }

  // Helper method to build medical history list
  List<Widget> _buildMedicalHistoryList(List<Map<String, dynamic>> medicalHistory) {
    if (medicalHistory.isEmpty) {
      return [Text('No medical history recorded', style: TextStyle(color: context.secondaryText))];
    }
    return medicalHistory.map((h) => 
      _buildDetailRow(
        h['condition'] ?? 'Unknown', 
        _formatDate(h['diagnosedDate']) ?? 'Date unknown'
      )
    ).toList();
  }

  // Helper method to build medications list
  List<Widget> _buildMedicationsList(List<Map<String, dynamic>> medications) {
    if (medications.isEmpty) {
      return [Text('No medications recorded', style: TextStyle(color: context.secondaryText))];
    }
    return medications.map((m) => 
      _buildDetailRow(
        m['name'] ?? 'Unknown', 
        '${m['dosage'] ?? ''} ${m['frequency'] ?? ''}'.trim()
      )
    ).toList();
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    
    _patientDetailsCache.clear();
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token != null && token.isNotEmpty) {
        _appointmentService.setToken(token);
        await _appointmentService.getAppointments();
        _refreshAppointments();
        await _refreshPatients();
      }
    } catch (e) {
      print('❌ Error refreshing data: $e');
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _resetToDashboard() {
    if (mounted) {
      setState(() => _currentIndex = 0);
      _refreshData();
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout', style: TextStyle(color: context.primaryText)),
        content: Text('Are you sure you want to logout?', style: TextStyle(color: context.secondaryText)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: context.primaryColor))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _performLogout() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SevaPulseSplashScreen()),
      (route) => false,
    );
  }

  void _showPrescriptionDialog(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Write Prescription for ${patient['name'] ?? 'Patient'}', style: TextStyle(color: context.primaryText)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                style: TextStyle(color: context.primaryText),
                decoration: InputDecoration(
                  labelText: 'Diagnosis',
                  labelStyle: TextStyle(color: context.secondaryText),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: TextStyle(color: context.primaryText),
                decoration: InputDecoration(
                  labelText: 'Medicines',
                  labelStyle: TextStyle(color: context.secondaryText),
                  border: const OutlineInputBorder(),
                  hintText: 'Enter medicines with dosage and timing...',
                  hintStyle: TextStyle(color: context.secondaryText),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: TextStyle(color: context.primaryText),
                decoration: InputDecoration(
                  labelText: 'Tests Recommended',
                  labelStyle: TextStyle(color: context.secondaryText),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: TextStyle(color: context.primaryText),
                decoration: const InputDecoration(
                  labelText: 'Follow-up Date',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: context.primaryColor))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Prescription sent to ${patient['name'] ?? 'Patient'}'),
                  backgroundColor: const Color(0xFF27ae60),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor),
            child: const Text('Send Prescription'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(Map<String, dynamic> appointment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Appointment', style: TextStyle(color: context.primaryText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cancel appointment with ${appointment['name'] ?? appointment['patientName'] ?? 'Patient'}?', style: TextStyle(color: context.secondaryText)),
            const SizedBox(height: 8),
            Text('Time: ${appointment['time']}', style: TextStyle(color: context.secondaryText)),
            Text('Date: ${appointment['date']}', style: TextStyle(color: context.secondaryText)),
            const SizedBox(height: 8),
            const Text('This action cannot be undone.', style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('No, Keep It', style: TextStyle(color: context.primaryColor))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Yes, Cancel')),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Row(children: [SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 12), Text('Cancelling appointment...')]), backgroundColor: Colors.orange),
    );
    
    try {
      await _appointmentService.cancelAppointment(appointment['id']?.toString() ?? '');
      await _refreshData();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Appointment cancelled successfully'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildDashboardTab() {
    if (_isLoading) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Loading appointments...')]));
    }
    
    return RefreshIndicator(
      color: context.primaryColor,
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 150, width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: const DecorationImage(image: AssetImage('assets/images/userfirstimg.png'), fit: BoxFit.cover))),
            const SizedBox(height: 20),
            
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: context.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(radius: 30, backgroundColor: context.primaryColor.withOpacity(0.1), child: Icon(Icons.medical_services, color: context.primaryColor, size: 30)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome, ${doctorProfile['name'] ?? 'Doctor'}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.primaryText)),
                          Text(doctorProfile['specialization'] ?? 'General Physician', style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('${_todayAppointments.length} appointment${_todayAppointments.length != 1 ? 's' : ''} today', style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: _isRefreshing ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor))) : Icon(Icons.refresh, color: context.primaryColor),
                      onPressed: _isRefreshing ? null : _refreshData,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's Appointments", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.primaryText)),
                Text('${_todayAppointments.length} total', style: TextStyle(fontSize: 14, color: context.secondaryText)),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_todayAppointments.isEmpty)
              Card(
                color: context.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.event_available, size: 64, color: context.secondaryText.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('No appointments for today', style: TextStyle(color: context.secondaryText)),
                      const SizedBox(height: 8),
                      Text('Appointments booked by patients will appear here', textAlign: TextAlign.center, style: TextStyle(color: context.secondaryText.withOpacity(0.7))),
                    ],
                  ),
                ),
              )
            else
              ..._todayAppointments.map((appointment) => _buildAppointmentCard(appointment)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final patientData = _patients.firstWhere(
      (p) => p['userId'] == appointment['patientUserId'],
      orElse: () => {'userId': appointment['patientUserId'], 'name': appointment['patientName'], 'email': appointment['patientEmail']},
    );
    
    Color statusColor = appointment['status'] == 'confirmed' ? const Color(0xFF27ae60) : (appointment['status'] == 'cancelled' ? const Color(0xFFe74c3c) : const Color(0xFFf39c12));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _showPatientDetails(patientData),
                        child: Row(
                          children: [
                            Text(appointment['name'] ?? appointment['patientName'] ?? 'Patient', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.primaryText)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: context.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text('View Full Details', style: TextStyle(fontSize: 10, color: context.primaryColor)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('ID: ${appointment['patientUserId'] ?? 'N/A'}', style: TextStyle(fontSize: 12, color: context.secondaryText)),
                      const SizedBox(height: 4),
                      Text('Email: ${appointment['email'] ?? appointment['patientEmail'] ?? 'N/A'}', style: TextStyle(fontSize: 12, color: context.secondaryText)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(appointment['status']?.toUpperCase() ?? 'PENDING', style: TextStyle(color: statusColor, fontWeight: FontWeight.w500, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${appointment['time'] ?? 'Time TBD'} • ${appointment['date'] ?? 'Date TBD'} • ${appointment['type'] ?? 'Consultation'}', style: TextStyle(color: context.secondaryText)),
            const SizedBox(height: 8),
            Text('Symptoms: ${appointment['symptoms'] ?? 'Not specified'}', style: TextStyle(fontSize: 14, color: context.primaryText)),
            const SizedBox(height: 12),
            Row(
              children: [
                if (appointment['status'] == 'pending') ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        try {
                          await _appointmentService.updateAppointmentStatusAPI(appointment['id']?.toString() ?? '', 'confirmed');
                          await _refreshData();
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Appointment confirmed'), backgroundColor: Colors.green));
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Confirm', style: TextStyle(color: context.primaryColor)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelAppointment(appointment),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text('Cancel'),
                    ),
                  ),
                ] else if (appointment['status'] == 'confirmed') ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showPatientDetails(patientData),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('View Details', style: TextStyle(color: context.primaryColor)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _completeAppointmentAndPrescribe(appointment, patientData),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27ae60), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                      ),
                      child: const Text('Complete & Prescribe'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCurrentTab() {
    switch (_currentIndex) {
      case 0: return _buildDashboardTab();
      case 1: return PatientsScreen(
        patients: _patients, 
        onPrescriptionPressed: _showPrescriptionDialog,
        onRefresh: _refreshData, // ✅ Added refresh callback
      );
      case 2: return const EventsScreen();
      case 3: return ProfileScreen(doctorProfile: doctorProfile, onLogoutPressed: _showLogoutDialog);
      default: return _buildDashboardTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('SEVA PULSE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
        actions: _currentIndex == 0 ? [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new notifications'), backgroundColor: Color(0xFF27ae60)))),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => const [PopupMenuItem(value: 'profile', child: Text('My Profile')), PopupMenuItem(value: 'settings', child: Text('Settings')), PopupMenuItem(value: 'logout', child: Text('Logout', style: TextStyle(color: Colors.red)))],
            onSelected: (value) { if (value == 'logout') _showLogoutDialog(); else if (value == 'profile') setState(() => _currentIndex = 3); },
          ),
        ] : null,
      ),
      body: _getCurrentTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: context.surfaceColor,
        selectedItemColor: context.primaryColor,
        unselectedItemColor: context.secondaryText,
        items: const [BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'), BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Patients'), BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'), BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile')],
      ),
    );
  }
}