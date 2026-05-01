const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const http = require('http'); // ✅ ADD THIS
const socketIO = require('socket.io'); // ✅ ADD THIS

// Load environment variables
dotenv.config();

// Import routes - CORRECT PATHS for your structure
const authRoutes = require('./src/routes/authRoutes');
const appointmentRoutes = require('./src/routes/appointmentRoutes');
const doctorRoutes = require('./src/routes/doctorRoutes');
const patientRoutes = require('./src/routes/patientRoutes');
const prescriptionRoutes = require('./src/routes/prescriptionRoutes');
const billRoutes = require('./src/routes/billRoutes');
const medicineRoutes = require('./src/routes/medicineRoutes');
const healthFeedRoutes = require('./src/routes/healthFeedRoutes');
const canteenRoutes = require('./src/routes/canteenRoutes');
const notificationRoutes = require('./src/routes/notificationRoutes'); // ✅ ADD THIS

// Import services - CREATE THESE FILES
const WebSocketService = require('./src/services/webSocketService'); // ✅ CREATE THIS
const { initNotificationService } = require('./src/controllers/healthFeedController'); // ✅ MODIFY THIS

const app = express();

// CORS Configuration
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  res.header('Access-Control-Allow-Credentials', 'true');
  
  if (req.method === 'OPTIONS') {
    return res.status(200).json({});
  }
  next();
});

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Origin', 'X-Requested-With', 'Accept'],
  credentials: true
}));
// Add this line after your middleware setup
app.use('/uploads', express.static('uploads'));
// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`📨 ${req.method} ${req.url}`);
  if (req.method === 'POST' || req.method === 'PUT') {
    const safeBody = { ...req.body };
    if (safeBody.password) safeBody.password = '***HIDDEN***';
    console.log('   Body:', safeBody);
  }
  next();
});

// Database connection
const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/seva-pulse';
    console.log(`📡 Connecting to MongoDB at: ${mongoURI}`);
    
    await mongoose.connect(mongoURI);
    
    console.log('✅ MongoDB connected successfully');
    console.log(`📊 Database name: ${mongoose.connection.db.databaseName}`);
    
    const collections = await mongoose.connection.db.listCollections().toArray();
    console.log(`📚 Available collections: ${collections.map(c => c.name).join(', ')}`);
    
  } catch (error) {
    console.error('❌ MongoDB connection error:', error.message);
    process.exit(1);
  }
};

// Test endpoints
app.get('/test', (req, res) => {
  console.log('✅ Test endpoint accessed');
  res.json({ 
    success: true, 
    message: 'Server is working!',
    timestamp: new Date().toISOString()
  });
});

app.get('/api/health', (req, res) => {
  console.log('✅ Health check accessed');
  res.status(200).json({ 
    status: 'OK', 
    message: 'SevaPulse Backend is running',
    timestamp: new Date().toISOString(),
    mongodb: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
    websocket: global.io ? 'enabled' : 'disabled'
  });
});

app.get('/ping', (req, res) => {
  res.send('pong');
});

// API Routes
console.log('📌 Registering API routes...');
app.use('/api/auth', authRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/doctors', doctorRoutes);
app.use('/api/patients', patientRoutes);
app.use('/api/prescriptions', prescriptionRoutes);
app.use('/api/bills', billRoutes);
app.use('/api/medicines', medicineRoutes);
app.use('/api/health-feed', healthFeedRoutes);
app.use('/api/canteen', canteenRoutes);
app.use('/api/notifications', notificationRoutes); // ✅ ADD THIS
console.log('✅ All API routes registered');

// 404 handler
app.use((req, res) => {
  console.log(`⚠️  404 - Route not found: ${req.method} ${req.url}`);
  res.status(404).json({ 
    success: false, 
    message: `Route ${req.method} ${req.url} not found` 
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('❌ Server error:', err.message);
  
  if (res.headersSent) {
    return next(err);
  }
  
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error'
  });
});

// Start server with WebSocket support
const PORT = process.env.PORT || 5000;
const HOST = '0.0.0.0';

function getLocalIp() {
  const { networkInterfaces } = require('os');
  const nets = networkInterfaces();
  
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      if (net.family === 'IPv4' && !net.internal) {
        return net.address;
      }
    }
  }
  return 'localhost';
}

connectDB().then(async () => {
  // ✅ CREATE HTTP SERVER
  const server = http.createServer(app);
  
  // ✅ INITIALIZE WEBSOCKET SERVICE
  const webSocketService = new WebSocketService(server);
  const io = webSocketService.getIO();
  
  // ✅ STORE IO IN GLOBAL FOR ACCESS IN CONTROLLERS
  global.io = io;
  
  // ✅ INITIALIZE NOTIFICATION SERVICE WITH IO
  initNotificationService(io);
  
  console.log('✅ WebSocket and Notification services initialized');
  
  // ✅ START SERVER
  server.listen(PORT, HOST, () => {
    console.log(`
    ═══════════════════════════════════════════════════════
    🚀 SevaPulse Backend Server is running!
    ═══════════════════════════════════════════════════════
    📡 Local:        http://localhost:${PORT}
    🌐 Network:      http://${getLocalIp()}:${PORT}
    📋 Health Check: http://localhost:${PORT}/api/health
    🧪 Test:         http://localhost:${PORT}/test
    🔌 WebSocket:    ws://${getLocalIp()}:${PORT}
    ═══════════════════════════════════════════════════════
    `);
  });
}).catch(err => {
  console.error('❌ Failed to start server:', err);
  process.exit(1);
});