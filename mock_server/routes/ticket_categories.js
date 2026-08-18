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
  const soldTicketsCount = (db.tickets || []).filter(t => {
    if (t.categoryId !== c.id || ['CANCELLED', 'EXPIRED', 'REFUND'].includes(t.status)) return false;
    const order = (db.orders || []).find(o => o.id === t.orderId);
    if (!order) return false;
    if (order.status === 'PAID') return true;
    if (['HELD', 'PAYMENT_PENDING'].includes(order.status) && new Date(order.expiresAt) > new Date()) return true;
    return false;
  }).length;

  const availableQuota = Math.max(0, (c.totalQuota || 0) - soldTicketsCount);
  return {
    id: c.id,
    eventId: c.eventId,
    name: c.name,
    price: c.price,
    totalQuota: c.totalQuota,
    posIndex: c.posIndex || 0,
    rows: c.rows !== undefined ? c.rows : null,
    columns: c.columns !== undefined ? c.columns : null,
    blockedSeats: c.blockedSeats || [],
    availableQuota,
    isAvailable: availableQuota > 0,
    createdAt: c.createdAt,
    updatedAt: c.updatedAt
  };
}

module.exports = function (db) {
  // 1. GET /ticket-categories/event/:eventId (Public)
  router.get('/event/:eventId', (req, res) => {
    const event = db.events.find(e => e.id === req.params.eventId);
    if (!event) {
      return res.status(404).json({
        status_code: 404,
        message: `Event with id ${req.params.eventId} not found`
      });
    }

    const categories = db.categories
      .filter(c => c.eventId === req.params.eventId)
      .map(c => formatCategoryResponse(c, db))
      .sort((a, b) => (a.posIndex - b.posIndex) || (b.price - a.price));

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
        message: `Ticket category with id ${req.params.id} not found`
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
        message: 'Forbidden: You do not have permission to add categories to this event'
      });
    }

    const { eventId, name, price, totalQuota, posIndex, rows, columns, blockedSeats } = req.body || {};

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
        message: `Event with id ${eventId} not found`
      });
    }

    if (event.organizerId !== user.id) {
      return res.status(403).json({
        status_code: 403,
        message: 'You do not have permission to add categories to this event'
      });
    }

    let calculatedQuota = totalQuota;
    if (event.isSeated) {
      if (!rows || !columns) {
        return res.status(400).json({
          status_code: 400,
          message: 'Seated events must provide rows and columns for category'
        });
      }
      const blockedCount = Array.isArray(blockedSeats) ? blockedSeats.length : 0;
      calculatedQuota = (Number(rows) * Number(columns)) - blockedCount;
    } else {
      if (!totalQuota) {
        return res.status(400).json({
          status_code: 400,
          message: 'Non-seated events must provide totalQuota for category'
        });
      }
    }

    const newCategory = {
      id: generateUuid(),
      eventId,
      name,
      price: Number(price),
      totalQuota: Number(calculatedQuota),
      posIndex: posIndex !== undefined ? Number(posIndex) : 0,
      rows: event.isSeated ? Number(rows) : null,
      columns: event.isSeated ? Number(columns) : null,
      blockedSeats: event.isSeated ? (Array.isArray(blockedSeats) ? blockedSeats : []) : [],
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
        message: `Ticket category with id ${req.params.id} not found`
      });
    }

    const event = db.events.find(e => e.id === category.eventId);
    if (!event || event.organizerId !== user.id) {
      return res.status(403).json({
        status_code: 403,
        message: 'You do not have permission to update this category'
      });
    }

    const { name, price, totalQuota, posIndex, rows, columns, blockedSeats } = req.body || {};

    if (totalQuota !== undefined && Number(totalQuota) < category.totalQuota) {
      if (event.isSeated) {
        const existingSeatsCount = (db.seats || []).filter(s => s.categoryId === category.id).length;
        if (Number(totalQuota) < existingSeatsCount) {
          return res.status(400).json({
            status_code: 400,
            message: `Cannot reduce totalQuota to ${totalQuota}. There are already ${existingSeatsCount} seats generated.`
          });
        }
      }
      const activeTicketCount = (db.tickets || []).filter(t => t.categoryId === category.id && !['CANCELLED', 'EXPIRED', 'REFUND'].includes(t.status)).length;
      if (Number(totalQuota) < activeTicketCount) {
        return res.status(400).json({
          status_code: 400,
          message: `Cannot reduce totalQuota to ${totalQuota}. There are ${activeTicketCount} active ticket(s) in this category.`
        });
      }
    }

    if (name !== undefined) category.name = name;
    if (price !== undefined) category.price = Number(price);
    if (totalQuota !== undefined) category.totalQuota = Number(totalQuota);
    if (posIndex !== undefined) category.posIndex = Number(posIndex);
    if (rows !== undefined) category.rows = Number(rows);
    if (columns !== undefined) category.columns = Number(columns);
    if (blockedSeats !== undefined) category.blockedSeats = Array.isArray(blockedSeats) ? blockedSeats : [];
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
        message: `Ticket category with id ${req.params.id} not found`
      });
    }

    const category = db.categories[index];
    const event = db.events.find(e => e.id === category.eventId);
    if (!event || event.organizerId !== user.id) {
      return res.status(403).json({
        status_code: 403,
        message: 'You do not have permission to delete this category'
      });
    }

    const existingSeatsCount = (db.seats || []).filter(s => s.categoryId === category.id).length;
    if (existingSeatsCount > 0) {
      return res.status(400).json({
        status_code: 400,
        message: `Cannot delete category because it has ${existingSeatsCount} seats generated. Please delete the seats first.`
      });
    }

    const activeTicketCount = (db.tickets || []).filter(t => t.categoryId === category.id && !['CANCELLED', 'EXPIRED', 'REFUND'].includes(t.status)).length;
    if (activeTicketCount > 0) {
      return res.status(400).json({
        status_code: 400,
        message: `Cannot delete category because it has ${activeTicketCount} active ticket(s). Refund or cancel them first.`
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
