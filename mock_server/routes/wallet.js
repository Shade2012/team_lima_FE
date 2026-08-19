const express = require('express');
const router = express.Router();
const crypto = require('crypto');

function generateUuid() {
  return '019146a0-' + crypto.randomBytes(2).toString('hex') + '-7abc-9a12-' + crypto.randomBytes(6).toString('hex');
}

function getUserFromToken(req, db) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null;
  const token = authHeader.split(' ')[1];
  if (db.blacklistedTokens.includes(token)) return null;

  try {
    const parts = token.split('.');
    if (parts.length < 2) return null;
    const payload = JSON.parse(Buffer.from(parts[1], 'base64').toString('utf-8'));
    return db.users.find(u => u.id === payload.sub) || null;
  } catch (e) {
    return null;
  }
}

module.exports = function (db) {
  if (!db.wallets) db.wallets = [];
  if (!db.walletTransactions) db.walletTransactions = [];

  // Helper to find or create customer wallet
  function getOrCreateWallet(userId) {
    let wallet = db.wallets.find(w => w.userId === userId);
    if (!wallet) {
      wallet = {
        id: generateUuid(),
        userId: userId,
        balance: 0,
        currency: 'IDR',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      db.wallets.push(wallet);
    }
    return wallet;
  }

  // 1. GET /wallet (Role: CUSTOMER)
  router.get('/', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'CUSTOMER') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: Only CUSTOMER role can access wallet'
      });
    }

    const wallet = getOrCreateWallet(user.id);
    return res.status(200).json({
      message: 'Wallet balance retrieved successfully',
      data: wallet
    });
  });

  // 2. POST /wallet/topup (Role: CUSTOMER)
  router.post('/topup', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'CUSTOMER') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: Only CUSTOMER role can top up wallet'
      });
    }

    const { amount } = req.body || {};
    if (!amount || typeof amount !== 'number' || amount <= 0 || !Number.isInteger(amount)) {
      return res.status(400).json({
        status_code: 400,
        message: ['amount must be a positive integer']
      });
    }

    if (amount > 10000000) {
      return res.status(400).json({
        status_code: 400,
        message: ['Maximum top up amount is 10,000,000']
      });
    }

    const wallet = getOrCreateWallet(user.id);
    const MAX_BALANCE = 50000000;

    if (wallet.balance + amount > MAX_BALANCE) {
      return res.status(400).json({
        status_code: 400,
        message: 'Top up failed. Maximum balance exceeded'
      });
    }

    wallet.balance += amount;
    wallet.updatedAt = new Date().toISOString();

    const trx = {
      id: generateUuid(),
      walletId: wallet.id,
      amount: amount,
      type: 'TOPUP',
      refId: `TOPUP-${Date.now()}`,
      note: 'Wallet Top Up',
      createdAt: new Date().toISOString()
    };
    db.walletTransactions.push(trx);

    return res.status(201).json({
      message: 'Wallet topped up successfully',
      data: wallet
    });
  });

  // 3. GET /wallet/transactions (Role: CUSTOMER)
  router.get('/transactions', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'CUSTOMER') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: Only CUSTOMER role can view wallet transactions'
      });
    }

    const wallet = getOrCreateWallet(user.id);
    const transactions = db.walletTransactions
      .filter(t => t.walletId === wallet.id)
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    return res.status(200).json({
      message: 'Transactions retrieved successfully',
      data: transactions
    });
  });

  return router;
};
