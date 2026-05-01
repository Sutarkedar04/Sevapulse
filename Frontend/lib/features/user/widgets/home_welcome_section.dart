// lib/features/user/widgets/home_welcome_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION
import '../../../data/providers/auth_provider.dart';

class HomeWelcomeSection extends StatelessWidget {
  final Color? accentColor;
  final int activeCardIndex;
  
  const HomeWelcomeSection({
    Key? key,
    this.accentColor,
    this.activeCardIndex = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.user?.name.split(' ')[0] ?? '';
    
    // Use provided accent color or theme primary color
    final Color activeColor = accentColor ?? context.primaryColor;
    
    // Determine which animation to show based on active card index
    String getAnimationPath() {
      switch (activeCardIndex) {
        case 0:
          return 'assets/animations/hospital_animation.json';
        case 1:
          return 'assets/animations/checkup_with_doctor.json';
        case 2:
          return 'assets/animations/health_camp.json';
        default:
          return 'assets/animations/hospital_animation.json';
      }
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            activeColor.withOpacity(0.15),
            activeColor.withOpacity(0.05),
            context.surfaceColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting with animated color
            Row(
              children: [
                Icon(
                  Icons.waving_hand,
                  color: activeColor,
                  size: 28,
                ),
                const SizedBox(width: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Hello, ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.normal,
                          color: context.primaryText,
                        ),
                      ),
                      TextSpan(
                        text: userName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: activeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Fixed container size with animated content
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: Transform.scale(
                    scale: 1.4,
                    child: Lottie.asset(
                      getAnimationPath(),
                      key: ValueKey<int>(activeCardIndex),
                      fit: BoxFit.contain,
                      repeat: true,
                      reverse: false,
                      animate: true,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Info text with animated color
            Row(
              children: [
                Icon(
                  Icons.health_and_safety,
                  size: 16,
                  color: activeColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Need to see a doctor?',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Text(
                activeCardIndex == 0 
                    ? 'Book your next appointment in just a few clicks.'
                    : (activeCardIndex == 1 
                        ? 'Get daily health tips for a better lifestyle.'
                        : 'Join our health camps for free checkups.'),
                style: TextStyle(
                  fontSize: 12,
                  color: activeColor.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}