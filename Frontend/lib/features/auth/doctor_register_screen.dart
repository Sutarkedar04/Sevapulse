// lib/features/auth/doctor_register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seva_pulse/features/doctor/screens/doctor_home_screen.dart';
import '../../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION
import '../../../data/providers/auth_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../core/services/doctor_service.dart';

class DoctorRegisterScreen extends StatefulWidget {
  const DoctorRegisterScreen({Key? key}) : super(key: key);

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _experienceController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  final _bioController = TextEditingController();
  final _dobController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  DateTime? _selectedDate;
  
  // Dropdown selections
  String? _selectedSpecialization;
  List<String> _selectedQualifications = [];
  
  // Specialization options
  final List<String> _specializations = [
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
  
  // Qualification options
  final List<Map<String, String>> _qualifications = [
    {'degree': 'MBBS', 'institution': 'Medical College'},
    {'degree': 'MD', 'institution': 'Medical College'},
    {'degree': 'MS', 'institution': 'Medical College'},
    {'degree': 'DM', 'institution': 'Super Specialty'},
    {'degree': 'MCh', 'institution': 'Super Specialty'},
    {'degree': 'DNB', 'institution': 'National Board'},
    {'degree': 'FRCS', 'institution': 'Royal College'},
    {'degree': 'MRCP', 'institution': 'Royal College'},
    {'degree': 'Fellowship', 'institution': 'Various'},
    {'degree': 'PhD', 'institution': 'University'},
  ];

  @override
  void initState() {
    super.initState();
    _dobController.text = '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _hospitalController.dispose();
    _consultationFeeController.dispose();
    _bioController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _registerDoctor() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedSpecialization == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a specialization'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedQualifications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one qualification'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Format qualifications as list of maps
      final qualificationsList = _selectedQualifications.map((qual) {
        final qualData = _qualifications.firstWhere(
          (q) => q['degree'] == qual,
          orElse: () => {'degree': qual, 'institution': 'Medical College'},
        );
        return {
          'degree': qualData['degree'],
          'institution': qualData['institution'],
          'year': DateTime.now().year,
        };
      }).toList();
      
      // Create doctor user object with all fields
      final user = User(
        id: '',
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        userType: 'doctor',
        profileImage: null,
        createdAt: DateTime.now(),
        specialization: _selectedSpecialization,
        experience: _experienceController.text.trim(),
        address: _hospitalController.text.trim(),
        dateOfBirth: _selectedDate,
      );

      final success = await authProvider.register(user, _passwordController.text);

      if (success && mounted) {
        // After successful registration, update doctor profile with additional details
        final token = authProvider.token;
        if (token != null) {
          final doctorService = DoctorService();
          doctorService.setToken(token);
          
          // Update doctor profile with all details
          await doctorService.updateDoctorProfile({
            'specialization': _selectedSpecialization,
            'experience': int.tryParse(_experienceController.text.trim()) ?? 0,
            'consultationFee': int.tryParse(_consultationFeeController.text.trim()) ?? 500,
            'qualifications': qualificationsList,
            'bio': _bioController.text.trim().isEmpty 
                ? 'Experienced doctor dedicated to patient care.' 
                : _bioController.text.trim(),
            'hospital': _hospitalController.text.trim(),
            'dateOfBirth': _selectedDate?.toIso8601String(),
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Doctor registration successful!'),
            backgroundColor: const Color(0xFF27ae60),
            duration: const Duration(seconds: 2),
          ),
        );
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DoctorHomeScreen()),
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Registration failed. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Registration error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString().replaceFirst('Exception: ', '')}'),
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

  void _showQualificationDialog() {
    List<String> tempSelected = List.from(_selectedQualifications);
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Select Qualifications',
                style: TextStyle(fontWeight: FontWeight.bold, color: context.primaryText),
              ),
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _qualifications.map((qualification) {
                      final degree = qualification['degree']!;
                      return CheckboxListTile(
                        title: Text(
                          degree,
                          style: TextStyle(fontSize: 14, color: context.primaryText),
                        ),
                        subtitle: Text(
                          qualification['institution']!,
                          style: TextStyle(fontSize: 12, color: context.secondaryText),
                        ),
                        value: tempSelected.contains(degree),
                        onChanged: (bool? checked) {
                          setDialogState(() {
                            if (checked == true) {
                              tempSelected.add(degree);
                            } else {
                              tempSelected.remove(degree);
                            }
                          });
                        },
                        activeColor: context.primaryColor,
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel', style: TextStyle(color: context.primaryColor)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedQualifications = List.from(tempSelected);
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27ae60),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: context.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.primaryColor.withOpacity(0.3)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: context.primaryText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Doctor Registration'),
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Join as Doctor',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: context.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your doctor account to manage patients and appointments',
                style: TextStyle(
                  color: context.secondaryText,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),

              // Personal Information Section
              _buildSectionHeader('Personal Information'),
              const SizedBox(height: 20),

              // Name Field
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: context.primaryText),
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  labelStyle: TextStyle(color: context.secondaryText),
                  prefixIcon: Icon(Icons.person, color: context.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.secondaryText.withOpacity(0.3)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  if (value.length < 2) {
                    return 'Name must be at least 2 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Email Field
              TextFormField(
                controller: _emailController,
                style: TextStyle(color: context.primaryText),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address *',
                  labelStyle: TextStyle(color: context.secondaryText),
                  prefixIcon: Icon(Icons.email, color: context.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.secondaryText.withOpacity(0.3)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                style: TextStyle(color: context.primaryText),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  labelStyle: TextStyle(color: context.secondaryText),
                  prefixIcon: Icon(Icons.phone, color: context.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.secondaryText.withOpacity(0.3)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Date of Birth Field
              TextFormField(
                controller: _dobController,
                style: TextStyle(color: context.primaryText),
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date of Birth (Optional)',
                  labelStyle: TextStyle(color: context.secondaryText),
                  prefixIcon: Icon(Icons.calendar_today, color: context.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.secondaryText.withOpacity(0.3)),
                  ),
                  hintText: 'YYYY-MM-DD',
                  hintStyle: TextStyle(color: context.secondaryText.withOpacity(0.5)),
                ),
                onTap: _selectDate,
              ),
              const SizedBox(height: 30),

              // Professional Information Section
              _buildSectionHeader('Professional Information'),
              const SizedBox(height: 20),

              // Specialization Dropdown
              DropdownButtonFormField<String>(
                value: _selectedSpecialization,
                decoration: InputDecoration(
                  labelText: 'Specialization *',
                  labelStyle: TextStyle(color: context.secondaryText),
                  prefixIcon: Icon(Icons.medical_services, color: context.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.secondaryText.withOpacity(0.3)),
                  ),
                  hintText: 'Select your specialization',
                ),
                items: _specializations.map((String specialization) {
                  return DropdownMenuItem<String>(
                    value: specialization,
                    child: Text(specialization, style: TextStyle(color: context.primaryText)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSpecialization = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your specialization';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Qualifications Selection
              InkWell(
                onTap: _showQualificationDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.secondaryText.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.school, color: context.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Qualifications *',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedQualifications.isEmpty
                                  ? 'Select your qualifications'
                                  : _selectedQualifications.join(', '),
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedQualifications.isEmpty
                                    ? context.secondaryText.withOpacity(0.5)
                                    : context.primaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: context.primaryColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Experience Field
              TextFormField(
                controller: _experienceController,
                style: TextStyle(color: context.primaryText),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Years of Experience *',
                  labelStyle: TextStyle(color: context.secondaryText),
                  prefixIcon: Icon(Icons.work, color: context.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.secondaryText.withOpacity(0.3)),
                  ),
                  hintText: 'e.g., 5',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your experience';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Hospital/Clinic Field
              TextFormField(
                controller: _hospitalController,
                style: TextStyle(color: context.primaryText),
                decoration: InputDecoration(
                  labelText: 'Hospital/Clinic *',
                  labelStyle: TextStyle(color: context.secondaryText),
                  prefixIcon: Icon(Icons.local_hospital, color: context.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.secondaryText.withOpacity(0.3)),
                  ),
                  hintText: 'e.g., City Heart Center',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your hospital/clinic name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Consultation Fee Field
              TextFormField(
                controller: _consultationFeeController,
                style: TextStyle(color: context.primaryText),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Consultation Fee (₹) *',
                  labelStyle: TextStyle(color: context.secondaryText),
                  prefixIcon: Icon(Icons.currency_rupee, color: context.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.secondaryText.withOpacity(0.3)),
                  ),
                  hintText: 'e.g., 500',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter consultation fee';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Bio Field
              TextFormField(
                controller: _bioController,
                style: TextStyle(color: context.primaryText),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Bio / About (Optional)',
                  labelStyle: TextStyle(color: context.secondaryText),
                  prefixIcon: Icon(Icons.description, color: context.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.secondaryText.withOpacity(0.3)),
                  ),
                  hintText: 'Tell patients about yourself, your expertise, and approach to care...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 30),

              // Security Section
              _buildSectionHeader('Security'),
              const SizedBox(height: 20),

              // Password Field
              TextFormField(
                controller: _passwordController,
                style: TextStyle(color: context.primaryText),
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  labelStyle: TextStyle(color: context.secondaryText),
                  prefixIcon: Icon(Icons.lock, color: context.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.secondaryText.withOpacity(0.3)),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: context.secondaryText,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                style: TextStyle(color: context.primaryText),
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password *',
                  labelStyle: TextStyle(color: context.secondaryText),
                  prefixIcon: Icon(Icons.lock_outline, color: context.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.secondaryText.withOpacity(0.3)),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      color: context.secondaryText,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerDoctor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27ae60),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Doctor Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Terms and Conditions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text.rich(
                  TextSpan(
                    text: 'By creating an account, you agree to our ',
                    style: TextStyle(color: context.secondaryText),
                    children: [
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: context.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: context.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),

              // Already have account
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text.rich(
                    TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: context.secondaryText),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: context.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}