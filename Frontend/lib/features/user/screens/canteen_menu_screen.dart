import 'package:flutter/material.dart';
import '../../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION

class CanteenMenuScreen extends StatelessWidget {
  const CanteenMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'category': 'Breakfast',
        'items': [
          {'name': 'Masala Dosa', 'price': '₹60', 'description': 'Crispy rice crepe with potato filling'},
          {'name': 'Idli Sambar', 'price': '₹40', 'description': 'Steamed rice cakes with lentil soup'},
          {'name': 'Poha', 'price': '₹35', 'description': 'Flattened rice with vegetables'},
          {'name': 'Sandwich', 'price': '₹50', 'description': 'Vegetable sandwich with chutney'},
        ],
      },
      {
        'category': 'Lunch',
        'items': [
          {'name': 'Thali Meal', 'price': '₹120', 'description': 'Complete meal with 3 vegetables, dal, rice, roti'},
          {'name': 'Vegetable Biryani', 'price': '₹90', 'description': 'Fragrant rice with mixed vegetables'},
          {'name': 'Dal Tadka', 'price': '₹70', 'description': 'Tempered lentil soup with rice'},
          {'name': 'Paneer Butter Masala', 'price': '₹110', 'description': 'Cottage cheese in rich tomato gravy'},
        ],
      },
      {
        'category': 'Snacks',
        'items': [
          {'name': 'Samosa', 'price': '₹25', 'description': 'Crispy pastry with potato filling'},
          {'name': 'Vada Pav', 'price': '₹30', 'description': 'Mumbai style potato burger'},
          {'name': 'Tea/Coffee', 'price': '₹15', 'description': 'Hot beverage'},
          {'name': 'Fresh Juice', 'price': '₹40', 'description': 'Seasonal fruit juice'},
        ],
      },
      {
        'category': 'Dinner',
        'items': [
          {'name': 'Roti Sabzi', 'price': '₹80', 'description': 'Indian bread with vegetable curry'},
          {'name': 'Vegetable Pulao', 'price': '₹85', 'description': 'Fragrant rice with vegetables'},
          {'name': 'Kadhi Chawal', 'price': '₹75', 'description': 'Yogurt curry with rice'},
          {'name': 'Mix Veg', 'price': '₹95', 'description': 'Assorted vegetables in gravy'},
        ],
      },
    ];

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Canteen Menu'),
        backgroundColor: const Color(0xFFe67e22),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: menuItems.length,
        itemBuilder: (context, categoryIndex) {
          final category = menuItems[categoryIndex];
          return _buildCategorySection(category, context);
        },
      ),
    );
  }

  Widget _buildCategorySection(Map<String, dynamic> category, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: context.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category['category'],
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFe67e22),
              ),
            ),
            const SizedBox(height: 12),
            ...(category['items'] as List).map((item) => _buildMenuItem(item, context)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: context.secondaryText.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['description'],
                  style: TextStyle(
                    color: context.secondaryText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFe67e22).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item['price'],
              style: const TextStyle(
                color: Color(0xFFe67e22),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}