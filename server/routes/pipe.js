const express = require('express');
const router = express.Router({ mergeParams: true });
const PipeStockItem = require('../models/PipeStockItem');
const PipeLog = require('../models/PipeLog');

router.post('/pipe-stock', async (req, res) => {
  try {
    const { size, quantity } = req.body;
    const existing = await PipeStockItem.findOne({ managerId: req.params.managerId, size });
    if (existing) {
      existing.quantity += quantity;
      await existing.save();
      res.json({ id: existing._id.toString() });
    } else {
      const item = await PipeStockItem.create({ size, quantity, managerId: req.params.managerId });
      res.status(201).json({ id: item._id.toString() });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/pipe-stock/:size', async (req, res) => {
  try {
    const { quantity } = req.body;
    const size = parseFloat(req.params.size);
    const item = await PipeStockItem.findOne({ managerId: req.params.managerId, size });
    if (item) {
      item.quantity = quantity;
      await item.save();
      res.json({ message: 'Pipe stock updated' });
    } else {
      res.status(404).json({ error: 'Pipe stock not found for this size' });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/pipe-stock/:size', async (req, res) => {
  try {
    const size = parseFloat(req.params.size);
    await PipeStockItem.deleteOne({ managerId: req.params.managerId, size });
    res.json({ message: 'Pipe stock deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/pipe-logs', async (req, res) => {
  try {
    const { date, type, quantity, diameter, relatedBore } = req.body;
    const log = await PipeLog.create({
      date: new Date(date),
      type,
      quantity,
      diameter: diameter || 0,
      relatedBore: relatedBore || null,
      managerId: req.params.managerId,
    });
    res.status(201).json({ id: log._id.toString() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
