// lib/features/user/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../core/services/patient_service.dart';
import '../../../core/constants/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../presentation/common/widgets/settings_section.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _userProfile = {
    'personalInfo': {
      'name': '',
      'email': '',
      'phone': '',
      'dateOfBirth': 'Not set',
      'gender': 'Not set',
      'bloodType': 'Not set',
      'address': {
        'street': '',
        'city': '',
        'state': '',
        'zipCode': '',
      },
    },
    'emergencyContact': {
      'name': '',
      'relationship': '',
      'phone': '',
    },
    'medicalInfo': {
      'allergies': 'No allergies recorded',
      'medicalConditions': 'No conditions recorded',
      'currentMedications': 'No medications recorded',
      'surgeries': 'No surgeries recorded',
      'familyHistory': 'No family history recorded',
    },
  };

  final PatientService _patientService = PatientService();

  // Dropdown options
  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Not set'];
  final List<String> _bloodTypeOptions = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-', 'Not set'];
  final List<String> _relationshipOptions = ['Spouse', 'Parent', 'Child', 'Sibling', 'Friend', 'Other', 'Not set'];
  
  // Medical dropdown options
  final List<String> _allergiesOptions = [
    'No allergies recorded',
    'Pollen',
    'Dust',
    'Peanuts',
    'Tree nuts',
    'Shellfish',
    'Dairy',
    'Eggs',
    'Soy',
    'Wheat',
    'Latex',
    'Penicillin',
    'Sulfa drugs',
    'NSAIDs',
    'Insect stings',
    'Other'
  ];
  
  final List<String> _medicalConditionsOptions = [
    'No conditions recorded',
    'Hypertension',
    'Diabetes Type 1',
    'Diabetes Type 2',
    'Asthma',
    'COPD',
    'Arthritis',
    'Osteoarthritis',
    'Rheumatoid Arthritis',
    'Heart Disease',
    'Coronary Artery Disease',
    'Heart Failure',
    'Kidney Disease',
    'Chronic Kidney Disease',
    'Thyroid Disorder',
    'Hypothyroidism',
    'Hyperthyroidism',
    'Anemia',
    'Migraine',
    'Depression',
    'Anxiety',
    'Allergies',
    'Other'
  ];
  
  final List<String> _medicationsOptions = [
    'No medications recorded',
    'Lisinopril',
    'Amlodipine',
    'Metformin',
    'Atorvastatin',
    'Levothyroxine',
    'Omeprazole',
    'Losartan',
    'Albuterol',
    'Gabapentin',
    'Hydrochlorothiazide',
    'Sertraline',
    'Escitalopram',
    'Other'
  ];
  
  final List<String> _surgeriesOptions = [
    'No surgeries recorded',
    'Appendectomy',
    'Gallbladder removal',
    'Hernia repair',
    'Knee surgery',
    'Hip replacement',
    'C-section',
    'Tonsillectomy',
    'Wisdom teeth removal',
    'Cataract surgery',
    'Other'
  ];
  
  final List<String> _familyHistoryOptions = [
    'No family history recorded',
    'Heart Disease',
    'Diabetes',
    'High Blood Pressure',
    'Cancer',
    'Stroke',
    'Kidney Disease',
    'Thyroid Disorder',
    'Alzheimer\'s',
    'Asthma',
    'Arthritis',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user != null) {
        if (authProvider.token != null) {
          _patientService.setToken(authProvider.token!);
        }
        
        final patientDetails = await _getPatientDetails(authProvider.token);
        
        // Extract address data
        final address = patientDetails['address'] ?? {};
        final emergencyContact = patientDetails['emergencyContact'] ?? {};
        
        setState(() {
          _userProfile = {
            'personalInfo': {
              'name': user.name,
              'email': user.email,
              'phone': user.phone,
              'dateOfBirth': patientDetails['dateOfBirth'] != null 
                  ? _formatDate(patientDetails['dateOfBirth']) 
                  : (user.dateOfBirth?.toString().split('T')[0] ?? 'Not set'),
              'gender': patientDetails['gender'] ?? user.gender ?? 'Not set',
              'bloodType': patientDetails['bloodGroup'] ?? 'Not set',
              'address': {
                'street': address['street']?.toString() ?? '',
                'city': address['city']?.toString() ?? '',
                'state': address['state']?.toString() ?? '',
                'zipCode': address['zipCode']?.toString() ?? '',
              },
            },
            'emergencyContact': {
              'name': emergencyContact['name']?.toString() ?? '',
              'relationship': emergencyContact['relationship']?.toString() ?? '',
              'phone': emergencyContact['phone']?.toString() ?? '',
            },
            'medicalInfo': {
              'allergies': patientDetails['allergies']?.isNotEmpty == true 
                  ? patientDetails['allergies'].join(', ') 
                  : 'No allergies recorded',
              'medicalConditions': patientDetails['medicalHistory']?.isNotEmpty == true
                  ? patientDetails['medicalHistory'].map((h) => h['condition']).join(', ')
                  : 'No conditions recorded',
              'currentMedications': patientDetails['currentMedications']?.isNotEmpty == true
                  ? patientDetails['currentMedications'].map((m) => '${m['name']}').join(', ')
                  : 'No medications recorded',
              'surgeries': patientDetails['surgeries']?.isNotEmpty == true
                  ? patientDetails['surgeries'].join(', ')
                  : 'No surgeries recorded',
              'familyHistory': patientDetails['familyHistory']?.isNotEmpty == true
                  ? patientDetails['familyHistory'].join(', ')
                  : 'No family history recorded',
            },
          };
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'Not set';
    try {
      if (dateValue is String) {
        final date = DateTime.parse(dateValue);
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } else if (dateValue is DateTime) {
        return '${dateValue.year}-${dateValue.month.toString().padLeft(2, '0')}-${dateValue.day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return dateValue.toString();
    }
    return 'Not set';
  }

  String _getFullAddress() {
    final address = _userProfile['personalInfo']['address'];
    final parts = [
      address['street'],
      address['city'],
      address['state'],
      address['zipCode'],
    ].where((p) => p != null && p.toString().isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Not set';
  }

  Future<Map<String, dynamic>> _getPatientDetails(String? token) async {
    if (token == null) return {};
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.patients}/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          return data['data'];
        }
      }
      return {};
    } catch (e) {
      print('Error fetching patient details: $e');
      return {};
    }
  }

  Future<void> _updateProfile(Map<String, dynamic> newProfile) async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      _patientService.setToken(token);
      
      final updateData = <String, dynamic>{};
      
      // Personal info
      if (newProfile['personalInfo']['name'] != _userProfile['personalInfo']['name']) {
        updateData['name'] = newProfile['personalInfo']['name'];
      }
      if (newProfile['personalInfo']['email'] != _userProfile['personalInfo']['email']) {
        updateData['email'] = newProfile['personalInfo']['email'];
      }
      if (newProfile['personalInfo']['phone'] != _userProfile['personalInfo']['phone']) {
        updateData['phone'] = newProfile['personalInfo']['phone'];
      }
      if (newProfile['personalInfo']['dateOfBirth'] != _userProfile['personalInfo']['dateOfBirth'] &&
          newProfile['personalInfo']['dateOfBirth'] != 'Not set') {
        updateData['dateOfBirth'] = newProfile['personalInfo']['dateOfBirth'];
      }
      if (newProfile['personalInfo']['gender'] != _userProfile['personalInfo']['gender'] &&
          newProfile['personalInfo']['gender'] != 'Not set') {
        updateData['gender'] = newProfile['personalInfo']['gender'];
      }
      if (newProfile['personalInfo']['bloodType'] != _userProfile['personalInfo']['bloodType'] &&
          newProfile['personalInfo']['bloodType'] != 'Not set') {
        updateData['bloodGroup'] = newProfile['personalInfo']['bloodType'];
      }
      
      // Address update
      final oldAddress = _userProfile['personalInfo']['address'];
      final newAddress = newProfile['personalInfo']['address'];
      if (newAddress['street'] != oldAddress['street'] ||
          newAddress['city'] != oldAddress['city'] ||
          newAddress['state'] != oldAddress['state'] ||
          newAddress['zipCode'] != oldAddress['zipCode']) {
        updateData['address'] = {
          'street': newAddress['street'],
          'city': newAddress['city'],
          'state': newAddress['state'],
          'zipCode': newAddress['zipCode'],
        };
      }
      
      // Emergency Contact update
      final oldEmergency = _userProfile['emergencyContact'];
      final newEmergency = newProfile['emergencyContact'];
      if (newEmergency['name'] != oldEmergency['name'] ||
          newEmergency['relationship'] != oldEmergency['relationship'] ||
          newEmergency['phone'] != oldEmergency['phone']) {
        updateData['emergencyContact'] = {
          'name': newEmergency['name'],
          'phone': newEmergency['phone'],
          'relationship': newEmergency['relationship'],
        };
      }
      
      // Medical info - Allergies
      if (newProfile['medicalInfo']['allergies'] != _userProfile['medicalInfo']['allergies'] &&
          newProfile['medicalInfo']['allergies'] != 'No allergies recorded') {
        updateData['allergies'] = newProfile['medicalInfo']['allergies']
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty && s != 'No allergies recorded')
            .toList();
      }
      
      // Medical info - Conditions
      if (newProfile['medicalInfo']['medicalConditions'] != _userProfile['medicalInfo']['medicalConditions'] &&
          newProfile['medicalInfo']['medicalConditions'] != 'No conditions recorded') {
        updateData['medicalHistory'] = newProfile['medicalInfo']['medicalConditions']
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty && s != 'No conditions recorded')
            .map((condition) => ({
              'condition': condition,
              'diagnosedDate': DateTime.now().toIso8601String(),
              'notes': ''
            }))
            .toList();
      }
      
      // Medical info - Medications
      if (newProfile['medicalInfo']['currentMedications'] != _userProfile['medicalInfo']['currentMedications'] &&
          newProfile['medicalInfo']['currentMedications'] != 'No medications recorded') {
        updateData['currentMedications'] = newProfile['medicalInfo']['currentMedications']
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty && s != 'No medications recorded')
            .map((med) => ({
              'name': med,
              'dosage': '',
              'frequency': ''
            }))
            .toList();
      }
      
      // Medical info - Surgeries
      if (newProfile['medicalInfo']['surgeries'] != _userProfile['medicalInfo']['surgeries'] &&
          newProfile['medicalInfo']['surgeries'] != 'No surgeries recorded') {
        updateData['surgeries'] = newProfile['medicalInfo']['surgeries']
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty && s != 'No surgeries recorded')
            .toList();
      }
      
      // Medical info - Family History
      if (newProfile['medicalInfo']['familyHistory'] != _userProfile['medicalInfo']['familyHistory'] &&
          newProfile['medicalInfo']['familyHistory'] != 'No family history recorded') {
        updateData['familyHistory'] = newProfile['medicalInfo']['familyHistory']
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty && s != 'No family history recorded')
            .toList();
      }
      
      print('📤 Sending update data: $updateData');
      
      if (updateData.isNotEmpty) {
        await _patientService.updatePatientProfile(updateData);
        
        setState(() {
          _userProfile = newProfile;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No changes to update'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3498db)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.edit),
            onPressed: _isSaving ? null : () {
              _showEditProfileDialog(context, authProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(_userProfile['personalInfo']),
            const SizedBox(height: 24),
            _buildPersonalInfoSection(_userProfile['personalInfo']),
            const SizedBox(height: 24),
            _buildAddressSection(_userProfile['personalInfo']['address']),
            const SizedBox(height: 24),
            _buildEmergencyContactSection(_userProfile['emergencyContact']),
            const SizedBox(height: 24),
            _buildMedicalInfoSection(_userProfile['medicalInfo']),
            const SizedBox(height: 24),
            _buildSettingsSection(context, authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> personalInfo) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 40,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    personalInfo['name'] ?? 'User Name',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    personalInfo['email'] ?? 'user@example.com',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27ae60).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Seva Pulse Member',
                      style: TextStyle(
                        color: Color(0xFF27ae60),
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
      ),
    );
  }

  Widget _buildPersonalInfoSection(Map<String, dynamic> personalInfo) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Full Name', personalInfo['name'] ?? 'Not set'),
            _buildInfoRow('Email', personalInfo['email'] ?? 'Not set'),
            _buildInfoRow('Phone', personalInfo['phone'] ?? 'Not set'),
            _buildInfoRow('Date of Birth', personalInfo['dateOfBirth'] ?? 'Not set'),
            _buildInfoRow('Gender', personalInfo['gender'] ?? 'Not set'),
            _buildInfoRow('Blood Type', personalInfo['bloodType'] ?? 'Not set'),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection(Map<String, dynamic> address) {
    final theme = Theme.of(context);
    final fullAddress = [
      address['street'],
      address['city'],
      address['state'],
      address['zipCode'],
    ].where((p) => p != null && p.toString().isNotEmpty).join(', ');
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (fullAddress.isNotEmpty && fullAddress != 'Not set')
              Text(
                fullAddress,
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
              )
            else
              Text(
                'No address added',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactSection(Map<String, dynamic> emergencyContact) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emergency, color: Color(0xFFe74c3c)),
                SizedBox(width: 8),
                Text(
                  'Emergency Contact',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2c3e50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', emergencyContact['name']?.isNotEmpty == true ? emergencyContact['name'] : 'Not set'),
            _buildInfoRow('Relationship', emergencyContact['relationship']?.isNotEmpty == true ? emergencyContact['relationship'] : 'Not set'),
            _buildInfoRow('Phone', emergencyContact['phone']?.isNotEmpty == true ? emergencyContact['phone'] : 'Not set'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalInfoSection(Map<String, dynamic> medicalInfo) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Medical Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMedicalItem('Allergies', medicalInfo['allergies'] ?? 'Not set'),
            _buildMedicalItem('Medical Conditions', medicalInfo['medicalConditions'] ?? 'Not set'),
            _buildMedicalItem('Current Medications', medicalInfo['currentMedications'] ?? 'Not set'),
            _buildMedicalItem('Surgeries', medicalInfo['surgeries'] ?? 'Not set'),
            _buildMedicalItem('Family History', medicalInfo['familyHistory'] ?? 'Not set'),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalItem(String title, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: theme.colorScheme.onSurface.withOpacity(0.1)),
        ],
      ),
    );
  }

  
Widget _buildSettingsSection(BuildContext context, AuthProvider authProvider) {
  return SettingsSection(
    onLogout: () => _showLogoutDialog(context, authProvider),
    showNotifications: true,
    showPrivacy: true,
    showHealthData: true,
    showLanguage: true,
    showHelp: true,
    showAbout: true,
  );
}

  void _showEditProfileDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(
        authProvider: authProvider,
        currentProfile: _userProfile,
        onProfileUpdated: _updateProfile,
        genderOptions: _genderOptions,
        bloodTypeOptions: _bloodTypeOptions,
        relationshipOptions: _relationshipOptions,
        allergiesOptions: _allergiesOptions,
        medicalConditionsOptions: _medicalConditionsOptions,
        medicationsOptions: _medicationsOptions,
        surgeriesOptions: _surgeriesOptions,
        familyHistoryOptions: _familyHistoryOptions,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from Seva Pulse?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              authProvider.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced EditProfileDialog with Medical Dropdowns and theme support
class EditProfileDialog extends StatefulWidget {
  final AuthProvider authProvider;
  final Map<String, dynamic> currentProfile;
  final Function(Map<String, dynamic>) onProfileUpdated;
  final List<String> genderOptions;
  final List<String> bloodTypeOptions;
  final List<String> relationshipOptions;
  final List<String> allergiesOptions;
  final List<String> medicalConditionsOptions;
  final List<String> medicationsOptions;
  final List<String> surgeriesOptions;
  final List<String> familyHistoryOptions;

  const EditProfileDialog({
    Key? key,
    required this.authProvider,
    required this.currentProfile,
    required this.onProfileUpdated,
    required this.genderOptions,
    required this.bloodTypeOptions,
    required this.relationshipOptions,
    required this.allergiesOptions,
    required this.medicalConditionsOptions,
    required this.medicationsOptions,
    required this.surgeriesOptions,
    required this.familyHistoryOptions,
  }) : super(key: key);

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  
  // Address controllers
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;
  
  // Emergency Contact controllers
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  
  // Medical selections
  late String _selectedGender;
  late String _selectedBloodType;
  late String _selectedRelationship;
  late String _selectedAllergies;
  late String _selectedMedicalConditions;
  late String _selectedMedications;
  late String _selectedSurgeries;
  late String _selectedFamilyHistory;
  
  // Custom text controllers for "Other" option
  late TextEditingController _customAllergiesController;
  late TextEditingController _customMedicalConditionsController;
  late TextEditingController _customMedicationsController;
  late TextEditingController _customSurgeriesController;
  late TextEditingController _customFamilyHistoryController;

  @override
  void initState() {
    super.initState();
    final personalInfo = widget.currentProfile['personalInfo'];
    final address = personalInfo['address'] ?? {};
    final emergencyContact = widget.currentProfile['emergencyContact'] ?? {};
    final medicalInfo = widget.currentProfile['medicalInfo'];
    
    _nameController = TextEditingController(text: personalInfo['name'] ?? '');
    _emailController = TextEditingController(text: personalInfo['email'] ?? '');
    _phoneController = TextEditingController(text: personalInfo['phone'] ?? '');
    _dobController = TextEditingController(text: personalInfo['dateOfBirth'] != 'Not set' ? personalInfo['dateOfBirth'] : '');
    
    _streetController = TextEditingController(text: address['street'] ?? '');
    _cityController = TextEditingController(text: address['city'] ?? '');
    _stateController = TextEditingController(text: address['state'] ?? '');
    _zipCodeController = TextEditingController(text: address['zipCode'] ?? '');
    
    _emergencyNameController = TextEditingController(text: emergencyContact['name'] ?? '');
    _emergencyPhoneController = TextEditingController(text: emergencyContact['phone'] ?? '');
    
    _selectedGender = personalInfo['gender'] ?? 'Not set';
    _selectedBloodType = personalInfo['bloodType'] ?? 'Not set';
    _selectedRelationship = emergencyContact['relationship'] ?? 'Not set';
    _selectedAllergies = medicalInfo['allergies'] ?? 'No allergies recorded';
    _selectedMedicalConditions = medicalInfo['medicalConditions'] ?? 'No conditions recorded';
    _selectedMedications = medicalInfo['currentMedications'] ?? 'No medications recorded';
    _selectedSurgeries = medicalInfo['surgeries'] ?? 'No surgeries recorded';
    _selectedFamilyHistory = medicalInfo['familyHistory'] ?? 'No family history recorded';
    
    _customAllergiesController = TextEditingController();
    _customMedicalConditionsController = TextEditingController();
    _customMedicationsController = TextEditingController();
    _customSurgeriesController = TextEditingController();
    _customFamilyHistoryController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _customAllergiesController.dispose();
    _customMedicalConditionsController.dispose();
    _customMedicationsController.dispose();
    _customSurgeriesController.dispose();
    _customFamilyHistoryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // Handle custom values
      String allergies = _selectedAllergies;
      if (_selectedAllergies == 'Other' && _customAllergiesController.text.isNotEmpty) {
        allergies = _customAllergiesController.text;
      }
      
      String medicalConditions = _selectedMedicalConditions;
      if (_selectedMedicalConditions == 'Other' && _customMedicalConditionsController.text.isNotEmpty) {
        medicalConditions = _customMedicalConditionsController.text;
      }
      
      String medications = _selectedMedications;
      if (_selectedMedications == 'Other' && _customMedicationsController.text.isNotEmpty) {
        medications = _customMedicationsController.text;
      }
      
      String surgeries = _selectedSurgeries;
      if (_selectedSurgeries == 'Other' && _customSurgeriesController.text.isNotEmpty) {
        surgeries = _customSurgeriesController.text;
      }
      
      String familyHistory = _selectedFamilyHistory;
      if (_selectedFamilyHistory == 'Other' && _customFamilyHistoryController.text.isNotEmpty) {
        familyHistory = _customFamilyHistoryController.text;
      }
      
      final updatedProfile = {
        'personalInfo': {
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'dateOfBirth': _dobController.text.isEmpty ? 'Not set' : _dobController.text,
          'gender': _selectedGender,
          'bloodType': _selectedBloodType,
          'address': {
            'street': _streetController.text,
            'city': _cityController.text,
            'state': _stateController.text,
            'zipCode': _zipCodeController.text,
          },
        },
        'emergencyContact': {
          'name': _emergencyNameController.text,
          'phone': _emergencyPhoneController.text,
          'relationship': _selectedRelationship,
        },
        'medicalInfo': {
          'allergies': allergies,
          'medicalConditions': medicalConditions,
          'currentMedications': medications,
          'surgeries': surgeries,
          'familyHistory': familyHistory,
        },
      };

      widget.onProfileUpdated(updatedProfile);
      Navigator.pop(context);
    }
  }

  Widget _buildDropdownField(String label, String value, List<String> options, Function(String?) onChanged,
      {TextEditingController? customController}) {
    final theme = Theme.of(context);
    final isOtherSelected = value == 'Other';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: options.contains(value) ? value : (options.contains('Other') ? 'Other' : null),
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: onChanged,
        ),
        if (isOtherSelected && customController != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextFormField(
              controller: customController,
              decoration: InputDecoration(
                labelText: 'Please specify',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 500,
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Profile',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information
                      _buildSectionHeader('Personal Information'),
                      const SizedBox(height: 12),
                      _buildTextField('Full Name', _nameController),
                      const SizedBox(height: 12),
                      _buildTextField('Email', _emailController),
                      const SizedBox(height: 12),
                      _buildTextField('Phone', _phoneController),
                      const SizedBox(height: 12),
                      _buildDateField('Date of Birth', _dobController, _selectDate),
                      const SizedBox(height: 12),
                      _buildDropdownField('Gender', _selectedGender, widget.genderOptions, (value) => setState(() => _selectedGender = value!)),
                      const SizedBox(height: 12),
                      _buildDropdownField('Blood Type', _selectedBloodType, widget.bloodTypeOptions, (value) => setState(() => _selectedBloodType = value!)),
                      
                      const SizedBox(height: 24),
                      // Address Section
                      _buildSectionHeader('Address'),
                      const SizedBox(height: 12),
                      _buildTextField('Street', _streetController),
                      const SizedBox(height: 12),
                      _buildTextField('City', _cityController),
                      const SizedBox(height: 12),
                      _buildTextField('State', _stateController),
                      const SizedBox(height: 12),
                      _buildTextField('Zip Code', _zipCodeController, keyboardType: TextInputType.number),
                      
                      const SizedBox(height: 24),
                      // Emergency Contact Section
                      _buildSectionHeader('Emergency Contact', iconColor: Colors.red),
                      const SizedBox(height: 12),
                      _buildTextField('Contact Name', _emergencyNameController),
                      const SizedBox(height: 12),
                      _buildTextField('Contact Phone', _emergencyPhoneController, keyboardType: TextInputType.phone),
                      const SizedBox(height: 12),
                      _buildDropdownField('Relationship', _selectedRelationship, widget.relationshipOptions, (value) => setState(() => _selectedRelationship = value!)),
                      
                      const SizedBox(height: 24),
                      // Medical Information Section
                      _buildSectionHeader('Medical Information'),
                      const SizedBox(height: 12),
                      _buildDropdownField('Allergies', _selectedAllergies, widget.allergiesOptions, 
                          (value) => setState(() => _selectedAllergies = value!), 
                          customController: _customAllergiesController),
                      const SizedBox(height: 12),
                      _buildDropdownField('Medical Conditions', _selectedMedicalConditions, widget.medicalConditionsOptions, 
                          (value) => setState(() => _selectedMedicalConditions = value!), 
                          customController: _customMedicalConditionsController),
                      const SizedBox(height: 12),
                      _buildDropdownField('Current Medications', _selectedMedications, widget.medicationsOptions, 
                          (value) => setState(() => _selectedMedications = value!), 
                          customController: _customMedicationsController),
                      const SizedBox(height: 12),
                      _buildDropdownField('Surgeries', _selectedSurgeries, widget.surgeriesOptions, 
                          (value) => setState(() => _selectedSurgeries = value!), 
                          customController: _customSurgeriesController),
                      const SizedBox(height: 12),
                      _buildDropdownField('Family History', _selectedFamilyHistory, widget.familyHistoryOptions, 
                          (value) => setState(() => _selectedFamilyHistory = value!), 
                          customController: _customFamilyHistoryController),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27ae60)),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color iconColor = Colors.blue}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.info, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller, VoidCallback onTap) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
    );
  }
}