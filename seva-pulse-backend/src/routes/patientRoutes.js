// src/routes/patientRoutes.js
const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const Patient = require('../models/Patient');
const User = require('../models/User');

// IMPORTANT: This route must be BEFORE the /:id route to avoid conflicts
// Get patient by user ID - MUST be before /:id
router.get('/user/:userId', protect, async (req, res) => {
  try {
    console.log('📡 Fetching patient by user ID:', req.params.userId);
    
    const patient = await Patient.findOne({ user: req.params.userId })
      .populate('user', 'name email phone profilePicture address dateOfBirth gender');
    
    if (!patient) {
      return res.status(404).json({ success: false, message: 'Patient not found' });
    }
    
    res.status(200).json({ success: true, data: patient });
  } catch (error) {
    console.error('Error fetching patient by user ID:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// Get all patients
router.get('/', protect, async (req, res) => {
  try {
    const patients = await Patient.find().populate('user', 'name email phone profilePicture');
    res.status(200).json({ success: true, data: patients });
  } catch (error) {
    console.error('Error fetching patients:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// Get current patient profile
router.get('/me', protect, async (req, res) => {
  try {
    console.log('📡 Fetching current patient for user:', req.user.id);
    
    let patient = await Patient.findOne({ user: req.user.id })
      .populate('user', 'name email phone profilePicture address dateOfBirth gender');
    
    if (!patient) {
      // Create patient profile if it doesn't exist
      patient = await Patient.create({
        user: req.user.id,
        dateOfBirth: new Date('1990-01-01'),
        gender: 'Not specified'
      });
      
      const populatedPatient = await Patient.findById(patient._id)
        .populate('user', 'name email phone profilePicture address dateOfBirth gender');
      
      return res.status(200).json({ success: true, data: populatedPatient });
    }
    
    res.status(200).json({ success: true, data: patient });
  } catch (error) {
    console.error('Error fetching current patient:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// Get patient by ID (patient collection _id)
router.get('/:id', protect, async (req, res) => {
  try {
    console.log('📡 Fetching patient by ID:', req.params.id);
    
    const patient = await Patient.findById(req.params.id)
      .populate('user', 'name email phone profilePicture address dateOfBirth gender');
    
    if (!patient) {
      return res.status(404).json({ success: false, message: 'Patient not found' });
    }
    
    res.status(200).json({ success: true, data: patient });
  } catch (error) {
    console.error('Error fetching patient:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// Update current patient profile
router.put('/me', protect, async (req, res) => {
  try {
    console.log('📝 Updating patient profile for user:', req.user.id);
    
    let patient = await Patient.findOne({ user: req.user.id });
    
    if (!patient) {
      patient = await Patient.create({
        user: req.user.id,
        dateOfBirth: new Date('1990-01-01'),
        gender: 'Not specified'
      });
    }
    
    // Update patient fields
    if (req.body.dateOfBirth) patient.dateOfBirth = new Date(req.body.dateOfBirth);
    if (req.body.gender) patient.gender = req.body.gender;
    if (req.body.bloodGroup) patient.bloodGroup = req.body.bloodGroup;
    if (req.body.address) patient.address = req.body.address;
    if (req.body.emergencyContact) patient.emergencyContact = req.body.emergencyContact;
    if (req.body.allergies) patient.allergies = req.body.allergies;
    if (req.body.medicalHistory) patient.medicalHistory = req.body.medicalHistory;
    if (req.body.currentMedications) patient.currentMedications = req.body.currentMedications;
    
    await patient.save();
    
    // Update user fields
    const userUpdate = {};
    if (req.body.name) userUpdate.name = req.body.name;
    if (req.body.email) userUpdate.email = req.body.email;
    if (req.body.phone) userUpdate.phone = req.body.phone;
    
    if (Object.keys(userUpdate).length > 0) {
      await User.findByIdAndUpdate(req.user.id, userUpdate);
    }
    
    const updatedPatient = await Patient.findById(patient._id)
      .populate('user', 'name email phone profilePicture address dateOfBirth gender');
    
    res.status(200).json({ 
      success: true, 
      data: updatedPatient,
      message: 'Profile updated successfully'
    });
  } catch (error) {
    console.error('Error updating patient:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// Update patient by ID (for doctors/admin)
router.put('/:id', protect, async (req, res) => {
  try {
    const patient = await Patient.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    ).populate('user', 'name email phone');
    
    if (!patient) {
      return res.status(404).json({ success: false, message: 'Patient not found' });
    }
    
    res.status(200).json({ success: true, data: patient });
  } catch (error) {
    console.error('Error updating patient:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;