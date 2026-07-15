const express = require('express');
const router = express.Router({ mergeParams: true });
const NormalExpense = require('../models/NormalExpense');
const LabourPayment = require('../models/LabourPayment');
const Worker = require('../models/Worker');

router.post('/normal-expenses', async (req, res) => {
  try {
    const { description, amount, date, method, createdBy } = req.body;
    const expense = await NormalExpense.create({
      description,
      amount,
      date: new Date(date),
      method: method || 'cash',
      createdBy: createdBy || 'manager',
      managerId: req.params.managerId,
    });
    res.status(201).json({ id: expense._id.toString() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/normal-expenses/:expenseId', async (req, res) => {
  try {
    await NormalExpense.findByIdAndDelete(req.params.expenseId);
    res.json({ message: 'Expense deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/labour-payments', async (req, res) => {
  try {
    const { workerId, amount, date, method, createdBy } = req.body;
    const payment = await LabourPayment.create({
      workerId,
      amount,
      date: new Date(date),
      method: method || 'cash',
      createdBy: createdBy || 'manager',
      managerId: req.params.managerId,
    });

    const worker = await Worker.findById(workerId);
    if (worker) {
      worker.amountPaid = (worker.amountPaid || 0) + amount;
      await worker.save();
    }

    res.status(201).json({ id: payment._id.toString() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/labour-payments/:paymentId', async (req, res) => {
  try {
    const payment = await LabourPayment.findById(req.params.paymentId);
    if (!payment) return res.status(404).json({ error: 'Payment not found' });

    const worker = await Worker.findById(payment.workerId);
    if (worker) {
      worker.amountPaid = Math.max(0, (worker.amountPaid || 0) - payment.amount);
      await worker.save();
    }

    await LabourPayment.findByIdAndDelete(req.params.paymentId);
    res.json({ message: 'Labour payment deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
