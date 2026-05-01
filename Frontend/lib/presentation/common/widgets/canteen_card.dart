import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION

class CanteenCard extends StatefulWidget {
  final VoidCallback onViewMenu;

  const CanteenCard({
    Key? key,
    required this.onViewMenu,
  }) : super(key: key);

  @override
  State<CanteenCard> createState() => _CanteenCardState();
}

class _CanteenCardState extends State<CanteenCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  final String _canteenPhoneNumber = '+919623744227';
  final String _canteenWhatsApp = '919623744227';

  final List<Map<String, dynamic>> _previewItems = [
    {'name': 'Masala Dosa', 'price': '₹60', 'icon': Icons.restaurant},
    {'name': 'Idli Sambar', 'price': '₹40', 'icon': Icons.breakfast_dining},
    {'name': 'Veg Biryani', 'price': '₹90', 'icon': Icons.rice_bowl},
    {'name': 'Samosa', 'price': '₹25', 'icon': Icons.lunch_dining},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _isSimulator {
    if (Platform.isIOS) {
      return Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');
    }
    if (Platform.isAndroid) {
      return Platform.environment.containsKey('ANDROID_EMULATOR');
    }
    return false;
  }

  Future<void> _makePhoneCall() async {
    if (_isSimulator) {
      _showSimulatorWarning();
      return;
    }
    final Uri phoneUri = Uri(scheme: 'tel', path: _canteenPhoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showErrorSnackBar('Phone calls are not supported on this device');
      }
    } catch (e) {
      _showErrorSnackBar('Could not place call. Please dial $_canteenPhoneNumber manually.');
    }
  }

  Future<void> _sendWhatsApp() async {
    if (_isSimulator) {
      _showSimulatorWarning();
      return;
    }
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$_canteenWhatsApp?text=Hello,%20I%20would%20like%20to%20know%20about%20your%20canteen%20menu.',
    );
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else {
        _showErrorSnackBar('WhatsApp is not installed on this device');
      }
    } catch (e) {
      _showErrorSnackBar('Could not open WhatsApp. Please contact us at $_canteenPhoneNumber');
    }
  }

  void _showSimulatorWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Simulator Mode', style: TextStyle(color: context.primaryText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone calls are not supported on simulators/emulators.', style: TextStyle(color: context.secondaryText)),
            const SizedBox(height: 12),
            Text(
              'To contact the canteen:\n\n'
              '📞 Phone: $_canteenPhoneNumber\n'
              '💬 WhatsApp: $_canteenPhoneNumber\n\n'
              'Please use a real device to test calling functionality.',
              style: TextStyle(fontSize: 14, color: context.secondaryText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: context.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
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
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.secondaryText.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Contact Canteen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.primaryText,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF27ae60).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.phone, color: Color(0xFF27ae60)),
              ),
              title: Text('Call Canteen', style: TextStyle(color: context.primaryText)),
              subtitle: Text(_canteenPhoneNumber, style: TextStyle(color: context.secondaryText)),
              trailing: _isSimulator
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Simulator',
                        style: TextStyle(fontSize: 10, color: Colors.orange),
                      ),
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                _makePhoneCall();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.message, color: Color(0xFF25D366)),
              ),
              title: Text('WhatsApp', style: TextStyle(color: context.primaryText)),
              subtitle: Text('Chat with canteen staff', style: TextStyle(color: context.secondaryText)),
              trailing: _isSimulator
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Simulator',
                        style: TextStyle(fontSize: 10, color: Colors.orange),
                      ),
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                _sendWhatsApp();
              },
            ),
            const Divider(),
            if (_isSimulator) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '📱 On a real device, you can call directly.',
                      style: TextStyle(fontSize: 12, color: context.secondaryText),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone, size: 16, color: Color(0xFFe67e22)),
                          const SizedBox(width: 8),
                          Text(
                            _canteenPhoneNumber,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFe67e22),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can manually dial this number',
                      style: TextStyle(fontSize: 12, color: context.secondaryText),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Card(
              elevation: _isHovered ? 8 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: context.cardColor,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFe67e22).withOpacity(0.1),
                            const Color(0xFFf39c12).withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFe67e22), Color(0xFFf39c12)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFe67e22).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.restaurant,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hospital Canteen',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: context.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF27ae60),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Open Now',
                                      style: TextStyle(
                                        color: Color(0xFF27ae60),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Color(0xFFf39c12),
                                    ),
                                    const Text(
                                      ' 4.8',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // View Menu Button
                          ElevatedButton(
                            onPressed: widget.onViewMenu,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFe67e22),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.menu_book, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'View Menu',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Image Section
                    Stack(
                      children: [
                        Container(
                          height: 160,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.5),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_offer,
                                  size: 14,
                                  color: Color(0xFFe67e22),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '20% OFF on first order',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Menu Preview & Contact Section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Popular Items',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: context.primaryText,
                                ),
                              ),
                              Text(
                                'See all →',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFFe67e22),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 80,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _previewItems.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final item = _previewItems[index];
                                return Container(
                                  width: 100,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: context.surfaceColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: context.secondaryText.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(item['icon'], size: 24, color: const Color(0xFFe67e22)),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['name'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: context.primaryText,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        item['price'],
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: context.secondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Enjoy delicious and nutritious meals prepared fresh daily. Our canteen offers a variety of healthy options for patients and visitors.',
                            style: TextStyle(
                              color: context.secondaryText,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildInfoChip(Icons.access_time, '7:00 AM - 9:00 PM', const Color(0xFFe67e22)),
                                const SizedBox(width: 8),
                                _buildInfoChip(Icons.local_shipping, 'Free Delivery', const Color(0xFF27ae60)),
                                const SizedBox(width: 8),
                                _buildInfoChip(Icons.credit_card, 'UPI/Card', const Color(0xFF3498db)),
                                const SizedBox(width: 8),
                                _buildInfoChip(Icons.room_service, 'Dine-in', const Color(0xFF9b59b6)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Contact button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showContactOptions,
                              icon: const Icon(Icons.contact_phone, size: 20),
                              label: const Text('Contact Canteen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFe67e22),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 48),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}