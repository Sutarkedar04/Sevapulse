import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION
import '../../data/providers/auth_provider.dart';
import '../../features/user/screens/user_home_screen.dart';
import 'user_register_screen.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({Key? key}) : super(key: key);

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _clearInvalidToken();
    _loadSavedCredentials();
  }

  Future<void> _clearInvalidToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null && (token == 'dummy_token' || !token.startsWith('eyJ'))) {
        await prefs.remove('auth_token');
        print('Cleared invalid token: $token');
      }
    } catch (e) {
      print('Error clearing token: $e');
    }
  }

  void _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email') ?? '';
      final savedPassword = prefs.getString('saved_password') ?? '';
      final rememberMe = prefs.getBool('remember_me') ?? false;

      if (rememberMe && savedEmail.isNotEmpty && savedPassword.isNotEmpty) {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        setState(() {
          _rememberMe = true;
        });
      }
    } catch (e) {
      print('Error loading saved credentials: $e');
    }
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoggingIn = true;
      });
      
      await _clearInvalidToken();
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
        'patient',
      );

      if (success && mounted) {
        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_email', _emailController.text.trim());
          await prefs.setString('saved_password', _passwordController.text);
          await prefs.setBool('remember_me', true);
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('saved_email');
          await prefs.remove('saved_password');
          await prefs.setBool('remember_me', false);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Login successful!'),
              backgroundColor: context.primaryColor,
              duration: const Duration(seconds: 2),
            ),
          );
          
          await Future.delayed(const Duration(milliseconds: 1500));
          
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const UserHomeScreen()),
              (route) => false,
            );
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Login failed. Please check your credentials.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
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
      MaterialPageRoute(builder: (context) => const UserRegisterScreen()),
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
                colors: [Color(0xFF3498db), Color(0xFF2c3e50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.health_and_safety, color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome Back!',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: context.primaryText),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue your health journey',
          style: TextStyle(fontSize: 16, color: context.secondaryText),
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
            labelText: 'Email Address',
            labelStyle: TextStyle(color: context.secondaryText),
            prefixIcon: Icon(Icons.email, color: context.primaryColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.secondaryText.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.primaryColor, width: 2),
            ),
            filled: true,
            fillColor: context.surfaceColor,
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your email';
            if (!value.contains('@') || !value.contains('.')) return 'Please enter a valid email address';
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
            prefixIcon: Icon(Icons.lock, color: context.primaryColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.secondaryText.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.primaryColor, width: 2),
            ),
            filled: true,
            fillColor: context.surfaceColor,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: context.secondaryText),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          obscureText: _obscurePassword,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your password';
            if (value.length < 6) return 'Password must be at least 6 characters';
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
                  onChanged: (value) => setState(() => _rememberMe = value ?? false),
                  activeColor: context.primaryColor,
                ),
                Text('Remember me', style: TextStyle(color: context.primaryText)),
              ],
            ),
            const SizedBox(width: 100),
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
          backgroundColor: context.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoggingIn
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
            : const Text('SIGN IN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAdditionalOptions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: context.secondaryText.withOpacity(0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Or continue with', style: TextStyle(color: context.secondaryText, fontSize: 14)),
            ),
            Expanded(child: Divider(color: context.secondaryText.withOpacity(0.3))),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(icon: Icons.g_mobiledata, color: const Color(0xFFDB4437), onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Google login coming soon!'), duration: Duration(seconds: 2)),
              );
            }),
            const SizedBox(width: 16),
            _buildSocialButton(icon: Icons.facebook, color: const Color(0xFF4267B2), onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Facebook login coming soon!'), duration: Duration(seconds: 2)),
              );
            }),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Don't have an account?", style: TextStyle(color: context.secondaryText)),
            const SizedBox(width: 4),
            TextButton(
              onPressed: _navigateToRegister,
              child: Text('Sign up', style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({required IconData icon, required Color color, required VoidCallback onTap}) {
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