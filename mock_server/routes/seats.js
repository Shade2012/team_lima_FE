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
    const category = db.categories.find(c => c.id === req.params.categoryId);
    if (!category) {
      return res.status(404).json({
        status_code: 404,
        message: 'Category not found'
      });
    }

    const seats = db.seats
      .filter(s => s.categoryId === req.params.categoryId)
      .sort((a, b) => a.seatCode.localeCompare(b.seatCode, undefined, { numeric: true }));

    const activeTickets = (db.tickets || []).filter(t =>
      t.categoryId === req.params.categoryId &&
      !['CANCELLED', 'EXPIRED', 'REFUND'].includes(t.status) &&
      t.seatId
    );

    const activeSeatMap = new Map();
    activeTickets.forEach(t => {
      const order = (db.orders || []).find(o => o.id === t.orderId);
      if (order) {
        const isPaid = order.status === 'PAID';
        const isPending = ['HELD', 'PAYMENT_PENDING'].includes(order.status) && new Date(order.expiresAt) > new Date();
        if (isPaid || isPending) {
          activeSeatMap.set(t.seatId, isPaid ? 'BOOKED' : 'HELD');
        }
      }
    });

    const formattedSeats = seats.map(seat => {
      const parts = seat.seatCode.split('-');
      const column = parseInt(parts.pop() || '0', 10);
      const row = parts.pop() || '';
      const status = activeSeatMap.get(seat.id) || 'AVAILABLE';

      return {
        id: seat.id,
        categoryId: seat.categoryId,
        seatCode: seat.seatCode,
        row,
        column,
        status,
        createdAt: seat.createdAt
      };
    });

    return res.status(200).json({
      message: 'Success',
      data: formattedSeats
    });
  });

  // 2. GET /seats/:id (Public)
  router.get('/:id', (req, res) => {
    const seat = db.seats.find(s => s.id === req.params.id);
    if (!seat) {
      return res.status(404).json({
        status_code: 404,
        message: `Seat with id ${req.params.id} not found`
      });
    }

    return res.status(200).json({
      message: 'Success',
      data: seat
    });
  });

  // 3. POST /seats/bulk (Role: ORGANIZER - Only event owner)
  router.post('/bulk', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'ORGANIZER') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: You do not have permission to manage seats for this event'
      });
    }

    const { categoryId, prefix: rawPrefix } = req.body || {};
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
        message: 'Category not found'
      });
    }

    const event = db.events.find(e => e.id === category.eventId);
    if (!event) {
      return res.status(404).json({
        status_code: 404,
        message: 'Event not found'
      });
    }

    if (event.organizerId !== user.id) {
      return res.status(403).json({
        status_code: 403,
        message: 'You do not have permission to manage seats for this event'
      });
    }

    if (!event.isSeated) {
      return res.status(400).json({
        status_code: 400,
        message: 'Cannot create seats for a non-seated event'
      });
    }

    const existingSeats = db.seats.filter(s => s.categoryId === categoryId);
    const remainingToCreate = category.totalQuota - existingSeats.length;

    if (remainingToCreate <= 0) {
      return res.status(400).json({
        status_code: 400,
        message: `All ${category.totalQuota} seats have already been created for this category`
      });
    }

    const prefix = rawPrefix ? `${rawPrefix}-` : (rawPrefix === '' ? '' : 'VIP-');
    const columns = category.columns || 1;
    const blockedSeats = category.blockedSeats || [];

    const seatData = [];
    let createdCount = 0;
    let gridIndex = 0;
    let validSeatCounter = 0;

    // Advance past existing seats
    while (validSeatCounter < existingSeats.length) {
      const rowIndex = Math.floor(gridIndex / columns);
      const colIndex = (gridIndex % columns) + 1;

      let rowStr = '';
      let temp = rowIndex;
      while (temp >= 0) {
        rowStr = String.fromCharCode(65 + (temp % 26)) + rowStr;
        temp = Math.floor(temp / 26) - 1;
      }

      const coreCode = `${rowStr}-${colIndex}`;
      if (!blockedSeats.includes(coreCode)) {
        validSeatCounter++;
      }
      gridIndex++;
    }

    // Generate remaining seats
    while (createdCount < remainingToCreate) {
      const rowIndex = Math.floor(gridIndex / columns);
      const colIndex = (gridIndex % columns) + 1;

      let rowStr = '';
      let temp = rowIndex;
      while (temp >= 0) {
        rowStr = String.fromCharCode(65 + (temp % 26)) + rowStr;
        temp = Math.floor(temp / 26) - 1;
      }

      const coreCode = `${rowStr}-${colIndex}`;

      if (!blockedSeats.includes(coreCode)) {
        const seatObj = {
          id: generateUuid(),
          categoryId,
          seatCode: `${prefix}${coreCode}`,
          createdAt: new Date().toISOString()
        };
        db.seats.push(seatObj);
        seatData.push(seatObj);
        createdCount++;
      }

      gridIndex++;

      if (category.rows && gridIndex > (category.rows * columns) * 2) {
        break; // safety fallback
      }
    }

    return res.status(201).json({
      message: 'Success',
      data: {
        seatsCreated: seatData.length,
        totalQuota: category.totalQuota,
        prefix,
        firstSeatCode: seatData[0] ? seatData[0].seatCode : '',
        lastSeatCode: seatData[seatData.length - 1] ? seatData[seatData.length - 1].seatCode : ''
      }
    });
  });

  // 4. DELETE /seats/category/:categoryId (Role: ORGANIZER - Only event owner)
  router.delete('/category/:categoryId', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'ORGANIZER') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden'
      });
    }

    const category = db.categories.find(c => c.id === req.params.categoryId);
    if (!category) {
      return res.status(404).json({
        status_code: 404,
        message: 'Category not found'
      });
    }

    const event = db.events.find(e => e.id === category.eventId);
    if (!event || event.organizerId !== user.id) {
      return res.status(403).json({
        status_code: 403,
        message: 'You do not have permission to delete seats for this event'
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
