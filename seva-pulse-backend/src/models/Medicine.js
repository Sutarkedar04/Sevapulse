// src/models/Medicine.js
const mongoose = require('mongoose');

// Each entry records which doses were taken on a specific date
const doseHistorySchema = new mongoose.Schema({
  date: { type: String, required: true }, // 'YYYY-MM-DD'
  taken: [{ type: Boolean, default: false }], // one entry per dose time
}, { _id: false });

const medicineSchema = new mongoose.Schema({
  user:         { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name:         { type: String, required: true },
  dosage:       { type: String, required: true },
  schedule:     { type: String, required: true },
  times:        [{ type: String }],           // e.g. ['8:00 AM', '8:00 PM']
  startDate:    { type: String, default: 'Not set' },
  endDate:      { type: String, default: 'Not set' },
  remaining:    { type: String, default: 'Ongoing' },
  instructions: { type: String, default: 'No special instructions' },

  // ✅ Date-keyed history replaces the single flat `taken` array.
  // This makes real streak calculation possible.
  doseHistory:  [doseHistorySchema],          // ordered list, one doc per calendar day

  createdAt:    { type: Date, default: Date.now },
});

// ─── Virtual: today's taken array ────────────────────────────────────────────
medicineSchema.virtual('taken').get(function () {
  const today = new Date().toISOString().slice(0, 10);
  const record = this.doseHistory.find(h => h.date === today);
  // Return a fresh all-false array if today has no record yet
  return record ? record.taken : Array(this.times.length).fill(false);
});

medicineSchema.set('toJSON', { virtuals: true });
medicineSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Medicine', medicineSchema);