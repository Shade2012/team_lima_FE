const express = require('express');
const router = express.Router();
const crypto = require('crypto');

// Helper UUID v7 mock
function generateUuid() {
  return '019146a0-' + crypto.randomBytes(2).toString('hex') + '-7abc-9a12-' + crypto.randomBytes(6).toString('hex');
}

// Helper mock JWT
function generateToken(user) {
  const payload = Buffer.from(JSON.stringify({
    sub: user.id,
    username: user.username,
    role: user.role,
    exp: Math.floor(Date.now() / 1000) + 86400
  })).toString('base64');
  return `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.${payload}.mockSignature1234567890`;
}

// Parse user from Bearer Token
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
  // 1. POST /users/register (Public: CUSTOMER & ORGANIZER)
  router.post('/register', (req, res) => {
    const { username, email, password, role } = req.body;

    if (!username || !email || !password || !role) {
      return res.status(400).json({
        status_code: 400,
        message: ['username, email, password, and role are required']
      });
    }

    if (role === 'GATE_OPERATOR') {
      return res.status(400).json({
        status_code: 400,
        message: 'GATE_OPERATOR role is not allowed via public register. Use POST /users/register/gate-operator'
      });
    }

    if (role !== 'CUSTOMER' && role !== 'ORGANIZER') {
      return res.status(400).json({
        status_code: 400,
        message: 'Role must be either CUSTOMER or ORGANIZER'
      });
    }

    const existing = db.users.find(u => u.email === email || u.username === username);
    if (existing) {
      return res.status(409).json({
        status_code: 409,
        message: 'Email or username already registered'
      });
    }

    const newUser = {
      id: generateUuid(),
      username,
      email,
      password,
      role,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    db.users.push(newUser);

    const { password: _, ...userResponse } = newUser;
    return res.status(201).json({
      message: 'Success',
      data: userResponse
    });
  });

  // 2. POST /users/register/gate-operator (Organizer Only)
  router.post('/register/gate-operator', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user || user.role !== 'ORGANIZER') {
      return res.status(403).json({
        status_code: 403,
        message: 'Forbidden: Only ORGANIZER role can register gate operators'
      });
    }

    const inputData = req.body;
    const isArray = Array.isArray(inputData);
    const items = isArray ? inputData : [inputData];

    if (items.length === 0) {
      return res.status(400).json({
        status_code: 400,
        message: 'Request body must contain at least one Gate Operator object'
      });
    }

    // Validate all items first
    for (const item of items) {
      const { username, email, password, eventId } = item || {};
      if (!username || !email || !password || !eventId) {
        return res.status(400).json({
          status_code: 400,
          message: 'username, email, password, and eventId are required for each gate operator'
        });
      }

      const event = db.events.find(e => e.id === eventId);
      if (!event) {
        return res.status(404).json({
          status_code: 404,
          message: `Event with ID ${eventId} not found`
        });
      }

      if (event.organizerId !== user.id) {
        return res.status(403).json({
          status_code: 403,
          message: `Event with ID ${eventId} does not belong to logged-in organizer`
        });
      }

      const existing = db.users.find(u => u.email === email || u.username === username);
      if (existing) {
        return res.status(409).json({
          status_code: 409,
          message: `User with email ${email} or username ${username} already registered`
        });
      }
    }

    // Create operators
    const createdResponses = [];
    for (const item of items) {
      const { username, email, password, eventId } = item;
      const newOperator = {
        id: generateUuid(),
        username,
        email,
        password,
        role: 'GATE_OPERATOR',
        eventId,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };

      db.users.push(newOperator);
      const { password: _, ...opResponse } = newOperator;
      createdResponses.push(opResponse);
    }

    return res.status(201).json({
      message: 'Success',
      data: isArray ? createdResponses : createdResponses[0]
    });
  });

  // 2. POST /users/login
  router.post('/login', (req, res) => {
    const { email, password } = req.body;
    const user = db.users.find(u => u.email === email && u.password === password);

    if (!user) {
      return res.status(401).json({
        status_code: 401,
        message: 'Invalid email or password'
      });
    }

    const token = generateToken(user);
    return res.status(200).json({
      message: 'Success',
      data: token
    });
  });

  // 3. GET /users/profile
  router.get('/profile', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user) {
      return res.status(401).json({
        status_code: 401,
        message: 'Unauthorized / Invalid or expired token'
      });
    }

    const { password: _, ...userResponse } = user;
    return res.status(200).json({
      message: 'Success',
      data: userResponse
    });
  });

  // 4. POST /users/logout
  router.post('/logout', (req, res) => {
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      db.blacklistedTokens.push(token);
    }
    return res.status(200).json({
      message: 'Success',
      data: true
    });
  });

  // 5. PATCH /users/profile
  router.patch('/profile', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user) {
      return res.status(401).json({
        status_code: 401,
        message: 'Unauthorized'
      });
    }

    const { username, email } = req.body;
    if (username) user.username = username;
    if (email) user.email = email;
    user.updatedAt = new Date().toISOString();

    const { password: _, ...userResponse } = user;
    return res.status(200).json({
      message: 'Success',
      data: userResponse
    });
  });

  // 6. DELETE /users
  router.delete('/', (req, res) => {
    const user = getUserFromToken(req, db);
    if (!user) {
      return res.status(401).json({
        status_code: 401,
        message: 'Unauthorized'
      });
    }

    const index = db.users.findIndex(u => u.id === user.id);
    if (index !== -1) {
      db.users.splice(index, 1);
    }

    return res.status(200).json({
      message: 'Success',
      data: true
    });
  });

  return router;
};
