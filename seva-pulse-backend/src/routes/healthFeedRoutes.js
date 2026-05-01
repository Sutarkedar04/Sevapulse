const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const HealthCamp = require('../models/HealthCamp');
const User = require('../models/User');
const healthFeedController = require('../controllers/healthFeedController');

// Get all health camps
router.get('/', protect, healthFeedController.getHealthCamps);

// Get single health camp
router.get('/:id', protect, healthFeedController.getHealthCamp);

// Create health camp
router.post('/', protect, healthFeedController.createHealthCamp);

// Update health camp
router.put('/:id', protect, healthFeedController.updateHealthCamp);

// Delete health camp
router.delete('/:id', protect, healthFeedController.deleteHealthCamp);

// Register for health camp
router.post('/:id/register', protect, healthFeedController.registerForCamp);

// ✅ Get participants for a specific camp
router.get('/:id/participants', protect, async (req, res) => {
  try {
    const camp = await HealthCamp.findById(req.params.id);
    if (!camp) {
      return res.status(404).json({ success: false, message: 'Camp not found' });
    }
    
    // Get participants with user details
    const participants = [];
    if (camp.participants && camp.participants.length > 0) {
      for (const participantId of camp.participants) {
        const user = await User.findById(participantId).select('name email phone');
        if (user) {
          participants.push({
            id: user._id,
            name: user.name,
            email: user.email,
            phone: user.phone
          });
        }
      }
    }
    
    res.status(200).json({ 
      success: true, 
      data: participants,
      count: participants.length
    });
  } catch (error) {
    console.error('Error fetching participants:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// ✅ Cancel registration
router.delete('/:id/register', protect, async (req, res) => {
  try {
    const camp = await HealthCamp.findById(req.params.id);
    if (!camp) {
      return res.status(404).json({ success: false, message: 'Camp not found' });
    }
    
    // Check if user is registered
    if (!camp.participants || !camp.participants.includes(req.user.id)) {
      return res.status(400).json({ success: false, message: 'You are not registered for this camp' });
    }
    
    // Remove participant
    camp.participants = camp.participants.filter(p => p.toString() !== req.user.id);
    camp.registeredParticipants = Math.max(0, camp.registeredParticipants - 1);
    await camp.save();
    
    res.status(200).json({ 
      success: true, 
      message: 'Registration cancelled successfully',
      data: camp
    });
  } catch (error) {
    console.error('Error cancelling registration:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// ✅ TEST ENDPOINT - Remove in production
router.get('/test-notification', protect, async (req, res) => {
  try {
    const Notification = require('../models/Notification');
    const patients = await User.find({ userType: 'patient' }).select('_id');
    
    const testNotif = await Notification.create({
      title: 'Test Notification',
      message: 'This is a test notification from server',
      type: 'TEST',
      recipients: patients.map(p => p._id),
      createdAt: new Date()
    });
    
    // Emit via socket if available
    if (global.io) {
      global.io.to('all_patients').emit('health_camp_notification', {
        id: testNotif._id,
        title: 'Test Notification',
        message: 'This is a test notification from server',
        type: 'TEST',
        createdAt: new Date()
      });
      console.log('✅ Test notification emitted to all_patients');
    }
    
    res.json({ 
      success: true, 
      message: 'Test notification sent', 
      count: patients.length,
      notificationId: testNotif._id
    });
  } catch (error) {
    console.error('Error sending test notification:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;