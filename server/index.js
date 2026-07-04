const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const mongoose = require('mongoose');
const nodemailer = require('nodemailer');
const cookieParser = require('cookie-parser');
const { setOtp, getOtp, deleteOtp } = require('./otpHelper');

dotenv.config({ path: path.join(__dirname, '..', '.env') });

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(cookieParser());

// ── MongoDB connection ────────────────────────────────────────────────────────
const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/aquatrack';

// ── Middleware: wait for MongoDB ───────────────────────────────────────────────
app.use(async (req, res, next) => {
  if (mongoose.connection.readyState === 0) {
    try {
      await mongoose.connect(MONGO_URI, { serverSelectionTimeoutMS: 5000 });
      console.log('MongoDB connected');
    } catch (err) {
      console.error('MongoDB connection error:', err);
      return res.status(503).json({ error: 'Database connection failed. Please try again.' });
    }
  } else if (mongoose.connection.readyState === 2) {
    // connecting — wait up to 5s
    try {
      await new Promise((resolve, reject) => {
        mongoose.connection.once('connected', resolve);
        mongoose.connection.once('error', reject);
        setTimeout(() => reject(new Error('Connection timeout')), 5000);
      });
    } catch (err) {
      console.error('MongoDB connection timeout:', err);
      return res.status(503).json({ error: 'Database connection timed out. Please try again.' });
    }
  }
  next();
});

// ── EJS / Admin ────────────────────────────────────────────────────────────────
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use('/admin', require('./routes/admin'));

// ── Routes ────────────────────────────────────────────────────────────────────
app.use('/api/owners', require('./routes/owners'));
app.use('/api/managers', require('./routes/managers'));
app.use('/api/managers/:managerId/agents', require('./routes/agents'));
app.use('/api/managers/:managerId/bores', require('./routes/bores'));
app.use('/api/managers/:managerId/workers', require('./routes/workers'));
app.use('/api/managers/:managerId', require('./routes/finance'));
app.use('/api/managers/:managerId', require('./routes/pipe'));
app.use('/api/auth', require('./routes/auth').router);

// ── Email OTP (MongoDB-backed for serverless) ─────────────────────────────────
function generateOtp() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

async function sendOtpEmail(recipientEmail, otp) {
  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });

  await transporter.sendMail({
    from: `"AquaTrack" <${process.env.EMAIL_USER}>`,
    to: recipientEmail,
    subject: 'Your AquaTrack OTP Code',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
        <h2 style="color: #1565C0;">AquaTrack Verification</h2>
        <p>Your one-time verification code is:</p>
        <div style="font-size: 32px; font-weight: bold; letter-spacing: 6px;
                    text-align: center; padding: 16px; margin: 16px 0;
                    background: #F5F7FA; border-radius: 8px; color: #1565C0;">
          ${otp}
        </div>
        <p>This code expires in 5 minutes.</p>
        <p style="color: #6B7280; font-size: 12px;">If you didn't request this, ignore this email.</p>
      </div>
    `,
  });
}

app.post('/api/send-otp', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: 'Email is required' });

    const otp = generateOtp();
    await setOtp(email, otp);
    await sendOtpEmail(email, otp);
    res.json({ message: 'OTP sent successfully' });
  } catch (error) {
    console.error('Error sending OTP:', error);
    res.status(500).json({ error: 'Failed to send OTP. Check EMAIL_USER/EMAIL_PASS in .env' });
  }
});

app.post('/api/verify-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) return res.status(400).json({ error: 'Email and OTP are required' });

    const record = await getOtp(email, otp);
    if (!record) return res.status(400).json({ error: 'Invalid or expired OTP' });

    await deleteOtp(email);
    res.json({ message: 'OTP verified successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  const states = ['disconnected', 'connected', 'connecting', 'disconnecting'];
  res.json({ status: 'ok', mongodb: states[mongoose.connection.readyState] || 'unknown' });
});

app.get('/', (req, res) => {
  res.redirect('/api/health');
});

// ── Start (local) ─────────────────────────────────────────────────────────────
const port = Number(process.env.PORT) || 9000;

module.exports = app;

if (require.main === module) {
  app.listen(port, '0.0.0.0', () => {
    console.log(`AquaTrack API running on port ${port}`);
  });
}
