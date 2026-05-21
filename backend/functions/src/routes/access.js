const express = require('express');
const { db, Timestamp, FieldValue } = require('../services/firebase');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

router.post('/open', authenticateToken, async (req, res) => {
  try {
    const { classroom_id, card_uid } = req.body;

    if (!classroom_id || !card_uid) {
      return res.status(400).json({ error: 'classroom_id and card_uid are required' });
    }

    const normalizedUid = card_uid.trim().toLowerCase();

    const usersSnapshot = await db
      .collection('users')
      .where('card_uid', '==', normalizedUid)
      .where('active', '==', true)
      .limit(1)
      .get();

    if (usersSnapshot.empty) {
      return res.status(200).json({
        success: false,
        message: 'Acceso denegado: tarjeta no reconocida',
      });
    }

    const userDoc = usersSnapshot.docs[0];
    const user = userDoc.data();

    const classroomRef = db.collection('classrooms').doc(classroom_id);
    const classroomDoc = await classroomRef.get();

    if (!classroomDoc.exists) {
      return res.status(404).json({ error: 'Classroom not found' });
    }

    await classroomRef.update({
      current_status: 'open',
      lights_on: true,
    });

    await db.collection('access_logs').add({
      classroom_id,
      user_id: userDoc.id,
      user_name: user.name,
      role: user.role,
      action: 'open',
      granted: true,
      timestamp: Timestamp.now(),
    });

    return res.status(200).json({
      success: true,
      message: `Bienvenido ${user.name}. Aula abierta, luces encendidas.`,
    });
  } catch (error) {
    console.error('Error opening access:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/close', authenticateToken, async (req, res) => {
  try {
    const { classroom_id, card_uid } = req.body;

    if (!classroom_id || !card_uid) {
      return res.status(400).json({ error: 'classroom_id and card_uid are required' });
    }

    const normalizedUid = card_uid.trim().toLowerCase();

    const usersSnapshot = await db
      .collection('users')
      .where('card_uid', '==', normalizedUid)
      .where('active', '==', true)
      .limit(1)
      .get();

    if (usersSnapshot.empty) {
      return res.status(200).json({
        success: false,
        message: 'Acceso denegado: tarjeta no reconocida',
      });
    }

    const userDoc = usersSnapshot.docs[0];
    const user = userDoc.data();

    const classroomRef = db.collection('classrooms').doc(classroom_id);
    const classroomDoc = await classroomRef.get();

    if (!classroomDoc.exists) {
      return res.status(404).json({ error: 'Classroom not found' });
    }

    await classroomRef.update({
      current_status: 'closed',
      lights_on: false,
    });

    await db.collection('access_logs').add({
      classroom_id,
      user_id: userDoc.id,
      user_name: user.name,
      role: user.role,
      action: 'close',
      granted: true,
      timestamp: Timestamp.now(),
    });

    return res.status(200).json({
      success: true,
      message: `Aula cerrada por ${user.name}. Luces apagadas.`,
    });
  } catch (error) {
    console.error('Error closing access:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/logs', authenticateToken, async (req, res) => {
  try {
    const { classroom_id, from, to, limit: queryLimit = 50 } = req.query;

    let query = db.collection('access_logs').orderBy('timestamp', 'desc');

    if (classroom_id) {
      query = query.where('classroom_id', '==', classroom_id);
    }

    if (from) {
      const fromDate = new Date(from);
      query = query.where('timestamp', '>=', Timestamp.fromDate(fromDate));
    }

    if (to) {
      const toDate = new Date(to);
      query = query.where('timestamp', '<=', Timestamp.fromDate(toDate));
    }

    if (!req.user.role === 'admin') {
      query = query.where('user_id', '==', req.user.uid);
    }

    query = query.limit(parseInt(queryLimit, 10));

    const snapshot = await query.get();
    const logs = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      timestamp: doc.data().timestamp?.toDate().toISOString(),
    }));

    return res.status(200).json({ logs });
  } catch (error) {
    console.error('Error fetching access logs:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
