const express = require('express');
const { db } = require('../services/firebase');

const router = express.Router();

router.post('/validate-nfc', async (req, res) => {
  try {
    const { card_uid } = req.body;

    console.log('[validate-nfc] Raw card_uid:', JSON.stringify(card_uid));

    if (!card_uid) {
      return res.status(400).json({ error: 'card_uid is required' });
    }

    const normalizedUid = card_uid.trim().toLowerCase();
    console.log('[validate-nfc] Normalized:', JSON.stringify(normalizedUid));

    let usersSnapshot = await db
      .collection('users')
      .where('card_uid', '==', normalizedUid)
      .where('active', '==', true)
      .limit(1)
      .get();

    console.log('[validate-nfc] Firestore card_uid results:', usersSnapshot.size);

    if (usersSnapshot.empty) {
      console.log('[validate-nfc] Checking device_tokens for:', normalizedUid);
      usersSnapshot = await db
        .collection('users')
        .where('device_tokens', 'array-contains', normalizedUid)
        .where('active', '==', true)
        .limit(1)
        .get();
      console.log('[validate-nfc] Firestore device_tokens results:', usersSnapshot.size);
    }

    if (usersSnapshot.empty) {
      console.log('[validate-nfc] No user found for UID or device token:', normalizedUid);
      return res.status(200).json({
        authorized: false,
        message: 'Tarjeta o celular no reconocido o usuario desactivado',
      });
    }

    const userDoc = usersSnapshot.docs[0];
    const userData = userDoc.data();

    return res.status(200).json({
      authorized: true,
      user_id: userDoc.id,
      role: userData.role,
      name: userData.name,
    });
  } catch (error) {
    console.error('Error validating NFC:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
