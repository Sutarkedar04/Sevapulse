// src/models/HealthCamp.js
const mongoose = require('mongoose');

const healthCampSchema = new mongoose.Schema({
  title: { type: String, required: true },
  organization: { type: String, required: true, default: 'Seva Pulse Hospital' },
  date: { type: Date, required: true },
  endDate: { type: Date },
  time: { type: String, required: true },
  location: { type: String, required: true },
  description: { type: String, required: true },
  imageUrl: { type: String, default: '' },
  availableSlots: { type: Number, required: true, min: 1 },
  registeredParticipants: { type: Number, default: 0 },
  participants: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }], // ✅ REQUIRED
  services: [{ type: String }],
  contact: { type: String, required: true },
  isFree: { type: Boolean, default: true },
  fee: { type: Number, default: null },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('HealthCamp', healthCampSchema);