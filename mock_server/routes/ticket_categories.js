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
  // 1. GET /ticket-categories/event/:eventId (Public)
  router.get('/event/:eventId', (req, res) => {
    const categories = db.categories
      .filter(c => c.eventId === req.params.eventId)
      .sort((a, b) => b.price - a.price);

    return res.status(200).json({
      message: 'Success',
      data: categories
    });
  });

  // 2. GET /ticket-categories/:id (Public)
  router.get('/:id', (req, res) => {
    const category = db.categories.find(c => c.id === req.params.id);
    if (!category) {
      return res.status(404).json({
        status_code: 404,
        message: 'Ticket category not found'
      });
    }

    return res.status(200).json({
      message: 'Success',
      data: category
    });
  });

  // 3. POST /ticket-categories (Role: ORGANIZER)
  router.post('/', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'ORGANIZER') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: Only ORGANIZER can create ticket categories'
      });
    }

    const { eventId, name, price, totalQuota } = req.body;

    if (!eventId || !name || price === undefined || !totalQuota) {
      return res.status(400).json({
        status_code: 400,
        message: ['eventId, name, price, and totalQuota are required']
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

    const newCategory = {
      id: generateUuid(),
      eventId,
      name,
      price: Number(price),
      totalQuota: Number(totalQuota),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    db.categories.push(newCategory);
    return res.status(201).json({
      message: 'Success',
      data: newCategory
    });
  });

  // 4. PATCH /ticket-categories/:id (Role: ORGANIZER - Only event owner)
  router.patch('/:id', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'ORGANIZER') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden'
      });
    }

    const category = db.categories.find(c => c.id === req.params.id);
    if (!category) {
      return res.status(404).json({
        status_code: 404,
        message: 'Ticket category not found'
      });
    }

    const event = db.events.find(e => e.id === category.eventId);
    if (!event || event.organizerId !== user.id) {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: You do not own the event associated with this category'
      });
    }

    const { totalQuota } = req.body;
    if (totalQuota !== undefined) {
      const existingSeatsCount = db.seats.filter(s => s.categoryId === category.id).length;
      if (Number(totalQuota) < existingSeatsCount) {
        return res.status(400).json({
          status_code: 400,
          message: `totalQuota cannot be reduced below existing seats count (${existingSeatsCount})`
        });
      }
    }

    Object.assign(category, req.body, { updatedAt: new Date().toISOString() });
    return res.status(200).json({
      message: 'Success',
      data: category
    });
  });

  // 5. DELETE /ticket-categories/:id (Role: ORGANIZER - Only event owner)
  router.delete('/:id', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'ORGANIZER') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden'
      });
    }

    const index = db.categories.findIndex(c => c.id === req.params.id);
    if (index === -1) {
      return res.status(404).json({
        status_code: 404,
        message: 'Ticket category not found'
      });
    }

    const category = db.categories[index];
    const event = db.events.find(e => e.id === category.eventId);
    if (!event || event.organizerId !== user.id) {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: You do not own the event associated with this category'
      });
    }

    const existingSeatsCount = db.seats.filter(s => s.categoryId === category.id).length;
    if (existingSeatsCount > 0) {
      return res.status(400).json({
        status_code: 400,
        message: `Cannot delete category with existing generated seats (${existingSeatsCount}). Delete seats first via DELETE /seats/category/:categoryId.`
      });
    }

    const deleted = db.categories.splice(index, 1)[0];
    return res.status(200).json({
      message: 'Success',
      data: deleted
    });
  });

  return router;
};
