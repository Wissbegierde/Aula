const express = require('express');
const { db, Timestamp } = require('../services/firebase');
const { authenticateTokenOrApiKey } = require('../middleware/authOrApiKey');

const router = express.Router();

router.get('/', authenticateTokenOrApiKey, async (req, res) => {
  try {
    const { classroom_id, resolved } = req.query;

    const snapshot = await db.collection('alerts').get();
    let docs = snapshot.docs;

    // Sort in memory by timestamp desc
    docs.sort((a, b) => {
      const tA = a.data().timestamp?.toDate() || new Date(0);
      const tB = b.data().timestamp?.toDate() || new Date(0);
      return tB - tA;
    });

    if (classroom_id) {
      docs = docs.filter(doc => doc.data().classroom_id === classroom_id);
    }

    if (resolved !== undefined) {
      const targetResolved = resolved === 'true';
      docs = docs.filter(doc => doc.data().resolved === targetResolved);
    }

    const alerts = docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      timestamp: doc.data().timestamp?.toDate().toISOString(),
      resolved_at: doc.data().resolved_at?.toDate().toISOString() || null,
    }));

    return res.status(200).json({ alerts });
  } catch (error) {
    console.error('Error fetching alerts:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

router.patch('/:alertId/resolve', authenticateTokenOrApiKey, async (req, res) => {
  try {
    const { alertId } = req.params;
    const { resolved_by } = req.body;

    if (!resolved_by) {
      return res.status(400).json({ error: 'resolved_by is required' });
    }

    const alertRef = db.collection('alerts').doc(alertId);
    const alertDoc = await alertRef.get();

    if (!alertDoc.exists) {
      return res.status(404).json({ error: 'Alert not found' });
    }

    await alertRef.update({
      resolved: true,
      resolved_by,
      resolved_at: Timestamp.now(),
    });

    return res.status(200).json({ success: true, message: 'Alert marked as resolved' });
  } catch (error) {
    console.error('Error resolving alert:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
