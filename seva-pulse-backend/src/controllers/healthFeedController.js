const HealthCamp = require('../models/HealthCamp');
const Notification = require('../models/Notification');
const User = require('../models/User');

// Helper function to send health camp notification
async function sendHealthCampNotification(camp, action, userId, io) {
  try {
    console.log(`📢 Sending ${action} notification for camp: ${camp.title}`);
    
    const patients = await User.find({ role: 'patient' }).select('_id');
    const patientIds = patients.map(p => p._id);
    
    console.log(`📢 Found ${patientIds.length} patients to notify`);
    
    const notificationData = {
      title: getNotificationTitle(action, camp.title),
      message: getNotificationMessage(action, camp),
      type: `HEALTH_CAMP_${action}`,
      campId: camp._id,
      campData: {
        title: camp.title,
        date: camp.date,
        location: camp.location,
        time: camp.time,
        availableSlots: camp.availableSlots,
        isFree: camp.isFree
      },
      recipients: patientIds,
      createdAt: new Date()
    };

    const notification = await Notification.create(notificationData);
    console.log(`✅ Notification saved to database with ID: ${notification._id}`);

    if (io) {
      io.to('all_patients').emit('health_camp_notification', {
        id: notification._id,
        title: notification.title,
        message: notification.message,
        type: notification.type,
        campId: camp._id,
        campData: notification.campData,
        createdAt: notification.createdAt
      });
      console.log(`📡 WebSocket notification emitted to all_patients`);
    }
    
    return notification;
  } catch (error) {
    console.error('❌ Error sending notification:', error);
    return null;
  }
}

function getNotificationTitle(action, campTitle) {
  switch(action) {
    case 'CREATE':
      return `🆕 New Health Camp: ${campTitle}`;
    case 'UPDATE':
      return `📝 Health Camp Updated: ${campTitle}`;
    case 'DELETE':
      return `❌ Health Camp Cancelled: ${campTitle}`;
    default:
      return `Health Camp Update`;
  }
}

function getNotificationMessage(action, camp) {
  const dateStr = camp.date ? new Date(camp.date).toLocaleDateString('en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  }) : 'TBD';
  
  switch(action) {
    case 'CREATE':
      return `A new health camp "${camp.title}" has been scheduled on ${dateStr} at ${camp.location}. ${camp.availableSlots} slots available! Tap to view details and register.`;
    case 'UPDATE':
      return `The health camp "${camp.title}" has been updated. Please check the new details for ${dateStr}.`;
    case 'DELETE':
      return `The health camp "${camp.title}" scheduled on ${dateStr} has been cancelled. We apologize for the inconvenience.`;
    default:
      return `Health camp "${camp.title}" has been updated.`;
  }
}

// Controller methods
exports.getHealthCamps = async (req, res, next) => {
  try {
    const camps = await HealthCamp.find().sort({ date: 1 });
    res.status(200).json({ success: true, data: camps });
  } catch (error) {
    next(error);
  }
};

exports.getHealthCamp = async (req, res, next) => {
  try {
    const camp = await HealthCamp.findById(req.params.id);
    if (!camp) {
      return res.status(404).json({ success: false, message: 'Camp not found' });
    }
    res.status(200).json({ success: true, data: camp });
  } catch (error) {
    next(error);
  }
};

exports.createHealthCamp = async (req, res, next) => {
  try {
    console.log('📝 Creating health camp. Request body:', req.body);
    
    const campData = {
      title: req.body.title,
      organization: req.body.organization || 'Seva Pulse Hospital',
      date: new Date(req.body.date),
      time: req.body.time,
      location: req.body.location,
      description: req.body.description,
      imageUrl: req.body.imageUrl || '',
      availableSlots: req.body.availableSlots,
      registeredParticipants: 0,
      services: req.body.services || [],
      contact: req.body.contact,
      isFree: req.body.isFree !== undefined ? req.body.isFree : true,
      fee: req.body.isFree ? null : req.body.fee,
      createdAt: new Date()
    };
    
    const camp = await HealthCamp.create(campData);
    console.log('✅ Health camp created with ID:', camp._id);
    
    // ✅ Send notification
    await sendHealthCampNotification(camp, 'CREATE', req.user.id, global.io);
    
    res.status(201).json({ 
      success: true, 
      data: camp,
      message: 'Health camp created successfully'
    });
  } catch (error) {
    console.error('❌ Error creating health camp:', error);
    next(error);
  }
};

exports.updateHealthCamp = async (req, res, next) => {
  try {
    console.log('📝 Updating health camp:', req.params.id);
    
    const updateData = {
      ...req.body,
      date: req.body.date ? new Date(req.body.date) : undefined,
      updatedAt: new Date()
    };
    
    Object.keys(updateData).forEach(key => 
      updateData[key] === undefined && delete updateData[key]
    );
    
    const camp = await HealthCamp.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    );
    
    if (!camp) {
      return res.status(404).json({ success: false, message: 'Health camp not found' });
    }
    
    console.log('✅ Health camp updated successfully');
    
    // ✅ Send notification
    await sendHealthCampNotification(camp, 'UPDATE', req.user.id, global.io);
    
    res.status(200).json({ 
      success: true, 
      data: camp,
      message: 'Health camp updated successfully'
    });
  } catch (error) {
    console.error('❌ Error updating health camp:', error);
    next(error);
  }
};

exports.deleteHealthCamp = async (req, res, next) => {
  try {
    console.log('🗑️ Deleting health camp:', req.params.id);
    
    const camp = await HealthCamp.findById(req.params.id);
    
    if (!camp) {
      return res.status(404).json({ success: false, message: 'Health camp not found' });
    }
    
    const campData = { ...camp._doc };
    
    await HealthCamp.findByIdAndDelete(req.params.id);
    console.log('✅ Health camp deleted successfully');
    
    // ✅ Send notification
    await sendHealthCampNotification(campData, 'DELETE', req.user.id, global.io);
    
    res.status(200).json({ 
      success: true, 
      message: 'Health camp deleted successfully' 
    });
  } catch (error) {
    console.error('❌ Error deleting health camp:', error);
    next(error);
  }
};
// src/controllers/healthFeedController.js
// Update the registerForCamp function to store participant ID

exports.registerForCamp = async (req, res, next) => {
  try {
    const camp = await HealthCamp.findById(req.params.id);
    if (!camp) {
      return res.status(404).json({ success: false, message: 'Camp not found' });
    }
    
    if (camp.registeredParticipants >= camp.availableSlots) {
      return res.status(400).json({ success: false, message: 'No slots available' });
    }
    
    // Check if already registered
    if (camp.participants && camp.participants.includes(req.user.id)) {
      return res.status(400).json({ success: false, message: 'Already registered for this camp' });
    }
    
    // Add participant
    camp.registeredParticipants += 1;
    if (!camp.participants) camp.participants = [];
    camp.participants.push(req.user.id);
    await camp.save();
    
    res.status(200).json({ success: true, message: 'Registered successfully', data: camp });
  } catch (error) {
    console.error('Error in registerForCamp:', error);
    next(error);
  }
};

// Export init function for compatibility
exports.initNotificationService = (io) => {
  console.log('✅ Notification service initialized with IO');
};