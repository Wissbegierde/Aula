const express = require('express');
const { db, Timestamp } = require('../services/firebase');
const { authenticateToken, requireRole } = require('../middleware/auth');
const { authenticateApiKey } = require('../middleware/apiKey');
const { SENSOR_THRESHOLDS, ALERT_TYPES } = require('../config');

const router = express.Router();

router.post('/reading', authenticateApiKey, async (req, res) => {
  try {
    const {
      classroom_id,
      temperature,
      humidity,
      smoke_detected,
      power_consumption_watts,
      air_quality_index,
    } = req.body;

    if (!classroom_id) {
      return res.status(400).json({ error: 'classroom_id is required' });
    }

    const reading = {
      classroom_id,
      temperature: temperature ?? null,
      humidity: humidity ?? null,
      smoke_detected: smoke_detected ?? false,
      power_consumption_watts: power_consumption_watts ?? null,
      air_quality_index: air_quality_index ?? null,
      timestamp: Timestamp.now(),
    };

    await db.collection('sensor_readings').add(reading);

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error('Error saving sensor reading:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/latest', authenticateToken, async (req, res) => {
  try {
    const { classroom_id } = req.query;

    if (!classroom_id) {
      return res.status(400).json({ error: 'classroom_id is required' });
    }

    const snapshot = await db
      .collection('sensor_readings')
      .where('classroom_id', '==', classroom_id)
      .orderBy('timestamp', 'desc')
      .limit(1)
      .get();

    if (snapshot.empty) {
      return res.status(200).json({ reading: null });
    }

    const doc = snapshot.docs[0];
    const data = doc.data();

    return res.status(200).json({
      reading: {
        id: doc.id,
        ...data,
        timestamp: data.timestamp?.toDate().toISOString(),
      },
    });
  } catch (error) {
    console.error('Error fetching latest reading:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/history', authenticateToken, async (req, res) => {
  try {
    const { classroom_id, from, to, limit: queryLimit = 100 } = req.query;

    if (!classroom_id) {
      return res.status(400).json({ error: 'classroom_id is required' });
    }

    let query = db
      .collection('sensor_readings')
      .where('classroom_id', '==', classroom_id)
      .orderBy('timestamp', 'desc');

    if (from) {
      const fromDate = new Date(from);
      query = query.where('timestamp', '>=', Timestamp.fromDate(fromDate));
    }

    if (to) {
      const toDate = new Date(to);
      query = query.where('timestamp', '<=', Timestamp.fromDate(toDate));
    }

    query = query.limit(parseInt(queryLimit, 10));

    const snapshot = await query.get();
    const readings = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      timestamp: doc.data().timestamp?.toDate().toISOString(),
    }));

    return res.status(200).json({ readings });
  } catch (error) {
    console.error('Error fetching sensor history:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
