const mongoose = require('mongoose');

const pipeStockItemSchema = new mongoose.Schema({
  size: { type: Number, required: true },
  quantity: { type: Number, required: true },
  managerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Manager', required: true, index: true },
});

pipeStockItemSchema.index({ size: 1, managerId: 1 }, { unique: true });

module.exports = mongoose.model('PipeStockItem', pipeStockItemSchema);
