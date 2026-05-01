const User = require('../models/User');
const Patient = require('../models/Patient');
const Doctor = require('../models/Doctor');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET || 'secretkey123', { expiresIn: '7d' });
};

exports.register = async (req, res) => {
  try {
    const {
      name, email, password, phone, userType,
      specialization, experience, dateOfBirth, gender
    } = req.body;

    console.log('📝 Register:', { name, email, phone, userType });

    if (!name || !email || !password || !phone) {
      return res.status(400).json({
        success: false,
        message: 'Please provide name, email, password and phone'
      });
    }

    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({ success: false, message: 'User already exists' });
    }

    // ✅ Pass plain password — User model pre('save') hook hashes it ONCE
    const user = await User.create({
      name,
      email,
      password,       // plain text here, DO NOT hash manually
      phone,
      role: userType || 'patient',
      isActive: true
    });

    console.log('✅ User created:', user._id, '| role:', user.role);

    // ✅ Create the RIGHT profile based on role
    if (user.role === 'doctor') {
      await Doctor.create({
        user: user._id,
        specialization: specialization || 'General',
        experience: parseInt(experience) || 0,
        consultationFee: 500,
        department: specialization || 'General',
        bio: '',
        qualifications: [],
      });
      console.log('✅ Doctor profile created');
    } else {
      await Patient.create({
        user: user._id,
        dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : null,
        gender: gender || 'Not specified',
      });
      console.log('✅ Patient profile created');
    }

    const token = generateToken(user._id);

    return res.status(201).json({
      success: true,
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        userType: user.role,
        createdAt: user.createdAt
      }
    });

  } catch (error) {
    console.error('❌ Registration error:', error.message);
    if (error.code === 11000) {
      return res.status(400).json({ success: false, message: 'Email already registered' });
    }
    return res.status(500).json({ success: false, message: error.message || 'Registration failed' });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password, userType } = req.body;

    console.log('🔐 Login:', { email, userType });

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Please provide email and password' });
    }

    const user = await User.findOne({ email }).select('+password');

    if (!user) {
      console.log('❌ User not found:', email);
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    console.log('🔐 Password match:', isMatch);

    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    // ✅ Better error message so you know exactly what went wrong
    if (userType && user.role !== userType) {
      console.log('❌ Role mismatch — expected:', userType, 'actual:', user.role);
      return res.status(401).json({
        success: false,
        message: `This email is registered as a ${user.role}, not a ${userType}`
      });
    }

    const token = generateToken(user._id);

    let profile = null;
    if (user.role === 'patient') {
      profile = await Patient.findOne({ user: user._id });
    } else if (user.role === 'doctor') {
      profile = await Doctor.findOne({ user: user._id });
    }

    console.log('✅ Login successful:', email);

    return res.status(200).json({
      success: true,
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        userType: user.role,
        specialization: profile?.specialization || null,
        experience: profile?.experience || null,
        createdAt: user.createdAt
      }
    });

  } catch (error) {
    console.error('❌ Login error:', error.message);
    return res.status(500).json({ success: false, message: error.message || 'Login failed' });
  }
};

exports.getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    let profile = null;
    if (user.role === 'patient') {
      profile = await Patient.findOne({ user: user._id });
    } else if (user.role === 'doctor') {
      profile = await Doctor.findOne({ user: user._id });
    }

    return res.status(200).json({
      success: true,
      data: {
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          userType: user.role,
          createdAt: user.createdAt,
          ...(profile ? profile.toObject() : {})
        }
      }
    });
  } catch (error) {
    console.error('❌ GetMe error:', error.message);
    return res.status(500).json({ success: false, message: error.message });
  }
};

exports.logout = async (req, res) => {
  return res.status(200).json({ success: true, message: 'Logged out successfully' });
};