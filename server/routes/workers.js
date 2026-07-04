const express = require('express');
const router = express.Router({ mergeParams: true });
const Worker = require('../models/Worker');
const LabourPayment = require('../models/LabourPayment');
const mongoose = require('mongoose');

router.post('/', async (req, res) => {
  try {
    const { name, place, monthlySalary, monthsWorked, joiningDate } = req.body;
    const worker = await Worker.create({
      name,
      place: place || '',
      monthlySalary: monthlySalary || 0,
      monthsWorked: monthsWorked ?? 12,
      joiningDate: joiningDate ? new Date(joiningDate) : null,
      amountPaid: 0,
      managerId: req.params.managerId,
    });
    res.status(201).json({ id: worker._id.toString() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/:workerId', async (req, res) => {
  try {
    const { name, place, monthlySalary, monthsWorked, joiningDate } = req.body;
    await Worker.findByIdAndUpdate(req.params.workerId, {
      name,
      place: place || '',
      monthlySalary: monthlySalary || 0,
      monthsWorked: monthsWorked ?? 12,
      joiningDate: joiningDate ? new Date(joiningDate) : null,
    });
    res.json({ message: 'Worker updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:workerId', async (req, res) => {
  try {
    await LabourPayment.deleteMany({ workerId: req.params.workerId });
    await Worker.findByIdAndDelete(req.params.workerId);
    res.json({ message: 'Worker deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/:workerId/absences', async (req, res) => {
  try {
    const worker = await Worker.findById(req.params.workerId);
    if (!worker) return res.status(404).json({ error: 'Worker not found' });
    worker.absenceRanges.push({
      fromDate: new Date(req.body.fromDate),
      toDate: new Date(req.body.toDate),
    });
    await worker.save();
    const newAbsence = worker.absenceRanges[worker.absenceRanges.length - 1];
    res.status(201).json({ id: newAbsence._id.toString() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:workerId/absences/:absenceId', async (req, res) => {
  try {
    const worker = await Worker.findById(req.params.workerId);
    if (!worker) return res.status(404).json({ error: 'Worker not found' });
    worker.absenceRanges.pull({ _id: req.params.absenceId });
    await worker.save();
    res.json({ message: 'Absence deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
