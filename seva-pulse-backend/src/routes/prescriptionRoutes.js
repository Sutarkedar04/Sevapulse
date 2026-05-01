// src/routes/prescriptionRoutes.js
const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { protect } = require('../middleware/auth');
const Prescription = require('../models/Prescription');
const Patient = require('../models/Patient');
const Doctor = require('../models/Doctor');
const Appointment = require('../models/Appointment');

// Configure multer for prescription image uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'uploads/prescriptions/';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'prescription-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ 
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    if (extname && mimetype) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  }
});

// ==================== HELPER FUNCTIONS ====================

// Get patient ID from authenticated user
async function getPatientIdFromUser(userId) {
  const patient = await Patient.findOne({ user: userId });
  if (!patient) {
    throw new Error('Patient profile not found');
  }
  return patient._id;
}

// ==================== CONTROLLER FUNCTIONS ====================

// Get all prescriptions (admin only)
const getPrescriptions = async (req, res, next) => {
  try {
    const prescriptions = await Prescription.find()
      .populate({
        path: 'doctor',
        populate: { path: 'user', select: 'name email specialization' }
      })
      .populate({
        path: 'patient',
        populate: { path: 'user', select: 'name email' }
      })
      .populate('appointment')
      .sort({ createdAt: -1 });
    
    res.status(200).json({ 
      success: true, 
      count: prescriptions.length, 
      data: prescriptions 
    });
  } catch (error) {
    console.error('Error in getPrescriptions:', error);
    next(error);
  }
};

// Get current user's prescriptions (for patient view)
const getMyPrescriptions = async (req, res, next) => {
  try {
    console.log('📋 Fetching my prescriptions for user:', req.user.id);
    
    const patient = await Patient.findOne({ user: req.user.id });
    
    if (!patient) {
      console.log('⚠️ No patient profile found for user:', req.user.id);
      return res.status(200).json({ success: true, data: [] });
    }
    
    const prescriptions = await Prescription.find({ patient: patient._id })
      .populate({
        path: 'doctor',
        populate: { path: 'user', select: 'name email specialization' }
      })
      .populate({
        path: 'patient',
        populate: { path: 'user', select: 'name email' }
      })
      .populate('appointment')
      .sort({ createdAt: -1 });
    
    console.log(`✅ Found ${prescriptions.length} prescriptions for patient`);
    
    res.status(200).json({ 
      success: true, 
      data: prescriptions 
    });
  } catch (error) {
    console.error('Error in getMyPrescriptions:', error);
    next(error);
  }
};

// Get prescriptions by patient ID (for doctors)
const getPrescriptionsByPatient = async (req, res, next) => {
  try {
    const { patientId } = req.params;
    console.log('📋 Fetching prescriptions for patient ID:', patientId);
    
    const prescriptions = await Prescription.find({ patient: patientId })
      .populate({
        path: 'doctor',
        populate: { path: 'user', select: 'name email specialization' }
      })
      .populate({
        path: 'patient',
        populate: { path: 'user', select: 'name email' }
      })
      .populate('appointment')
      .sort({ createdAt: -1 });
    
    console.log(`✅ Found ${prescriptions.length} prescriptions`);
    
    res.status(200).json({ 
      success: true, 
      data: prescriptions 
    });
  } catch (error) {
    console.error('Error in getPrescriptionsByPatient:', error);
    next(error);
  }
};

// Create prescription from doctor (requires appointment, doctor, patient)
const createPrescription = async (req, res, next) => {
  try {
    console.log('📝 Creating new prescription from doctor');
    console.log('Request body:', req.body);
    
    // Validate required fields for doctor-created prescriptions
    if (!req.body.doctor || !req.body.patient) {
      return res.status(400).json({ 
        success: false, 
        message: 'Doctor and patient are required for doctor-created prescriptions' 
      });
    }
    
    const prescription = await Prescription.create({
      ...req.body,
      createdAt: new Date()
    });
    
    const populatedPrescription = await Prescription.findById(prescription._id)
      .populate({
        path: 'doctor',
        populate: { path: 'user', select: 'name email specialization' }
      })
      .populate({
        path: 'patient',
        populate: { path: 'user', select: 'name email' }
      })
      .populate('appointment');
    
    console.log('✅ Prescription created successfully:', prescription._id);
    
    res.status(201).json({ 
      success: true, 
      data: populatedPrescription 
    });
  } catch (error) {
    console.error('Error in createPrescription:', error);
    next(error);
  }
};

