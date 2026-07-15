const mongoose = require('mongoose');

const labourPaymentSchema = new mongoose.Schema({
  workerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Worker', required: true },
  amount: { type: Number, required: true },
  date: { type: Date, required: true },
  method: { type: String, default: 'cash' },
  createdBy: { type: String, default: 'manager' },
  managerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Manager', required: true, index: true },
});

module.exports = mongoose.model('LabourPayment', labourPaymentSchema);
