// src/models/Patient.js
const mongoose = require('mongoose');

const patientSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  dateOfBirth: { type: Date, default: null },
  gender: { type: String, enum: ['Male', 'Female', 'Other', 'Not specified'], default: 'Not specified' },
  bloodGroup: { type: String, default: '' },
  emergencyContact: {
    name: { type: String, default: '' },
    relationship: { type: String, default: '' },
    phone: { type: String, default: '' }
  },
  address: {
    street: { type: String, default: '' },
    city: { type: String, default: '' },
    state: { type: String, default: '' },
    zipCode: { type: String, default: '' }
  },
  medicalHistory: [{
    condition: { type: String, default: '' },
    diagnosedDate: { type: Date, default: null },
    notes: { type: String, default: '' }
  }],
  allergies: [{ type: String }],
  currentMedications: [{
    name: { type: String, default: '' },
    dosage: { type: String, default: '' },
    frequency: { type: String, default: '' }
  }],
  surgeries: [{ type: String }],  // ✅ ADD THIS
  familyHistory: [{ type: String }],  // ✅ ADD THIS
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Patient', patientSchema);