// lib/data/models/prescription_model.dart

class Medicine {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String instructions;

  Medicine({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.instructions,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      name: json['name']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      instructions: json['instructions']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
    };
  }
}

class Prescription {
  final String id;
  final String? appointmentId;
  final String? doctorId;
  final String patientId;
  final String doctorName;
  final String patientName;
  final List<Medicine> medicines;
  final String advice;
  final String? notes;
  final DateTime createdAt;
  final String? imageUrl;
  final List<String>? imageUrls;

  Prescription({
    required this.id,
    this.appointmentId,
    this.doctorId,
    required this.patientId,
    required this.doctorName,
    required this.patientName,
    required this.medicines,
    required this.advice,
    this.notes,
    required this.createdAt,
    this.imageUrl,
    this.imageUrls,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    // Handle different ID field names
    String id = '';
    if (json['_id'] != null) {
      id = json['_id'].toString();
    } else if (json['id'] != null) {
      id = json['id'].toString();
    }
    
    // Handle patient ID
    String patientId = '';
    if (json['patient'] != null) {
      if (json['patient'] is Map) {
        patientId = json['patient']['_id']?.toString() ?? json['patient'].toString();
      } else {
        patientId = json['patient'].toString();
      }
    }
    
    // Handle doctor name
    String doctorName = json['doctorName']?.toString() ?? '';
    if (doctorName.isEmpty && json['doctor'] != null && json['doctor'] is Map) {
      doctorName = json['doctor']['name']?.toString() ?? '';
    }
    
    // Handle medicines
    List<Medicine> medicines = [];
    if (json['medicines'] != null && json['medicines'] is List) {
      medicines = (json['medicines'] as List).map((m) {
        if (m is Map) {
          Map<String, dynamic> convertedMap = {};
          m.forEach((key, value) {
            convertedMap[key.toString()] = value;
          });
          return Medicine.fromJson(convertedMap);
        } else {
          return Medicine.fromJson({'name': m.toString()});
        }
      }).toList();
    }
    
    // Handle dates
    DateTime createdAt = DateTime.now();
    if (json['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(json['createdAt'].toString());
      } catch (e) {
        createdAt = DateTime.now();
      }
    }
    
    // Handle image URLs (support both single and multiple)
    String? imageUrl = json['imageUrl']?.toString();
    List<String>? imageUrls;
    if (json['imageUrls'] != null && json['imageUrls'] is List) {
      imageUrls = List<String>.from(json['imageUrls'].map((url) => url.toString()));
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      imageUrls = [imageUrl];
    }
    
    return Prescription(
      id: id,
      appointmentId: json['appointment']?.toString(),
      doctorId: json['doctor']?.toString(),
      patientId: patientId,
      doctorName: doctorName,
      patientName: json['patientName']?.toString() ?? 'Patient',
      medicines: medicines,
      advice: json['advice']?.toString() ?? '',
      notes: json['notes']?.toString(),
      createdAt: createdAt,
      imageUrl: imageUrl,
      imageUrls: imageUrls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'doctorId': doctorId,
      'patientId': patientId,
      'doctorName': doctorName,
      'patientName': patientName,
      'medicines': medicines.map((m) => m.toJson()).toList(),
      'advice': advice,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
    };
  }

  bool get hasMedicines => medicines.isNotEmpty;
  bool get hasImages => (imageUrls != null && imageUrls!.isNotEmpty);
  List<String> get allImages => imageUrls ?? [];
  String get medicinesSummary => medicines.map((m) => m.name).join(', ');
}