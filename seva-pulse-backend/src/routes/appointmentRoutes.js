const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const Appointment = require('../models/Appointment');
const Doctor = require('../models/Doctor');
const Patient = require('../models/Patient');
const User = require('../models/User');
const Notification = require('../models/Notification');

// Helper function to send appointment notification
async function sendAppointmentNotification(appointment, action, io) {
  try {
    console.log(`📢 Sending ${action} notification for appointment: ${appointment._id}`);

    const patient = await Patient.findById(appointment.patient).populate('user', 'name');
    const doctor  = await Doctor.findById(appointment.doctor).populate('user', 'name');

    const patientUserId = patient?.user?._id;
    const doctorUserId  = doctor?.user?._id;

    if (!patientUserId) {
      console.log('⚠️ No patient user ID found');
      return null;
    }

    let recipients = [];
    let title = '';
    let message = '';

    const appointmentDate = new Date(appointment.date).toLocaleDateString('en-US', {
      weekday: 'long', year: 'numeric', month: 'long', day: 'numeric'
    });

    if (action === 'BOOKED') {
      recipients = [patientUserId];
      title   = '✅ Appointment Booked Successfully';
      message = `Your appointment with Dr. ${doctor?.user?.name || 'Doctor'} has been booked for ${appointmentDate} at ${appointment.timeSlot?.start || 'scheduled time'}. Please arrive 10 minutes before your appointment.`;
    } else if (action === 'CONFIRMED') {
      recipients = [patientUserId];
      if (doctorUserId) recipients.push(doctorUserId);
      title   = '✅ Appointment Confirmed';
      message = `Appointment with Dr. ${doctor?.user?.name || 'Doctor'} on ${appointmentDate} at ${appointment.timeSlot?.start || 'scheduled time'} has been confirmed.`;
    } else if (action === 'CANCELLED') {
      recipients = [patientUserId];
      if (doctorUserId) recipients.push(doctorUserId);
      title   = '❌ Appointment Cancelled';
      message = `Appointment with Dr. ${doctor?.user?.name || 'Doctor'} on ${appointmentDate} at ${appointment.timeSlot?.start || 'scheduled time'} has been cancelled.`;
    }

    if (recipients.length === 0) return null;

    const notificationData = {
      title,
      message,
      type: `APPOINTMENT_${action}`,
      appointmentId: appointment._id,
      appointmentData: {
        doctorName:  doctor?.user?.name  || 'Doctor',
        patientName: patient?.user?.name || 'Patient',
        date:   appointment.date,
        time:   appointment.timeSlot?.start || '10:00 AM',
        status: appointment.status,
        type:   appointment.type
      },
      recipients,
      createdAt: new Date()
    };

    const notification = await Notification.create(notificationData);
    console.log(`✅ Notification saved: ${notification._id}`);

    if (io) {
      recipients.forEach(recipientId => {
        io.to(`patient_${recipientId}`).emit('notification', {
          id:            notification._id,
          title:         notification.title,
          message:       notification.message,
          type:          notification.type,
          appointmentId: appointment._id,
          appointmentData: notification.appointmentData,
          createdAt:     notification.createdAt
        });

        if (doctorUserId) {
          io.to(`doctor_${doctorUserId}`).emit('notification', {
            id:            notification._id,
            title:         notification.title,
            message:       notification.message,
            type:          notification.type,
            appointmentId: appointment._id,
            appointmentData: notification.appointmentData,
            createdAt:     notification.createdAt
          });
        }
      });
      console.log(`📡 WebSocket notification emitted`);
    }

    return notification;
  } catch (error) {
    console.error('❌ Error sending appointment notification:', error);
    return null;
  }
}
// Add this debug endpoint at the VERY TOP of appointmentRoutes.js
router.get('/debug', protect, async (req, res) => {
  try {
    console.log('=== DEBUG APPOINTMENT ROUTE ===');
    console.log('Query params:', req.query);
    
    const doctorId = req.query.doctorId;
    const date = req.query.date;
    
    if (!doctorId || !date) {
      return res.json({ success: false, message: 'Missing doctorId or date', query: req.query });
    }
    
    // Find doctor
    let doctor = await Doctor.findById(doctorId);
    if (!doctor) {
      doctor = await Doctor.findOne({ user: doctorId });
    }
    
    if (!doctor) {
      return res.json({ success: false, message: 'Doctor not found', doctorId: doctorId });
    }
    
    const startDate = new Date(date);
    const endDate = new Date(date);
    endDate.setDate(endDate.getDate() + 1);
    
    const appointments = await Appointment.find({
      doctor: doctor._id,
      date: { $gte: startDate, $lt: endDate }
    });
    
    res.json({
      success: true,
      doctor: {
        id: doctor._id,
        name: doctor.user?.name
      },
      appointments: appointments.map(a => ({
        time: a.timeSlot?.start,
        status: a.status
      }))
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});
// DEBUG endpoint - Add this at the top of appointmentRoutes.js
router.get('/debug-slots', protect, async (req, res) => {
  try {
    console.log('=== DEBUG SLOTS ENDPOINT ===');
    console.log('Query params:', req.query);
    
    const doctorId = req.query.doctorId;
    const date = req.query.date;
    
    if (!doctorId || !date) {
      return res.status(400).json({ 
        success: false, 
        message: 'Missing doctorId or date',
        received: { doctorId, date }
      });
    }
    
    // Find doctor
    let doctor = await Doctor.findById(doctorId);
    if (!doctor) {
      doctor = await Doctor.findOne({ user: doctorId });
    }
    
    if (!doctor) {
      return res.status(404).json({ 
        success: false, 
        message: 'Doctor not found',
        doctorId: doctorId 
      });
    }
    
    // Parse date
    const startDate = new Date(date);
    const endDate = new Date(date);
    endDate.setDate(endDate.getDate() + 1);
    
    // Find appointments
    const appointments = await Appointment.find({
      doctor: doctor._id,
      date: { $gte: startDate, $lt: endDate }
    });
    
    res.json({
      success: true,
      doctor: {
        id: doctor._id,
        name: doctor.user?.name
      },
      date: date,
      appointmentsCount: appointments.length,
      appointments: appointments.map(a => ({
        time: a.timeSlot?.start,
        status: a.status
      }))
    });
  } catch (error) {
    console.error('Debug error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});
// Add this temporary debug endpoint at the top of your appointmentRoutes.js
router.get('/debug-doctors', protect, async (req, res) => {
  try {
    const doctors = await Doctor.find().populate('user', 'name email');
    const formatted = doctors.map(d => ({
      _id: d._id,
      name: d.user?.name,
      specialization: d.specialization
    }));
    res.json({ success: true, doctors: formatted });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Also add this to debug slot checks
router.get('/debug-slots/:doctorId/:date', protect, async (req, res) => {
  try {
    const { doctorId, date } = req.params;
    console.log('Debug slots - Doctor ID:', doctorId);
    console.log('Debug slots - Date:', date);
    
    // Try to find doctor by ID
    let doctor = await Doctor.findById(doctorId);
    if (!doctor) {
      doctor = await Doctor.findOne({ user: doctorId });
    }
    
    if (!doctor) {
      return res.json({ success: false, message: 'Doctor not found', doctorId });
    }
    
    const startDate = new Date(date);
    const endDate = new Date(date);
    endDate.setDate(endDate.getDate() + 1);
    
    const appointments = await Appointment.find({
      doctor: doctor._id,
      date: { $gte: startDate, $lt: endDate }
    });
    
    res.json({
      success: true,
      doctorId: doctor._id,
      doctorFound: true,
      appointmentsCount: appointments.length,
      appointments: appointments.map(a => ({
        time: a.timeSlot?.start,
        status: a.status
      }))
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});
// src/routes/appointmentRoutes.js - Fix the GET route
// src/routes/appointmentRoutes.js - REPLACE the GET route with this

router.get('/', protect, async (req, res, next) => {
  try {
    console.log('📋 GET /appointments');
    console.log('User ID:', req.user.id);
    console.log('User role:', req.user.role);
    console.log('Query params:', req.query);
    
    let query = {};
    
    // CHECK IF THIS IS A SLOT AVAILABILITY REQUEST
    const isSlotCheck = req.query.doctorId && req.query.doctorId !== '' && req.query.date && req.query.date !== '';
    
    if (isSlotCheck) {
      console.log('🔍 SLOT CHECK REQUEST - Doctor:', req.query.doctorId, 'Date:', req.query.date);
      
      // Find the doctor by ID
      let doctor = await Doctor.findById(req.query.doctorId);
      if (!doctor) {
        doctor = await Doctor.findOne({ user: req.query.doctorId });
      }
      
      if (!doctor) {
        console.log('❌ Doctor not found:', req.query.doctorId);
        return res.status(200).json({ success: true, count: 0, data: [] });
      }
      
      query.doctor = doctor._id;
      console.log('✅ Doctor found, ID:', doctor._id);
      
      // Add date filter
      const startDate = new Date(req.query.date);
      const endDate = new Date(req.query.date);
      endDate.setDate(endDate.getDate() + 1);
      query.date = { $gte: startDate, $lt: endDate };
      console.log('📅 Date range:', startDate, 'to', endDate);
      
      // FOR SLOT CHECK - DO NOT ADD PATIENT/DOCTOR ROLE FILTERS
      // Just return all appointments for this doctor on this date
      
    } else {
      // NORMAL REQUEST - Filter by patient or doctor role
      console.log('👤 NORMAL REQUEST - Filtering by user role');
      
      if (req.user.role === 'patient') {
        const patient = await Patient.findOne({ user: req.user.id });
        if (patient) {
          query.patient = patient._id;
          console.log('Filtering for patient:', patient._id);
        } else {
          return res.status(200).json({ success: true, count: 0, data: [] });
        }
      } else if (req.user.role === 'doctor') {
        const doctor = await Doctor.findOne({ user: req.user.id });
        if (doctor) {
          query.doctor = doctor._id;
          console.log('Filtering for doctor:', doctor._id);
        } else {
          return res.status(200).json({ success: true, count: 0, data: [] });
        }
      }
    }
    
    console.log('Final query:', JSON.stringify(query));
    
    const appointments = await Appointment.find(query)
      .populate({ path: 'doctor', populate: { path: 'user', select: 'name email' } })
      .populate({ path: 'patient', populate: { path: 'user', select: 'name email' } })
      .sort('date timeSlot.start');
    
    const formattedAppointments = appointments.map(apt => ({
      id: apt._id,
      patientId: apt.patient?.user?._id?.toString(),
      doctorId: apt.doctor?._id?.toString(),
      patientName: apt.patient?.user?.name || 'Unknown',
      doctorName: apt.doctor?.user?.name || 'Unknown',
      patientEmail: apt.patient?.user?.email || '',
      date: apt.date,
      time: apt.timeSlot?.start || '10:00 AM',
      status: apt.status,
      type: apt.type,
      symptoms: apt.symptoms || '',
      notes: apt.notes
    }));
    
    console.log(`✅ Found ${formattedAppointments.length} appointments`);
    res.status(200).json({ 
      success: true, 
      count: formattedAppointments.length, 
      data: formattedAppointments 
    });
  } catch (error) {
    console.error('❌ Error in getAppointments:', error);
    next(error);
  }
});

// ─── POST /api/appointments ───────────────────────────────────────────────────
router.post('/', protect, async (req, res, next) => {
  try {
    console.log('📝 Creating appointment for user:', req.user.id);

    let patient = await Patient.findOne({ user: req.user.id });
    if (!patient) {
      patient = await Patient.create({
        user: req.user.id,
        dateOfBirth: new Date('1990-01-01'),
        gender: 'Not specified'
      });
      console.log('✅ Created new patient profile for user:', req.user.id);
    }

    const doctor = await Doctor.findById(req.body.doctorId).populate('user');
    if (!doctor) {
      return res.status(404).json({ success: false, message: 'Doctor not found' });
    }

    const appointmentData = {
      doctor:   doctor._id,
      patient:  patient._id,
      date:     new Date(req.body.date),
      timeSlot: { start: req.body.time },
      status:   'pending',
      type:     req.body.type     || 'consultation',
      symptoms: req.body.symptoms || '',
      notes:    req.body.notes    || ''
    };

    const appointment = await Appointment.create(appointmentData);

    await sendAppointmentNotification(appointment, 'BOOKED', global.io);

    const populated = await Appointment.findById(appointment._id)
      .populate({ path: 'doctor',  populate: { path: 'user', select: 'name email' } })
      .populate({ path: 'patient', populate: { path: 'user', select: 'name email' } });

    res.status(201).json({
      success: true,
      data: {
        id:           populated._id,
        patientId:    populated.patient?.user?._id?.toString(),
        doctorId:     populated.doctor?._id?.toString(),
        patientName:  populated.patient?.user?.name  || 'Patient',
        doctorName:   populated.doctor?.user?.name   || 'Doctor',
        patientEmail: populated.patient?.user?.email || '',
        date:         populated.date,
        time:         populated.timeSlot.start,
        status:       populated.status,
        type:         populated.type,
        symptoms:     populated.symptoms
      }
    });
  } catch (error) {
    console.error('❌ Error in createAppointment:', error);
    next(error);
  }
});

// ─── PUT /api/appointments/:id ────────────────────────────────────────────────
router.put('/:id', protect, async (req, res, next) => {
  try {
    const { status } = req.body;
    const oldAppointment = await Appointment.findById(req.params.id);

    const appointment = await Appointment.findByIdAndUpdate(
      req.params.id, { status }, { new: true }
    )
      .populate({ path: 'doctor',  populate: { path: 'user', select: 'name email' } })
      .populate({ path: 'patient', populate: { path: 'user', select: 'name email' } });

    if (!appointment) {
      return res.status(404).json({ success: false, message: 'Appointment not found' });
    }

    if (oldAppointment.status !== 'confirmed' && status === 'confirmed') {
      await sendAppointmentNotification(appointment, 'CONFIRMED', global.io);
    }
    if (oldAppointment.status !== 'cancelled' && status === 'cancelled') {
      await sendAppointmentNotification(appointment, 'CANCELLED', global.io);
    }

    res.status(200).json({
      success: true,
      data: {
        id:           appointment._id,
        patientId:    appointment.patient?.user?._id?.toString(),
        doctorId:     appointment.doctor?._id?.toString(),
        patientName:  appointment.patient?.user?.name  || 'Patient',
        doctorName:   appointment.doctor?.user?.name   || 'Doctor',
        patientEmail: appointment.patient?.user?.email || '',
        date:         appointment.date,
        time:         appointment.timeSlot?.start || '10:00 AM',
        status:       appointment.status,
        type:         appointment.type,
        symptoms:     appointment.symptoms
      }
    });
  } catch (error) {
    console.error('❌ Error in updateAppointment:', error);
    next(error);
  }
});
router.use((req, res, next) => {
  console.log('🔍 Incoming request:', req.method, req.url);
  console.log('🔍 Query params:', req.query);
  next();
});

// ─── DELETE /api/appointments/:id ─────────────────────────────────────────────
router.delete('/:id', protect, async (req, res, next) => {
  try {
    const appointment = await Appointment.findById(req.params.id)
      .populate({ path: 'doctor',  populate: { path: 'user', select: 'name email' } })
      .populate({ path: 'patient', populate: { path: 'user', select: 'name email' } });

    if (!appointment) {
      return res.status(404).json({ success: false, message: 'Appointment not found' });
    }

    await sendAppointmentNotification(appointment, 'CANCELLED', global.io);
    await Appointment.findByIdAndDelete(req.params.id);

    res.status(200).json({ success: true, message: 'Appointment deleted' });
  } catch (error) {
    console.error('❌ Error in deleteAppointment:', error);
    next(error);
  }
});

module.exports = router;