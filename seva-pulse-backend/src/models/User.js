// src/models/User.js
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true, select: false },
  role: { type: String, enum: ['admin', 'doctor', 'patient', 'staff'], default: 'patient' },
  phone: { type: String, required: true },
  address: {
    street: String,
    city: String,
    state: String,
    zipCode: String
  },
  profilePicture: { type: String, default: '' },
  isActive: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now }
});

// ✅ CORRECT VERSION FOR MONGOSE v7+ - NO 'next' parameter
userSchema.pre('save', async function() {
  console.log('🔐 PRE-SAVE HOOK TRIGGERED');
  console.log('📝 this.isModified("password"):', this.isModified('password'));
  
  if (this.isModified('password')) {
    console.log('🔑 Hashing password...');
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    console.log('✅ Password hashed successfully');
  }
});

userSchema.methods.matchPassword = async function(enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', userSchema);