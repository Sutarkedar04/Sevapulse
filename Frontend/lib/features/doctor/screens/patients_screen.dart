// lib/features/doctor/screens/patients_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme_extensions.dart';

class PatientsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> patients;
  final Function(Map<String, dynamic>) onPrescriptionPressed;
  final VoidCallback? onRefresh; // ✅ Added refresh callback

  const PatientsScreen({
    Key? key,
    required this.patients,
    required this.onPrescriptionPressed,
    this.onRefresh, // ✅ Added refresh callback
  }) : super(key: key);

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  String _searchQuery = '';
  String _filterPeriod = 'last10days';
  bool _isRefreshing = false;
  
  // TEST MODE FLAG - Set to false when done testing
  final bool _isTestMode = false; // ✅ Set to false for production

  @override
  void initState() {
    super.initState();
  }

  // Generate test patients with recent dates (only for testing)
  List<Map<String, dynamic>> _getTestPatientsWithRecentDates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return [
      {
        'name': 'Test Patient 1 (2 days ago)',
        'email': 'test1@example.com',
        'lastVisit': today.subtract(const Duration(days: 2)).toIso8601String(),
        'condition': 'Flu',
        'userId': 'TEST001',
        'medicalHistory': '• Patient presented with fever and cough\n• Prescribed antibiotics\n• Follow-up recommended in 3 days',
        'emergencyContact': false,
      },
      {
        'name': 'Test Patient 2 (5 days ago)',
        'email': 'test2@example.com',
        'lastVisit': today.subtract(const Duration(days: 5)).toIso8601String(),
        'condition': 'Hypertension',
        'userId': 'TEST002',
        'medicalHistory': '• Blood pressure monitoring\n• Regular medication check\n• Lifestyle modification advice given',
        'emergencyContact': true,
      },
      {
        'name': 'Test Patient 3 (8 days ago)',
        'email': 'test3@example.com',
        'lastVisit': today.subtract(const Duration(days: 8)).toIso8601String(),
        'condition': 'Diabetes',
        'userId': 'TEST003',
        'medicalHistory': '• Blood sugar levels monitored\n• Insulin dosage adjusted\n• Diet plan reviewed',
        'emergencyContact': false,
      },
    ];
  }

  // Get all patients (original + test patients if test mode is enabled)
  List<Map<String, dynamic>> get _allPatients {
    if (_isTestMode) {
      return [...widget.patients, ..._getTestPatientsWithRecentDates()];
    }
    return widget.patients;
  }

  // Safe date parsing that handles multiple formats
  DateTime? _parseDateSafely(dynamic dateValue) {
    if (dateValue == null) return null;
    
    try {
      final dateStr = dateValue.toString();
      
      // Try ISO format first (yyyy-mm-dd or yyyy-mm-ddThh:mm:ss)
      if (dateStr.contains('-') && (dateStr.length >= 10)) {
        if (dateStr.contains('T')) {
          return DateTime.parse(dateStr);
        } else if (dateStr.length >= 10) {
          final parts = dateStr.split('-');
          if (parts.length >= 3) {
            return DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2].substring(0, 2)),
            );
          }
        }
      }
      
      // Try dd/mm/yyyy format
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length >= 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
      
      return null;
    } catch (e) {
      print('Error parsing date: $dateValue - $e');
      return null;
    }
  }

  bool _isWithinLastNDays(DateTime date, int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nDaysAgo = today.subtract(Duration(days: days));
    final visitDate = DateTime(date.year, date.month, date.day);
    
    return visitDate.isAfter(nDaysAgo) || 
           visitDate.isAtSameMomentAs(nDaysAgo);
  }

  List<Map<String, dynamic>> get _filteredByDate {
    if (_filterPeriod == 'all') {
      return _allPatients;
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int daysToSubtract;
    
    switch (_filterPeriod) {
      case 'last7days':
        daysToSubtract = 7;
        break;
      case 'last10days':
        daysToSubtract = 10;
        break;
      case 'last30days':
        daysToSubtract = 30;
        break;
      default:
        return _allPatients;
    }
    
    final filterDate = today.subtract(Duration(days: daysToSubtract));
    
    return _allPatients.where((patient) {
      final lastVisit = _parseDateSafely(patient['lastVisit']);
      if (lastVisit == null) {
        return false;
      }
      
      final visitDate = DateTime(lastVisit.year, lastVisit.month, lastVisit.day);
      return visitDate.isAfter(filterDate) || 
             visitDate.isAtSameMomentAs(filterDate);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredPatients {
    List<Map<String, dynamic>> filtered = _filteredByDate;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((patient) {
        final name = patient['name']?.toString().toLowerCase() ?? '';
        final email = patient['email']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        
        return name.contains(query) || email.contains(query);
      }).toList();
    }

    filtered.sort((a, b) {
      final dateA = _parseDateSafely(a['lastVisit']);
      final dateB = _parseDateSafely(b['lastVisit']);
      
      if (dateA == null || dateB == null) return 0;
      return dateB.compareTo(dateA);
    });

    return filtered;
  }

  int get _recentPatientsCount {
    return _allPatients.where((patient) {
      final lastVisit = _parseDateSafely(patient['lastVisit']);
      return lastVisit != null && _isWithinLastNDays(lastVisit, 10);
    }).length;
  }

  void _showPatientDetails(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.surfaceColor,
        title: Text(patient['name'] ?? 'Unknown', 
                style: TextStyle(color: context.primaryText)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Patient ID', patient['userId'] ?? patient['id'] ?? 'N/A'),
              _buildDetailRow('Email', patient['email'] ?? 'N/A'),
              _buildDetailRow('Last Visit', _formatDateFromValue(patient['lastVisit'])),
              _buildDetailRow('Condition', patient['condition'] ?? 'Not specified'),
              _buildDetailRow('Blood Group', patient['bloodGroup'] ?? 'Not set'),
              _buildDetailRow('Gender', patient['gender'] ?? 'Not set'),
              const SizedBox(height: 16),
              Text(
                'Medical History:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                patient['medicalHistory']?.isNotEmpty == true 
                    ? (patient['medicalHistory'] is List 
                        ? (patient['medicalHistory'] as List).map((h) => '• ${h['condition'] ?? h}').join('\n')
                        : patient['medicalHistory'])
                    : 'No medical history recorded',
                style: TextStyle(color: context.secondaryText),
              ),
              if (patient['allergies'] != null && (patient['allergies'] as List).isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Allergies:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (patient['allergies'] as List).map((a) => '• $a').join('\n'),
                  style: TextStyle(color: context.secondaryText),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: context.primaryColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onPrescriptionPressed(patient);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
            ),
            child: const Text('Write Prescription'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: context.primaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              (value == null || value.isEmpty) ? 'Not set' : value,
              style: TextStyle(color: context.secondaryText),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateFromValue(dynamic dateValue) {
    final date = _parseDateSafely(dateValue);
    return date != null ? _formatDate(date) : (dateValue?.toString() ?? 'Not set');
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Color _getConditionColor(String condition) {
    final conditionLower = condition.toLowerCase();
    if (conditionLower.contains('hypertension') || 
        conditionLower.contains('chest') ||
        conditionLower.contains('heart')) {
      return const Color(0xFFe74c3c);
    } else if (conditionLower.contains('migraine') ||
               conditionLower.contains('headache')) {
      return const Color(0xFFf39c12);
    } else if (conditionLower.contains('flu') ||
               conditionLower.contains('fever') ||
               conditionLower.contains('cold')) {
      return const Color(0xFF3498db);
    } else if (conditionLower.contains('diabetes')) {
      return const Color(0xFF9b59b6);
    }
    return const Color(0xFF27ae60);
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }
    
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentCount = _recentPatientsCount;
    final totalCount = _allPatients.length;
    
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Column(
          children: [
            // Test Mode Banner (only visible when test mode is enabled)
            if (_isTestMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.orange.withOpacity(0.8),
                child: Row(
                  children: [
                    const Icon(Icons.bug_report, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'TEST MODE ACTIVE - Showing test patients',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (_isRefreshing)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            
            // Search and Filter Section
            Container(
              padding: const EdgeInsets.all(16),
              color: context.surfaceColor,
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    style: TextStyle(color: context.primaryText),
                    decoration: InputDecoration(
                      hintText: 'Search patients by name or email...',
                      hintStyle: TextStyle(color: context.secondaryText),
                      prefixIcon: Icon(Icons.search, color: context.secondaryText),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: context.secondaryText),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: context.cardColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All Patients', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Last 7 Days', 'last7days'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Last 10 Days', 'last10days'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Last 30 Days', 'last30days'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Patient Stats
                  Row(
                    children: [
                      _buildStatCard('Recent (10 days)', recentCount, 
                          const Color(0xFF27ae60)),
                      const SizedBox(width: 12),
                      _buildStatCard('Total Patients', totalCount, 
                          context.primaryColor),
                    ],
                  ),
                ],
              ),
            ),

            // Patients List
            Expanded(
              child: _filteredPatients.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredPatients.length,
                      itemBuilder: (context, index) {
                        final patient = _filteredPatients[index];
                        return _buildPatientCard(patient);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterPeriod == value;
    return FilterChip(
      label: Text(label, 
               style: TextStyle(
                 color: isSelected ? Colors.white : context.primaryText
               )),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterPeriod = selected ? value : 'last10days';
        });
      },
      selectedColor: context.primaryColor,
      checkmarkColor: Colors.white,
      backgroundColor: context.cardColor,
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final lastVisitDate = _parseDateSafely(patient['lastVisit']);
    final isRecent = lastVisitDate != null && _isWithinLastNDays(lastVisitDate, 10);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: context.cardColor,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isRecent 
              ? Border.all(color: const Color(0xFF27ae60).withOpacity(0.3), width: 1.5)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: context.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: context.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Patient Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                patient['name'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: context.primaryText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isRecent)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF27ae60).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Recent',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF27ae60),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          patient['email'] ?? 'No email',
                          style: TextStyle(
                            color: context.secondaryText,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getConditionColor(patient['condition'] ?? '').withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                patient['condition'] ?? 'General',
                                style: TextStyle(
                                  color: _getConditionColor(patient['condition'] ?? ''),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (patient['emergencyContact'] == true)
                              const Icon(
                                Icons.emergency,
                                color: Color(0xFFe74c3c),
                                size: 16,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Additional Info and Actions
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Visit: ${_formatDateFromValue(patient['lastVisit'])}',
                          style: TextStyle(
                            color: context.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Patient ID: ${patient['userId'] ?? patient['id'] ?? 'N/A'}',
                          style: TextStyle(
                            color: context.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _showPatientDetails(patient),
                        icon: Icon(Icons.visibility, size: 20, color: context.primaryColor),
                        tooltip: 'View Details',
                      ),
                      IconButton(
                        onPressed: () => widget.onPrescriptionPressed(patient),
                        icon: const Icon(Icons.medical_services, size: 20, color: Color(0xFF27ae60)),
                        tooltip: 'Write Prescription',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: context.secondaryText.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Patients Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              _searchQuery.isNotEmpty
                  ? 'No patients found for "$_searchQuery". Try a different search term.'
                  : _filterPeriod != 'all'
                      ? 'No patients visited in the selected period. Try "All Patients" to see everyone.'
                      : 'Patients who book appointments with you will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.secondaryText.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_searchQuery.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Search'),
            ),
          if (_filterPeriod != 'all')
            TextButton(
              onPressed: () {
                setState(() {
                  _filterPeriod = 'all';
                });
              },
              child: Text(
                'Show All Patients',
                style: TextStyle(color: context.primaryColor),
              ),
            ),
          if (widget.onRefresh != null)
            TextButton(
              onPressed: _handleRefresh,
              child: Text(
                'Refresh Patients',
                style: TextStyle(color: context.primaryColor),
              ),
            ),
        ],
      ),
    );
  }
}