// ✅ Patient upload prescription (with image + data, no appointment/doctor required)
const patientUploadPrescription = async (req, res, next) => {
  try {
    console.log('📝 Patient uploading prescription');
    
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'No file uploaded' });
    }
    
    // Get patient ID from authenticated user
    const patient = await Patient.findOne({ user: req.user.id });
    if (!patient) {
      return res.status(404).json({ success: false, message: 'Patient profile not found' });
    }
    
    const imageUrl = `${req.protocol}://${req.get('host')}/uploads/prescriptions/${req.file.filename}`;
    
    // Parse prescription data from form-data
    let prescriptionData = {};
    if (req.body.data) {
      try {
        prescriptionData = JSON.parse(req.body.data);
      } catch (e) {
        prescriptionData = req.body;
      }
    }
    
    console.log('Prescription data:', prescriptionData);
    
    // Create prescription without requiring appointment/doctor IDs
    const prescription = await Prescription.create({
      patient: patient._id,
      medicines: prescriptionData.medicines || [],
      tests: prescriptionData.tests || [],
      advice: prescriptionData.advice || '',
      followUpDate: prescriptionData.followUpDate ? new Date(prescriptionData.followUpDate) : null,
      imageUrl: imageUrl,
      doctorName: prescriptionData.doctorName || 'Unknown Doctor',
      createdAt: new Date()
    });
    
    // Populate the prescription before returning
    const populatedPrescription = await Prescription.findById(prescription._id)
      .populate({
        path: 'patient',
        populate: { path: 'user', select: 'name email' }
      });
    
    console.log('✅ Patient prescription created successfully:', prescription._id);
    
    res.status(201).json({ 
      success: true, 
      data: populatedPrescription 
    });
  } catch (error) {
    console.error('Error in patientUploadPrescription:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// Update prescription
const updatePrescription = async (req, res, next) => {
  try {
    const { id } = req.params;
    console.log('📝 Updating prescription:', id);
    
    const prescription = await Prescription.findByIdAndUpdate(
      id,
      { ...req.body, updatedAt: new Date() },
      { new: true, runValidators: true }
    )
    .populate({
      path: 'doctor',
      populate: { path: 'user', select: 'name email specialization' }
    })
    .populate({
      path: 'patient',
      populate: { path: 'user', select: 'name email' }
    })
    .populate('appointment');
    
    if (!prescription) {
      return res.status(404).json({ 
        success: false, 
        message: 'Prescription not found' 
      });
    }
    
    console.log('✅ Prescription updated successfully');
    
    res.status(200).json({ 
      success: true, 
      data: prescription 
    });
  } catch (error) {
    console.error('Error in updatePrescription:', error);
    next(error);
  }
};

// Delete prescription
const deletePrescription = async (req, res, next) => {
  try {
    const { id } = req.params;
    console.log('🗑️ Deleting prescription:', id);
    
    const prescription = await Prescription.findByIdAndDelete(id);
    
    if (!prescription) {
      return res.status(404).json({ 
        success: false, 
        message: 'Prescription not found' 
      });
    }
    
    console.log('✅ Prescription deleted successfully');
    
    res.status(200).json({ 
      success: true, 
      message: 'Prescription deleted successfully' 
    });
  } catch (error) {
    console.error('Error in deletePrescription:', error);
    next(error);
  }
};

// Upload prescription image (standalone)
const uploadPrescriptionImage = async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ 
        success: false, 
        message: 'No file uploaded' 
      });
    }
    
    const imageUrl = `${req.protocol}://${req.get('host')}/uploads/prescriptions/${req.file.filename}`;
    
    console.log('✅ Image uploaded:', imageUrl);
    
    res.status(200).json({ 
      success: true, 
      imageUrl: imageUrl 
    });
  } catch (error) {
    console.error('Error in uploadPrescriptionImage:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
};
// Add this after your existing routes in prescriptionRoutes.js

// Helper to send prescription notification
async function sendPrescriptionNotification(prescription, patientId, doctorName, io) {
  try {
    const patient = await Patient.findById(prescription.patient).populate('user');
    if (!patient) return null;
    
    const notificationData = {
      title: '📋 New Prescription Available',
      message: `Dr. ${doctorName} has sent you a prescription. Please check your prescriptions section.`,
      type: 'PRESCRIPTION_CREATED',
      prescriptionId: prescription._id,
      prescriptionData: {
        doctorName: doctorName,
        medicines: prescription.medicines,
        advice: prescription.advice,
        imageUrls: prescription.imageUrls,
        createdAt: prescription.createdAt
      },
      recipients: [patient.user._id],
      createdAt: new Date()
    };
    
    const notification = await Notification.create(notificationData);
    
    if (io) {
      io.to(`patient_${patient.user._id}`).emit('notification', {
        id: notification._id,
        title: notification.title,
        message: notification.message,
        type: notification.type,
        prescriptionData: notificationData.prescriptionData,
        createdAt: notification.createdAt
      });
      console.log(`📡 Prescription notification sent to patient ${patient.user._id}`);
    }
    
    return notification;
  } catch (error) {
    console.error('Error sending prescription notification:', error);
    return null;
  }
}


// ==================== ROUTES ====================
// Doctor creates prescription and completes appointment
router.post('/doctor-create', protect, upload.array('images', 5), async (req, res) => {
  try {
    console.log('📝 Doctor creating prescription with images');
    console.log('Request body:', req.body);
    console.log('Files:', req.files?.length || 0);
    
    const { appointmentId, patientId, medicines, advice, notes } = req.body;
    const doctor = await Doctor.findOne({ user: req.user.id }).populate('user');
    
    if (!doctor) {
      return res.status(404).json({ success: false, message: 'Doctor not found' });
    }
    
    // Save uploaded images
    const imageUrls = [];
    if (req.files && req.files.length > 0) {
      for (const file of req.files) {
        const imageUrl = `${req.protocol}://${req.get('host')}/uploads/prescriptions/${file.filename}`;
        imageUrls.push(imageUrl);
        console.log('Saved image:', imageUrl);
      }
    }
    
    // Parse medicines from JSON string
    let medicinesList = [];
    if (medicines) {
      try {
        medicinesList = JSON.parse(medicines);
        console.log('Parsed medicines:', medicinesList);
      } catch (e) {
        console.log('Error parsing medicines:', e);
        medicinesList = [];
      }
    }
    
    // Create prescription
    const prescription = await Prescription.create({
      appointment: appointmentId,
      doctor: doctor._id,
      patient: patientId,
      medicines: medicinesList,
      advice: advice || '',
      notes: notes || '',
      imageUrls: imageUrls,
      createdAt: new Date()
    });
    
    console.log('✅ Prescription created:', prescription._id);
    
    // Update appointment status to completed
    if (appointmentId) {
      await Appointment.findByIdAndUpdate(appointmentId, { status: 'completed' });
      console.log('✅ Appointment marked as completed:', appointmentId);
    }
    
    // Send notification to patient
    await sendPrescriptionNotification(prescription, patientId, doctor.user.name, global.io);
    
    // Populate the prescription
    const populatedPrescription = await Prescription.findById(prescription._id)
      .populate({
        path: 'doctor',
        populate: { path: 'user', select: 'name email specialization' }
      })
      .populate({
        path: 'patient',
        populate: { path: 'user', select: 'name email' }
      })
      .populate('appointment');
    
    res.status(201).json({ 
      success: true, 
      data: populatedPrescription,
      message: 'Prescription sent successfully and appointment completed'
    });
  } catch (error) {
    console.error('Error creating doctor prescription:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});
// Image upload endpoint (standalone)
router.post('/upload', protect, upload.single('prescription'), uploadPrescriptionImage);

// ✅ Patient upload prescription (with image + data) - MUST be before /my and /patient/:patientId
router.post('/patient-upload', protect, upload.single('prescription'), patientUploadPrescription);

// Get current user's prescriptions (for patient)
router.get('/my', protect, getMyPrescriptions);

// Get prescriptions by patient ID (for doctors)
router.get('/patient/:patientId', protect, getPrescriptionsByPatient);

// CRUD operations
router.get('/', protect, getPrescriptions);
router.post('/', protect, createPrescription);
router.put('/:id', protect, updatePrescription);
router.delete('/:id', protect, deletePrescription);

module.exports = router;