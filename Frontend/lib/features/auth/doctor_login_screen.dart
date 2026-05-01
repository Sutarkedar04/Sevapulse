import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION
import '../../../data/providers/auth_provider.dart';
import '../doctor/screens/doctor_home_screen.dart';
import 'doctor_register_screen.dart';

class DoctorLoginScreen extends StatefulWidget {
  const DoctorLoginScreen({Key? key}) : super(key: key);

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = 'sachinshinde@gmail.com';
    _passwordController.text = '12345678';
    _rememberMe = true;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoggingIn = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
        'doctor',
      );

      if (success && mounted) {
        authProvider.clearError();
        
        final doctorUser = authProvider.user;
        print('✅ Doctor logged in: ${doctorUser?.name}');
        print('✅ Doctor ID: ${doctorUser?.id}');
        print('✅ Doctor Email: ${doctorUser?.email}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Login successful!'),
            backgroundColor: const Color(0xFF27ae60),
            duration: const Duration(seconds: 2),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorHomeScreen(
                key: UniqueKey(),
                doctorData: doctorUser,
              ),
            ),
            (route) => false,
          );
        }
      } else if (mounted) {
        print('❌ Doctor login failed: ${authProvider.error}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Login failed. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DoctorRegisterScreen(),
      ),
    );
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Forgot Password?', style: TextStyle(color: context.primaryText)),
        content: Text(
          'Please contact the hospital administration to reset your password. '
          'You can reach them at:\n\n'
          '📞 +1 (555) 123-4567\n'
          '📧 admin@hospital.com\n\n'
          'Office Hours: Mon-Fri, 9:00 AM - 5:00 PM',
          style: TextStyle(color: context.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF27ae60)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDemoCredentials() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Demo Credentials', style: TextStyle(color: context.primaryText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For testing purposes, use:',
              style: TextStyle(fontSize: 16, color: context.primaryText),
            ),
            const SizedBox(height: 12),
            Text(
              '📧 Email: doctor@test.com',
              style: TextStyle(fontWeight: FontWeight.w500, color: context.primaryText),
            ),
            const SizedBox(height: 8),
            Text(
              '🔑 Password: password',
              style: TextStyle(fontWeight: FontWeight.w500, color: context.primaryText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'GOT IT',
              style: TextStyle(color: Color(0xFF27ae60)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: context.primaryText),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 20),
                _buildWelcomeSection(),
                const SizedBox(height: 40),
                _buildLoginForm(),
                const SizedBox(height: 30),
                _buildLoginButton(),
                const SizedBox(height: 20),
                _buildAdditionalOptions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF27ae60), Color(0xFF3498db)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.medical_services,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome Back, Doctor!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: context.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to access your medical dashboard',
          style: TextStyle(
            fontSize: 16,
            color: context.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          style: TextStyle(color: context.primaryText),
          decoration: InputDecoration(
            labelText: 'Doctor ID / Email',
            labelStyle: TextStyle(color: context.secondaryText),
            prefixIcon: Icon(Icons.email, color: const Color(0xFF27ae60)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.secondaryText.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.secondaryText.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF27ae60), width: 2),
            ),
            filled: true,
            fillColor: context.surfaceColor,
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _passwordController,
          style: TextStyle(color: context.primaryText),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: TextStyle(color: context.secondaryText),
            prefixIcon: Icon(Icons.lock, color: const Color(0xFF27ae60)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.secondaryText.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.secondaryText.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF27ae60), width: 2),
            ),
            filled: true,
            fillColor: context.surfaceColor,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: context.secondaryText,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          obscureText: _obscurePassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF27ae60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Text(
                  'Remember me',
                  style: TextStyle(
                    color: context.primaryText,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: _forgotPassword,
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Color(0xFF27ae60),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoggingIn ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF27ae60),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoggingIn
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'SIGN IN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildAdditionalOptions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(color: context.secondaryText.withOpacity(0.3)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: TextStyle(
                  color: context.secondaryText,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: context.secondaryText.withOpacity(0.3)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(
              icon: Icons.g_mobiledata,
              color: const Color(0xFFDB4437),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Google login coming soon!')),
                );
              },
            ),
            const SizedBox(width: 16),
            _buildSocialButton(
              icon: Icons.facebook,
              color: const Color(0xFF4267B2),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Facebook login coming soon!')),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account?",
              style: TextStyle(
                color: context.secondaryText,
              ),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: _navigateToRegister,
              child: const Text(
                'Sign up',
                style: TextStyle(
                  color: Color(0xFF27ae60),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _showDemoCredentials,
          style: TextButton.styleFrom(
            foregroundColor: context.secondaryText,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 16, color: context.secondaryText),
              const SizedBox(width: 6),
              Text(
                'VIEW DEMO CREDENTIALS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}