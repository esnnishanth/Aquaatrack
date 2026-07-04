const express = require('express');
const router = express.Router();
const Owner = require('../models/Owner');
const Manager = require('../models/Manager');

router.get('/', async (req, res) => {
  try {
    if (req.query.email) {
      const owner = await Owner.findOne({ email: req.query.email });
      if (!owner) return res.json(null);
      return res.json(owner);
    }
    if (req.query.phone) {
      const owner = await Owner.findOne({ phone: req.query.phone });
      if (!owner) return res.json(null);
      return res.json(owner);
    }
    const owners = await Owner.find();
    res.json(owners);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const owner = await Owner.findById(req.params.id);
    if (!owner) return res.status(404).json({ error: 'Owner not found' });
    res.json(owner);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const { id, name, email } = req.body;
    const owner = await Owner.create({
      _id: id || undefined,
      name,
      email,
    });
    res.status(201).json(owner);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const owner = await Owner.findById(req.params.id);
    if (!owner) return res.status(404).json({ error: 'Owner not found' });
    if (req.body.name !== undefined) owner.name = req.body.name;
    if (req.body.email !== undefined) owner.email = req.body.email;
    if (req.body.phone !== undefined) owner.phone = req.body.phone;
    if (req.body.password) {
      owner.password = req.body.password;
    }
    if (req.body.locked !== undefined) {
      if (req.body.locked !== owner.locked) {
        if (!owner.statusHistory) owner.statusHistory = [];
        owner.statusHistory.push({
          action: req.body.locked ? 'locked' : 'unlocked',
          reason: req.body.statusReason || '',
          date: new Date(),
        });
      }
      owner.locked = req.body.locked;
    }
    if (req.body.statusReason !== undefined) owner.statusReason = req.body.statusReason;
    if (req.body.subscriptionDisabled !== undefined) owner.subscriptionDisabled = req.body.subscriptionDisabled;
    if (req.body.maxManagers !== undefined) owner.maxManagers = req.body.maxManagers;
    if (req.body.pricePerManager !== undefined) owner.pricePerManager = req.body.pricePerManager;
    if (req.body.spin !== undefined) owner.spin = req.body.spin;
    if (req.body.subscription !== undefined) {
      owner.subscription = { ...owner.subscription.toObject(), ...req.body.subscription };
    }
    await owner.save();
    res.json({ message: 'Owner updated', id: owner._id.toString(), name: owner.name, email: owner.email, phone: owner.phone, locked: owner.locked, maxManagers: owner.maxManagers, managersUsed: owner.managersUsed, pricePerManager: owner.pricePerManager, spin: owner.spin, subscription: owner.subscription, subscriptionDisabled: owner.subscriptionDisabled });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/:id/verify-spin', async (req, res) => {
  try {
    const { spin } = req.body;
    const owner = await Owner.findById(req.params.id);
    if (!owner) return res.status(404).json({ error: 'Owner not found' });
    if (!owner.spin) return res.json({ valid: false, error: 'SPIN not set' });
    const valid = owner.spin === spin;
    res.json({ valid });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    await Owner.findByIdAndDelete(req.params.id);
    res.json({ message: 'Owner deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
