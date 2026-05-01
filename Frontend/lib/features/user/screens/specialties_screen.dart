// lib/features/user/screens/specialties_screen.dart
//
// FIX: Converted to StatefulWidget so _searchQuery lives in State
// and does not reset every time the parent tree rebuilds.
import 'package:flutter/material.dart';
import 'doctor_list_screen.dart';
import '../../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION

class SpecialtiesScreen extends StatefulWidget {
  const SpecialtiesScreen({Key? key}) : super(key: key);

  @override
  State<SpecialtiesScreen> createState() => _SpecialtiesScreenState();
}

class _SpecialtiesScreenState extends State<SpecialtiesScreen> {
  // Moved from a local variable inside build() to a proper State field
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<Map<String, dynamic>> _specialties = [
    {'name': 'Orthopaedic Surgeons',         'icon': Icons.accessible,         'id': 'orthopaedic',       'department': 'Orthopaedics'},
    {'name': 'General Surgeons',              'icon': Icons.medical_services,   'id': 'general_surgery',   'department': 'General Surgery'},
    {'name': 'Physicians/Internal Medicine',  'icon': Icons.health_and_safety,  'id': 'internal_medicine', 'department': 'Internal Medicine'},
    {'name': 'Nephrologists',                 'icon': Icons.water_drop,         'id': 'nephrology',        'department': 'Nephrology'},
    {'name': 'Paediatricians',                'icon': Icons.child_care,         'id': 'pediatrics',        'department': 'Pediatrics'},
    {'name': 'Neuro-Spine Surgeons',          'icon': Icons.psychology,         'id': 'neuro_spine',       'department': 'Neurosurgery'},
    {'name': 'Cancer Specialist',             'icon': Icons.medical_services,   'id': 'oncology',          'department': 'Oncology'},
    {'name': 'Cardiologists',                 'icon': Icons.favorite,           'id': 'cardiology',        'department': 'Cardiology'},
    {'name': 'Dermatologists',                'icon': Icons.medical_services,   'id': 'dermatology',       'department': 'Dermatology'},
    {'name': 'Neurologists',                  'icon': Icons.psychology,         'id': 'neurology',         'department': 'Neurology'},
    {'name': 'Ophthalmologists',              'icon': Icons.visibility,         'id': 'ophthalmology',     'department': 'Ophthalmology'},
    {'name': 'Psychiatrists',                 'icon': Icons.psychology,         'id': 'psychiatry',        'department': 'Psychiatry'},
    {'name': 'Radiologists',                  'icon': Icons.image,              'id': 'radiology',         'department': 'Radiology'},
    {'name': 'Urologists',                    'icon': Icons.water,              'id': 'urology',           'department': 'Urology'},
    {'name': 'Gastroenterologists',           'icon': Icons.restaurant,         'id': 'gastroenterology',  'department': 'Gastroenterology'},
    {'name': 'Endocrinologists',              'icon': Icons.biotech,            'id': 'endocrinology',     'department': 'Endocrinology'},
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _specialties;
    final q = _searchQuery.toLowerCase();
    return _specialties
        .where((s) => s['name'].toString().toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Specialties'),
        backgroundColor: context.primaryColor, // ✅ Theme-aware
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search specialties...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: context.surfaceColor, // ✅ Theme-aware
              ),
            ),
          ),

          // ── Grid ─────────────────────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No specialties found for "$_searchQuery"',
                          style: TextStyle(color: context.secondaryText), // ✅ Theme-aware
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final s = _filtered[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: context.cardColor, // ✅ Theme-aware card color
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DoctorListScreen(
                                specialty: s['name'],
                                specialtyId: s['id'],
                                department: s['department'],
                              ),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                s['icon'] as IconData,
                                size: 40,
                                color: context.primaryColor, // ✅ Theme-aware
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                                child: Text(
                                  s['name'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: context.primaryText, // ✅ Theme-aware
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}