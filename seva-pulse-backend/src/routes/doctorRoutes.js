// src/routes/doctorRoutes.js
const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const Doctor = require('../models/Doctor');
const User = require('../models/User');
const Appointment = require('../models/Appointment');

// ==================== GET ROUTES ====================

// Get all doctors (for patients to view)
router.get('/', protect, async (req, res, next) => {
  try {
    console.log('👨‍⚕️ Fetching doctors for user:', req.user.id);
    
    const doctors = await Doctor.find()
      .populate('user', 'name email phone profilePicture address');
    
    console.log(`✅ Found ${doctors.length} doctors`);
    
    const formattedDoctors = doctors.map(doctor => ({
      _id: doctor._id,
      user: doctor.user ? {
        name: doctor.user.name,
        email: doctor.user.email,
        phone: doctor.user.phone,
        profilePicture: doctor.user.profilePicture,
        address: doctor.user.address
      } : null,
      specialization: doctor.specialization || 'General',
      experience: doctor.experience || 0,
      consultationFee: doctor.consultationFee || 500,
      department: doctor.department || 'General',
      qualifications: doctor.qualifications || [],
      rating: doctor.rating || 4.5,
      availability: doctor.availability || [],
      bio: doctor.bio || '',
    }));
    
    res.status(200).json({ 
      success: true, 
      count: formattedDoctors.length, 
      data: formattedDoctors 
    });
  } catch (error) {
    console.error('❌ Error in getDoctors:', error);
    next(error);
  }
});

