// lib/features/doctor/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../data/providers/auth_provider.dart';
import '../../../core/services/doctor_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../presentation/common/widgets/settings_section.dart';
import '../../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? doctorProfile;
  final VoidCallback? onLogoutPressed;

  const ProfileScreen({
    Key? key,
    this.doctorProfile,
    this.onLogoutPressed,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _doctorProfile = {};
  final DoctorService _doctorService = DoctorService();

  // Dropdown options
  final List<String> _specializations = [
    'Cardiology',
    'Orthopaedic Surgeons',
    'General Surgeons',
    'Physicians/Internal Medicine',
    'Nephrologists',
    'Paediatricians',
    'Neuro-Spine Surgeons',
    'Cancer Specialist',
    'Cardiologists',
    'Dermatologists',
    'Neurologists',
    'Ophthalmologists',
    'Psychiatrists',
    'Radiologists',
    'Urologists',
    'Gastroenterologists',
    'Endocrinologists',
  ];

  final List<String> _experienceOptions = [
    '0-1 years',
    '1-2 years',
    '2-3 years',
    '3-4 years',
    '4-5 years',
    '5-6 years',
    '6-7 years',
    '7-8 years',
    '8-9 years',
    '9-10 years',
    '10-12 years',
    '12-15 years',
    '15-20 years',
    '20+ years',
  ];

  final List<String> _qualificationOptions = [
    'MBBS',
    'MD - Medicine',
    'MD - Pediatrics',
    'MD - Dermatology',
    'MD - Psychiatry',
    'MS - General Surgery',
    'MS - Orthopedics',
    'MS - ENT',
    'MS - Ophthalmology',
    'DM - Cardiology',
    'DM - Neurology',
    'DM - Nephrology',
    'DM - Gastroenterology',
    'MCh - Neurosurgery',
    'MCh - Cardiothoracic Surgery',
    'MCh - Urology',
    'DNB - Family Medicine',
    'FRCS - General Surgery',
  ];

  final List<String> _consultationFeeOptions = [
    '₹300',
    '₹400',
    '₹500',
    '₹600',
    '₹700',
    '₹800',
    '₹900',
    '₹1000',
    '₹1200',
    '₹1500',
    '₹2000',
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
  }

  Future<void> _loadDoctorProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user != null) {
        if (authProvider.token != null) {
          _doctorService.setToken(authProvider.token!);
        }
        
        final doctorDetails = await _getDoctorDetails(authProvider.token);
        
        setState(() {
          _doctorProfile = {
            'name': user.name,
            'email': user.email,
            'phone': user.phone,
            'specialization': doctorDetails['specialization']?.toString() ?? 'Cardiology',
            'experience': _getExperienceString(doctorDetails['experience']),
            'qualification': _getQualificationsString(doctorDetails['qualifications']),
            'hospital': _getHospitalString(doctorDetails['hospital'] ?? user.address),
            'consultationFee': _getFeeString(doctorDetails['consultationFee']),
            'bio': doctorDetails['bio']?.toString() ?? 'Experienced doctor dedicated to patient care.',
            'department': doctorDetails['department']?.toString() ?? 'General',
            'rating': doctorDetails['rating']?.toString() ?? '4.5',
            'patientsCount': doctorDetails['patientsCount'] ?? 0,
          };
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading doctor profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getExperienceString(dynamic experience) {
    if (experience == null) return '5-6 years';
    if (experience is String) return experience;
    if (experience is int) {
      if (experience < 1) return '0-1 years';
      if (experience <= 2) return '1-2 years';
      if (experience <= 3) return '2-3 years';
      if (experience <= 4) return '3-4 years';
      if (experience <= 5) return '4-5 years';
      if (experience <= 6) return '5-6 years';
      if (experience <= 7) return '6-7 years';
      if (experience <= 8) return '7-8 years';
      if (experience <= 9) return '8-9 years';
      if (experience <= 10) return '9-10 years';
      if (experience <= 12) return '10-12 years';
      if (experience <= 15) return '12-15 years';
      if (experience <= 20) return '15-20 years';
      return '20+ years';
    }
    return '5-6 years';
  }

  String _getQualificationsString(dynamic qualifications) {
    if (qualifications == null) return 'MBBS';
    if (qualifications is String) return qualifications;
    if (qualifications is List && qualifications.isNotEmpty) {
      final degrees = qualifications.map((q) {
        if (q is Map) return q['degree']?.toString() ?? '';
        return q.toString();
      }).where((s) => s.isNotEmpty).toList();
      return degrees.isNotEmpty ? degrees.first : 'MBBS';
    }
    return 'MBBS';
  }

  String _getHospitalString(dynamic hospital) {
    if (hospital == null) return 'City Hospital';
    if (hospital is String) return hospital;
    if (hospital is Map) {
      return hospital['city']?.toString() ?? hospital['name']?.toString() ?? 'City Hospital';
    }
    return 'City Hospital';
  }

  String _getFeeString(dynamic fee) {
    if (fee == null) return '₹500';
    if (fee is String) return fee.startsWith('₹') ? fee : '₹$fee';
    if (fee is int) return '₹$fee';
    return '₹500';
  }

  int _getExperienceValue(String experienceStr) {
    switch (experienceStr) {
      case '0-1 years': return 0;
      case '1-2 years': return 1;
      case '2-3 years': return 2;
      case '3-4 years': return 3;
      case '4-5 years': return 4;
      case '5-6 years': return 5;
      case '6-7 years': return 6;
      case '7-8 years': return 7;
      case '8-9 years': return 8;
      case '9-10 years': return 9;
      case '10-12 years': return 11;
      case '12-15 years': return 13;
      case '15-20 years': return 17;
      case '20+ years': return 22;
      default: return 5;
    }
  }

  int _getFeeValue(String feeStr) {
    final numericStr = feeStr.replaceAll('₹', '').trim();
    return int.tryParse(numericStr) ?? 500;
  }

  Future<Map<String, dynamic>> _getDoctorDetails(String? token) async {
    if (token == null) return {};
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.doctors}/me'),
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
      print('Error fetching doctor details: $e');
      return {};
    }
  }

  Future<void> _updateProfile(Map<String, dynamic> updatedProfile) async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      _doctorService.setToken(token);
      
      final updateData = <String, dynamic>{};
      
      // Only include fields that have changed and are valid
      if (updatedProfile['name'] != _doctorProfile['name'] && updatedProfile['name'] != null) {
        updateData['name'] = updatedProfile['name'].toString();
      }
      if (updatedProfile['email'] != _doctorProfile['email'] && updatedProfile['email'] != null) {
        updateData['email'] = updatedProfile['email'].toString();
      }
      if (updatedProfile['phone'] != _doctorProfile['phone'] && updatedProfile['phone'] != null) {
        updateData['phone'] = updatedProfile['phone'].toString();
      }
      if (updatedProfile['specialization'] != _doctorProfile['specialization'] && updatedProfile['specialization'] != null) {
        updateData['specialization'] = updatedProfile['specialization'].toString();
      }
      if (updatedProfile['experience'] != _doctorProfile['experience'] && updatedProfile['experience'] != null) {
        updateData['experience'] = _getExperienceValue(updatedProfile['experience'].toString());
      }
      if (updatedProfile['qualification'] != _doctorProfile['qualification'] && updatedProfile['qualification'] != null) {
        updateData['qualifications'] = [
          {'degree': updatedProfile['qualification'].toString(), 'institution': 'Medical College', 'year': DateTime.now().year}
        ];
      }
      if (updatedProfile['hospital'] != _doctorProfile['hospital'] && updatedProfile['hospital'] != null) {
        updateData['hospital'] = updatedProfile['hospital'].toString();
      }
      if (updatedProfile['consultationFee'] != _doctorProfile['consultationFee'] && updatedProfile['consultationFee'] != null) {
        updateData['consultationFee'] = _getFeeValue(updatedProfile['consultationFee'].toString());
      }
      if (updatedProfile['bio'] != _doctorProfile['bio'] && updatedProfile['bio'] != null) {
        updateData['bio'] = updatedProfile['bio'].toString();
      }
      
      print('📤 Sending update data: $updateData');
      
      if (updateData.isNotEmpty) {
        await _doctorService.updateDoctorProfile(updateData);
        
        setState(() {
          _doctorProfile = updatedProfile;
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
      print('Error updating profile: $e');
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

  void _showEditProfileSheet() {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: _doctorProfile['name']?.toString() ?? '');
    final emailController = TextEditingController(text: _doctorProfile['email']?.toString() ?? '');
    final phoneController = TextEditingController(text: _doctorProfile['phone']?.toString() ?? '');
    final hospitalController = TextEditingController(text: _doctorProfile['hospital']?.toString() ?? '');
    final bioController = TextEditingController(text: _doctorProfile['bio']?.toString() ?? '');
    
    String selectedSpecialization = _doctorProfile['specialization']?.toString() ?? _specializations[0];
    String selectedExperience = _doctorProfile['experience']?.toString() ?? _experienceOptions[5];
    String selectedQualification = _doctorProfile['qualification']?.toString() ?? _qualificationOptions[0];
    String selectedFee = _doctorProfile['consultationFee']?.toString() ?? _consultationFeeOptions[2];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
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
                Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.primaryText),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Basic Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.primaryColor)),
                        const SizedBox(height: 12),
                        _buildEditField('Full Name', nameController),
                        const SizedBox(height: 12),
                        _buildEditField('Email', emailController),
                        const SizedBox(height: 12),
                        _buildEditField('Phone', phoneController),
                        const SizedBox(height: 12),
                        _buildEditField('Hospital/Clinic', hospitalController),
                        const SizedBox(height: 24),
                        
                        Text('Professional Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.primaryColor)),
                        const SizedBox(height: 12),
                        
                        // Specialization
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: DropdownButtonFormField<String>(
                            value: selectedSpecialization,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Specialization',
                              labelStyle: TextStyle(color: context.secondaryText),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: _specializations.map((String spec) {
                              return DropdownMenuItem<String>(
                                value: spec,
                                child: Text(spec, style: TextStyle(color: context.primaryText), overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setSheetState(() {
                                selectedSpecialization = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Experience
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: DropdownButtonFormField<String>(
                            value: selectedExperience,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Experience',
                              labelStyle: TextStyle(color: context.secondaryText),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: _experienceOptions.map((String exp) {
                              return DropdownMenuItem<String>(
                                value: exp,
                                child: Text(exp, style: TextStyle(color: context.primaryText)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setSheetState(() {
                                selectedExperience = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Qualification
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: DropdownButtonFormField<String>(
                            value: selectedQualification,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Qualification',
                              labelStyle: TextStyle(color: context.secondaryText),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: _qualificationOptions.map((String qual) {
                              return DropdownMenuItem<String>(
                                value: qual,
                                child: Text(qual, style: TextStyle(color: context.primaryText), overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setSheetState(() {
                                selectedQualification = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Consultation Fee
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: DropdownButtonFormField<String>(
                            value: selectedFee,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Consultation Fee',
                              labelStyle: TextStyle(color: context.secondaryText),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: _consultationFeeOptions.map((String fee) {
                              return DropdownMenuItem<String>(
                                value: fee,
                                child: Text(fee, style: TextStyle(color: context.primaryText)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setSheetState(() {
                                selectedFee = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Bio
                        _buildEditField('Bio', bioController, maxLines: 3),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.primaryColor),
                        ),
                        child: Text('Cancel', style: TextStyle(color: context.primaryColor)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final updatedProfile = {
                            'name': nameController.text,
                            'email': emailController.text,
                            'phone': phoneController.text,
                            'specialization': selectedSpecialization,
                            'experience': selectedExperience,
                            'qualification': selectedQualification,
                            'hospital': hospitalController.text,
                            'consultationFee': selectedFee,
                            'bio': bioController.text,
                            'rating': _doctorProfile['rating'],
                            'patientsCount': _doctorProfile['patientsCount'],
                          };
                          _updateProfile(updatedProfile);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27ae60),
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: context.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
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
            onPressed: _isSaving ? null : _showEditProfileSheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: context.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: context.primaryColor.withOpacity(0.1),
                      child: Icon(Icons.medical_services, size: 40, color: context.primaryColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _doctorProfile['name']?.toString() ?? 'Doctor',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.primaryText),
                    ),
                    Text(
                      _doctorProfile['specialization']?.toString() ?? 'Specialist',
                      style: TextStyle(fontSize: 18, color: context.primaryColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _doctorProfile['hospital']?.toString() ?? 'City Hospital',
                      style: TextStyle(color: context.secondaryText),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildProfileStat('Patients', _doctorProfile['patientsCount']?.toString() ?? '0'),
                        const SizedBox(width: 20),
                        _buildProfileStat('Rating', _doctorProfile['rating']?.toString() ?? '4.5 ⭐'),
                        const SizedBox(width: 20),
                        _buildProfileStat('Exp', _doctorProfile['experience']?.toString() ?? '5 yrs'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: context.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Professional Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.primaryText),
                    ),
                    const SizedBox(height: 16),
                    _buildProfileDetail('Qualification', _doctorProfile['qualification']?.toString() ?? 'MBBS'),
                    _buildProfileDetail('Consultation Fee', _doctorProfile['consultationFee']?.toString() ?? '₹500'),
                    _buildProfileDetail('Contact', _doctorProfile['phone']?.toString() ?? ''),
                    _buildProfileDetail('Email', _doctorProfile['email']?.toString() ?? ''),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: context.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.primaryText),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _doctorProfile['bio']?.toString() ?? 'Experienced doctor dedicated to patient care.',
                      style: TextStyle(color: context.secondaryText, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Settings & Logout section with SettingsSection widget
            SettingsSection(
              onLogout: widget.onLogoutPressed ?? () {},
              showNotifications: true,
              showPrivacy: true,
              showHealthData: true,
              showLanguage: true,
              showHelp: true,
              showAbout: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String title, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.primaryText)),
        Text(title, style: TextStyle(color: context.secondaryText, fontSize: 12)),
      ],
    );
  }

  Widget _buildProfileDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label: ',
              style: TextStyle(fontWeight: FontWeight.w500, color: context.primaryText),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not specified' : value,
              style: TextStyle(color: context.secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}