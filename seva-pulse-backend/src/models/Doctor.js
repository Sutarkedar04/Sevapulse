// src/models/Doctor.js - Add bio field
const mongoose = require('mongoose');

const doctorSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  specialization: { type: String, required: true },
  qualifications: [{ degree: String, institution: String, year: Number }],
  experience: { type: Number, default: 0 },
  consultationFee: { type: Number, required: true },
  bio: { type: String, default: '' }, // ADD THIS FIELD
  availability: [{
    day: { type: String, enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'] },
    startTime: String,
    endTime: String,
    isAvailable: Boolean
  }],
  rating: { type: Number, min: 0, max: 5, default: 0 },
  department: { type: String, required: true },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Doctor', doctorSchema);