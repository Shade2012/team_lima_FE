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
  // 1. GET /events (Public)
  router.get('/', (req, res) => {
    const sortedEvents = [...db.events].sort((a, b) => new Date(a.eventDate) - new Date(b.eventDate));
    return res.status(200).json({
      message: 'Success',
      data: sortedEvents
    });
  });

  // 2. GET /events/organizer/me (Role: ORGANIZER)
  router.get('/organizer/me', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'ORGANIZER') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: Only ORGANIZER role can access this resource'
      });
    }

    const myEvents = db.events.filter(e => e.organizerId === user.id);
    return res.status(200).json({
      message: 'Success',
      data: myEvents
    });
  });

  // 3. GET /events/:id/statistics (Role: ORGANIZER - Only owner)
  router.get('/:id/statistics', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'ORGANIZER') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: Only ORGANIZER role can access event statistics'
      });
    }

    const event = db.events.find(e => e.id === req.params.id);
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

    const categories = db.categories.filter(c => c.eventId === event.id);
    let totalQuotaSum = 0;
    let totalTicketsSoldSum = 0;
    let grossRevenueSum = 0;
    let totalRefundCountSum = 0;
    let totalRefundAmountSum = 0;

    const categoryStats = categories.map(cat => {
      const catTickets = (db.tickets || []).filter(t => t.categoryId === cat.id);
      const ticketsSold = catTickets.filter(t => {
        const order = (db.orders || []).find(o => o.id === t.orderId);
        return order && order.status === 'PAID';
      }).length;

      const grossRevenue = ticketsSold * cat.price;

      const catTicketIds = catTickets.map(t => t.id);
      const approvedRefunds = (db.refunds || []).filter(r => catTicketIds.includes(r.ticketId) && r.status === 'APPROVED');
      const refundCount = approvedRefunds.length;
      const totalRefundAmount = approvedRefunds.reduce((sum, r) => sum + r.amount, 0);
      const refundPercentage = ticketsSold > 0 ? Number(((refundCount / ticketsSold) * 100).toFixed(2)) : 0;

      totalQuotaSum += cat.totalQuota;
      totalTicketsSoldSum += ticketsSold;
      grossRevenueSum += grossRevenue;
      totalRefundCountSum += refundCount;
      totalRefundAmountSum += totalRefundAmount;

      return {
        categoryId: cat.id,
        categoryName: cat.name,
        price: cat.price,
        totalQuota: cat.totalQuota,
        ticketsSold,
        grossRevenue,
        refundCount,
        totalRefundAmount,
        refundPercentage
      };
    });

    const netRevenue = grossRevenueSum - totalRefundAmountSum;
    const percentageSold = totalQuotaSum > 0 ? Number(((totalTicketsSoldSum / totalQuotaSum) * 100).toFixed(2)) : 0;
    const refundPercentage = totalTicketsSoldSum > 0 ? Number(((totalRefundCountSum / totalTicketsSoldSum) * 100).toFixed(2)) : 0;

    return res.status(200).json({
      message: 'Success',
      data: {
        eventId: event.id,
        eventName: event.name,
        totalQuota: totalQuotaSum,
        totalTicketsSold: totalTicketsSoldSum,
        grossRevenue: grossRevenueSum,
        totalRefundCount: totalRefundCountSum,
        totalRefundAmount: totalRefundAmountSum,
        netRevenue,
        percentageSold,
        refundPercentage,
        categories: categoryStats
      }
    });
  });

  // 4. GET /events/:id (Public)
  router.get('/:id', (req, res) => {
    const event = db.events.find(e => e.id === req.params.id);
    if (!event) {
      return res.status(404).json({
        status_code: 404,
        message: 'Event not found'
      });
    }

    return res.status(200).json({
      message: 'Success',
      data: event
    });
  });

  // 4. POST /events (Role: ORGANIZER)
  router.post('/', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'ORGANIZER') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: Only ORGANIZER role can create events'
      });
    }

    const { name, isSeated, salesStartTime, salesEndTime, eventDate, refundEndDate, refundPolicy, refundPercentage } = req.body;

    if (!name || isSeated === undefined || !salesStartTime || !salesEndTime || !eventDate) {
      return res.status(400).json({
        status_code: 400,
        message: ['Missing required event fields']
      });
    }

    // Date validations
    const start = new Date(salesStartTime);
    const end = new Date(salesEndTime);
    const eventD = new Date(eventDate);
    const refundD = refundEndDate ? new Date(refundEndDate) : null;

    if (end <= start) {
      return res.status(400).json({
        status_code: 400,
        message: 'salesEndTime must be after salesStartTime'
      });
    }

    if (refundD && refundD <= start) {
      return res.status(400).json({
        status_code: 400,
        message: 'refundEndDate must be after salesStartTime'
      });
    }

    if (eventD <= end || (refundD && eventD <= refundD)) {
      return res.status(400).json({
        status_code: 400,
        message: 'eventDate must be after salesEndTime and refundEndDate'
      });
    }

    const newEvent = {
      id: generateUuid(),
      organizerId: user.id,
      name,
      isSeated: Boolean(isSeated),
      salesStartTime,
      salesEndTime,
      eventDate,
      refundEndDate: refundEndDate || null,
      refundPolicy: refundPolicy || '',
      refundPercentage: refundPercentage || 0,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    db.events.push(newEvent);
    return res.status(201).json({
      message: 'Success',
      data: newEvent
    });
  });

  // 5. PATCH /events/:id (Role: ORGANIZER - Only owner)
  router.patch('/:id', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'ORGANIZER') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden'
      });
    }

    const event = db.events.find(e => e.id === req.params.id);
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

    Object.assign(event, req.body, { updatedAt: new Date().toISOString() });
    return res.status(200).json({
      message: 'Success',
      data: event
    });
  });

  // 6. DELETE /events/:id (Role: ORGANIZER - Only owner)
  router.delete('/:id', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'ORGANIZER') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden'
      });
    }

    const index = db.events.findIndex(e => e.id === req.params.id);
    if (index === -1) {
      return res.status(404).json({
        status_code: 404,
        message: 'Event not found'
      });
    }

    if (db.events[index].organizerId !== user.id) {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: You do not own this event'
      });
    }

    const deleted = db.events.splice(index, 1)[0];
    return res.status(200).json({
      message: 'Success',
      data: deleted
    });
  });

  return router;
};
