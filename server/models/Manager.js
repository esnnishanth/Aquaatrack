const mongoose = require('mongoose');

const managerSchema = new mongoose.Schema({
  name: { type: String, required: true },
  vehicleNumber: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  ownerId: { type: String, default: null },
  frozen: { type: Boolean, default: false },
  locked: { type: Boolean, default: false },
  statusReason: { type: String, default: '' },
  statusHistory: [{
    action: { type: String, required: true },
    reason: { type: String, default: '' },
    date: { type: Date, default: Date.now },
  }],
});

module.exports = mongoose.model('Manager', managerSchema);
