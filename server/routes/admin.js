const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const Owner = require('../models/Owner');

const JWT_SECRET = process.env.JWT_SECRET || 'aquatrack-jwt-secret-change-in-production';

async function adminAuth(req, res, next) {
  const token = req.cookies?.admin_token;
  if (!token) return res.redirect('/admin/login');
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const owner = await Owner.findById(decoded.id).lean();
    if (!owner) {
      res.clearCookie('admin_token');
      return res.redirect('/admin/login');
    }
    req.admin = { id: owner._id.toString(), name: owner.name, email: owner.email };
    next();
  } catch {
    res.clearCookie('admin_token');
    res.redirect('/admin/login');
  }
}

router.get('/login', (req, res) => {
  const token = req.cookies?.admin_token;
  if (token) {
    try {
      jwt.verify(token, JWT_SECRET);
      return res.redirect('/admin/dashboard');
    } catch {}
  }
  res.render('admin/login', { title: 'Admin Login' });
});

router.get('/dashboard', adminAuth, (req, res) => {
  res.render('admin/dashboard', { title: 'Dashboard', page: 'dashboard', admin: req.admin });
});

router.get('/managers', adminAuth, (req, res) => {
  res.render('admin/managers', { title: 'Managers', page: 'managers', admin: req.admin });
});

router.get('/managers/:id', adminAuth, (req, res) => {
  res.render('admin/manager-detail', { title: 'Manager Detail', page: 'manager-detail', managerId: req.params.id, admin: req.admin });
});

router.get('/owners', adminAuth, (req, res) => {
  res.render('admin/owners', { title: 'Owners', page: 'owners', admin: req.admin });
});

router.get('/owners/:id', adminAuth, (req, res) => {
  res.render('admin/owner-detail', { title: 'Owner Detail', page: 'owner-detail', ownerId: req.params.id, admin: req.admin });
});

router.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Email and password required' });

    const owner = await Owner.findOne({ email });
    if (!owner) return res.status(401).json({ error: 'Invalid email or password' });
    if (owner.locked) return res.status(403).json({ error: 'Account is locked' });

    const valid = await owner.comparePassword(password);
    if (!valid) return res.status(401).json({ error: 'Invalid email or password' });

    const token = jwt.sign({ id: owner._id.toString(), email: owner.email }, JWT_SECRET, { expiresIn: '30d' });
    res.cookie('admin_token', token, { httpOnly: true, sameSite: 'lax', maxAge: 30 * 24 * 60 * 60 * 1000 });
    res.json({ token, owner: { id: owner._id.toString(), name: owner.name, email: owner.email } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/api/logout', (req, res) => {
  res.clearCookie('admin_token');
  res.json({ message: 'Logged out' });
});

module.exports = router;
