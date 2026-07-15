const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

const ownerSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  phone: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
  locked: { type: Boolean, default: false },
  statusReason: { type: String, default: '' },
  statusHistory: [{
    action: { type: String },
    reason: { type: String, default: '' },
    date: { type: Date, default: Date.now },
  }],
  maxManagers: { type: Number, default: 0 },
  managersUsed: { type: Number, default: 0 },
  pricePerManager: { type: Number, default: 300 },
  spin: { type: String, default: '' },
  partnership: { type: Boolean, default: false },
  partnerEmails: [{ type: String }],
  subscriptionDisabled: { type: Boolean, default: false },
  subscription: {
    plan: { type: String, enum: ['free', 'basic', 'premium'], default: 'free' },
    status: { type: String, enum: ['active', 'expired', 'cancelled'], default: 'active' },
    startDate: { type: Date },
    endDate: { type: Date },
    amount: { type: Number, default: 0 },
  },
});

ownerSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

ownerSchema.methods.comparePassword = async function (candidate) {
  return bcrypt.compare(candidate, this.password);
};

module.exports = mongoose.model('Owner', ownerSchema);
