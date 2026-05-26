const express = require('express');
const { db, auth, Timestamp } = require('../services/firebase');
const { authenticateTokenOrApiKey, requireRole } = require('../middleware/authOrApiKey');

const router = express.Router();

router.get('/', authenticateTokenOrApiKey, requireRole('admin'), async (req, res) => {
  try {
    const snapshot = await db.collection('users').get();
    const users = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    return res.status(200).json({ users });
  } catch (error) {
    console.error('Error fetching users:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/:userId', authenticateTokenOrApiKey, requireRole('admin'), async (req, res) => {
  try {
    const { userId } = req.params;
    const doc = await db.collection('users').doc(userId).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    return res.status(200).json({
      user: { id: doc.id, ...doc.data() },
    });
  } catch (error) {
    console.error('Error fetching user:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/', authenticateTokenOrApiKey, requireRole('admin'), async (req, res) => {
  try {
    const { name, role, card_uid, email } = req.body;

    if (!name || !role || !card_uid) {
      return res.status(400).json({ error: 'name, role, and card_uid are required' });
    }

    const validRoles = ['admin', 'docente', 'conserje'];
    if (!validRoles.includes(role)) {
      return res.status(400).json({ error: `Invalid role. Must be one of: ${validRoles.join(', ')}` });
    }

    const existingCard = await db
      .collection('users')
      .where('card_uid', '==', card_uid.trim().toLowerCase())
      .limit(1)
      .get();

    if (!existingCard.empty) {
      return res.status(409).json({ error: 'card_uid already registered' });
    }

    const userData = {
      name,
      role,
      card_uid: card_uid.trim().toLowerCase(),
      email: email || '',
      active: true,
      created_at: Timestamp.now(),
    };

    const docRef = await db.collection('users').add(userData);

    return res.status(201).json({
      success: true,
      user: { id: docRef.id, ...userData, created_at: userData.created_at.toDate().toISOString() },
    });
  } catch (error) {
    console.error('Error creating user:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

router.patch('/:userId', authenticateTokenOrApiKey, requireRole('admin'), async (req, res) => {
  try {
    const { userId } = req.params;
    const updates = {};

    if (req.body.name !== undefined) updates.name = req.body.name;
    if (req.body.role !== undefined) {
      const validRoles = ['admin', 'docente', 'conserje'];
      if (!validRoles.includes(req.body.role)) {
        return res.status(400).json({ error: `Invalid role. Must be one of: ${validRoles.join(', ')}` });
      }
      updates.role = req.body.role;
    }
    if (req.body.card_uid !== undefined) updates.card_uid = req.body.card_uid.trim().toLowerCase();
    if (req.body.email !== undefined) updates.email = req.body.email;
    if (req.body.active !== undefined) updates.active = req.body.active;

    await db.collection('users').doc(userId).update(updates);

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error('Error updating user:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

router.delete('/:userId', authenticateTokenOrApiKey, requireRole('admin'), async (req, res) => {
  try {
    const { userId } = req.params;
    await db.collection('users').doc(userId).delete();
    return res.status(200).json({ success: true });
  } catch (error) {
    console.error('Error deleting user:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
