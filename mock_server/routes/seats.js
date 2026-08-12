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
  // 1. GET /seats/category/:categoryId (Public)
  router.get('/category/:categoryId', (req, res) => {
    const seats = db.seats
      .filter(s => s.categoryId === req.params.categoryId)
      .sort((a, b) => a.seatCode.localeCompare(b.seatCode, undefined, { numeric: true }));

    return res.status(200).json({
      message: 'Success',
      data: seats
    });
  });

  // 2. POST /seats/bulk (Role: ORGANIZER)
  router.post('/bulk', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'ORGANIZER') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: Only ORGANIZER can generate seats'
      });
    }

    const { categoryId, prefix = 'SEAT' } = req.body;
    if (!categoryId) {
      return res.status(400).json({
        status_code: 400,
        message: 'categoryId is required'
      });
    }

    const category = db.categories.find(c => c.id === categoryId);
    if (!category) {
      return res.status(404).json({
        status_code: 404,
        message: 'Ticket category not found'
      });
    }

    const event = db.events.find(e => e.id === category.eventId);
    if (!event) {
      return res.status(404).json({
        status_code: 404,
        message: 'Event associated with this category not found'
      });
    }

    if (!event.isSeated) {
      return res.status(400).json({
        status_code: 400,
        message: 'Event is not a seated event (isSeated == false)'
      });
    }

    const existingSeats = db.seats.filter(s => s.categoryId === categoryId);
    const remainingToCreate = category.totalQuota - existingSeats.length;

    if (remainingToCreate <= 0) {
      return res.status(400).json({
        status_code: 400,
        message: `Seats for category quota (${category.totalQuota}) are already fully generated`
      });
    }

    const startIndex = existingSeats.length + 1;
    const endIndex = category.totalQuota;
    const createdSeats = [];

    for (let i = startIndex; i <= endIndex; i++) {
      const seatNumStr = String(i).padStart(3, '0');
      const seatCode = `${prefix}-${seatNumStr}`;
      const seatObj = {
        id: generateUuid(),
        categoryId,
        seatCode,
        createdAt: new Date().toISOString()
      };
      db.seats.push(seatObj);
      createdSeats.push(seatObj);
    }

    const firstSeatCode = `${prefix}-${String(startIndex).padStart(3, '0')}`;
    const lastSeatCode = `${prefix}-${String(endIndex).padStart(3, '0')}`;

    return res.status(201).json({
      message: 'Success',
      data: {
        seatsCreated: createdSeats.length,
        totalQuota: category.totalQuota,
        prefix,
        firstSeatCode,
        lastSeatCode
      }
    });
  });

  // 3. DELETE /seats/category/:categoryId (Role: ORGANIZER)
  router.delete('/category/:categoryId', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'ORGANIZER') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden'
      });
    }

    const initialLength = db.seats.length;
    db.seats = db.seats.filter(s => s.categoryId !== req.params.categoryId);
    const seatsDeleted = initialLength - db.seats.length;

    return res.status(200).json({
      message: 'Success',
      data: {
        seatsDeleted
      }
    });
  });

  return router;
};
