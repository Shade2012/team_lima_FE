const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS & JSON parsing
app.use(cors());
app.use(express.json());

// Load seed mock data
const seedDataPath = path.join(__dirname, 'data', 'initial_mock_data.json');
let db = {
  users: [],
  events: [],
  categories: [],
  seats: [],
  gates: [],
  admissionScans: [],
  orders: [],
  tickets: [],
  payments: [],
  refunds: [],
  blacklistedTokens: []
};

if (fs.existsSync(seedDataPath)) {
  try {
    const fileContent = fs.readFileSync(seedDataPath, 'utf-8');
    db = JSON.parse(fileContent);
    console.log('✅ Initial mock seed data loaded successfully.');
  } catch (e) {
    console.error('⚠️ Could not load seed data, running with empty state:', e.message);
  }
}

// Request logger middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Root check endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Tim Lima Backend - Mock API Server is Running',
    version: '1.2.0',
    availableEndpoints: [
      '/users/register',
      '/users/register/gate-operator',
      '/users/login',
      '/users/profile',
      '/events',
      '/events/:id/statistics',
      '/ticket-categories',
      '/seats',
      '/gates',
      '/gates/operator/assigned',
      '/orders/event/:eventId',
      '/orders/customer',
      '/orders/clear',
      '/tickets/my-tickets',
      '/scans',
      '/refunds',
      '/refunds/my-refunds',
      '/mock-pg/transaction',
      '/mock-pg/simulate-payment'
    ]
  });
});

// Register feature routes
app.use('/users', require('./routes/users')(db));
app.use('/events', require('./routes/events')(db));
app.use('/ticket-categories', require('./routes/ticket_categories')(db));
app.use('/seats', require('./routes/seats')(db));
app.use('/gates', require('./routes/gates')(db));
app.use('/orders', require('./routes/orders')(db));
app.use('/tickets', require('./routes/tickets')(db));
app.use('/scans', require('./routes/scans')(db));
app.use('/refunds', require('./routes/refunds')(db));
app.use('/mock-pg', require('./routes/mock_pg')(db));

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    status_code: 404,
    message: `Endpoint ${req.method} ${req.originalUrl} not found`
  });
});

// 500 Error Handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    status_code: 500,
    message: 'Internal Server Error'
  });
});

app.listen(PORT, () => {
  console.log(`=================================================`);
  console.log(`🚀 Tim Lima Mock API Server running on port ${PORT}`);
  console.log(`🌐 Base URL: http://localhost:${PORT}`);
  console.log(`=================================================`);
});
