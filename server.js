require('dotenv').config();
const express    = require('express');
const cors       = require('cors');
const helmet     = require('helmet');
const path       = require('path');

const employeesRouter = require('./routes/employees');
const templatesRouter = require('./routes/templates');
const scheduleRouter  = require('./routes/schedule');
const rulesRouter     = require('./routes/rules');

const app  = express();
const PORT = process.env.PORT || 3000;

// ── MIDDLEWARE ────────────────────────────────────────────────
app.use(helmet({ contentSecurityPolicy: false })); // CSP off — single-file HTML app
app.use(cors());
app.use(express.json());

// ── SERVE FRONTEND ────────────────────────────────────────────
// The built HTML file lives at /public/index.html
app.use(express.static(path.join(__dirname, 'public')));

// ── API ROUTES ────────────────────────────────────────────────
app.use('/api/employees', employeesRouter);
app.use('/api/templates', templatesRouter);
app.use('/api/schedule',  scheduleRouter);
app.use('/api/rules',     rulesRouter);

// Health check (Railway uses this)
app.get('/health', (req, res) => res.json({ ok: true, ts: new Date() }));

// Catch-all — serve the app for any non-API route
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// ── START ─────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`Vet Scheduler server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});
