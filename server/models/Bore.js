const mongoose = require('mongoose');

const pipeEntrySchema = new mongoose.Schema({
  size: { type: Number, required: true },
  length: { type: Number, required: true },
  pricePerPipeFoot: { type: Number, default: 0 },
}, { _id: false });

const feetEntrySchema = new mongoose.Schema({
  length: { type: Number, required: true },
  pricePerFeet: { type: Number, default: 0 },
}, { _id: false });

const paymentSchema = new mongoose.Schema({
  date: { type: Date, required: true },
  amount: { type: Number, required: true },
}, { _id: true });

const boreSchema = new mongoose.Schema({
  date: { type: Date, required: true },
  boreNumber: { type: String, required: true },
  totalFeet: { type: Number, default: 0 },
  pricePerFeet: { type: Number, default: 0 },
  agentCommissionPerFeet: { type: Number, default: 0 },
  agentCommissionPerPipeFoot: { type: Number, default: 0 },
  commissionSettled: { type: Number, default: 0 },
  agentName: { type: String, default: '' },
  steelFeet: { type: Number, default: 0 },
  steelPricePerFeet: { type: Number, default: 0 },
  steelAgentCommission: { type: Number, default: 0 },
  steelWeldingCharge: { type: Number, default: 0 },
  totalBill: { type: Number, default: 0 },
  managerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Manager', required: true, index: true },
  pipesUsed: [pipeEntrySchema],
  feetEntries: [feetEntrySchema],
  payments: [paymentSchema],
});

module.exports = mongoose.model('Bore', boreSchema);
