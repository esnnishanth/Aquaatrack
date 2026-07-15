const mongoose = require('mongoose');

const normalExpenseSchema = new mongoose.Schema({
  description: { type: String, required: true },
  amount: { type: Number, required: true },
  date: { type: Date, required: true },
  method: { type: String, default: 'cash' },
  createdBy: { type: String, default: 'manager' },
  managerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Manager', required: true, index: true },
});

module.exports = mongoose.model('NormalExpense', normalExpenseSchema);
