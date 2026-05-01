import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'user_selection_screen.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION
import '../user/screens/user_home_screen.dart';
import '../doctor/screens/doctor_home_screen.dart';

class SevaPulseSplashScreen extends StatefulWidget {
  const SevaPulseSplashScreen({Key? key}) : super(key: key);

  @override
  State<SevaPulseSplashScreen> createState() => _SevaPulseSplashScreenState();
}

class _SevaPulseSplashScreenState extends State<SevaPulseSplashScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  int _currentPage = 0;
  bool _isCheckingAuth = true;

  final List<Map<String, dynamic>> _splashScreens = [
    {
      'title': 'SEVA PULSE',
      'subtitle': 'Health Access',
      'description':
          'Find clinics and hospitals in your city with available transportation options',
      'color': const Color(0xFF3498db),
      'buttonText': 'Next',
      'imageType': 'logo',
    },
    {
      'title': 'SEVA PULSE',
      'subtitle': 'Queue Management',
      'description':
          'Skip the waiting line by registering for online queue at clinics and hospitals',
      'color': const Color(0xFF2ecc71),
      'buttonText': 'Next',
      'imageType': 'svg',
      'svgPath': 'assets/images/undraw_login_weas.svg',
    },
    {
      'title': 'SEVA PULSE',
      'subtitle': 'Wellness Guide',
      'description':
          'Get health tips and knowledge to stay fit and maintain a healthy lifestyle',
      'color': const Color(0xFFe74c3c),
      'buttonText': 'Get Started',
      'imageType': 'svg',
      'svgPath': 'assets/images/undraw_doctor_aum1.svg'
    },
  ];

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();

    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    print('🔐 SplashScreen - Checking auth, isInitializing: ${authProvider.isInitializing}');
    print('🔐 SplashScreen - isAuthenticated: ${authProvider.isAuthenticated}');

    if (authProvider.isInitializing) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      _checkAuthAndNavigate();
      return;
    }

    setState(() {
      _isCheckingAuth = false;
    });

    if (authProvider.isAuthenticated) {
      print('✅ User already logged in: ${authProvider.user?.name}');

      if (authProvider.isDoctor) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DoctorHomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserHomeScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _animationController.reset();
      _animationController.forward();
    });
  }

  void _navigateToNext() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      if (authProvider.isDoctor) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DoctorHomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserHomeScreen()),
        );
      }
      return;
    }

    if (_currentPage < _splashScreens.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserSelectionScreen()),
      );
    }
  }

  Widget _buildImageContainer(Map<String, dynamic> screenData, double imageSize) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: imageSize,
            height: imageSize,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: screenData['color'].withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: screenData['color'].withOpacity(0.1),
                width: 2,
              ),
            ),
            child: screenData['imageType'] == 'svg'
                ? SvgPicture.asset(
                    screenData['svgPath'],
                    fit: BoxFit.contain,
                    colorFilter: context.isDark
                        ? const ColorFilter.mode(Colors.white70, BlendMode.srcIn)
                        : null,
                  )
                : Image.asset(
                    'assets/images/logo/kstarlogo.png',
                    fit: BoxFit.contain,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSplashContent(Map<String, dynamic> screenData) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final imageSize = isSmallScreen ? 180.0 : 250.0;
    final verticalSpacingLarge = isSmallScreen ? 20.0 : 40.0;
    final verticalSpacingMedium = isSmallScreen ? 12.0 : 16.0;
    final verticalSpacingSmall = isSmallScreen ? 16.0 : 30.0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildImageContainer(screenData, imageSize),

            SizedBox(height: verticalSpacingLarge),

            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                screenData['title'],
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: context.primaryText,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            SizedBox(height: verticalSpacingMedium),

            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_slideAnimation.value, 0),
                  child: Text(
                    screenData['subtitle'],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: screenData['color'],
                      letterSpacing: 1.1,
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: verticalSpacingSmall),

            Container(
              width: 80,
              height: 4,
              decoration: BoxDecoration(
                color: screenData['color'],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            SizedBox(height: verticalSpacingSmall),

            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                screenData['description'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: context.secondaryText,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor: context.surfaceColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
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
                child: const Icon(
                  Icons.health_and_safety,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'SEVA PULSE',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.primaryText,
                ),
              ),
              const SizedBox(height: 10),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            if (_currentPage < _splashScreens.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const UserSelectionScreen()),
                      );
                    },
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: _splashScreens[_currentPage]['color'],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _splashScreens.length,
                itemBuilder: (context, index) {
                  return _buildSplashContent(_splashScreens[index]);
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _splashScreens.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentPage == index
                          ? _splashScreens[index]['color']
                          : context.secondaryText.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _fadeAnimation.value,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _navigateToNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _splashScreens[_currentPage]['color'],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          shadowColor: _splashScreens[_currentPage]['color']
                              .withOpacity(0.3),
                        ),
                        child: Text(
                          _splashScreens[_currentPage]['buttonText'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}