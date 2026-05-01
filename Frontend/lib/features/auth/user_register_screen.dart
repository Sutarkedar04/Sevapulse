import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION
import '../../data/providers/auth_provider.dart';
import '../../data/models/user_model.dart';
import '../user/screens/user_home_screen.dart';

class UserRegisterScreen extends StatefulWidget {
  const UserRegisterScreen({Key? key}) : super(key: key);

  @override
  State<UserRegisterScreen> createState() => _UserRegisterScreenState();
}

class _UserRegisterScreenState extends State<UserRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Controllers for date and gender to prevent rebuild issues
  final TextEditingController _dobController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  DateTime? _selectedDate;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    // Initialize DOB controller
    _dobController.text = 'Select your date of birth';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Update the controller text to show the selected date
        _dobController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final user = User(
        id: '',
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        userType: 'patient',
        profileImage: null,
        createdAt: DateTime.now(),
        specialization: null,
        experience: null,
        address: null,
        dateOfBirth: _selectedDate,
        gender: _selectedGender,
      );

      final success = await authProvider.register(user, _passwordController.text);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registration successful!'),
            backgroundColor: const Color(0xFF27ae60),
            duration: const Duration(seconds: 2),
          ),
        );
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const UserHomeScreen()),
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
      print('❌ Registration error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Account'),
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
                'Join Seva Pulse',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: context.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your account to access healthcare services',
                style: TextStyle(
                  color: context.secondaryText,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),

              // Full Name Field
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

              // Date of Birth Field - FIXED with controller
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
                  hintText: 'Select your date of birth',
                  hintStyle: TextStyle(color: context.secondaryText.withOpacity(0.5)),
                ),
                onTap: _selectDate,
              ),
              const SizedBox(height: 20),

              // Gender Field - FIXED with proper value handling
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Gender (Optional)',
                  labelStyle: TextStyle(color: context.secondaryText),
                  prefixIcon: Icon(Icons.person_outline, color: context.primaryColor),
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
                items: const [
                  DropdownMenuItem(value: null, child: Text('Select Gender')),
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                validator: (value) {
                  // No validation needed as it's optional
                  return null;
                },
              ),
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
                  onPressed: _isLoading ? null : _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
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
                          'Create Account',
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