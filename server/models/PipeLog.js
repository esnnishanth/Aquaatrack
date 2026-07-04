const mongoose = require('mongoose');

const pipeLogSchema = new mongoose.Schema({
  date: { type: Date, required: true },
  type: { type: String, required: true },
  quantity: { type: Number, required: true },
  diameter: { type: Number, default: 0 },
  relatedBore: { type: String, default: null },
  managerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Manager', required: true, index: true },
});

module.exports = mongoose.model('PipeLog', pipeLogSchema);
