// src/models/Prescription.js
const mongoose = require('mongoose');

const prescriptionSchema = new mongoose.Schema({
  appointment: { type: mongoose.Schema.Types.ObjectId, ref: 'Appointment', required: false, default: null },
  doctor: { type: mongoose.Schema.Types.ObjectId, ref: 'Doctor', required: false, default: null },
  patient: { type: mongoose.Schema.Types.ObjectId, ref: 'Patient', required: true },
  doctorName: { type: String, default: '' }, // For patient-uploaded prescriptions
  medicines: [{ 
    name: { type: String, default: '' },
    dosage: { type: String, default: '' },
    frequency: { type: String, default: '' },
    duration: { type: String, default: '' },
    instructions: { type: String, default: '' }
  }],
  tests: [{ 
    name: { type: String, default: '' }, 
    instructions: { type: String, default: '' } 
  }],
  advice: { type: String, default: '' },
  followUpDate: { type: Date, default: null },
  imageUrl: { type: String, default: '' },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Prescription', prescriptionSchema);