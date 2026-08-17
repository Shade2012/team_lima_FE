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
  if (!db.admissionScans) db.admissionScans = [];

  // 1. POST /scans (Role: GATE_OPERATOR)
  router.post('/', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'GATE_OPERATOR') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: Only GATE_OPERATOR role can scan tickets'
      });
    }

    if (!user.gateId) {
      return res.status(404).json({
        status_code: 404,
        message: 'Gate id has not been assigned to this operator yet'
      });
    }

    const { ticketId } = req.body || {};
    if (!ticketId) {
      return res.status(400).json({
        status_code: 400,
        message: ['ticketId is required']
      });
    }

    const ticket = db.tickets.find(t => t.id === ticketId);
    if (!ticket) {
      return res.status(404).json({
        status_code: 404,
        message: 'Ticket not found'
      });
    }

    const order = db.orders.find(o => o.id === ticket.orderId);
    if (!order || !['PAID', 'PARTIAL_REFUND'].includes(order.status)) {
      return res.status(409).json({
        status_code: 409,
        message: `Ticket must be paid (current status: ${order ? order.status : 'UNKNOWN'})`
      });
    }

    if (ticket.status === 'SEATED') {
      return res.status(409).json({
        status_code: 409,
        message: 'Ticket has already been scanned'
      });
    }

    if (ticket.status !== 'AVAILABLE') {
      return res.status(409).json({
        status_code: 409,
        message: `Ticket is no longer available (current status: ${ticket.status})`
      });
    }

    ticket.status = 'SEATED';
    ticket.updatedAt = new Date().toISOString();

    const scanRecord = {
      id: generateUuid(),
      ticketId,
      gateOperatorId: user.id,
      gateId: user.gateId,
      scannedAt: new Date().toISOString()
    };

    db.admissionScans.push(scanRecord);

    return res.status(201).json({
      message: 'Success',
      data: 'Success scans'
    });
  });

  // 2. GET /scans (Role: GATE_OPERATOR)
  router.get('/', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'GATE_OPERATOR') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: Only GATE_OPERATOR role can view admission scans'
      });
    }

    if (!user.gateId) {
      return res.status(404).json({
        status_code: 404,
        message: 'Gate id has not been assigned to this operator yet'
      });
    }

    const gate = db.gates.find(g => g.id === user.gateId);
    const eventId = gate ? gate.eventId : null;

    const scannedCount = db.admissionScans.filter(s => s.gateOperatorId === user.id).length;

    let totalTickets = 0;
    if (eventId) {
      const eventCategories = db.categories.filter(c => c.eventId === eventId).map(c => c.id);
      totalTickets = db.tickets.filter(t => eventCategories.includes(t.categoryId) && ['SEATED', 'AVAILABLE'].includes(t.status)).length;
    }

    return res.status(200).json({
      message: 'Success',
      data: {
        scanned: scannedCount,
        total: totalTickets || 100
      }
    });
  });

  return router;
};
