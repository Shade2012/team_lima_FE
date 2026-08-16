const express = require('express');
const router = express.Router();

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
  if (!db.tickets) db.tickets = [];

  // 1. GET /tickets/my-tickets (Role: CUSTOMER)
  router.get('/my-tickets', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user) {
      return res.status(401).json({
        status_code: 401,
        message: 'Unauthorized'
      });
    }

    const myOrders = db.orders.filter(o => o.customerId === user.id && ['PAID', 'PARTIAL_REFUND'].includes(o.status));
    const orderIds = myOrders.map(o => o.id);

    const myTickets = db.tickets
      .filter(t => orderIds.includes(t.orderId) && t.status === 'AVAILABLE')
      .map(t => {
        const category = db.categories.find(c => c.id === t.categoryId);
        const event = category ? db.events.find(e => e.id === category.eventId) : null;
        const seat = t.seatId ? db.seats.find(s => s.id === t.seatId) : null;

        return {
          id: t.id,
          status: t.status,
          createdAt: t.createdAt,
          updatedAt: t.updatedAt,
          category: category ? {
            id: category.id,
            name: category.name,
            price: category.price,
            event: event ? {
              id: event.id,
              name: event.name,
              eventDate: event.eventDate,
              isSeated: event.isSeated
            } : null
          } : null,
          seat: seat ? {
            id: seat.id,
            seatCode: seat.seatCode
          } : null
        };
      });

    return res.status(200).json({
      message: 'Success',
      data: myTickets
    });
  });

  // 2. GET /tickets/:id (Role: CUSTOMER)
  router.get('/:id', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user) {
      return res.status(401).json({
        status_code: 401,
        message: 'Unauthorized'
      });
    }

    const ticket = db.tickets.find(t => t.id === req.params.id);
    if (!ticket) {
      return res.status(404).json({
        status_code: 404,
        message: 'Ticket not found'
      });
    }

    const order = db.orders.find(o => o.id === ticket.orderId);
    if (!order || order.customerId !== user.id) {
      return res.status(404).json({
        status_code: 404,
        message: 'Ticket not found'
      });
    }

    const category = db.categories.find(c => c.id === ticket.categoryId);
    const event = category ? db.events.find(e => e.id === category.eventId) : null;
    const seat = ticket.seatId ? db.seats.find(s => s.id === ticket.seatId) : null;
    const scan = (db.admissionScans || []).find(s => s.ticketId === ticket.id) || null;
    const refund = (db.refunds || []).find(r => r.ticketId === ticket.id) || null;

    return res.status(200).json({
      message: 'Success',
      data: {
        ...ticket,
        category: category ? {
          id: category.id,
          name: category.name,
          price: category.price,
          event: event ? {
            id: event.id,
            name: event.name,
            eventDate: event.eventDate,
            isSeated: event.isSeated
          } : null
        } : null,
        seat: seat ? {
          id: seat.id,
          seatCode: seat.seatCode
        } : null,
        scan,
        refund
      }
    });
  });

  return router;
};
