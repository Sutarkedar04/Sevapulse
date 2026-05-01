// src/controllers/medicineController.js
const Medicine = require('../models/Medicine');

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** Returns today's date string as 'YYYY-MM-DD' (server local date). */
function todayStr() {
  return new Date().toISOString().slice(0, 10);
}

/**
 * Given a medicine document, calculate the current consecutive-day streak.
 * A day counts toward the streak only if ALL doses were taken that day.
 */
function calculateStreak(medicine) {
  if (!medicine.doseHistory || medicine.doseHistory.length === 0) return 0;

  // Sort history descending so we walk backwards from most recent day
  const sorted = [...medicine.doseHistory].sort((a, b) =>
    b.date.localeCompare(a.date)
  );

  const today = todayStr();
  let streak = 0;
  let expectedDate = today;

  for (const record of sorted) {
    // Skip future dates (shouldn't exist, but just in case)
    if (record.date > today) continue;

    // If there's a gap in days, streak is broken
    if (record.date !== expectedDate) break;

    const allTaken =
      record.taken.length > 0 && record.taken.every(Boolean);

    if (allTaken) {
      streak++;
      // Move expected date one day back
      const d = new Date(expectedDate);
      d.setDate(d.getDate() - 1);
      expectedDate = d.toISOString().slice(0, 10);
    } else {
      // Today's doses are partially done — still counts if it's today
      if (record.date === today) {
        // Don't increment streak for today (not fully done yet), just continue
      } else {
        break; // Past day with incomplete doses breaks the streak
      }
    }
  }

  return streak;
}

/**
 * Serialize a medicine document for the API response.
 * Includes today's `taken` state, full `doseHistory`, and calculated `streak`.
 */
function serializeMedicine(medicine) {
  const obj = medicine.toObject({ virtuals: true });
  return {
    _id:          obj._id,
    name:         obj.name,
    dosage:       obj.dosage,
    schedule:     obj.schedule,
    times:        obj.times,
    taken:        obj.taken,           // today's snapshot via virtual
    doseHistory:  obj.doseHistory,     // full history for calendar/streak
    streak:       calculateStreak(medicine),
    startDate:    obj.startDate,
    endDate:      obj.endDate,
    instructions: obj.instructions,
    remaining:    obj.remaining,
    createdAt:    obj.createdAt,
  };
}

// ─── Controllers ─────────────────────────────────────────────────────────────

exports.getMedicines = async (req, res, next) => {
  try {
    console.log('Fetching medicines for user:', req.user.id);
    const medicines = await Medicine.find({ user: req.user.id });
    console.log('Found medicines:', medicines.length);
    res.status(200).json({
      success: true,
      data: medicines.map(serializeMedicine),
    });
  } catch (error) {
    console.error('Error in getMedicines:', error);
    next(error);
  }
};

exports.createMedicine = async (req, res, next) => {
  try {
    console.log('Creating medicine for user:', req.user.id);
    const { name, dosage, schedule, times = [], startDate, endDate, instructions, remaining } = req.body;

    const medicine = await Medicine.create({
      user:         req.user.id,
      name,
      dosage,
      schedule,
      times,
      startDate:    startDate    || 'Not set',
      endDate:      endDate      || 'Not set',
      instructions: instructions || 'No special instructions',
      remaining:    remaining    || 'Ongoing',
      doseHistory:  [], // fresh medicine, no history yet
    });

    console.log('Medicine created with ID:', medicine._id);
    res.status(201).json({ success: true, data: serializeMedicine(medicine) });
  } catch (error) {
    console.error('Error in createMedicine:', error);
    next(error);
  }
};

exports.updateMedicine = async (req, res, next) => {
  try {
    console.log('Updating medicine ID:', req.params.id);

    // Prevent overwriting doseHistory via a bulk update
    const { doseHistory, taken, ...safeFields } = req.body;

    const medicine = await Medicine.findOneAndUpdate(
      { _id: req.params.id, user: req.user.id },
      { $set: safeFields },
      { new: true }
    );

    if (!medicine) {
      return res.status(404).json({ success: false, message: 'Medicine not found' });
    }

    res.status(200).json({ success: true, data: serializeMedicine(medicine) });
  } catch (error) {
    console.error('Error in updateMedicine:', error);
    next(error);
  }
};

exports.deleteMedicine = async (req, res, next) => {
  try {
    console.log('Deleting medicine ID:', req.params.id, 'for user:', req.user.id);

    const medicine = await Medicine.findOne({ _id: req.params.id, user: req.user.id });

    if (!medicine) {
      return res.status(404).json({ success: false, message: 'Medicine not found' });
    }

    await Medicine.findByIdAndDelete(req.params.id);
    console.log('Medicine deleted successfully:', req.params.id);

    res.status(200).json({ success: true, message: 'Medicine deleted' });
  } catch (error) {
    console.error('Error in deleteMedicine:', error);
    next(error);
  }
};

/**
 * Toggle a specific dose for TODAY.
 * Updates (or creates) the doseHistory entry for today's date.
 */
exports.toggleDose = async (req, res, next) => {
  try {
    const { id, doseIndex: doseIndexStr } = req.params;
    const doseIndex = parseInt(doseIndexStr, 10);
    console.log(`Toggling dose ${doseIndex} for medicine ${id}`);

    const medicine = await Medicine.findOne({ _id: id, user: req.user.id });
    if (!medicine) {
      return res.status(404).json({ success: false, message: 'Medicine not found' });
    }

    if (doseIndex < 0 || doseIndex >= medicine.times.length) {
      return res.status(400).json({ success: false, message: 'Invalid dose index' });
    }

    const today = todayStr();

    // Find or create today's history entry
    let record = medicine.doseHistory.find(h => h.date === today);
    if (!record) {
      // Initialise all doses to false for today
      medicine.doseHistory.push({
        date:  today,
        taken: Array(medicine.times.length).fill(false),
      });
      record = medicine.doseHistory[medicine.doseHistory.length - 1];
    }

    // Ensure the taken array is long enough (times may have changed after an edit)
    while (record.taken.length < medicine.times.length) {
      record.taken.push(false);
    }

    record.taken[doseIndex] = !record.taken[doseIndex];

    medicine.markModified('doseHistory');
    await medicine.save();

    console.log(
      `Dose ${doseIndex} for ${today} is now: ${record.taken[doseIndex]}`
    );

    res.status(200).json({ success: true, data: serializeMedicine(medicine) });
  } catch (error) {
    console.error('Error in toggleDose:', error);
    next(error);
  }
};