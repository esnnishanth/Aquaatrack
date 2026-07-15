const express = require('express');
const router = express.Router();
const Manager = require('../models/Manager');
const Owner = require('../models/Owner');
const Worker = require('../models/Worker');
const Bore = require('../models/Bore');
const NormalExpense = require('../models/NormalExpense');
const LabourPayment = require('../models/LabourPayment');
const PipeLog = require('../models/PipeLog');
const PipeStockItem = require('../models/PipeStockItem');
const Agent = require('../models/Agent');

async function buildManagerResponse(manager) {
  const [workers, bores, normalExpenses, labourPayments, pipeLogs, agents, pipeStock] = await Promise.all([
    Worker.find({ managerId: manager._id }).lean(),
    Bore.find({ managerId: manager._id }).lean(),
    NormalExpense.find({ managerId: manager._id }).lean(),
    LabourPayment.find({ managerId: manager._id }).lean(),
    PipeLog.find({ managerId: manager._id }).lean(),
    Agent.find({ managerId: manager._id }).lean(),
    PipeStockItem.find({ managerId: manager._id }).lean(),
  ]);

  return {
    id: manager._id.toString(),
    name: manager.name,
    vehicleNumber: manager.vehicleNumber,
    password: manager.password || null,
    ownerId: manager.ownerId || null,
    frozen: manager.frozen || false,
    locked: manager.locked || false,
    statusReason: manager.statusReason || '',
    statusHistory: (manager.statusHistory || []).map(h => ({
      action: h.action,
      reason: h.reason,
      date: h.date,
    })),
    data: {
        workers: workers.map(w => ({
          id: w._id.toString(),
          name: w.name,
          place: w.place,
          monthlySalary: w.monthlySalary,
          monthsWorked: w.monthsWorked,
          amountPaid: w.amountPaid,
          joiningDate: w.joiningDate || null,
          absenceRanges: (w.absenceRanges || []).map(a => ({
          id: a._id.toString(),
          fromDate: a.fromDate,
          toDate: a.toDate,
          workerId: w._id.toString(),
        })),
      })),
      bores: bores.map(b => ({
        id: b._id.toString(),
        date: b.date,
        boreNumber: b.boreNumber,
        totalFeet: b.totalFeet,
        pricePerFeet: b.pricePerFeet,
        agentCommissionPerFeet: b.agentCommissionPerFeet,
        agentCommissionPerPipeFoot: b.agentCommissionPerPipeFoot,
        commissionSettled: b.commissionSettled,
        agentName: b.agentName,
        steelFeet: b.steelFeet || 0,
        steelPricePerFeet: b.steelPricePerFeet || 0,
        steelAgentCommission: b.steelAgentCommission || 0,
        steelWeldingCharge: b.steelWeldingCharge || 0,
        totalBill: b.totalBill,
        pipesUsed: (b.pipesUsed || []).map(p => ({
          size: p.size,
          length: p.length,
          pricePerPipeFoot: p.pricePerPipeFoot,
        })),
        feetEntries: (b.feetEntries || []).map(f => ({
          length: f.length,
          pricePerFeet: f.pricePerFeet,
        })),
        payments: (b.payments || []).map(p => ({
          id: p._id.toString(),
          date: p.date,
          amount: p.amount,
          method: p.method || 'cash',
        })),
      })),
      normalExpenses: normalExpenses.map(e => ({
        id: e._id.toString(),
        description: e.description,
        amount: e.amount,
        date: e.date,
        method: e.method || 'cash',
        createdBy: e.createdBy,
      })),
      labourPayments: labourPayments.map(l => ({
        id: l._id.toString(),
        workerId: l.workerId.toString(),
        amount: l.amount,
        date: l.date,
        method: l.method || 'cash',
        createdBy: l.createdBy,
      })),
      pipeLogs: pipeLogs.map(p => ({
        id: p._id.toString(),
        date: p.date,
        type: p.type,
        quantity: p.quantity,
        diameter: p.diameter,
        relatedBore: p.relatedBore || null,
      })),
      agents: agents.map(a => ({
        id: a._id.toString(),
        name: a.name,
      })),
      pipeStock: pipeStock.map(s => ({
        id: s._id.toString(),
        size: s.size,
        quantity: s.quantity,
      })),
    },
  };
}

router.get('/', async (req, res) => {
  try {
    const filter = {};
    if (req.query.ownerId) filter.ownerId = req.query.ownerId;
    const managers = await Manager.find(filter).lean();
    const result = await Promise.all(managers.map(m => buildManagerResponse(m)));
    res.json({ data: result });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/vehicle/:vehicleNumber', async (req, res) => {
  try {
    const manager = await Manager.findOne({ vehicleNumber: req.params.vehicleNumber });
    if (!manager) return res.json(null);
    const result = await buildManagerResponse(manager);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const manager = await Manager.findById(req.params.id);
    if (!manager) return res.status(404).json({ error: 'Manager not found' });
    const result = await buildManagerResponse(manager);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const { name, vehicleNumber, password, ownerId } = req.body;
    if (ownerId) {
      const owner = await Owner.findById(ownerId);
      if (owner && owner.managersUsed >= owner.maxManagers) {
        return res.status(403).json({ error: 'Manager limit reached. Upgrade subscription to add more managers.' });
      }
    }
    const manager = await Manager.create({ name, vehicleNumber, password, ownerId });
    if (ownerId) {
      await Owner.findByIdAndUpdate(ownerId, { $inc: { managersUsed: 1 } });
    }
    res.status(201).json({ id: manager._id.toString() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const manager = await Manager.findById(req.params.id);
    if (!manager) return res.status(404).json({ error: 'Manager not found' });
    if (req.body.name !== undefined) manager.name = req.body.name;
    if (req.body.vehicleNumber !== undefined) manager.vehicleNumber = req.body.vehicleNumber;
    if (req.body.password !== undefined) manager.password = req.body.password;
    if (req.body.statusReason !== undefined) manager.statusReason = req.body.statusReason;
    if (req.body.frozen !== undefined) {
      if (req.body.frozen !== manager.frozen) {
        if (!manager.statusHistory) manager.statusHistory = [];
        manager.statusHistory.push({
          action: req.body.frozen ? 'frozen' : 'unfrozen',
          reason: req.body.statusReason || '',
          date: new Date(),
        });
      }
      manager.frozen = req.body.frozen;
    }
    if (req.body.locked !== undefined) {
      if (req.body.locked !== manager.locked) {
        if (!manager.statusHistory) manager.statusHistory = [];
        manager.statusHistory.push({
          action: req.body.locked ? 'locked' : 'unlocked',
          reason: req.body.statusReason || '',
          date: new Date(),
        });
      }
      manager.locked = req.body.locked;
    }
    await manager.save();
    res.json({ message: 'Manager updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const managerId = req.params.id;
    const manager = await Manager.findById(managerId);
    await Promise.all([
      Worker.deleteMany({ managerId }),
      Bore.deleteMany({ managerId }),
      NormalExpense.deleteMany({ managerId }),
      LabourPayment.deleteMany({ managerId }),
      PipeLog.deleteMany({ managerId }),
      Agent.deleteMany({ managerId }),
      PipeStockItem.deleteMany({ managerId }),
    ]);
    await Manager.findByIdAndDelete(managerId);
    if (manager && manager.ownerId) {
      await Owner.findByIdAndUpdate(manager.ownerId, [
        { $set: { managersUsed: { $max: [0, { $subtract: ['$managersUsed', 1] }] } } }
      ]);
    }
    res.json({ message: 'Manager and all data deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
