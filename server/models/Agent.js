const mongoose = require('mongoose');

const agentSchema = new mongoose.Schema({
  name: { type: String, required: true },
  managerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Manager', required: true, index: true },
});

agentSchema.index({ name: 1, managerId: 1 }, { unique: true });

module.exports = mongoose.model('Agent', agentSchema);
