// lib/core/services/local_notification_service.dart
//
// Handles two kinds of scheduled local notifications:
//   1. Medicine reminders  – daily at each dose time, within start→end range
//   2. Appointment reminders – one notification the day before at 8 PM,
//                              one on the day itself at 8 AM
//
// Notification ID allocation (all % 2^31 to stay in int range):
//   Medicine:    hash('med-<id>-<hour>-<minute>') % 200000          → 0 … 199999
//   Appt day-before: hash('appt-pre-<id>') % 100000 + 200000        → 200000 … 299999
//   Appt day-of:     hash('appt-day-<id>') % 100000 + 300000        → 300000 … 399999
//   Immediate test:  DateTime.millisecondsSinceEpoch % 100000 + 900000

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  // ─── Singleton ─────────────────────────────────────────────────────────────
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  // ─── Internal state ────────────────────────────────────────────────────────
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// medicine-id  →  list of notification IDs we own
  final Map<String, List<int>> _medicineIds = {};

  /// appointment-id  →  [dayBeforeId, dayOfId]
  final Map<String, List<int>> _appointmentIds = {};

  // ─── Channel / category constants ─────────────────────────────────────────
  static const _medChannelId   = 'medicine_alarm_channel';
  static const _medChannelName = 'Medicine Reminders';
  static const _apptChannelId   = 'appointment_reminder_channel';
  static const _apptChannelName = 'Appointment Reminders';

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALISE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    _setLocalTimezone();

    // ── Android init ────────────────────────────────────────────────────────
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // ── iOS init ────────────────────────────────────────────────────────────
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundTap,
    );

    // ── Request Android 13+ permission ──────────────────────────────────────
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      await _createAndroidChannel(
        id: _medChannelId,
        name: _medChannelName,
        description: 'Daily reminders to take your medicine',
        importance: Importance.max,
        sound: const RawResourceAndroidNotificationSound('alarm_sound'),
        ledColor: const Color(0xFF27ae60),
      );

      await _createAndroidChannel(
        id: _apptChannelId,
        name: _apptChannelName,
        description: 'Reminders about upcoming appointments',
        importance: Importance.high,
        sound: const RawResourceAndroidNotificationSound('notification_sound'),
        ledColor: const Color(0xFF3498db),
      );
    }

    // ── Request iOS permission explicitly (needed on iOS 16+) ───────────────
    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
    debugPrint('✅ LocalNotificationService initialised');
  }

  void _setLocalTimezone() {
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }
  }

  Future<void> _createAndroidChannel({
    required String id,
    required String name,
    required String description,
    required Importance importance,
    required AndroidNotificationSound sound,
    required Color ledColor,
  }) async {
    final channel = AndroidNotificationChannel(
      id,
      name,
      description: description,
      importance: importance,
      playSound: true,
      sound: sound,
      enableVibration: true,
      enableLights: true,
      ledColor: ledColor,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MEDICINE REMINDERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Schedule daily reminders for every dose time of [medicine].
  /// Cancels any previous reminders for the same medicine first.
  Future<void> scheduleAlarmsForMedicine(Map<String, dynamic> medicine) async {
    if (!_initialized) await initialize();

    final id       = medicine['id']?.toString() ?? '';
    final name     = medicine['name']?.toString() ?? 'Medicine';
    final dosage   = medicine['dosage']?.toString() ?? '';
    final times    = List<String>.from(medicine['times'] ?? []);

    if (id.isEmpty || times.isEmpty) {
      debugPrint('⚠️ Skipping medicine "$name" – missing id or times');
      return;
    }

    final startDate = _parseDate(medicine['startDate']?.toString()) ??
        DateTime.now();
    final endDate   = _parseDate(medicine['endDate']?.toString()) ??
        DateTime.now().add(const Duration(days: 365));

    // Skip medicines whose course is already finished
    final todayMidnight = _todayMidnight();
    final endMidnight   = DateTime(endDate.year, endDate.month, endDate.day);
    if (endMidnight.isBefore(todayMidnight)) {
      debugPrint('⚠️ "$name" ended on $endMidnight – skipping');
      return;
    }

    await cancelMedicineAlarms(id);

    for (final timeStr in times) {
      final parsed = _parseTime(timeStr);
      if (parsed == null) {
        debugPrint('⚠️ Cannot parse time "$timeStr" for $name');
        continue;
      }
      await _scheduleDailyMedicineReminder(
        medicineId: id,
        medicineName: name,
        dosage: dosage,
        hour: parsed['hour']!,
        minute: parsed['minute']!,
        endDate: endDate,
      );
    }
  }

  Future<void> _scheduleDailyMedicineReminder({
    required String medicineId,
    required String medicineName,
    required String dosage,
    required int hour,
    required int minute,
    required DateTime endDate,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final end = tz.TZDateTime.from(
        endDate.add(const Duration(days: 1)), tz.local);

    // Next occurrence of hour:minute from now
    tz.TZDateTime scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    if (scheduled.isAfter(end)) {
      debugPrint(
          '⚠️ $medicineName – first fire $scheduled is after end $end');
      return;
    }

    final notifId = _medNotifId(medicineId, hour, minute);
    final timeLabel = _formatHM(hour, minute);

    await _plugin.zonedSchedule(
      notifId,
      '💊 Time to take your medicine',
      '$medicineName  •  $dosage\nScheduled dose: $timeLabel',
      scheduled,
      _medDetails(),
      // ✅ This is the key flag: repeat at the same clock time every day
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      payload: 'medicine_$medicineId',
    );

    _medicineIds.putIfAbsent(medicineId, () => []).add(notifId);
    debugPrint(
        '✅ Medicine reminder: "$medicineName" every day at $timeLabel (id $notifId)');
  }

  /// Schedule reminders for every medicine in [medicines].
  Future<void> scheduleAllMedicineAlarms(
      List<Map<String, dynamic>> medicines) async {
    if (!_initialized) await initialize();
    for (final m in medicines) {
      await scheduleAlarmsForMedicine(m);
    }
  }

  /// Cancel all scheduled reminders for [medicineId].
  Future<void> cancelMedicineAlarms(String medicineId) async {
    final ids = _medicineIds.remove(medicineId) ?? [];
    for (final id in ids) {
      await _plugin.cancel(id);
    }
    if (ids.isNotEmpty) {
      debugPrint('🗑️ Cancelled ${ids.length} medicine reminders for $medicineId');
    }
  }

  /// Cancel every medicine alarm across all medicines.
  Future<void> cancelAllMedicineAlarms() async {
    // Cancel each individually so we don't wipe appointment reminders too
    for (final ids in _medicineIds.values) {
      for (final id in ids) {
        await _plugin.cancel(id);
      }
    }
    _medicineIds.clear();
    debugPrint('🗑️ Cancelled all medicine alarms');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APPOINTMENT REMINDERS
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // Two reminders per appointment:
  //   • Evening before  – fires at 20:00 the day before
  //   • Morning of      – fires at 08:00 on the appointment day
  //
  // Both are one-shot (no repeat); they are cancelled when the appointment
  // is cancelled or when the patient marks it complete.

  /// Schedule both reminders for [appointment].
  /// Pass the appointment as a Map with at minimum:
  ///   { 'id': String, 'doctorName': String, 'date': String (ISO8601), 'time': String }
  Future<void> scheduleAppointmentReminders(
      Map<String, dynamic> appointment) async {
    if (!_initialized) await initialize();

    final id         = appointment['id']?.toString() ?? '';
    final doctorName = appointment['doctorName']?.toString() ?? 'your doctor';
    final timeLabel  = appointment['time']?.toString() ?? '';
    final dateRaw    = appointment['date'];

    if (id.isEmpty || dateRaw == null) {
      debugPrint('⚠️ Cannot schedule appointment reminder – missing id/date');
      return;
    }

    DateTime apptDate;
    try {
      apptDate = (dateRaw is DateTime)
          ? dateRaw.toLocal()
          : DateTime.parse(dateRaw.toString()).toLocal();
    } catch (e) {
      debugPrint('⚠️ Cannot parse appointment date: $dateRaw');
      return;
    }

    final now = DateTime.now();

    // ── Cancel any existing reminders for this appointment ──────────────────
    await cancelAppointmentReminders(id);

    // ── 1. Day-before reminder at 20:00 ─────────────────────────────────────
    final dayBefore = DateTime(
        apptDate.year, apptDate.month, apptDate.day - 1, 20, 0);
    if (dayBefore.isAfter(now)) {
      final dbId = _apptPreNotifId(id);
      await _plugin.zonedSchedule(
        dbId,
        '📅 Appointment Tomorrow',
        'Reminder: appointment with Dr. $doctorName tomorrow at $timeLabel.\nPlease arrive 10 min early.',
        tz.TZDateTime.from(dayBefore, tz.local),
        _apptDetails(isUrgent: false),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'appointment_$id',
      );
      _appointmentIds.putIfAbsent(id, () => []).add(dbId);
      debugPrint(
          '✅ Appointment day-before reminder: Dr. $doctorName on '
          '${DateFormat('dd MMM').format(apptDate)} (id $dbId)');
    } else {
      debugPrint(
          'ℹ️ Day-before reminder for appt $id is in the past – skipping');
    }

    // ── 2. Day-of reminder at 08:00 ─────────────────────────────────────────
    final dayOf = DateTime(
        apptDate.year, apptDate.month, apptDate.day, 8, 0);
    if (dayOf.isAfter(now)) {
      final doId = _apptDayNotifId(id);
      await _plugin.zonedSchedule(
        doId,
        '🏥 Appointment Today!',
        'You have an appointment with Dr. $doctorName today at $timeLabel. See you soon!',
        tz.TZDateTime.from(dayOf, tz.local),
        _apptDetails(isUrgent: true),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'appointment_$id',
      );
      _appointmentIds.putIfAbsent(id, () => []).add(doId);
      debugPrint(
          '✅ Appointment day-of reminder: Dr. $doctorName at $timeLabel '
          '(id $doId)');
    } else {
      debugPrint(
          'ℹ️ Day-of reminder for appt $id is in the past – skipping');
    }
  }

  /// Schedule reminders for a list of appointments (call after loadAppointments).
  Future<void> scheduleAllAppointmentReminders(
      List<Map<String, dynamic>> appointments) async {
    if (!_initialized) await initialize();
    for (final a in appointments) {
      await scheduleAppointmentReminders(a);
    }
  }

  /// Cancel both reminders for [appointmentId].
  Future<void> cancelAppointmentReminders(String appointmentId) async {
    final ids = _appointmentIds.remove(appointmentId) ?? [];
    for (final id in ids) {
      await _plugin.cancel(id);
    }
    if (ids.isNotEmpty) {
      debugPrint(
          '🗑️ Cancelled ${ids.length} appointment reminders for $appointmentId');
    }
  }

  /// Cancel ALL appointment reminders.
  Future<void> cancelAllAppointmentReminders() async {
    for (final ids in _appointmentIds.values) {
      for (final id in ids) {
        await _plugin.cancel(id);
      }
    }
    _appointmentIds.clear();
    debugPrint('🗑️ Cancelled all appointment reminders');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // IMMEDIATE / TEST NOTIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> showImmediateAlarm({
    required String medicineId,
    required String medicineName,
    required String dosage,
  }) async {
    if (!_initialized) await initialize();
    final notifId = DateTime.now().millisecondsSinceEpoch % 100000 + 900000;
    await _plugin.show(
      notifId,
      '💊 Time to take your medicine',
      '$medicineName  •  $dosage',
      _medDetails(),
      payload: 'medicine_$medicineId',
    );
    debugPrint('✅ Immediate alarm shown for $medicineName (id $notifId)');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEBUGGING
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return _plugin.pendingNotificationRequests();
  }

  Future<void> printPendingAlarms() async {
    final pending = await getPendingNotifications();
    debugPrint('📋 Pending notifications: ${pending.length}');
    for (final p in pending) {
      debugPrint('   id=${p.id}  title="${p.title}"  payload="${p.payload}"');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTIFICATION DETAILS BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════

  NotificationDetails _medDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _medChannelId,
        _medChannelName,
        channelDescription: 'Daily reminders to take your medicine',
        importance: Importance.max,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        enableVibration: true,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('alarm_sound'),
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        color: const Color(0xFF27ae60),
        actions: [
          const AndroidNotificationAction(
            'take_medicine',
            '✅ Mark as Taken',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          const AndroidNotificationAction(
            'snooze_medicine',
            '⏰ Snooze 10 min',
            showsUserInterface: false,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // Use your bundled alarm_sound.wav in the iOS Runner target
        sound: 'alarm_sound.wav',
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: 'medicine_category',
      ),
    );
  }

  NotificationDetails _apptDetails({required bool isUrgent}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _apptChannelId,
        _apptChannelName,
        channelDescription: 'Reminders about upcoming appointments',
        importance: isUrgent ? Importance.max : Importance.high,
        priority: isUrgent ? Priority.high : Priority.defaultPriority,
        visibility: NotificationVisibility.public,
        enableVibration: true,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('notification_sound'),
        color: const Color(0xFF3498db),
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.wav',
        interruptionLevel: isUrgent
            ? InterruptionLevel.timeSensitive
            : InterruptionLevel.active,
        categoryIdentifier: 'appointment_category',
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTIFICATION RESPONSE HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  static void _onTap(NotificationResponse response) {
    final payload = response.payload ?? '';
    debugPrint('📱 Notification tapped: $payload');
    // Deep-link handling:
    //   medicine_<id>     → open My Medicine screen
    //   appointment_<id>  → open Appointments screen
    // Wire this up in your NavigationService / GoRouter when you need it.
  }

  @pragma('vm:entry-point')
  static void _onBackgroundTap(NotificationResponse response) {
    // Same as _onTap but called when the app is fully terminated.
    debugPrint('📱 Background notification tapped: ${response.payload}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stable, unique notification ID for a medicine dose slot.
  int _medNotifId(String medicineId, int hour, int minute) =>
      'med-$medicineId-$hour-$minute'.hashCode.abs() % 200000;

  /// Stable ID for the day-before appointment reminder.
  int _apptPreNotifId(String apptId) =>
      'appt-pre-$apptId'.hashCode.abs() % 100000 + 200000;

  /// Stable ID for the day-of appointment reminder.
  int _apptDayNotifId(String apptId) =>
      'appt-day-$apptId'.hashCode.abs() % 100000 + 300000;

  DateTime _todayMidnight() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  String _formatHM(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$h:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Parse "8:00 AM" / "8:00 PM" / "13:30" → {hour, minute}
  Map<String, int>? _parseTime(String s) {
    try {
      if (s.contains('AM') || s.contains('PM')) {
        final parts = s.trim().split(' ');
        final hm    = parts[0].split(':');
        int hour    = int.parse(hm[0]);
        final min   = int.parse(hm[1]);
        if (parts[1].toUpperCase() == 'PM' && hour != 12) hour += 12;
        if (parts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;
        return {'hour': hour, 'minute': min};
      }
      final parts = s.split(':');
      if (parts.length == 2) {
        return {
          'hour':   int.parse(parts[0]),
          'minute': int.parse(parts[1]),
        };
      }
    } catch (e) {
      debugPrint('❌ _parseTime("$s"): $e');
    }
    return null;
  }

  /// Parse 'yyyy-MM-dd' or ISO8601 date string.
  DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty || s == 'Not set') return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      try {
        return DateFormat('yyyy-MM-dd').parse(s);
      } catch (_) {
        return null;
      }
    }
  }
}