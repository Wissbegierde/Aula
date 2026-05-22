const functions = require('firebase-functions');
const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const accessRoutes = require('./routes/access');
const sensorsRoutes = require('./routes/sensors');
const alertsRoutes = require('./routes/alerts');
const classroomsRoutes = require('./routes/classrooms');
const usersRoutes = require('./routes/users');

const app = express();

app.use(cors({ origin: true }));
app.use(express.json());

app.use('/auth', authRoutes);
app.use('/access', accessRoutes);
app.use('/sensors', sensorsRoutes);
app.use('/alerts', alertsRoutes);
app.use('/classrooms', classroomsRoutes);
app.use('/users', usersRoutes);

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'aula-inteligente-api' });
});

exports.api = functions
  .runWith({
    secrets: ['SENSOR_API_KEY'],
  })
  .https.onRequest(app);

const { triggerAlertOnReading } = require('./triggers/sensorAlerts');
const { autoCloseOnInactivity } = require('./triggers/autoClose');

exports.triggerAlertOnReading = triggerAlertOnReading;
exports.autoCloseOnInactivity = autoCloseOnInactivity;
