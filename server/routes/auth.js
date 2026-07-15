const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const Owner = require('../models/Owner');
const { setOtp, getOtp, deleteOtp } = require('../otpHelper');

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID_WEB);

const JWT_SECRET = process.env.JWT_SECRET || 'aquatrack-jwt-secret-change-in-production';

function signToken(owner) {
  return jwt.sign({ id: owner._id.toString(), email: owner.email }, JWT_SECRET, { expiresIn: '30d' });
}

function authMiddleware(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }
  try {
    const decoded = jwt.verify(header.split(' ')[1], JWT_SECRET);
    req.ownerId = decoded.id;
    req.ownerEmail = decoded.email;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}

// POST /api/auth/owner/signup
router.post('/owner/signup', async (req, res) => {
  try {
    const { name, email, password, phone, partnership, partnerEmails } = req.body;
    if (!name || !email || !password || !phone) {
      return res.status(400).json({ error: 'Name, email, phone, and password are required' });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }
    if (!/^\d{10}$/.test(phone)) {
      return res.status(400).json({ error: 'Phone must be a 10-digit number' });
    }

    const existing = await Owner.findOne({ email });
    if (existing) {
      return res.status(409).json({ error: 'An account with this email already exists' });
    }

    const existingPhone = await Owner.findOne({ phone });
    if (existingPhone) {
      return res.status(409).json({ error: 'An account with this phone number already exists' });
    }

    const owner = await Owner.create({
      name, email, phone, password,
      partnership: partnership === true,
      partnerEmails: Array.isArray(partnerEmails) ? partnerEmails : [],
    });
    const token = signToken(owner);
    res.status(201).json({
      token,
      owner: { id: owner._id.toString(), name: owner.name, email: owner.email, phone: owner.phone },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/auth/owner/signin
router.post('/owner/signin', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const owner = await Owner.findOne({ email });
    if (!owner) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    if (owner.locked) {
      const reason = owner.statusReason ? `\nReason: ${owner.statusReason}` : '';
      return res.status(403).json({ error: `Your account has been locked.${reason}` });
    }

    if (owner.subscriptionDisabled) {
      return res.status(403).json({ error: 'Your subscription has been disabled. Contact support.' });
    }

    const valid = await owner.comparePassword(password);
    if (!valid) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = signToken(owner);
    res.json({
      token,
      owner: { id: owner._id.toString(), name: owner.name, email: owner.email, phone: owner.phone },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/auth/owner/me  — verify token and return owner
router.get('/owner/me', authMiddleware, async (req, res) => {
  try {
    const owner = await Owner.findById(req.ownerId);
    if (!owner) return res.status(404).json({ error: 'Owner not found' });
    res.json({ id: owner._id.toString(), name: owner.name, email: owner.email, phone: owner.phone, subscriptionDisabled: owner.subscriptionDisabled || false });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/auth/owner/forgot-password  — send OTP
router.post('/owner/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: 'Email is required' });

    const owner = await Owner.findOne({ email });
    if (!owner) return res.status(404).json({ error: 'No account found with this email' });

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    await setOtp(email, otp, 'password-reset');

    const nodemailer = require('nodemailer');
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: { user: process.env.EMAIL_USER, pass: process.env.EMAIL_PASS },
    });
    await transporter.sendMail({
      from: `"AquaTrack" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: 'Your AquaTrack Password Reset OTP',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
          <h2 style="color: #1565C0;">AquaTrack Password Reset</h2>
          <p>Use this OTP to reset your password:</p>
          <div style="font-size: 32px; font-weight: bold; letter-spacing: 6px;
                      text-align: center; padding: 16px; margin: 16px 0;
                      background: #F5F7FA; border-radius: 8px; color: #1565C0;">
            ${otp}
          </div>
          <p>This code expires in 5 minutes.</p>
        </div>
      `,
    });

    res.json({ message: 'OTP sent to your email' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/auth/owner/reset-password  — verify OTP and set new password
router.post('/owner/reset-password', async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;
    if (!email || !otp || !newPassword) {
      return res.status(400).json({ error: 'Email, OTP, and new password are required' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }

    const record = await getOtp(email, otp, 'password-reset');
    if (!record) return res.status(400).json({ error: 'Invalid or expired OTP' });

    await deleteOtp(email, 'password-reset');

    const owner = await Owner.findOne({ email });
    if (!owner) return res.status(404).json({ error: 'Owner not found' });

    owner.password = newPassword;
    await owner.save();

    res.json({ message: 'Password reset successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/auth/owner/account  — delete owner account
router.delete('/owner/account', authMiddleware, async (req, res) => {
  try {
    await Owner.findByIdAndDelete(req.ownerId);
    res.json({ message: 'Account deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/auth/owner/password  — update password (authenticated)
router.put('/owner/password', authMiddleware, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ error: 'Current and new password are required' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }

    const owner = await Owner.findById(req.ownerId);
    if (!owner) return res.status(404).json({ error: 'Owner not found' });

    const valid = await owner.comparePassword(currentPassword);
    if (!valid) return res.status(401).json({ error: 'Current password is incorrect' });

    owner.password = newPassword;
    await owner.save();

    res.json({ message: 'Password updated successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/auth/owner/google  — sign in / sign up with Google ID token
router.post('/owner/google', async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken) return res.status(400).json({ error: 'ID token is required' });

    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: [process.env.GOOGLE_CLIENT_ID_WEB, process.env.GOOGLE_CLIENT_ID_ANDROID],
    });
    const payload = ticket.getPayload();
    if (!payload) return res.status(401).json({ error: 'Invalid token' });

    const email = payload.email;
    const name = payload.name || 'Owner';

    let owner = await Owner.findOne({ email });
    if (owner && owner.locked) {
      const reason = owner.statusReason ? `\nReason: ${owner.statusReason}` : '';
      return res.status(403).json({ error: `Your account has been locked.${reason}` });
    }
    if (owner && owner.subscriptionDisabled) {
      return res.status(403).json({ error: 'Your subscription has been disabled. Contact support.' });
    }
    if (!owner) {
      owner = await Owner.create({
        name,
        email,
        password: Math.random().toString(36).slice(2) + Math.random().toString(36).slice(2),
      });
    }

    const token = signToken(owner);
    res.json({
      token,
      owner: { id: owner._id.toString(), name: owner.name, email: owner.email },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = { router, authMiddleware };
