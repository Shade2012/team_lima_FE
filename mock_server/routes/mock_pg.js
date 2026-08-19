const express = require('express');
const router = express.Router();

module.exports = function (db) {
  // Ensure payments and orders collections exist in db
  if (!db.payments) db.payments = [];
  if (!db.orders) db.orders = [];

  // 1. POST /mock-pg/transaction
  router.post('/transaction', (req, res) => {
    const { paymentId, orderId, amount, paymentMethod } = req.body || {};

    if (!paymentId || !orderId || amount === undefined) {
      return res.status(400).json({
        status_code: 400,
        message: ['paymentId, orderId, and amount are required']
      });
    }

    const tokenPayload = { paymentId, orderId };
    const snapToken = Buffer.from(JSON.stringify(tokenPayload)).toString('base64');
    const checkoutUrl = `https://mock-pg.team-lima.com/checkout/${snapToken}`;

    // Store/update payment record in db
    let payment = db.payments.find(p => p.id === paymentId);
    if (payment) {
      payment.providerTrxId = snapToken;
      payment.amount = amount;
      if (paymentMethod) payment.method = paymentMethod;
      payment.updatedAt = new Date().toISOString();
    } else {
      db.payments.push({
        id: paymentId,
        orderId,
        providerTrxId: snapToken,
        amount,
        method: paymentMethod || 'VIRTUAL_ACCOUNT',
        status: 'PENDING',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      });
    }

    return res.status(201).json({
      message: 'Success',
      data: {
        providerTrxId: snapToken,
        checkoutUrl
      }
    });
  });

  // 2. POST /mock-pg/simulate-payment
  router.post('/simulate-payment', (req, res) => {
    const { providerTrxId, paymentMethod } = req.body || {};

    if (!providerTrxId || !paymentMethod) {
      return res.status(400).json({
        status_code: 400,
        message: ['providerTrxId and paymentMethod are required']
      });
    }

    let paymentId;
    let orderId;

    try {
      const decodedString = Buffer.from(providerTrxId, 'base64').toString('utf-8');
      const tokenData = JSON.parse(decodedString);

      if (!tokenData.paymentId || !tokenData.orderId) {
        return res.status(400).json({
          status_code: 400,
          message: 'Invalid Snap Token structure'
        });
      }

      paymentId = tokenData.paymentId;
      orderId = tokenData.orderId;
    } catch (e) {
      return res.status(400).json({
        status_code: 400,
        message: 'Invalid Snap Token'
      });
    }

    // Process payment success
    let payment = db.payments.find(p => p.id === paymentId);
    if (payment) {
      payment.status = 'SUCCESS';
      payment.providerTrxId = providerTrxId;
      payment.method = paymentMethod;
      payment.paidAt = new Date().toISOString();
      payment.updatedAt = new Date().toISOString();
    } else {
      db.payments.push({
        id: paymentId,
        orderId,
        providerTrxId,
        method: paymentMethod,
        status: 'SUCCESS',
        paidAt: new Date().toISOString(),
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      });
    }

    // Process order update
    let order = db.orders.find(o => o.id === orderId);
    if (order) {
      order.status = 'PAID';
      order.updatedAt = new Date().toISOString();

      // Deduct E_WALLET balance if paymentMethod is E_WALLET
      if (paymentMethod === 'E_WALLET' && order.customerId) {
        if (!db.wallets) db.wallets = [];
        if (!db.walletTransactions) db.walletTransactions = [];

        let wallet = db.wallets.find(w => w.userId === order.customerId);
        const amountToDeduct = order.totalPrice || (payment ? payment.amount : 0);

        if (wallet) {
          if (wallet.balance < amountToDeduct) {
            return res.status(400).json({
              status_code: 400,
              message: 'Insufficient Wallet Balance. Please top up your wallet.'
            });
          }
          wallet.balance -= amountToDeduct;
          wallet.updatedAt = new Date().toISOString();

          db.walletTransactions.push({
            id: '019146a0-' + require('crypto').randomBytes(2).toString('hex') + '-7abc-9a12-' + require('crypto').randomBytes(6).toString('hex'),
            walletId: wallet.id,
            amount: -amountToDeduct,
            type: 'PAYMENT',
            refId: order.id,
            note: `Payment for Order ${order.id}`,
            createdAt: new Date().toISOString()
          });
        }
      }
    } else {
      db.orders.push({
        id: orderId,
        status: 'PAID',
        updatedAt: new Date().toISOString()
      });
    }

    return res.status(200).json({
      message: 'Success',
      data: true
    });
  });

  return router;
};
