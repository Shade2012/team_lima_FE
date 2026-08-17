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

function formatCategoryResponse(c, db) {
  const soldTicketsCount = (db.tickets || []).filter(t => t.categoryId === c.id && ['AVAILABLE', 'SEATED'].includes(t.status)).length;
  const availableQuota = Math.max(0, (c.totalQuota || 0) - soldTicketsCount);
  return {
    ...c,
    posIndex: c.posIndex || 0,
    rows: c.rows !== undefined ? c.rows : null,
    columns: c.columns !== undefined ? c.columns : null,
    availableQuota,
    isAvailable: availableQuota > 0
  };
}

module.exports = function (db) {
  // 1. GET /ticket-categories/event/:eventId (Public)
  router.get('/event/:eventId', (req, res) => {
    const categories = db.categories
      .filter(c => c.eventId === req.params.eventId)
      .map(c => formatCategoryResponse(c, db))
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
      data: formatCategoryResponse(category, db)
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

    const { eventId, name, price, totalQuota, posIndex, rows, columns } = req.body;

    if (!eventId || !name || price === undefined) {
      return res.status(400).json({
        status_code: 400,
        message: ['eventId, name, and price are required']
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

    const calculatedQuota = totalQuota !== undefined ? Number(totalQuota) : (rows && columns ? Number(rows) * Number(columns) : 100);

    const newCategory = {
      id: generateUuid(),
      eventId,
      name,
      price: Number(price),
      totalQuota: calculatedQuota,
      posIndex: posIndex !== undefined ? Number(posIndex) : 0,
      rows: rows !== undefined ? Number(rows) : null,
      columns: columns !== undefined ? Number(columns) : null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    db.categories.push(newCategory);
    return res.status(201).json({
      message: 'Success',
      data: formatCategoryResponse(newCategory, db)
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
        message: 'Forbidden: You do not own this event'
      });
    }

    const { name, price, totalQuota, posIndex, rows, columns } = req.body;
    if (name !== undefined) category.name = name;
    if (price !== undefined) category.price = Number(price);
    if (totalQuota !== undefined) category.totalQuota = Number(totalQuota);
    if (posIndex !== undefined) category.posIndex = Number(posIndex);
    if (rows !== undefined) category.rows = Number(rows);
    if (columns !== undefined) category.columns = Number(columns);
    category.updatedAt = new Date().toISOString();

    return res.status(200).json({
      message: 'Success',
      data: formatCategoryResponse(category, db)
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
        message: 'Forbidden: You do not own this event'
      });
    }

    const deleted = db.categories.splice(index, 1)[0];

    return res.status(200).json({
      message: 'Success',
      data: formatCategoryResponse(deleted, db)
    });
  });

  return router;
};
