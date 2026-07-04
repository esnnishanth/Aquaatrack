const Otp = require('./models/Otp');

async function setOtp(email, otp, purpose = 'general') {
  await Otp.deleteMany({ email, purpose });
  await Otp.create({
    email,
    otp,
    purpose,
    expiresAt: new Date(Date.now() + 5 * 60 * 1000),
  });
}

async function getOtp(email, otp, purpose = 'general') {
  const record = await Otp.findOne({ email, otp, purpose });
  if (!record) return null;
  if (Date.now() > record.expiresAt.getTime()) {
    await Otp.deleteOne({ _id: record._id });
    return null;
  }
  return record;
}

async function deleteOtp(email, purpose = 'general') {
  await Otp.deleteMany({ email, purpose });
}

async function cleanupExpired() {
  await Otp.deleteMany({ expiresAt: { $lt: new Date() } });
}

module.exports = { setOtp, getOtp, deleteOtp, cleanupExpired };
