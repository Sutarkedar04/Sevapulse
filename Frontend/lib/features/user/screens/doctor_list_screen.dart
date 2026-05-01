// lib/features/user/screens/doctor_list_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION
import 'book_appointment_screen.dart';

class DoctorListScreen extends StatefulWidget {
  final String specialty;
  final String specialtyId;
  final String department;

  const DoctorListScreen({
    Key? key, 
    required this.specialty,
    required this.specialtyId,
    required this.department,
  }) : super(key: key);

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _filteredDoctors = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _availabilityFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Please login to view doctors';
          _isLoading = false;
        });
        return;
      }

      print('Fetching doctors from: ${ApiConstants.doctors}');
      print('Looking for specialty: ${widget.specialty}');
      print('Department: ${widget.department}');

      final response = await http.get(
        Uri.parse(ApiConstants.doctors),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          final allDoctors = List<Map<String, dynamic>>.from(data['data']);
          
          print('All doctors count: ${allDoctors.length}');
          
          // Enhanced filtering by specialty
          final filtered = allDoctors.where((doctor) {
            final specialization = doctor['specialization']?.toString().toLowerCase() ?? '';
            final department = doctor['department']?.toString().toLowerCase() ?? '';
            final specialtyName = widget.specialty.toLowerCase();
            final departmentName = widget.department.toLowerCase();
            
            return specialization.contains(specialtyName) ||
                   department.contains(departmentName) ||
                   specialization.contains(departmentName) ||
                   department.contains(specialtyName);
          }).toList();
          
          setState(() {
            _doctors = filtered;
            _filteredDoctors = filtered;
            _isLoading = false;
          });
          
          print('Filtered doctors count: ${_doctors.length}');
        } else {
          setState(() {
            _error = data['message'] ?? 'No doctors found';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _error = 'Session expired. Please login again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load doctors. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching doctors: $e');
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterDoctors() {
    setState(() {
      _filteredDoctors = _doctors.where((doctor) {
        final user = doctor['user'] ?? {};
        final name = user['name']?.toString().toLowerCase() ?? '';
        final specialization = doctor['specialization']?.toString().toLowerCase() ?? '';
        final matchesSearch = _searchQuery.isEmpty || 
            name.contains(_searchQuery.toLowerCase()) ||
            specialization.contains(_searchQuery.toLowerCase());
        
        bool matchesAvailability = true;
        if (_availabilityFilter == 'available') {
          matchesAvailability = doctor['isAvailable'] ?? true;
        } else if (_availabilityFilter == 'unavailable') {
          matchesAvailability = !(doctor['isAvailable'] ?? true);
        }
        
        return matchesSearch && matchesAvailability;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(widget.specialty),
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDoctors,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: context.secondaryText)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchDoctors,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search and Filter Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: context.surfaceColor,
                      child: Column(
                        children: [
                          // Search Bar
                          TextField(
                            onChanged: (value) {
                              _searchQuery = value;
                              _filterDoctors();
                            },
                            decoration: InputDecoration(
                              hintText: 'Search doctors by name or specialization...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                          _filterDoctors();
                                        });
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: context.cardColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Filter Chips
                          Row(
                            children: [
                              _buildFilterChip('All', 'all'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Available', 'available'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Unavailable', 'unavailable'),
                            ],
                          ),
                          
                          if (_filteredDoctors.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${_filteredDoctors.length} doctor${_filteredDoctors.length != 1 ? 's' : ''} found',
                                style: TextStyle(
                                  color: context.secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Doctors List
                    Expanded(
                      child: _filteredDoctors.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.medical_services,
                                    size: 64,
                                    color: context.secondaryText.withOpacity(0.4),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'No doctors found for this specialty'
                                        : 'No doctors match your search',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: context.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_searchQuery.isNotEmpty)
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                          _filterDoctors();
                                        });
                                      },
                                      child: Text('Clear Search', style: TextStyle(color: context.primaryColor)),
                                    ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredDoctors.length,
                              itemBuilder: (context, index) {
                                final doctor = _filteredDoctors[index];
                                return _buildDoctorCard(doctor);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label, style: TextStyle(color: context.primaryText)),
      selected: _availabilityFilter == value,
      onSelected: (selected) {
        setState(() {
          _availabilityFilter = selected ? value : 'all';
          _filterDoctors();
        });
      },
      selectedColor: context.primaryColor.withOpacity(0.2),
      checkmarkColor: context.primaryColor,
      backgroundColor: context.cardColor,
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final user = doctor['user'] ?? {};
    // Safely get values with proper type conversion
    final doctorId = doctor['_id']?.toString() ?? '';
    final name = user['name']?.toString() ?? 'Doctor';
    final specialization = doctor['specialization']?.toString() ?? widget.specialty;
    final experience = doctor['experience'] ?? 0;
    // Convert experience to int safely
    final experienceYears = experience is int ? experience : (int.tryParse(experience.toString()) ?? 0);
    final consultationFee = doctor['consultationFee'] ?? 500;
    // Convert fee to int safely
    final fee = consultationFee is int ? consultationFee : (int.tryParse(consultationFee.toString()) ?? 500);
    final isAvailable = doctor['isAvailable'] ?? true;
    final address = user['address'];
    final hospital = address is Map ? (address['city']?.toString() ?? 'City Hospital') : (address?.toString() ?? 'City Hospital');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: context.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: context.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialization,
                        style: TextStyle(
                          color: context.primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable 
                        ? const Color(0xFF27ae60).withOpacity(0.1)
                        : const Color(0xFFe74c3c).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAvailable ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      color: isAvailable ? const Color(0xFF27ae60) : const Color(0xFFe74c3c),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Text(
              '$experienceYears years experience',
              style: TextStyle(
                color: context.secondaryText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              'Consultation Fee: ₹$fee',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF27ae60),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showDoctorProfile(doctor);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('View Profile', style: TextStyle(color: context.primaryColor)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isAvailable
                        ? () {
                            print('=== BOOKING APPOINTMENT ===');
                            print('Doctor ID: $doctorId');
                            print('Doctor Name: $name');
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookAppointmentScreen(
                                  doctor: {
                                    'id': doctorId,
                                    'name': name,
                                    'specialization': specialization,
                                    'hospital': hospital,
                                    'consultationFee': fee,
                                  },
                                  specialty: widget.specialty,
                                ),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAvailable ? const Color(0xFF27ae60) : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Book Appointment'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDoctorProfile(Map<String, dynamic> doctor) {
    final user = doctor['user'] ?? {};
    final doctorId = doctor['_id']?.toString() ?? '';
    final name = user['name']?.toString() ?? 'Doctor';
    final specialization = doctor['specialization']?.toString() ?? widget.specialty;
    final experience = doctor['experience'] ?? 0;
    final experienceYears = experience is int ? experience : (int.tryParse(experience.toString()) ?? 0);
    final consultationFee = doctor['consultationFee'] ?? 500;
    final fee = consultationFee is int ? consultationFee : (int.tryParse(consultationFee.toString()) ?? 500);
    final qualifications = doctor['qualifications'] ?? [];
    final availability = doctor['availability'] ?? [];
    final email = user['email']?.toString() ?? '';
    final phone = user['phone']?.toString() ?? '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.secondaryText.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Doctor Name and Specialization
            Text(
              name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              specialization,
              style: TextStyle(
                fontSize: 16,
                color: context.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            
            // Contact Info
            if (email.isNotEmpty)
              _buildProfileDetail(Icons.email, 'Email', email),
            if (phone.isNotEmpty)
              _buildProfileDetail(Icons.phone, 'Phone', phone),
            
            const SizedBox(height: 12),
            _buildProfileDetail(Icons.work, 'Experience', '$experienceYears years'),
            _buildProfileDetail(Icons.attach_money, 'Consultation Fee', '₹$fee'),
            
            const SizedBox(height: 16),
            
            // Qualifications
            if (qualifications.isNotEmpty) ...[
              Text(
                'Qualifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              ...qualifications.map((qual) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${qual['degree'] ?? qual.toString()}', style: TextStyle(color: context.primaryText)),
              )),
              const SizedBox(height: 16),
            ],
            
            // Availability
            if (availability.isNotEmpty) ...[
              Text(
                'Availability',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              ...availability.map((slot) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${slot['day']}: ${slot['startTime']} - ${slot['endTime']}',
                  style: TextStyle(color: context.primaryText),
                ),
              )),
              const SizedBox(height: 16),
            ],
            
            const SizedBox(height: 20),
            
            // Book Appointment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookAppointmentScreen(
                        doctor: {
                          'id': doctorId,
                          'name': name,
                          'specialization': specialization,
                          'hospital': user['address'] is Map 
                              ? (user['address']['city']?.toString() ?? 'City Hospital')
                              : (user['address']?.toString() ?? 'City Hospital'),
                          'consultationFee': fee,
                        },
                        specialty: widget.specialty,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Book Appointment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.primaryColor),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: context.primaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: context.secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}