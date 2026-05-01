// lib/features/user/screens/contact_us_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme_extensions.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  // Real K-Star Hospital data
  static const String _name    = 'K-Star Multispeciality Hospital';
  static const String _address = 'Sambhaji Nagar Rd, Tapowan,\nKolhapur, Maharashtra 416007';
  static const String _phone   = '9090575353';
  static const String _email   = 'kstarhospital@gmail.com';
  static const double _lat     = 16.6768816;
  static const double _lng     = 74.220676;

  Future<void> _openMaps(BuildContext context) async {
    // 1️⃣ Try geo: URI — opens Google Maps (or any map app) directly on Android
    final Uri geoUri = Uri.parse(
      'geo:$_lat,$_lng?q=$_lat,$_lng(${Uri.encodeComponent(_name)})',
    );
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      return;
    }

    // 2️⃣ Fallback: Google Maps web URL — deep-links into app if installed, else browser
    final Uri mapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$_lat,$_lng',
    );
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
      return;
    }

    // 3️⃣ Last resort: show copy-address dialog
    _showOpenMapsDialog(context);
  }

  void _showOpenMapsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: context.primaryColor),
            const SizedBox(width: 8),
            const Text('Open in Google Maps'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please follow these steps:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('1. Tap "Copy Address" below'),
            const Text('2. Open Google Maps app'),
            const Text('3. Paste the address in search'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'K-Star Multispeciality Hospital',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(_address.replaceAll('\n', ' ')),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _address.replaceAll('\n', ' ')));
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Address copied! Open Google Maps and paste it.'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy Address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    final Uri uri = Uri.parse('tel:$_phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showErrorSnackBar(context, 'Could not make phone call');
    }
  }

  Future<void> _sendEmail(BuildContext context) async {
    final Uri uri = Uri.parse('mailto:$_email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showErrorSnackBar(context, 'Could not send email');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Contact Us'),
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3498db), Color(0xFF2980b9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    _name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.location_on, color: Colors.white70, size: 16),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _address,
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.star, color: Color(0xFFf1c40f), size: 16),
                      SizedBox(width: 4),
                      Text(
                        '4.7 · Open 24 hours',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quick-action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: [
                  _QuickAction(
                    icon: Icons.phone,
                    label: 'Call',
                    color: const Color(0xFF27ae60),
                    onTap: () => _makePhoneCall(context),
                  ),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.email,
                    label: 'Email',
                    color: context.primaryColor,
                    onTap: () => _sendEmail(context),
                  ),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.directions,
                    label: 'Directions',
                    color: const Color(0xFFe67e22),
                    onTap: () => _openMaps(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Map card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                color: context.cardColor,
                child: InkWell(
                  onTap: () => _openMaps(context),
                  child: Column(
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              context.primaryColor.withOpacity(0.1),
                              context.primaryColor.withOpacity(0.2),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map,
                                size: 48,
                                color: context.primaryColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: context.primaryText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap for directions',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tapowan, Kolhapur',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Color(0xFFe74c3c), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _address,
                                style: TextStyle(
                                    color: context.primaryText, fontSize: 14),
                              ),
                            ),
                            Icon(
                              Icons.copy,
                              size: 16,
                              color: context.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Contact details card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: context.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.primaryText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ContactRow(
                        icon: Icons.phone,
                        iconColor: const Color(0xFF27ae60),
                        label: 'Phone',
                        value: '+91 $_phone',
                        actionLabel: 'Call',
                        actionColor: const Color(0xFF27ae60),
                        onTap: () => _makePhoneCall(context),
                      ),
                      const Divider(height: 24),
                      _ContactRow(
                        icon: Icons.email,
                        iconColor: context.primaryColor,
                        label: 'Email',
                        value: _email,
                        actionLabel: 'Email',
                        actionColor: context.primaryColor,
                        onTap: () => _sendEmail(context),
                      ),
                      const Divider(height: 24),
                      _ContactRow(
                        icon: Icons.access_time,
                        iconColor: const Color(0xFF27ae60),
                        label: 'Hours',
                        value: 'Open 24 hours · 7 days a week',
                        actionLabel: null,
                        actionColor: null,
                        onTap: null,
                      ),
                      const Divider(height: 24),
                      _ContactRow(
                        icon: Icons.local_hospital,
                        iconColor: const Color(0xFF9b59b6),
                        label: 'Type',
                        value: 'Multispeciality Hospital',
                        actionLabel: null,
                        actionColor: null,
                        onTap: null,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Social media card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: context.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Follow Us',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.primaryText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _SocialBtn(
                            icon: Icons.facebook,
                            label: 'Facebook',
                            color: const Color(0xFF1877f2),
                            onTap: () => _launchUrl(context, 'https://www.facebook.com'),
                          ),
                          const SizedBox(width: 12),
                          _SocialBtn(
                            icon: Icons.camera_alt,
                            label: 'Instagram',
                            color: const Color(0xFFe1306c),
                            onTap: () => _launchUrl(context, 'https://www.instagram.com'),
                          ),
                          const SizedBox(width: 12),
                          _SocialBtn(
                            icon: Icons.play_circle_fill,
                            label: 'YouTube',
                            color: const Color(0xFFff0000),
                            onTap: () => _launchUrl(context, 'https://www.youtube.com'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// Helper sub-widgets
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final String? actionLabel;
  final Color? actionColor;

  const _ContactRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
    required this.actionLabel,
    required this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: context.secondaryText)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      color: context.primaryText,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        if (actionLabel != null && onTap != null)
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!,
                style: const TextStyle(fontSize: 13)),
          ),
      ],
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}