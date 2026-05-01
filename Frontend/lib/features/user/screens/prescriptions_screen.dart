// lib/features/user/screens/prescriptions_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/prescription_provider.dart';
import '../../../data/models/prescription_model.dart';
import '../widgets/full_screen_image_page.dart';
import '../../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({Key? key}) : super(key: key);

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPrescriptions();
    });
  }

  Future<void> _loadPrescriptions() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prescriptionProvider = Provider.of<PrescriptionProvider>(context, listen: false);
    
    if (authProvider.token != null) {
      prescriptionProvider.setToken(authProvider.token!);
      await prescriptionProvider.loadMyPrescriptions();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  Future<void> _uploadPrescription() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        _showPrescriptionDialog(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _scanPrescription() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        _showPrescriptionDialog(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: ${e.toString()}', Colors.red);
      }
    }
  }

  void _showPrescriptionDialog(File imageFile) {
    final TextEditingController doctorNameController = TextEditingController();
    final TextEditingController medicinesController = TextEditingController();
    final TextEditingController dosageController = TextEditingController();
    final TextEditingController adviceController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.medical_information, color: context.primaryColor),
                const SizedBox(width: 8),
                Text('Upload Prescription', style: TextStyle(color: context.primaryText)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.secondaryText.withOpacity(0.2)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        imageFile,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: doctorNameController,
                    decoration: InputDecoration(
                      labelText: 'Doctor Name *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.person, color: context.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  TextFormField(
                    controller: medicinesController,
                    decoration: InputDecoration(
                      labelText: 'Medicines *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.medication, color: context.primaryColor),
                      hintText: 'e.g., Paracetamol, Amoxicillin (comma separated)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  TextFormField(
                    controller: dosageController,
                    decoration: InputDecoration(
                      labelText: 'Dosage Instructions',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.medical_services, color: context.primaryColor),
                      hintText: 'e.g., 500mg twice daily after meals',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  
                  TextFormField(
                    controller: adviceController,
                    decoration: InputDecoration(
                      labelText: 'Doctor\'s Advice',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.note, color: context.primaryColor),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Prescription Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.calendar_today, color: context.primaryColor),
                      ),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(selectedDate),
                        style: TextStyle(fontSize: 16, color: context.primaryText),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: context.secondaryText)),
              ),
              Consumer<PrescriptionProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton(
                    onPressed: provider.isUploading
                        ? null
                        : () async {
                            if (doctorNameController.text.isEmpty) {
                              _showSnackBar('Please enter doctor name', Colors.red);
                              return;
                            }
                            if (medicinesController.text.isEmpty) {
                              _showSnackBar('Please enter medicines', Colors.red);
                              return;
                            }

                            final medicineNames = medicinesController.text
                                .split(',')
                                .map((m) => m.trim())
                                .where((m) => m.isNotEmpty)
                                .toList();
                            
                            final medicineList = medicineNames.map((name) => {
                              'name': name,
                              'dosage': dosageController.text.isEmpty ? 'As directed' : dosageController.text,
                              'frequency': 'As prescribed',
                              'duration': 'As prescribed',
                              'instructions': adviceController.text,
                            }).toList();

                            final success = await provider.patientUploadPrescription(
                              imageFile: imageFile,
                              doctorName: doctorNameController.text,
                              medicines: medicineList,
                              advice: adviceController.text,
                            );

                            if (success && mounted) {
                              Navigator.pop(context);
                              _showSnackBar('Prescription uploaded successfully!', Colors.green);
                              await _loadPrescriptions();
                            } else if (mounted) {
                              _showSnackBar(provider.error ?? 'Failed to upload prescription', Colors.red);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27ae60),
                      minimumSize: const Size(0, 36),
                    ),
                    child: provider.isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Upload'),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _viewPrescriptionDetails(Prescription prescription) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                'Prescription Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.primaryText,
                ),
              ),
              const SizedBox(height: 16),
              
              // Multiple Images if available
              if (prescription.hasImages) ...[
                Text(
                  'Prescription Images',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: prescription.allImages.length,
                    itemBuilder: (context, index) {
                      final imageUrl = prescription.allImages[index];
                      return GestureDetector(
                        onTap: () => _showFullScreenImage(imageUrl),
                        child: Container(
                          width: 180,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.secondaryText.withOpacity(0.2)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(Icons.broken_image, size: 40, color: context.secondaryText),
                                    );
                                  },
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.tap_and_play, size: 12, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Doctor Info
              _buildSectionHeader(Icons.person, 'Doctor Information'),
              const SizedBox(height: 8),
              _buildInfoRow('Doctor Name', prescription.doctorName),
              const SizedBox(height: 16),
              
              // Medicines
              if (prescription.hasMedicines) ...[
                _buildSectionHeader(Icons.medication, 'Medicines'),
                const SizedBox(height: 8),
                ...prescription.medicines.map((medicine) => _buildMedicineCard(medicine)),
                const SizedBox(height: 16),
              ],
              
              // Advice
              if (prescription.advice.isNotEmpty) ...[
                _buildSectionHeader(Icons.note, 'Doctor\'s Advice'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    prescription.advice,
                    style: TextStyle(color: context.primaryText, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Additional Notes
              if (prescription.notes != null && prescription.notes!.isNotEmpty) ...[
                _buildSectionHeader(Icons.note_add, 'Additional Notes'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    prescription.notes!,
                    style: TextStyle(color: context.primaryText, height: 1.4, fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Prescription Date
              _buildSectionHeader(Icons.date_range, 'Prescription Info'),
              const SizedBox(height: 8),
              _buildInfoRow('Issued On', DateFormat('MMM dd, yyyy \'at\' hh:mm a').format(prescription.createdAt)),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicineCard(Medicine medicine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.secondaryText.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medication, size: 16, color: Color(0xFF27ae60)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  medicine.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: context.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💊 Dosage: ${medicine.dosage}', style: TextStyle(fontSize: 13, color: context.secondaryText)),
                Text('⏰ Frequency: ${medicine.frequency}', style: TextStyle(fontSize: 13, color: context.secondaryText)),
                Text('📅 Duration: ${medicine.duration}', style: TextStyle(fontSize: 13, color: context.secondaryText)),
                if (medicine.instructions.isNotEmpty)
                  Text('📝 Instructions: ${medicine.instructions}', style: TextStyle(fontSize: 13, color: context.secondaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: context.secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: context.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDeleteConfirmation(Prescription prescription, PrescriptionProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Prescription', style: TextStyle(color: context.primaryText)),
        content: Text('Are you sure you want to delete this prescription?', style: TextStyle(color: context.secondaryText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: context.primaryColor)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deletePrescription(prescription.id);
              if (success && mounted) {
                _showSnackBar('Prescription deleted', Colors.red);
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImagePage(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PrescriptionProvider>(
      builder: (context, provider, child) {
        final filteredPrescriptions = provider.getFilteredPrescriptions(
          searchQuery: _searchQuery,
        );

        return Scaffold(
          backgroundColor: context.backgroundColor,
          appBar: AppBar(
            title: const Text('My Prescriptions'),
            backgroundColor: context.primaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
            actions: [
              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: _scanPrescription,
                tooltip: 'Scan Prescription',
              ),
              IconButton(
                icon: const Icon(Icons.upload_file),
                onPressed: _uploadPrescription,
                tooltip: 'Upload Prescription',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadPrescriptions,
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search medicine or doctor...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.secondaryText.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.secondaryText.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: context.surfaceColor,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${filteredPrescriptions.length} prescriptions',
                      style: TextStyle(
                        color: context.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                    if (provider.isLoading)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: provider.isLoading && filteredPrescriptions.isEmpty
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
                        ),
                      )
                    : filteredPrescriptions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.description, size: 80, color: context.secondaryText.withOpacity(0.4)),
                                const SizedBox(height: 16),
                                Text(
                                  'No prescriptions found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: context.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Scan or upload your first prescription',
                                  style: TextStyle(
                                    color: context.secondaryText.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 130,
                                      child: ElevatedButton.icon(
                                        onPressed: _scanPrescription,
                                        icon: const Icon(Icons.camera_alt, size: 18),
                                        label: const Text('Scan'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: context.primaryColor,
                                          minimumSize: const Size(90, 40),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 130,
                                      child: ElevatedButton.icon(
                                        onPressed: _uploadPrescription,
                                        icon: const Icon(Icons.upload_file, size: 18),
                                        label: const Text('Upload'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF27ae60),
                                          minimumSize: const Size(90, 40),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredPrescriptions.length,
                            itemBuilder: (context, index) {
                              final prescription = filteredPrescriptions[index];
                              return _buildPrescriptionCard(prescription, provider);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrescriptionCard(Prescription prescription, PrescriptionProvider provider) {
    final hasMultipleImages = prescription.allImages.length > 1;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: context.cardColor,
      child: InkWell(
        onTap: () => _viewPrescriptionDetails(prescription),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (prescription.hasImages) {
                        _showFullScreenImage(prescription.allImages.first);
                      }
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: context.surfaceColor,
                        border: Border.all(color: context.secondaryText.withOpacity(0.2)),
                      ),
                      child: prescription.hasImages
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                prescription.allImages.first,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.medical_information, size: 30, color: context.secondaryText);
                                },
                              ),
                            )
                          : Icon(Icons.medical_information, size: 30, color: context.secondaryText),
                    ),
                  ),
                  if (hasMultipleImages)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+${prescription.allImages.length - 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prescription.medicinesSummary,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Dr. ${prescription.doctorName}',
                          style: TextStyle(
                            color: context.primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF27ae60).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Doctor',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFF27ae60),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(prescription.createdAt),
                      style: TextStyle(
                        color: context.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _showDeleteConfirmation(prescription, provider),
                tooltip: 'Delete Prescription',
              ),
              
              Icon(Icons.chevron_right, color: context.secondaryText),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}