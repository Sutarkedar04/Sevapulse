// lib/presentation/common/widgets/settings_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/providers/theme_provider.dart';
import '../../../data/providers/notification_provider.dart';

class SettingsSection extends StatefulWidget {
  final VoidCallback onLogout;
  final bool showNotifications;
  final bool showPrivacy;
  final bool showHealthData;
  final bool showLanguage;
  final bool showHelp;
  final bool showAbout;

  const SettingsSection({
    Key? key,
    required this.onLogout,
    this.showNotifications = true,
    this.showPrivacy = true,
    this.showHealthData = true,
    this.showLanguage = true,
    this.showHelp = true,
    this.showAbout = true,
  }) : super(key: key);

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  bool _notificationsEnabled = true;
  bool _healthDataSharing = false;
  String _selectedLanguage = 'English';

  final List<String> _languages = ['English', 'Hindi', 'Marathi', 'Gujarati', 'Tamil', 'Telugu'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadSettings();
  });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _healthDataSharing = prefs.getBool('health_data_sharing') ?? false;
        _selectedLanguage = prefs.getString('language') ?? 'English';
      });
    }
  }

  Future<void> _saveNotificationSetting(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('notifications_enabled', value);

  if (!mounted) return;
  
  setState(() {
    _notificationsEnabled = value;
  });

  // Call provider AFTER setState, not inside it
  if (mounted) {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    if (value) {
      await notificationProvider.fetchNotifications();
    }
    _showSnackBar(value ? 'Notifications enabled' : 'Notifications disabled');
  }
}
  Future<void> _saveHealthDataSharing(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('health_data_sharing', value);
  
  if (!mounted) return;
  
  setState(() {
    _healthDataSharing = value;
  });
  _showSnackBar(value ? 'Health data sharing enabled' : 'Health data sharing disabled');
}

  Future<void> _changeLanguage(String language) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('language', language);
  
  if (!mounted) return;
  
  setState(() {
    _selectedLanguage = language;
  });
  _showSnackBar('Language changed to $language');
}

  void _toggleTheme() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleTheme();
    _showSnackBar(themeProvider.isDarkMode ? 'Dark mode enabled' : 'Light mode enabled');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).primaryColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy for Seva Pulse\n\n'
            '1. Information We Collect\n'
            '   - Personal information (name, email, phone number)\n'
            '   - Medical history and health data\n'
            '   - Appointment details\n\n'
            '2. How We Use Your Information\n'
            '   - To provide healthcare services\n'
            '   - To schedule and manage appointments\n'
            '   - To send important notifications\n\n'
            '3. Data Security\n'
            '   We implement industry-standard security measures.\n\n'
            '4. Your Rights\n'
            '   You can access, correct, or delete your personal information at any time.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Help & Support',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Color(0xFF3498db)),
              title: const Text('FAQs'),
              subtitle: const Text('Frequently asked questions'),
              onTap: () {
                Navigator.pop(context);
                _showFAQs();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.contact_support, color: Color(0xFF3498db)),
              title: const Text('Contact Support'),
              subtitle: const Text('Email or call our support team'),
              onTap: () {
                Navigator.pop(context);
                _showContactOptions();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.feedback, color: Color(0xFF3498db)),
              title: const Text('Send Feedback'),
              subtitle: const Text('Help us improve Seva Pulse'),
              onTap: () {
                Navigator.pop(context);
                _showFeedbackDialog();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.description, color: Color(0xFF3498db)),
              title: const Text('Terms of Service'),
              subtitle: const Text('Read our terms and conditions'),
              onTap: () {
                Navigator.pop(context);
                _showTermsOfService();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showFAQs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frequently Asked Questions'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Q: How do I book an appointment?',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('A: Go to Medical Specialties, select a specialty, choose a doctor, then confirm.',
                    style: TextStyle(fontSize: 13)),
                SizedBox(height: 12),
                Text('Q: Can I cancel my appointment?',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('A: Yes, you can cancel pending appointments from My Appointments.',
                    style: TextStyle(fontSize: 13)),
                SizedBox(height: 12),
                Text('Q: How do I view my prescriptions?',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('A: Go to Prescriptions section to view all prescriptions.',
                    style: TextStyle(fontSize: 13)),
                SizedBox(height: 12),
                Text('Q: How do I set medicine reminders?',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('A: Go to My Medicine, add medicines with timings, reminders set automatically.',
                    style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContactOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Contact Support',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('Call Support'),
              subtitle: const Text('+91-123-456-7890'),
              onTap: () async {
                final url = Uri(scheme: 'tel', path: '+911234567890');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text('Email Support'),
              subtitle: const Text('support@sevapulse.com'),
              onTap: () async {
                final url = Uri(scheme: 'mailto', path: 'support@sevapulse.com');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.message, color: Color(0xFF25D366)),
              title: const Text('WhatsApp Support'),
              subtitle: const Text('Chat with us on WhatsApp'),
              onTap: () async {
                final url = Uri.parse('https://wa.me/911234567890');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: TextFormField(
          controller: feedbackController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Share your feedback or suggestions...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (feedbackController.text.isNotEmpty) {
                _showSnackBar('Thank you for your feedback!');
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27ae60),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Terms of Service for Seva Pulse\n\n'
            '1. Acceptance of Terms\n'
            '   By using Seva Pulse, you agree to these terms.\n\n'
            '2. Medical Disclaimer\n'
            '   For medical emergencies, please contact emergency services immediately.\n\n'
            '3. User Responsibilities\n'
            '   - Provide accurate information\n'
            '   - Keep your account secure\n\n'
            '4. Service Availability\n'
            '   We strive to provide uninterrupted service.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Seva Pulse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF3498db).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.medical_services,
                  size: 40,
                  color: Color(0xFF3498db),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Seva Pulse',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: Color(0xFF7f8c8d)),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Your trusted healthcare partner.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '© 2024 Seva Pulse. All rights reserved.',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((language) {
            return RadioListTile<String>(
              title: Text(language),
              value: language,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                Navigator.pop(context);
                _changeLanguage(value!);
              },
              activeColor: const Color(0xFF3498db),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
                Icon(Icons.settings, color: Color(0xFF3498db)),
                SizedBox(width: 8),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Dark Mode Toggle
            ListTile(
              leading: const Icon(Icons.dark_mode, color: Color(0xFF3498db)),
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: isDarkMode,
                onChanged: (_) => _toggleTheme(),
                activeColor: const Color(0xFF3498db),
              ),
              onTap: () => _toggleTheme(),
            ),
            
            // Notifications
            if (widget.showNotifications)
              ListTile(
                leading: const Icon(Icons.notifications, color: Color(0xFF3498db)),
                title: const Text('Notifications'),
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: _saveNotificationSetting,
                  activeColor: const Color(0xFF3498db),
                ),
              ),
            
            // Privacy & Security
            if (widget.showPrivacy)
              ListTile(
                leading: const Icon(Icons.security, color: Color(0xFF3498db)),
                title: const Text('Privacy & Security'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showPrivacyPolicy,
              ),
            
            // Health Data Sharing
            if (widget.showHealthData)
              ListTile(
                leading: const Icon(Icons.medical_information, color: Color(0xFF3498db)),
                title: const Text('Health Data Sharing'),
                trailing: Switch(
                  value: _healthDataSharing,
                  onChanged: _saveHealthDataSharing,
                  activeColor: const Color(0xFF3498db),
                ),
              ),
            
            // Language
            if (widget.showLanguage)
              ListTile(
                leading: const Icon(Icons.language, color: Color(0xFF3498db)),
                title: const Text('Language'),
                trailing: Text(_selectedLanguage, style: const TextStyle(color: Color(0xFF7f8c8d))),
                onTap: _showLanguageDialog,
              ),
            
            // Help & Support
            if (widget.showHelp)
              ListTile(
                leading: const Icon(Icons.help, color: Color(0xFF3498db)),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showHelpSupport,
              ),
            
            // About
            if (widget.showAbout)
              ListTile(
                leading: const Icon(Icons.info, color: Color(0xFF3498db)),
                title: const Text('About Seva Pulse'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAboutDialog(context),
              ),
            
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe74c3c).withOpacity(0.1),
                  foregroundColor: const Color(0xFFe74c3c),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}