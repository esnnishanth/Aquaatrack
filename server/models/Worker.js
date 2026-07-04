const mongoose = require('mongoose');

const absenceRangeSchema = new mongoose.Schema({
  fromDate: { type: Date, required: true },
  toDate: { type: Date, required: true },
}, { _id: true });

const workerSchema = new mongoose.Schema({
  name: { type: String, required: true },
  place: { type: String, default: '' },
  monthlySalary: { type: Number, default: 0 },
  joiningDate: { type: Date, default: null },
  monthsWorked: { type: Number, default: 12 },
  amountPaid: { type: Number, default: 0 },
  managerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Manager', required: true, index: true },
  absenceRanges: [absenceRangeSchema],
});

module.exports = mongoose.model('Worker', workerSchema);
