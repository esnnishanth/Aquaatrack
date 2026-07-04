const express = require('express');
const router = express.Router({ mergeParams: true });
const Agent = require('../models/Agent');

router.post('/', async (req, res) => {
  try {
    const agent = await Agent.create({ name: req.body.name, managerId: req.params.managerId });
    res.status(201).json({ id: agent._id.toString() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/:agentId', async (req, res) => {
  try {
    await Agent.findByIdAndUpdate(req.params.agentId, { name: req.body.name });
    res.json({ message: 'Agent updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:agentId', async (req, res) => {
  try {
    await Agent.findByIdAndDelete(req.params.agentId);
    res.json({ message: 'Agent deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
