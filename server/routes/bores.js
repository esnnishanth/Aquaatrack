const express = require('express');
const router = express.Router({ mergeParams: true });
const Bore = require('../models/Bore');
const PipeLog = require('../models/PipeLog');
const PipeStockItem = require('../models/PipeStockItem');
const mongoose = require('mongoose');

async function adjustPipeStock(managerId, pipesUsed, multiplier) {
  for (const pipe of pipesUsed) {
    if (pipe.size <= 0) continue;
    const pipesNeeded = Math.ceil(pipe.length / 20);
    const qtyChange = pipesNeeded * multiplier;

    const stock = await PipeStockItem.findOne({ managerId, size: pipe.size });
    if (stock) {
      const newQty = stock.quantity + qtyChange;
      if (newQty <= 0) {
        await PipeStockItem.findByIdAndDelete(stock._id);
      } else {
        await PipeStockItem.findByIdAndUpdate(stock._id, { quantity: newQty });
      }
    } else if (multiplier > 0) {
      await PipeStockItem.create({ managerId, size: pipe.size, quantity: qtyChange });
    }
  }
}

router.post('/', async (req, res) => {
  try {
    const {
      date, boreNumber, totalFeet, pricePerFeet,
      agentCommissionPerFeet, agentCommissionPerPipeFoot,
      pipesUsed, feetEntries, agentName, totalBill,
      initialPayment, initialPaymentMethod, pipeLogs,
      steelFeet, steelPricePerFeet, steelAgentCommission, steelWeldingCharge,
    } = req.body;
    const managerId = req.params.managerId;

    const payments = [];
    if (initialPayment > 0) {
      payments.push({ date: new Date(), amount: initialPayment, method: initialPaymentMethod || 'cash' });
    }

    const bore = await Bore.create({
      date: new Date(date),
      boreNumber,
      totalFeet,
      pricePerFeet,
      agentCommissionPerFeet: agentCommissionPerFeet || 0,
      agentCommissionPerPipeFoot: agentCommissionPerPipeFoot || 0,
      commissionSettled: 0,
      agentName: agentName || '',
      steelFeet: steelFeet || 0,
      steelPricePerFeet: steelPricePerFeet || 0,
      steelAgentCommission: steelAgentCommission || 0,
      steelWeldingCharge: steelWeldingCharge || 0,
      totalBill,
      managerId,
      pipesUsed: pipesUsed || [],
      feetEntries: feetEntries || [],
      payments,
    });

    if (pipeLogs && pipeLogs.length > 0) {
      await PipeLog.insertMany(
        pipeLogs.map(log => ({
          date: new Date(log.date),
          type: log.type,
          quantity: log.quantity,
          diameter: log.diameter,
          relatedBore: log.relatedBore || null,
          managerId,
        }))
      );
    }

    await adjustPipeStock(managerId, pipesUsed || [], -1);

    res.status(201).json({ id: bore._id.toString() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/:boreId', async (req, res) => {
  try {
    const {
      date, boreNumber, totalFeet, pricePerFeet,
      agentCommissionPerFeet, agentCommissionPerPipeFoot,
      pipesUsed, feetEntries, agentName, totalBill,
      initialPayment, initialPaymentMethod, pipeLogs,
      steelFeet, steelPricePerFeet, steelAgentCommission, steelWeldingCharge,
    } = req.body;
    const managerId = req.params.managerId;
    const boreId = req.params.boreId;

    const oldBore = await Bore.findById(boreId);
    if (!oldBore) return res.status(404).json({ error: 'Bore not found' });

    const oldPipesUsed = oldBore.pipesUsed || [];

    const payments = oldBore.payments || [];
    if (initialPayment > 0 && payments.length === 0) {
      payments.push({ date: new Date(), amount: initialPayment, method: initialPaymentMethod || 'cash' });
    }

    await Bore.findByIdAndUpdate(boreId, {
      date: new Date(date),
      boreNumber,
      totalFeet,
      pricePerFeet,
      agentCommissionPerFeet: agentCommissionPerFeet || 0,
      agentCommissionPerPipeFoot: agentCommissionPerPipeFoot || 0,
      agentName: agentName || '',
      steelFeet: steelFeet || 0,
      steelPricePerFeet: steelPricePerFeet || 0,
      steelAgentCommission: steelAgentCommission || 0,
      steelWeldingCharge: steelWeldingCharge || 0,
      totalBill,
      pipesUsed: pipesUsed || [],
      feetEntries: feetEntries || [],
      payments,
    });

    await adjustPipeStock(managerId, oldPipesUsed, 1);
    await adjustPipeStock(managerId, pipesUsed || [], -1);

    res.json({ message: 'Bore updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:boreId', async (req, res) => {
  try {
    const bore = await Bore.findById(req.params.boreId);
    if (!bore) return res.status(404).json({ error: 'Bore not found' });

    await adjustPipeStock(req.params.managerId, bore.pipesUsed || [], 1);

    await Bore.findByIdAndDelete(req.params.boreId);
    res.json({ message: 'Bore deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/:boreId/settle', async (req, res) => {
  try {
    const bore = await Bore.findById(req.params.boreId);
    if (!bore) return res.status(404).json({ error: 'Bore not found' });
    const commission = (bore.agentCommissionPerFeet * bore.totalFeet) +
                       (bore.agentCommissionPerPipeFoot * bore.totalFeet) +
                       ((bore.steelAgentCommission || 0) * (bore.steelFeet || 0));
    await Bore.findByIdAndUpdate(req.params.boreId, { commissionSettled: commission });
    res.json({ message: 'Commission settled' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/:boreId/unsettle', async (req, res) => {
  try {
    await Bore.findByIdAndUpdate(req.params.boreId, { commissionSettled: 0 });
    res.json({ message: 'Commission unsettled' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/:boreId/payments', async (req, res) => {
  try {
    const bore = await Bore.findById(req.params.boreId);
    if (!bore) return res.status(404).json({ error: 'Bore not found' });
    const payment = { date: new Date(req.body.date), amount: req.body.amount, method: req.body.method || 'cash' };
    bore.payments.push(payment);
    await bore.save();
    const newPayment = bore.payments[bore.payments.length - 1];
    res.status(201).json({ id: newPayment._id.toString() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:boreId/payments/:paymentId', async (req, res) => {
  try {
    const bore = await Bore.findById(req.params.boreId);
    if (!bore) return res.status(404).json({ error: 'Bore not found' });
    bore.payments.pull({ _id: req.params.paymentId });
    await bore.save();
    res.json({ message: 'Payment deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
