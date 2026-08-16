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
  if (!db.orders) db.orders = [];
  if (!db.tickets) db.tickets = [];
  if (!db.payments) db.payments = [];

  // 1. POST /orders/event/:eventId (Role: CUSTOMER)
  router.post('/event/:eventId', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || (user.role !== 'CUSTOMER' && user.role !== 'ADMIN')) {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: Only CUSTOMER role can create orders'
      });
    }

    const { eventId } = req.params;
    const event = db.events.find(e => e.id === eventId);
    if (!event) {
      return res.status(404).json({
        status_code: 404,
        message: 'Event not found'
      });
    }

    const { seats } = req.body || {};
    if (!seats || !Array.isArray(seats) || seats.length === 0) {
      return res.status(400).json({
        status_code: 400,
        message: 'seats array must contain at least one item'
      });
    }

    let totalAmount = 0;
    const createdTickets = [];
    const orderId = generateUuid();

    for (const seatReq of seats) {
      const category = db.categories.find(c => c.id === seatReq.categoryId);
      if (!category) {
        return res.status(404).json({
          status_code: 404,
          message: `Category with ID ${seatReq.categoryId} not found`
        });
      }
      if (category.eventId !== eventId) {
        return res.status(400).json({
          status_code: 400,
          message: `Category ${category.id} does not belong to Event ${eventId}`
        });
      }

      totalAmount += category.price;

      const ticketObj = {
        id: generateUuid(),
        orderId,
        categoryId: category.id,
        seatId: seatReq.seatId || null,
        status: 'AVAILABLE',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      createdTickets.push(ticketObj);
    }

    const orderObj = {
      id: orderId,
      customerId: user.id,
      eventId,
      totalAmount,
      status: 'HELD',
      expiresAt: new Date(Date.now() + 15 * 60 * 1000).toISOString(),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    const paymentId = generateUuid();
    const tokenPayload = { paymentId, orderId };
    const snapToken = Buffer.from(JSON.stringify(tokenPayload)).toString('base64');
    const checkoutUrl = `https://mock-pg.team-lima.com/checkout/${snapToken}`;

    const paymentObj = {
      id: paymentId,
      orderId,
      providerTrxId: snapToken,
      amount: totalAmount,
      method: null,
      status: 'PENDING',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    db.orders.push(orderObj);
    db.tickets.push(...createdTickets);
    db.payments.push(paymentObj);

    return res.status(201).json({
      message: 'Success',
      data: {
        orderId,
        checkoutUrl,
        providerTrxId: snapToken,
        totalAmount
      }
    });
  });

  // 2. GET /orders/customer (Role: CUSTOMER)
  router.get('/customer', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user) {
      return res.status(401).json({
        status_code: 401,
        message: 'Unauthorized'
      });
    }

    const myOrders = db.orders
      .filter(o => o.customerId === user.id)
      .map(o => {
        const orderTickets = db.tickets.filter(t => t.orderId === o.id);
        const orderPayments = db.payments.filter(p => p.orderId === o.id);
        return {
          ...o,
          tickets: orderTickets,
          payments: orderPayments
        };
      })
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    return res.status(200).json({
      message: 'Success',
      data: myOrders
    });
  });

  // 3. GET /orders/clear (Role: CUSTOMER)
  router.get('/clear', (req, res) => {
    db.orders = [];
    db.tickets = [];
    db.payments = [];
    return res.status(200).json({
      message: 'Success',
      data: true
    });
  });

  // 4. GET /orders/customer/:id (Role: CUSTOMER)
  router.get('/customer/:id', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user) {
      return res.status(401).json({
        status_code: 401,
        message: 'Unauthorized'
      });
    }

    const order = db.orders.find(o => o.id === req.params.id && o.customerId === user.id);
    if (!order) {
      return res.status(404).json({
        status_code: 404,
        message: 'Order not found'
      });
    }

    const orderTickets = db.tickets.filter(t => t.orderId === order.id);
    const orderPayments = db.payments.filter(p => p.orderId === order.id);

    return res.status(200).json({
      message: 'Success',
      data: {
        ...order,
        tickets: orderTickets,
        payments: orderPayments
      }
    });
  });

  return router;
};
