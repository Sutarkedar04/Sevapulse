// lib/shared/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:seva_pulse/core/theme/theme_extensions.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<Map<String, dynamic>> items;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed, // This allows more than 3 items
          selectedItemColor: context.primaryColor,
          unselectedItemColor: context.secondaryText.withOpacity(0.5),
          backgroundColor: context.surfaceColor,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
          ),
          items: items.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item['icon']),
              label: item['label'],
            );
          }).toList(),
        ),
      ),
    );
  }
}