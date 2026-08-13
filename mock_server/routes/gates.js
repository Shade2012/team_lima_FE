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
  // 1. GET /gates/event/:eventId (Public)
  router.get('/event/:eventId', (req, res) => {
    const gates = db.gates
      .filter(g => g.eventId === req.params.eventId)
      .sort((a, b) => a.name.localeCompare(b.name));

    return res.status(200).json({
      message: 'Success',
      data: gates
    });
  });

  // 2. POST /gates (Role: ORGANIZER)
  router.post('/', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'ORGANIZER') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: Only ORGANIZER can create gates'
      });
    }

    const { eventId, name } = req.body;
    if (!eventId || !name) {
      return res.status(400).json({
        status_code: 400,
        message: ['eventId and name are required']
      });
    }

    const event = db.events.find(e => e.id === eventId);
    if (!event) {
      return res.status(404).json({
        status_code: 404,
        message: 'Event not found'
      });
    }

    if (event.organizerId !== user.id) {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: You do not own this event'
      });
    }

    const newGate = {
      id: generateUuid(),
      eventId,
      name,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    db.gates.push(newGate);
    return res.status(201).json({
      message: 'Success',
      data: newGate
    });
  });

  // 3. PATCH /gates/:id (Role: ORGANIZER - Only event owner)
  router.patch('/:id', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'ORGANIZER') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden'
      });
    }

    const gate = db.gates.find(g => g.id === req.params.id);
    if (!gate) {
      return res.status(404).json({
        status_code: 404,
        message: 'Gate not found'
      });
    }

    const event = db.events.find(e => e.id === gate.eventId);
    if (!event || event.organizerId !== user.id) {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: You do not own the event associated with this gate'
      });
    }

    if (req.body.name) gate.name = req.body.name;
    gate.updatedAt = new Date().toISOString();

    return res.status(200).json({
      message: 'Success',
      data: gate
    });
  });

  // 4. DELETE /gates/:id (Role: ORGANIZER - Only event owner)
  router.delete('/:id', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'ORGANIZER') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden'
      });
    }

    const index = db.gates.findIndex(g => g.id === req.params.id);
    if (index === -1) {
      return res.status(404).json({
        status_code: 404,
        message: 'Gate not found'
      });
    }

    const gate = db.gates[index];
    const event = db.events.find(e => e.id === gate.eventId);
    if (!event || event.organizerId !== user.id) {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: You do not own the event associated with this gate'
      });
    }

    const hasAdmissionScans = (db.admissionScans || []).some(scan => scan.gateId === gate.id);
    if (hasAdmissionScans) {
      return res.status(400).json({
        status_code: 400,
        message: 'Cannot delete Gate with existing admission scan history'
      });
    }

    const deleted = db.gates.splice(index, 1)[0];
    return res.status(200).json({
      message: 'Success',
      data: deleted
    });
  });

  return router;
};
