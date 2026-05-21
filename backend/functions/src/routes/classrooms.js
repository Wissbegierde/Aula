const express = require('express');
const { db, Timestamp } = require('../services/firebase');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

router.get('/', authenticateToken, async (req, res) => {
  try {
    const snapshot = await db.collection('classrooms').get();
    const classrooms = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    return res.status(200).json({ classrooms });
  } catch (error) {
    console.error('Error fetching classrooms:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/:classroomId', authenticateToken, async (req, res) => {
  try {
    const { classroomId } = req.params;
    const doc = await db.collection('classrooms').doc(classroomId).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Classroom not found' });
    }

    return res.status(200).json({
      classroom: { id: doc.id, ...doc.data() },
    });
  } catch (error) {
    console.error('Error fetching classroom:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const { name, location } = req.body;

    if (!name) {
      return res.status(400).json({ error: 'name is required' });
    }

    const classroom = {
      name,
      location: location || '',
      current_status: 'closed',
      lights_on: false,
    };

    const docRef = await db.collection('classrooms').add(classroom);

    return res.status(201).json({
      success: true,
      classroom: { id: docRef.id, ...classroom },
    });
  } catch (error) {
    console.error('Error creating classroom:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

router.patch('/:classroomId', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const { classroomId } = req.params;
    const updates = {};

    if (req.body.name !== undefined) updates.name = req.body.name;
    if (req.body.location !== undefined) updates.location = req.body.location;
    if (req.body.current_status !== undefined) updates.current_status = req.body.current_status;
    if (req.body.lights_on !== undefined) updates.lights_on = req.body.lights_on;

    await db.collection('classrooms').doc(classroomId).update(updates);

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error('Error updating classroom:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

router.delete('/:classroomId', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const { classroomId } = req.params;
    await db.collection('classrooms').doc(classroomId).delete();

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error('Error deleting classroom:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
