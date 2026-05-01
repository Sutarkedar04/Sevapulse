// lib/core/constants/api_constants.dart
class ApiConstants {
  static const String baseUrl = 'http://10.33.79.50:5001/api';
  
  // Auth endpoints
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String getProfile = '$baseUrl/auth/me';
  
  // Appointments
  static const String appointments = '$baseUrl/appointments';
  
  // Doctors
  static const String doctors = '$baseUrl/doctors';
  static const String doctorDetails = '$baseUrl/doctors';
  
  // Patients
  static const String patients = '$baseUrl/patients';
  static const String patientDetails = '$baseUrl/patients';
  static const String updatePatientProfile = '$baseUrl/patients/me';
  
  // Prescriptions
  static const String prescriptions = '$baseUrl/prescriptions';
  static const String myPrescriptions = '$baseUrl/prescriptions/my';
  static const String prescriptionUpload = '$baseUrl/prescriptions/upload';
  static const String doctorCreatePrescription = '$baseUrl/prescriptions/doctor-create';
  static const String patientPrescriptions = '$baseUrl/prescriptions/patient';
  
  // Add to api_constants.dart
static const String governmentSchemes = '$baseUrl/government-schemes';
  // Bills
  static const String bills = '$baseUrl/bills';
  
  // Medicines
  static const String medicines = '$baseUrl/medicines';
  
  // Health Feed
  static const String healthCamps = '$baseUrl/health-feed';
  static const String registerCamp = '$baseUrl/health-feed';
  
  // Canteen
  static const String canteenMenu = '$baseUrl/canteen/menu';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}