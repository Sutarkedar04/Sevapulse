// src/controllers/patientController.js
const Patient = require('../models/Patient');
const User = require('../models/User');

// Get patient by ID - MODIFIED to handle both Patient _id and User ID
exports.getPatient = async (req, res, next) => {
  try {
    const { id } = req.params;
    console.log('📡 Fetching patient with identifier:', id);
    
    let patient;
    
    // First try to find by Patient _id
    patient = await Patient.findById(id).populate('user', 'name email phone profilePicture address dateOfBirth gender');
    
    // If not found, try to find by User ID
    if (!patient) {
      patient = await Patient.findOne({ user: id }).populate('user', 'name email phone profilePicture address dateOfBirth gender');
      console.log('📡 Found patient by User ID:', patient ? patient._id : 'Not found');
    }
    
    if (!patient) {
      return res.status(404).json({ success: false, message: 'Patient not found' });
    }
    
    res.status(200).json({ success: true, data: patient });
  } catch (error) {
    console.error('Error in getPatient:', error);
    next(error);
  }
};

// Get all patients
exports.getPatients = async (req, res, next) => {
  try {
    const patients = await Patient.find().populate('user', 'name email phone profilePicture');
    res.status(200).json({ success: true, count: patients.length, data: patients });
  } catch (error) {
    next(error);
  }
};

// Get current patient (by authenticated user)
exports.getCurrentPatient = async (req, res, next) => {
  try {
    console.log('Getting current patient for user:', req.user.id);
    
    let patient = await Patient.findOne({ user: req.user.id }).populate('user', 'name email phone profilePicture address dateOfBirth gender');
    
    if (!patient) {
      console.log('Creating new patient profile for user:', req.user.id);
      patient = await Patient.create({
        user: req.user.id,
        dateOfBirth: new Date('1990-01-01'),
        gender: 'Not specified'
      });
      
      const populatedPatient = await Patient.findById(patient._id)
        .populate('user', 'name email phone profilePicture address dateOfBirth gender');
      
      return res.status(200).json({ 
        success: true, 
        data: populatedPatient
      });
    }
    
    res.status(200).json({ success: true, data: patient });
  } catch (error) {
    console.error('Error in getCurrentPatient:', error);
    next(error);
  }
};

// Update patient
exports.updatePatient = async (req, res, next) => {
  try {
    console.log('========================================');
    console.log('📝 Updating patient profile');
    console.log('Request params:', req.params);
    console.log('User ID:', req.user.id);
    console.log('Request body:', req.body);
    console.log('========================================');
    
    let patient;
    
    // If updating by ID from params
    if (req.params.id) {
      patient = await Patient.findById(req.params.id);
    }
    
    // Otherwise find by current user
    if (!patient) {
      patient = await Patient.findOne({ user: req.user.id });
    }
    
    if (!patient) {
      patient = await Patient.create({
        user: req.user.id,
        dateOfBirth: new Date('1990-01-01'),
        gender: 'Not specified'
      });
    }
    
    // Update patient fields
    if (req.body.dateOfBirth && req.body.dateOfBirth != 'Not set') {
      patient.dateOfBirth = new Date(req.body.dateOfBirth);
    }
    if (req.body.gender && req.body.gender != 'Not set') {
      patient.gender = req.body.gender;
    }
    if (req.body.bloodGroup && req.body.bloodGroup != 'Not set') {
      patient.bloodGroup = req.body.bloodGroup;
    }
    if (req.body.address) {
      patient.address = {
        ...patient.address,
        ...req.body.address
      };
    }
    if (req.body.allergies) {
      patient.allergies = req.body.allergies;
    }
    if (req.body.medicalHistory) {
      patient.medicalHistory = req.body.medicalHistory;
    }
    if (req.body.currentMedications) {
      patient.currentMedications = req.body.currentMedications;
    }
    
    await patient.save();
    console.log('✅ Patient updated successfully');
    
    // Update user fields if provided
    const userUpdate = {};
    if (req.body.name && req.body.name != 'Not set') userUpdate.name = req.body.name;
    if (req.body.email && req.body.email != 'Not set') userUpdate.email = req.body.email;
    if (req.body.phone && req.body.phone != 'Not set') userUpdate.phone = req.body.phone;
    
    if (Object.keys(userUpdate).length > 0) {
      await User.findByIdAndUpdate(req.user.id, userUpdate);
      console.log('✅ User updated successfully');
    }
    
    const updatedPatient = await Patient.findById(patient._id)
      .populate('user', 'name email phone profilePicture address dateOfBirth gender');
    
    res.status(200).json({ 
      success: true, 
      data: updatedPatient,
      message: 'Profile updated successfully'
    });
  } catch (error) {
    console.error('❌ Error in updatePatient:', error);
    next(error);
  }
};