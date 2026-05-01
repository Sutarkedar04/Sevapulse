// test-register.js
const mongoose = require('mongoose');
const User = require('./src/models/User');

async function test() {
  try {
    await mongoose.connect('mongodb+srv://trainerapp:trainer123@cluster0.nwz4zcn.mongodb.net/sevapulse?appName=Cluster0');
    console.log('Connected');
    
    const user = new User({
      name: 'Test User',
      email: 'test123@test.com',
      password: 'password123',
      phone: '1234567890',
      role: 'doctor'
    });
    
    console.log('Saving user...');
    await user.save();
    console.log('User saved successfully:', user._id);
    
    await mongoose.disconnect();
  } catch (error) {
    console.error('Error:', error.message);
    console.error('Stack:', error.stack);
  }
}

test();