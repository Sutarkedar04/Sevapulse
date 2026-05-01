// lib/presentation/screens/patient/my_medicine_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/medicine_provider.dart';
import '../../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION

class MyMedicineScreen extends StatefulWidget {
  const MyMedicineScreen({Key? key}) : super(key: key);

  @override
  State<MyMedicineScreen> createState() => _MyMedicineScreenState();
}

class _MyMedicineScreenState extends State<MyMedicineScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _nameController        = TextEditingController();
  final TextEditingController _dosageController      = TextEditingController();
  final TextEditingController _scheduleController    = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _startDateController   = TextEditingController();
  final TextEditingController _endDateController     = TextEditingController();

  List<TimeOfDay> _selectedTimes = [];
  final List<String> _scheduleOptions = [
    'Once a day',
    'Twice a day',
    'Three times a day',
    'Four times a day',
    'Custom',
  ];

  late AnimationController _streakAnimationController;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _streakAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final med  = Provider.of<MedicineProvider>(context, listen: false);
      if (auth.token != null) {
        med.setToken(auth.token!);
        med.loadMedicines();
      }
    });
  }

  @override
  void dispose() {
    _streakAnimationController.dispose();
    _nameController.dispose();
    _dosageController.dispose();
    _scheduleController.dispose();
    _instructionsController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  // ─── Stats ─────────────────────────────────────────────────────────────────

  Map<String, int> _getStats(List<Map<String, dynamic>> medicines) {
    int total = 0, completed = 0;
    for (final m in medicines) {
      final times = m['times'] as List? ?? [];
      final taken = m['taken'] as List? ?? [];
      total     += times.length;
      completed += taken.where((t) => t == true).length;
    }

    // Overall streak = minimum streak across all medicines (you missed one,
    // your streak is broken). Falls back to 0 if no medicines.
    final overallStreak = medicines.isEmpty
        ? 0
        : medicines
            .map((m) => (m['streak'] as int? ?? 0))
            .reduce((a, b) => a < b ? a : b);

    return {
      'total':     total,
      'completed': completed,
      'pending':   total - completed,
      'streak':    overallStreak,
    };
  }

  // ─── Streak Details Sheet ──────────────────────────────────────────────────

  void _showStreakDetails(Map<String, dynamic> medicine) async {
    _streakAnimationController.forward();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final streak = medicine['streak'] as int? ?? 0;
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.secondaryText.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Medicine name & dosage
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text(
                        medicine['name'] ?? 'Medicine',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: context.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${medicine['dosage']} • ${medicine['schedule']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Streak banner
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3498db), Color(0xFF2ecc71)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Colors.white, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        '$streak Day${streak == 1 ? '' : 's'} Streak!',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        streak > 0
                            ? 'Keep taking your medicine daily 💪'
                            : 'Take all doses today to start your streak!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Calendar header (dynamic month)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.primaryText,
                        ),
                      ),
                      Text(
                        'Streak Tracker',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Day-of-week headers
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                        .map((d) => Text(d,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: context.secondaryText)))
                        .toList(),
                  ),
                ),

                const SizedBox(height: 8),

                // Calendar grid
                Expanded(child: _buildMonthlyCalendar(medicine)),

                // Legend
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendDot(const Color(0xFF27ae60), 'All taken'),
                      const SizedBox(width: 16),
                      _legendDot(const Color(0xFFf39c12), 'Partial'),
                      const SizedBox(width: 16),
                      _legendDot(context.secondaryText.withOpacity(0.2), 'Missed'),
                    ],
                  ),
                ),

                // Close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
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
                      child: const Text('Close',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      _streakAnimationController.reset();
    });
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: context.secondaryText)),
      ],
    );
  }

  // ─── Calendar ──────────────────────────────────────────────────────────────

  Widget _buildMonthlyCalendar(Map<String, dynamic> medicine) {
    final now        = DateTime.now();
    final firstDay   = DateTime(now.year, now.month, 1);
    final daysInMonth= DateTime(now.year, now.month + 1, 0).day;
    // weekday: Mon=1 … Sun=7; we want Mon in column 0
    final firstOffset = (firstDay.weekday - 1); // 0-based

    // Build a lookup from 'YYYY-MM-DD' -> DayStatus
    final history =
        (medicine['doseHistory'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final Map<String, _DayStatus> statusMap = {};
    for (final record in history) {
      final date  = record['date'] as String? ?? '';
      final taken = (record['taken'] as List?)?.map((v) => v == true).toList() ?? [];
      if (date.isEmpty || taken.isEmpty) continue;
      final allTaken     = taken.every((t) => t);
      final anyTaken     = taken.any((t) => t);
      statusMap[date] = allTaken
          ? _DayStatus.full
          : anyTaken
              ? _DayStatus.partial
              : _DayStatus.none;
    }

    // Total cells = first offset + days in month, padded to a full grid
    final totalCells = firstOffset + daysInMonth;
    final gridCount  = (totalCells / 7).ceil() * 7;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: gridCount,
      itemBuilder: (context, index) {
        final dayNumber = index - firstOffset + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final date    = DateTime(now.year, now.month, dayNumber);
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final status  = statusMap[dateKey] ?? _DayStatus.none;
        final isToday = date.day == now.day;
        final isFuture= date.isAfter(now);

        Color bgColor;
        Widget? badge;
        if (isFuture) {
          bgColor = Colors.transparent;
        } else if (status == _DayStatus.full) {
          bgColor = const Color(0xFF27ae60).withOpacity(0.2);
          badge   = const Icon(Icons.check_circle, size: 10, color: Color(0xFF27ae60));
        } else if (status == _DayStatus.partial) {
          bgColor = const Color(0xFFf39c12).withOpacity(0.2);
          badge   = const Icon(Icons.radio_button_unchecked, size: 10, color: Color(0xFFf39c12));
        } else {
          // Past day with no doses taken (missed)
          bgColor = date.isBefore(DateTime(now.year, now.month, now.day))
              ? context.secondaryText.withOpacity(0.1)
              : Colors.transparent;
        }

        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            border: isToday
                ? Border.all(color: context.primaryColor, width: 2)
                : null,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayNumber.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: status == _DayStatus.full || isToday
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isFuture
                        ? context.secondaryText.withOpacity(0.5)
                        : status == _DayStatus.full
                            ? const Color(0xFF27ae60)
                            : context.primaryText,
                  ),
                ),
                if (badge != null) badge,
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Form helpers ──────────────────────────────────────────────────────────

  String _formatTimeOfDay(TimeOfDay tod) {
    final h  = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final m  = tod.minute.toString().padLeft(2, '0');
    final ap = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $ap';
  }

  void _updateTimesBasedOnSchedule(String schedule) {
    _selectedTimes.clear();
    switch (schedule) {
      case 'Once a day':
        _selectedTimes.add(const TimeOfDay(hour: 8, minute: 0));
        break;
      case 'Twice a day':
        _selectedTimes.addAll([
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ]);
        break;
      case 'Three times a day':
        _selectedTimes.addAll([
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 14, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ]);
        break;
      case 'Four times a day':
        _selectedTimes.addAll([
          const TimeOfDay(hour: 6, minute: 0),
          const TimeOfDay(hour: 12, minute: 0),
          const TimeOfDay(hour: 18, minute: 0),
          const TimeOfDay(hour: 22, minute: 0),
        ]);
        break;
    }
  }

  Future<void> _selectDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ctrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  // ─── Add / Edit ────────────────────────────────────────────────────────────

  void _addMedicine() {
    _nameController.clear();
    _dosageController.clear();
    _scheduleController.clear();
    _instructionsController.clear();
    _startDateController.clear();
    _endDateController.clear();
    setState(() => _selectedTimes = []);
    _showMedicineDialog(isEditing: false);
  }

  void _editMedicine(Map<String, dynamic> medicine, int index) {
    _nameController.text        = medicine['name'] ?? '';
    _dosageController.text      = medicine['dosage'] ?? '';
    _scheduleController.text    = medicine['schedule'] ?? '';
    _instructionsController.text= medicine['instructions'] ?? '';
    _startDateController.text   = medicine['startDate'] == 'Not set' ? '' : (medicine['startDate'] ?? '');
    _endDateController.text     = medicine['endDate']   == 'Not set' ? '' : (medicine['endDate']   ?? '');

    _selectedTimes = (medicine['times'] as List<String>? ?? []).map((s) {
      final parts   = s.split(' ');
      final hm      = parts[0].split(':');
      final isPM    = parts.length > 1 && parts[1] == 'PM';
      int hour = int.parse(hm[0]);
      if (isPM  && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: int.parse(hm[1]));
    }).toList();

    _showMedicineDialog(
        isEditing: true, medicineId: medicine['id'], index: index);
  }

  Future<void> _showMedicineDialog(
      {bool isEditing = false, String? medicineId, int? index}) async {
    String? currentSchedule =
        _scheduleController.text.isEmpty ? null : _scheduleController.text;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Medicine' : 'Add New Medicine', style: TextStyle(color: context.primaryText)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Medicine Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dosage
                  TextField(
                    controller: _dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosage (e.g. 500mg)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Schedule dropdown
                  DropdownButtonFormField<String>(
                    value: currentSchedule,
                    decoration: const InputDecoration(
                      labelText: 'Schedule',
                      border: OutlineInputBorder(),
                    ),
                    items: _scheduleOptions
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        currentSchedule = value;
                        _scheduleController.text = value;
                        _updateTimesBasedOnSchedule(value);
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Instructions
                  TextField(
                    controller: _instructionsController,
                    decoration: const InputDecoration(
                      labelText: 'Instructions (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Date row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _startDateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            border: OutlineInputBorder(),
                          ),
                          onTap: () => _selectDate(_startDateController),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _endDateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'End Date',
                            border: OutlineInputBorder(),
                          ),
                          onTap: () => _selectDate(_endDateController),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dose times
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Dose Times',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16, color: context.primaryText)),
                      IconButton(
                        icon: Icon(Icons.add_circle,
                            color: context.primaryColor, size: 30),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              _selectedTimes.add(picked);
                              _selectedTimes.sort((a, b) =>
                                  (a.hour * 60 + a.minute)
                                      .compareTo(b.hour * 60 + b.minute));
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (_selectedTimes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('Tap + to add dose times.',
                          style: TextStyle(color: context.secondaryText)),
                    )
                  else
                    ..._selectedTimes.asMap().entries.map((e) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time,
                                color: context.primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(_formatTimeOfDay(e.value),
                                  style: TextStyle(fontSize: 16, color: context.primaryText)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => setDialogState(
                                  () => _selectedTimes.removeAt(e.key)),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: context.secondaryText)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27ae60),
                ),
                onPressed: () async {
                  if (_nameController.text.trim().isEmpty) {
                    _showSnackBar('Please enter medicine name', Colors.red);
                    return;
                  }
                  if (_dosageController.text.trim().isEmpty) {
                    _showSnackBar('Please enter dosage', Colors.red);
                    return;
                  }
                  if (_selectedTimes.isEmpty) {
                    _showSnackBar(
                        'Please add at least one dose time', Colors.red);
                    return;
                  }

                  Navigator.pop(context);

                  final provider =
                      Provider.of<MedicineProvider>(context, listen: false);
                  final data = {
                    'name':         _nameController.text.trim(),
                    'dosage':       _dosageController.text.trim(),
                    'schedule':     _scheduleController.text.isNotEmpty
                        ? _scheduleController.text
                        : 'Custom',
                    'times':        _selectedTimes.map(_formatTimeOfDay).toList(),
                    'startDate':    _startDateController.text.isEmpty
                        ? 'Not set'
                        : _startDateController.text,
                    'endDate':      _endDateController.text.isEmpty
                        ? 'Not set'
                        : _endDateController.text,
                    'instructions': _instructionsController.text.isEmpty
                        ? 'No special instructions'
                        : _instructionsController.text.trim(),
                    'remaining':    _calcRemaining(
                        _startDateController.text, _endDateController.text),
                  };

                  final success = isEditing && medicineId != null
                      ? await provider.updateMedicine(medicineId, data)
                      : await provider.addMedicine(data);

                  if (mounted) {
                    _showSnackBar(
                      success
                          ? (isEditing
                              ? 'Medicine updated successfully'
                              : 'Medicine added successfully')
                          : (provider.error ?? 'Failed to save medicine'),
                      success ? Colors.green : Colors.red,
                    );
                  }
                },
                child: Text(isEditing ? 'Update' : 'Add',
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _calcRemaining(String start, String end) {
    if (end.isEmpty || end == 'Not set') return 'Ongoing';
    try {
      final diff = DateTime.parse(end).difference(DateTime.now()).inDays;
      if (diff < 0) return 'Completed';
      if (diff == 0) return 'Last day';
      return '$diff days left';
    } catch (_) {
      return 'Ongoing';
    }
  }

  void _toggleDose(String id, int doseIndex) async {
    final provider = Provider.of<MedicineProvider>(context, listen: false);
    final ok = await provider.toggleDose(id, doseIndex);
    if (!ok && mounted) {
      _showSnackBar(provider.error ?? 'Failed to update dose', Colors.red);
    }
  }

  void _deleteMedicine(String id) {
    if (id.isEmpty) {
      _showSnackBar('Cannot delete: Invalid medicine ID', Colors.red);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Medicine', style: TextStyle(color: context.primaryText)),
        content: Text('Are you sure you want to delete this medicine?', style: TextStyle(color: context.secondaryText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: context.primaryColor)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider =
                  Provider.of<MedicineProvider>(context, listen: false);
              final ok = await provider.deleteMedicine(id);
              if (mounted) {
                _showSnackBar(
                  ok
                      ? 'Medicine deleted successfully'
                      : (provider.error ?? 'Failed to delete medicine'),
                  ok ? Colors.green : Colors.red,
                );
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Consumer<MedicineProvider>(
        builder: (context, provider, _) {
          final medicines = provider.medicines;
          final stats     = _getStats(medicines);

          return Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3498db), Color(0xFF2980b9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.medical_services,
                                color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Text(
                              'My Medicine',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add,
                                color: Colors.white, size: 28),
                            onPressed: _addMedicine,
                            tooltip: 'Add Medicine',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem('Total Doses',
                            stats['total'].toString(), Icons.medication),
                        _statItem('Completed',
                            stats['completed'].toString(), Icons.check_circle),
                        _statItem('Pending',
                            stats['pending'].toString(), Icons.schedule),
                        _statItem('Streak',
                            '${stats['streak']}🔥', Icons.local_fire_department),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Body ────────────────────────────────────────────────────
              Expanded(
                child: provider.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
                        ),
                      )
                    : medicines.isEmpty
                        ? _emptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: medicines.length,
                            itemBuilder: (_, i) =>
                                _buildMedicineCard(medicines[i], i),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication, size: 80, color: context.secondaryText.withOpacity(0.4)),
          const SizedBox(height: 20),
          Text('No medicines added yet',
              style: TextStyle(fontSize: 18, color: context.secondaryText)),
          const SizedBox(height: 12),
          Text('Tap the + button to add your first medicine',
              style: TextStyle(fontSize: 14, color: context.secondaryText.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _statItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text(title,
            style: TextStyle(
                fontSize: 11, color: Colors.white.withOpacity(0.9))),
      ],
    );
  }

  // ─── Medicine Card ─────────────────────────────────────────────────────────

  Widget _buildMedicineCard(Map<String, dynamic> medicine, int index) {
    final times     = List<String>.from(medicine['times'] ?? []);
    final taken     = List<bool>.from(medicine['taken'] ?? []);
    final allTaken  = taken.isNotEmpty && taken.every((t) => t);
    final id        = medicine['id']?.toString() ?? '';
    final streak    = medicine['streak'] as int? ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      color: context.cardColor,
      child: InkWell(
        onTap: () => _showStreakDetails(medicine),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine['name'] ?? 'Unknown Medicine',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.primaryText),
                        ),
                        Text(
                          '${medicine['dosage'] ?? ''} • ${medicine['schedule'] ?? ''}',
                          style: TextStyle(color: context.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  // Streak badge
                  if (streak > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFe67e22).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department,
                              size: 14, color: Color(0xFFe67e22)),
                          const SizedBox(width: 4),
                          Text(
                            '$streak day${streak == 1 ? '' : 's'}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFe67e22)),
                          ),
                        ],
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: context.secondaryText),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'edit', child: Text('Edit Medicine')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                    onSelected: (v) {
                      if (v == 'edit') _editMedicine(medicine, index);
                      if (v == 'delete') _deleteMedicine(id);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Status chip + instructions
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: allTaken
                          ? const Color(0xFF27ae60).withOpacity(0.1)
                          : context.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      medicine['remaining'] ?? 'Ongoing',
                      style: TextStyle(
                        color: allTaken
                            ? const Color(0xFF27ae60)
                            : context.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      medicine['instructions'] ?? '',
                      style: TextStyle(
                          fontSize: 12,
                          color: context.secondaryText,
                          fontStyle: FontStyle.italic),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Dose rows with checkboxes
              ...times.asMap().entries.map((e) {
                final di      = e.key;
                final time    = e.value;
                final isTaken = di < taken.length ? taken[di] : false;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isTaken
                          ? const Color(0xFF27ae60).withOpacity(0.3)
                          : context.secondaryText.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isTaken,
                        onChanged: (_) => _toggleDose(id, di),
                        activeColor: const Color(0xFF27ae60),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          time,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isTaken
                                ? const Color(0xFF27ae60)
                                : context.primaryText,
                            decoration: isTaken
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isTaken
                              ? const Color(0xFF27ae60).withOpacity(0.1)
                              : context.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isTaken ? 'Taken' : 'Pending',
                          style: TextStyle(
                            color: isTaken
                                ? const Color(0xFF27ae60)
                                : context.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 8),

              // Course dates + streak link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Course: ${medicine['startDate'] ?? 'Not set'}'
                    ' → ${medicine['endDate'] ?? 'Not set'}',
                    style: TextStyle(
                        fontSize: 12, color: context.secondaryText),
                  ),
                  TextButton(
                    onPressed: () => _showStreakDetails(medicine),
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0)),
                    child: Text(
                      'View Streak →',
                      style: TextStyle(
                          fontSize: 12,
                          color: context.primaryColor,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Private enum ──────────────────────────────────────────────────────────────

enum _DayStatus { none, partial, full }