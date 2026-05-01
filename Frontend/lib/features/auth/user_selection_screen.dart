import 'package:flutter/material.dart';
import '../../core/theme/theme_extensions.dart';
import 'user_login_screen.dart';
import 'doctor_login_screen.dart';

class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Back Button - Only show if we can pop
              if (Navigator.canPop(context))
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: context.primaryText),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              else
                const SizedBox(height: 20),
              
              const Spacer(flex: 1),
              
              // Title
              Text(
                'Continue As',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: context.primaryText,
                ),
              ),
              
              const SizedBox(height: 10),
              
              Text(
                'Select your role to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: context.secondaryText,
                ),
              ),
              
              const Spacer(flex: 2),
              
              // User Type Selection Cards
              Column(
                children: [
                  // Patient Card
                  _buildUserTypeCard(
                    context: context, // ✅ Pass context to the method
                    title: 'Patient',
                    subtitle: 'Book appointments, consult doctors, manage health records',
                    icon: Icons.person,
                    color: context.primaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UserLoginScreen()),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Doctor Card
                  _buildUserTypeCard(
                    context: context, // ✅ Pass context to the method
                    title: 'Doctor',
                    subtitle: 'Manage appointments, consult patients, update availability',
                    icon: Icons.medical_services,
                    color: const Color(0xFF27ae60),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DoctorLoginScreen()),
                      );
                    },
                  ),
                ],
              ),
              
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard({
    required BuildContext context, // ✅ Add context parameter
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: context.cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: context.secondaryText.withOpacity(0.5), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}