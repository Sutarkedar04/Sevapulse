// lib/data/providers/medicine_provider.dart
import 'package:flutter/foundation.dart';
import '../../core/services/medicine_service.dart';
import '../../core/services/local_notification_service.dart';

class MedicineProvider with ChangeNotifier {
  List<Map<String, dynamic>> _medicines = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get medicines => _medicines;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final MedicineService _medicineService = MedicineService();
  final LocalNotificationService _notificationService =
      LocalNotificationService();

  void setToken(String token) {
    debugPrint('Setting token in MedicineProvider');
    _medicineService.setToken(token);
  }

  // ─── Mapping ───────────────────────────────────────────────────────────────

  /// Maps a raw backend medicine document to the shape the UI expects.
  Map<String, dynamic> _mapMedicineData(Map<String, dynamic> medicine) {
    // `taken` is the server virtual for TODAY — already an array of bools.
    final taken = (medicine['taken'] as List?)
            ?.map((v) => v == true)
            .toList() ??
        <bool>[];

    // `doseHistory` is the full history we use for streaks & calendar.
    final doseHistory =
        (medicine['doseHistory'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return {
      'id':           medicine['_id']?.toString() ?? medicine['id']?.toString() ?? '',
      'name':         medicine['name'] ?? '',
      'dosage':       medicine['dosage'] ?? '',
      'schedule':     medicine['schedule'] ?? '',
      'times':        List<String>.from(medicine['times'] ?? []),
      'taken':        taken,                  // today's snapshot
      'doseHistory':  doseHistory,            // full history for calendar/streak
      'streak':       (medicine['streak'] as num?)?.toInt() ?? 0, // from backend
      'startDate':    medicine['startDate'] ?? 'Not set',
      'endDate':      medicine['endDate'] ?? 'Not set',
      'instructions': medicine['instructions'] ?? 'No special instructions',
      'remaining':    medicine['remaining'] ?? 'Ongoing',
    };
  }

  // ─── Alarm helpers ─────────────────────────────────────────────────────────

  Future<void> _scheduleAlarmsForMedicine(Map<String, dynamic> med) async {
    try {
      await _notificationService.scheduleAlarmsForMedicine(med);
    } catch (e) {
      debugPrint('Error scheduling alarms: $e');
    }
  }

  Future<void> _scheduleAllAlarms() async {
    try {
      if (_medicines.isNotEmpty) {
        await _notificationService.scheduleAllMedicineAlarms(_medicines);
      }
    } catch (e) {
      debugPrint('Error scheduling all alarms: $e');
    }
  }

  // ─── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> loadMedicines() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _notificationService.initialize();
      final raw = await _medicineService.getMedicines();
      _medicines = raw.map(_mapMedicineData).toList();
      debugPrint('Medicines loaded: ${_medicines.length}');
      await _scheduleAllAlarms();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error loading medicines: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMedicine(Map<String, dynamic> medicineData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newMedicine = await _medicineService.createMedicine(medicineData);
      final mapped = _mapMedicineData(newMedicine);
      _medicines.add(mapped);
      await _scheduleAlarmsForMedicine(mapped);
      debugPrint('Medicine added: ${mapped['id']}');
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error adding medicine: $_error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMedicine(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _medicineService.updateMedicine(id, data);
      final mapped = _mapMedicineData(updated);
      final idx = _medicines.indexWhere((m) => m['id'] == id);
      if (idx != -1) {
        _medicines[idx] = mapped;
        await _notificationService.cancelMedicineAlarms(id);
        await _scheduleAlarmsForMedicine(mapped);
      }
      debugPrint('Medicine updated: $id');
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error updating medicine: $_error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMedicine(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _medicineService.deleteMedicine(id);
      _medicines.removeWhere((m) => m['id'] == id);
      await _notificationService.cancelMedicineAlarms(id);
      debugPrint('Medicine deleted: $id');
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error deleting medicine: $_error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Optimistically update local state, then confirm with server response.
  Future<bool> toggleDose(String id, int doseIndex) async {
    // Optimistic local update so the UI feels instant
    final idx = _medicines.indexWhere((m) => m['id'] == id);
    List<bool>? previousTaken;
    if (idx != -1) {
      final med = _medicines[idx];
      final taken = List<bool>.from(med['taken'] ?? []);
      previousTaken = List<bool>.from(taken);
      if (doseIndex < taken.length) {
        taken[doseIndex] = !taken[doseIndex];
        _medicines[idx] = {...med, 'taken': taken};
        notifyListeners();
      }
    }

    try {
      final updated = await _medicineService.toggleDose(id, doseIndex);
      // Sync authoritative server state (streak may have changed too)
      final mapped = _mapMedicineData(updated);
      final freshIdx = _medicines.indexWhere((m) => m['id'] == id);
      if (freshIdx != -1) {
        _medicines[freshIdx] = mapped;
        notifyListeners();
      }
      return true;
    } catch (e) {
      // Roll back optimistic update on failure
      if (idx != -1 && previousTaken != null) {
        _medicines[idx] = {..._medicines[idx], 'taken': previousTaken};
        notifyListeners();
      }
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error toggling dose: $_error');
      notifyListeners();
      return false;
    }
  }

  // ─── Alarm utilities ───────────────────────────────────────────────────────

  Future<void> rescheduleAllAlarms() async {
    try {
      await _notificationService.initialize();
      await _scheduleAllAlarms();
    } catch (e) {
      debugPrint('Error rescheduling alarms: $e');
    }
  }

  Future<void> cancelAllAlarms() async {
    try {
      await _notificationService.cancelAllMedicineAlarms();
    } catch (e) {
      debugPrint('Error cancelling alarms: $e');
    }
  }

  Future<int> getPendingAlarmCount() async {
    try {
      final pending = await _notificationService.getPendingNotifications();
      return pending.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> printPendingAlarms() async {
    await _notificationService.printPendingAlarms();
  }

  Future<void> testAlarmNow(
      String medicineId, String medicineName, String dosage) async {
    try {
      await _notificationService.initialize();
      await _notificationService.showImmediateAlarm(
        medicineId: medicineId,
        medicineName: medicineName,
        dosage: dosage,
      );
      debugPrint('Test alarm triggered for $medicineName');
    } catch (e) {
      debugPrint('Error showing test alarm: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}