// Get current doctor's profile (for logged in doctor)
router.get('/me', protect, async (req, res) => {
  try {
    console.log('📋 Fetching current doctor profile for user:', req.user.id);
    
    const doctor = await Doctor.findOne({ user: req.user.id })
      .populate('user', 'name email phone profilePicture address');
    
    if (!doctor) {
      // Create doctor profile if it doesn't exist
      console.log('⚠️ No doctor profile found, creating one...');
      const newDoctor = await Doctor.create({
        user: req.user.id,
        specialization: 'General Physician',
        experience: 0,
        consultationFee: 500,
        department: 'General',
        qualifications: [],
        rating: 4.5,
        availability: [],
        bio: 'Experienced doctor dedicated to patient care.',
        createdAt: new Date()
      });
      
      const populatedDoctor = await Doctor.findById(newDoctor._id)
        .populate('user', 'name email phone profilePicture address');
      
      return res.status(200).json({ 
        success: true, 
        data: {
          specialization: populatedDoctor.specialization,
          experience: populatedDoctor.experience,
          consultationFee: populatedDoctor.consultationFee,
          department: populatedDoctor.department,
          qualifications: populatedDoctor.qualifications,
          rating: populatedDoctor.rating,
          bio: populatedDoctor.bio,
          hospital: populatedDoctor.user?.address || 'Not specified',
          patientsCount: 0,
          name: populatedDoctor.user?.name,
          email: populatedDoctor.user?.email,
          phone: populatedDoctor.user?.phone
        }
      });
    }
    
    // Get patients count for this doctor
    const patientsCount = await Appointment.countDocuments({ 
      doctor: doctor._id,
      status: { $ne: 'cancelled' }
    }).distinct('patient');
    
    res.status(200).json({ 
      success: true, 
      data: {
        specialization: doctor.specialization,
        experience: doctor.experience,
        consultationFee: doctor.consultationFee,
        department: doctor.department,
        qualifications: doctor.qualifications,
        rating: doctor.rating,
        bio: doctor.bio || 'Experienced doctor dedicated to patient care.',
        hospital: doctor.user?.address || 'Not specified',
        patientsCount: patientsCount.length,
        name: doctor.user?.name,
        email: doctor.user?.email,
        phone: doctor.user?.phone
      }
    });
  } catch (error) {
    console.error('❌ Error in getDoctorProfile:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// Get doctor by ID
router.get('/:id', protect, async (req, res, next) => {
  try {
    const doctor = await Doctor.findById(req.params.id)
      .populate('user', 'name email phone profilePicture address');
    
    if (!doctor) {
      return res.status(404).json({ success: false, message: 'Doctor not found' });
    }
    
    res.status(200).json({ success: true, data: doctor });
  } catch (error) {
    console.error('❌ Error in getDoctor:', error);
    next(error);
  }
});

// ==================== PUT/UPDATE ROUTES ====================

// Update current doctor's profile
router.put('/me', protect, async (req, res) => {
  try {
    console.log('📝 Updating current doctor profile for user:', req.user.id);
    console.log('Update data:', req.body);
    
    // Find doctor profile
    let doctor = await Doctor.findOne({ user: req.user.id });
    
    if (!doctor) {
      // Create doctor profile if it doesn't exist
      doctor = await Doctor.create({
        user: req.user.id,
        specialization: req.body.specialization || 'General Physician',
        experience: req.body.experience || 0,
        consultationFee: req.body.consultationFee || 500,
        department: req.body.department || 'General',
        qualifications: req.body.qualifications || [],
        rating: 4.5,
        bio: req.body.bio || 'Experienced doctor dedicated to patient care.',
        createdAt: new Date()
      });
      console.log('✅ Created new doctor profile:', doctor._id);
    }
    
    // Update doctor fields - DON'T include 'user' field
    const updateFields = {};
    if (req.body.specialization !== undefined) updateFields.specialization = req.body.specialization;
    if (req.body.experience !== undefined) updateFields.experience = parseInt(req.body.experience) || 0;
    if (req.body.consultationFee !== undefined) updateFields.consultationFee = parseInt(req.body.consultationFee) || 500;
    if (req.body.department !== undefined) updateFields.department = req.body.department;
    if (req.body.bio !== undefined) updateFields.bio = req.body.bio;
    
    // Handle qualifications
    if (req.body.qualifications !== undefined) {
      if (typeof req.body.qualifications === 'string') {
        updateFields.qualifications = [{ degree: req.body.qualifications, institution: 'Medical College', year: new Date().getFullYear() }];
      } else {
        updateFields.qualifications = req.body.qualifications;
      }
    }
    
    // Only update doctor if there are fields to update
    if (Object.keys(updateFields).length > 0) {
      doctor = await Doctor.findByIdAndUpdate(
        doctor._id,
        { $set: updateFields },
        { new: true, runValidators: true }
      );
      console.log('✅ Doctor fields updated');
    }
    
    // Update User model fields - separate update for user collection
    const userUpdateFields = {};
    if (req.body.name !== undefined) userUpdateFields.name = req.body.name;
    if (req.body.email !== undefined) userUpdateFields.email = req.body.email;
    if (req.body.phone !== undefined) userUpdateFields.phone = req.body.phone;
    if (req.body.hospital !== undefined) {
      // Store hospital name in address field
      userUpdateFields.address = req.body.hospital;
    }
    if (req.body.address !== undefined) {
      userUpdateFields.address = req.body.address;
    }
    
    if (Object.keys(userUpdateFields).length > 0) {
      await User.findByIdAndUpdate(
        req.user.id,
        { $set: userUpdateFields },
        { new: true, runValidators: false }
      );
      console.log('✅ User model updated');
    }
    
    // Get updated doctor with populated user
    const updatedDoctor = await Doctor.findById(doctor._id)
      .populate('user', 'name email phone profilePicture address');
    
    // Get updated patients count
    const patientsCount = await Appointment.aggregate([
      { $match: { doctor: doctor._id, status: { $ne: 'cancelled' } } },
      { $group: { _id: '$patient' } },
      { $count: 'count' }
    ]);
    
    const patientCount = patientsCount.length > 0 ? patientsCount[0].count : 0;
    
    console.log('✅ Doctor profile updated successfully');
    
    res.status(200).json({ 
      success: true, 
      data: {
        specialization: updatedDoctor.specialization,
        experience: updatedDoctor.experience,
        consultationFee: updatedDoctor.consultationFee,
        department: updatedDoctor.department,
        qualifications: updatedDoctor.qualifications,
        rating: updatedDoctor.rating,
        bio: updatedDoctor.bio,
        hospital: updatedDoctor.user?.address || 'Not specified',
        patientsCount: patientCount,
        name: updatedDoctor.user?.name,
        email: updatedDoctor.user?.email,
        phone: updatedDoctor.user?.phone
      },
      message: 'Profile updated successfully'
    });
  } catch (error) {
    console.error('❌ Error in updateDoctorProfile:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// Update doctor by ID (admin only)
router.put('/:id', protect, async (req, res, next) => {
  try {
    // Check if user is admin
    const adminUser = await User.findById(req.user.id);
    if (adminUser.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }
    
    const doctor = await Doctor.findByIdAndUpdate(
      req.params.id, 
      req.body, 
      { new: true, runValidators: true }
    ).populate('user', 'name email phone profilePicture');
    
    if (!doctor) {
      return res.status(404).json({ success: false, message: 'Doctor not found' });
    }
    
    res.status(200).json({ success: true, data: doctor });
  } catch (error) {
    console.error('❌ Error in updateDoctor:', error);
    next(error);
  }
});

// ==================== STATS ROUTES ====================

// Get doctor's patients
router.get('/me/patients', protect, async (req, res) => {
  try {
    console.log('📋 Fetching patients for doctor:', req.user.id);
    
    const doctor = await Doctor.findOne({ user: req.user.id });
    if (!doctor) {
      return res.status(404).json({ success: false, message: 'Doctor not found' });
    }
    
    const appointments = await Appointment.find({ doctor: doctor._id, status: { $ne: 'cancelled' } })
      .populate({
        path: 'patient',
        populate: { path: 'user', select: 'name email phone' }
      })
      .sort({ date: -1 });
    
    // Get unique patients
    const patientMap = new Map();
    for (const apt of appointments) {
      if (apt.patient && !patientMap.has(apt.patient._id.toString())) {
        patientMap.set(apt.patient._id.toString(), {
          id: apt.patient._id,
          name: apt.patient.user?.name || 'Unknown',
          email: apt.patient.user?.email || 'N/A',
          phone: apt.patient.user?.phone || 'N/A',
          lastVisit: apt.date,
          condition: apt.symptoms || 'General'
        });
      }
    }
    
    const patients = Array.from(patientMap.values());
    console.log(`✅ Found ${patients.length} patients`);
    
    res.status(200).json({ 
      success: true, 
      data: patients 
    });
  } catch (error) {
    console.error('❌ Error in getDoctorPatients:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// Get doctor's appointments
router.get('/me/appointments', protect, async (req, res) => {
  try {
    console.log('📋 Fetching appointments for doctor:', req.user.id);
    
    const doctor = await Doctor.findOne({ user: req.user.id });
    if (!doctor) {
      return res.status(404).json({ success: false, message: 'Doctor not found' });
    }
    
    const { date, status } = req.query;
    let query = { doctor: doctor._id };
    
    if (date) {
      const startDate = new Date(date);
      const endDate = new Date(date);
      endDate.setDate(endDate.getDate() + 1);
      query.date = { $gte: startDate, $lt: endDate };
    }
    
    if (status) {
      query.status = status;
    }
    
    const appointments = await Appointment.find(query)
      .populate({
        path: 'patient',
        populate: { path: 'user', select: 'name email phone' }
      })
      .sort({ date: 1, 'timeSlot.start': 1 });
    
    const formattedAppointments = appointments.map(apt => ({
      id: apt._id,
      patientId: apt.patient?._id,
      patientName: apt.patient?.user?.name || 'Unknown',
      patientEmail: apt.patient?.user?.email || '',
      patientPhone: apt.patient?.user?.phone || '',
      date: apt.date,
      time: apt.timeSlot?.start || '10:00 AM',
      status: apt.status,
      type: apt.type,
      symptoms: apt.symptoms || '',
      notes: apt.notes || ''
    }));
    // Create doctor profile (for registration)
router.post('/profile', protect, async (req, res) => {
  try {
    console.log('📝 Creating doctor profile for user:', req.user.id);
    
    // Check if doctor profile already exists
    let doctor = await Doctor.findOne({ user: req.user.id });
    
    if (doctor) {
      // Update existing profile
      doctor = await Doctor.findByIdAndUpdate(
        doctor._id,
        { $set: req.body },
        { new: true }
      );
    } else {
      // Create new profile
      doctor = await Doctor.create({
        user: req.user.id,
        specialization: req.body.specialization || 'General Physician',
        experience: req.body.experience || 0,
        consultationFee: req.body.consultationFee || 500,
        department: req.body.department || 'General',
        qualifications: req.body.qualifications || [],
        rating: 4.5,
        bio: req.body.bio || 'Experienced doctor dedicated to patient care.',
        createdAt: new Date()
      });
    }
    
    // Update user with additional info
    if (req.body.dateOfBirth || req.body.address) {
      const userUpdate = {};
      if (req.body.dateOfBirth) userUpdate.dateOfBirth = new Date(req.body.dateOfBirth);
      if (req.body.address) userUpdate.address = req.body.address;
      await User.findByIdAndUpdate(req.user.id, { $set: userUpdate });
    }
    
    const populatedDoctor = await Doctor.findById(doctor._id)
      .populate('user', 'name email phone profilePicture address');
    
    console.log('✅ Doctor profile created/updated successfully');
    
    res.status(201).json({ 
      success: true, 
      data: populatedDoctor,
      message: 'Doctor profile created successfully'
    });
  } catch (error) {
    console.error('Error in createDoctorProfile:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});
    console.log(`✅ Found ${formattedAppointments.length} appointments`);
    
    res.status(200).json({ 
      success: true, 
      data: formattedAppointments 
    });
  } catch (error) {
    console.error('❌ Error in getDoctorAppointments:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;