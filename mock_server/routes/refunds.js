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
  if (!db.refunds) db.refunds = [];

  // 1. POST /refunds (Role: CUSTOMER)
  router.post('/', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'CUSTOMER') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: Only CUSTOMER role can request refunds'
      });
    }

    const { ticketId, reason } = req.body || {};
    if (!ticketId || !reason) {
      return res.status(400).json({
        status_code: 400,
        message: ['ticketId and reason are required']
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
    if (!order || order.customerId !== user.id) {
      return res.status(403).json({
        status_code: 403,
        message: 'You do not own this ticket'
      });
    }

    if (!['PAID', 'PARTIAL_REFUND'].includes(order.status)) {
      return res.status(400).json({
        status_code: 400,
        message: 'Order is not paid, cannot refund'
      });
    }

    if (ticket.status !== 'AVAILABLE') {
      return res.status(400).json({
        status_code: 400,
        message: 'Ticket is not available for refund'
      });
    }

    const category = db.categories.find(c => c.id === ticket.categoryId);
    const event = category ? db.events.find(e => e.id === category.eventId) : null;

    if (event && event.refundEndDate && new Date() > new Date(event.refundEndDate)) {
      return res.status(400).json({
        status_code: 400,
        message: 'Refund period has ended for this event'
      });
    }

    const existingRefund = db.refunds.find(r => r.ticketId === ticketId);
    if (existingRefund) {
      return res.status(400).json({
        status_code: 400,
        message: 'A refund request for this ticket has already been submitted'
      });
    }

    const refundPercentage = event ? event.refundPercentage : 80;
    const price = category ? category.price : 0;
    const amount = Math.floor(price * (refundPercentage / 100));

    const refundObj = {
      id: generateUuid(),
      ticketId,
      reason,
      amount,
      status: 'PENDING',
      adminId: null,
      providerRefundId: null,
      rejectReason: null,
      processedAt: null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    db.refunds.push(refundObj);

    return res.status(201).json({
      message: 'Success',
      data: refundObj
    });
  });

  // 2. GET /refunds/my-refunds (Role: CUSTOMER)
  router.get('/my-refunds', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user) {
      return res.status(401).json({
        status_code: 401,
        message: 'Unauthorized'
      });
    }

    const myOrders = db.orders.filter(o => o.customerId === user.id);
    const myOrderIds = myOrders.map(o => o.id);
    const myTickets = db.tickets.filter(t => myOrderIds.includes(t.orderId));
    const myTicketIds = myTickets.map(t => t.id);

    const myRefunds = db.refunds
      .filter(r => myTicketIds.includes(r.ticketId))
      .map(r => {
        const ticket = db.tickets.find(t => t.id === r.ticketId);
        const category = ticket ? db.categories.find(c => c.id === ticket.categoryId) : null;
        const event = category ? db.events.find(e => e.id === category.eventId) : null;
        const seat = ticket && ticket.seatId ? db.seats.find(s => s.id === ticket.seatId) : null;
        const order = ticket ? db.orders.find(o => o.id === ticket.orderId) : null;

        return {
          id: r.id,
          reason: r.reason,
          amount: r.amount,
          ticketId: r.ticketId,
          status: r.status,
          rejectReason: r.rejectReason,
          adminId: r.adminId,
          providerRefundId: r.providerRefundId,
          processedAt: r.processedAt,
          createdAt: r.createdAt,
          updatedAt: r.updatedAt,
          ticket: ticket ? {
            id: ticket.id,
            status: ticket.status,
            category: category ? {
              id: category.id,
              name: category.name,
              price: category.price,
              event: event ? {
                id: event.id,
                name: event.name,
                eventDate: event.eventDate
              } : null
            } : null,
            seat: seat ? {
              id: seat.id,
              seatCode: seat.seatCode
            } : null,
            order: order ? {
              id: order.id,
              customerId: order.customerId,
              status: order.status
            } : null
          } : null
        };
      })
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    return res.status(200).json({
      message: 'Success',
      data: myRefunds
    });
  });

  // 3. GET /refunds (Role: ADMIN or ORGANIZER)
  router.get('/', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || (user.role !== 'ADMIN' && user.role !== 'ORGANIZER')) {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: Only ADMIN or ORGANIZER role can access refunds'
      });
    }

    let allowedEventIds = null;
    if (user.role === 'ORGANIZER') {
      allowedEventIds = db.events.filter(e => e.organizerId === user.id).map(e => e.id);
    }

    const allRefunds = db.refunds
      .filter(r => {
        if (!allowedEventIds) return true;
        const ticket = db.tickets.find(t => t.id === r.ticketId);
        const category = ticket ? db.categories.find(c => c.id === ticket.categoryId) : null;
        return category && allowedEventIds.includes(category.eventId);
      })
      .map(r => {
        const ticket = db.tickets.find(t => t.id === r.ticketId);
        const category = ticket ? db.categories.find(c => c.id === ticket.categoryId) : null;
        const event = category ? db.events.find(e => e.id === category.eventId) : null;
        const seat = ticket && ticket.seatId ? db.seats.find(s => s.id === ticket.seatId) : null;
        const order = ticket ? db.orders.find(o => o.id === ticket.orderId) : null;
        const customer = order ? db.users.find(u => u.id === order.customerId) : null;

        return {
          id: r.id,
          reason: r.reason,
          amount: r.amount,
          ticketId: r.ticketId,
          status: r.status,
          rejectReason: r.rejectReason,
          adminId: r.adminId,
          providerRefundId: r.providerRefundId,
          processedAt: r.processedAt,
          createdAt: r.createdAt,
          updatedAt: r.updatedAt,
          customerName: customer ? customer.username : null,
          ticket: ticket ? {
            id: ticket.id,
            status: ticket.status,
            category: category ? {
              id: category.id,
              name: category.name,
              price: category.price,
              event: event ? {
                id: event.id,
                name: event.name,
                eventDate: event.eventDate
              } : null
            } : null,
            seat: seat ? {
              id: seat.id,
              seatCode: seat.seatCode
            } : null,
            order: order ? {
              id: order.id,
              customerId: order.customerId,
              status: order.status
            } : null
          } : null
        };
      })
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    return res.status(200).json({
      message: 'Success',
      data: allRefunds
    });
  });

  // 4. PATCH /refunds/:id/approve (Role: ADMIN)
  router.patch('/:id/approve', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'ADMIN') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: Only ADMIN can approve refunds'
      });
    }

    const refund = db.refunds.find(r => r.id === req.params.id);
    if (!refund) {
      return res.status(404).json({
        status_code: 404,
        message: 'Refund request not found'
      });
    }

    if (refund.status !== 'PENDING') {
      return res.status(400).json({
        status_code: 400,
        message: `Refund is already ${refund.status}`
      });
    }

    const ticket = db.tickets.find(t => t.id === refund.ticketId);
    if (!ticket || ticket.status !== 'AVAILABLE') {
      return res.status(400).json({
        status_code: 400,
        message: 'Ticket is no longer available for refund'
      });
    }

    refund.status = 'APPROVED';
    refund.adminId = user.id;
    refund.providerRefundId = 'ref_mock_' + Date.now();
    refund.processedAt = new Date().toISOString();
    refund.updatedAt = new Date().toISOString();

    ticket.status = 'REFUND';
    ticket.updatedAt = new Date().toISOString();

    const order = db.orders.find(o => o.id === ticket.orderId);
    if (order) {
      const activeTickets = db.tickets.filter(t => t.orderId === order.id && t.status !== 'REFUND');
      order.status = activeTickets.length === 0 ? 'FULL_REFUND' : 'PARTIAL_REFUND';
      order.updatedAt = new Date().toISOString();
    }

    return res.status(200).json({
      message: 'Success',
      data: refund
    });
  });

  // 5. PATCH /refunds/:id/reject (Role: ADMIN)
  router.patch('/:id/reject', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'ADMIN') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: Only ADMIN can reject refunds'
      });
    }

    const { rejectReason } = req.body || {};
    if (!rejectReason) {
      return res.status(400).json({
        status_code: 400,
        message: 'rejectReason is required'
      });
    }

    const refund = db.refunds.find(r => r.id === req.params.id);
    if (!refund) {
      return res.status(404).json({
        status_code: 404,
        message: 'Refund request not found'
      });
    }

    if (refund.status !== 'PENDING') {
      return res.status(400).json({
        status_code: 400,
        message: `Refund is already ${refund.status}`
      });
    }

    refund.status = 'REJECTED';
    refund.rejectReason = rejectReason;
    refund.adminId = user.id;
    refund.processedAt = new Date().toISOString();
    refund.updatedAt = new Date().toISOString();

    return res.status(200).json({
      message: 'Success',
      data: refund
    });
  });

  return router;
};
