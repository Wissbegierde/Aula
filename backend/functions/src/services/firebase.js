const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();
const FieldValue = admin.firestore.FieldValue;
const Timestamp = admin.firestore.Timestamp;

module.exports = {
  admin,
  db,
  auth,
  FieldValue,
  Timestamp,
};
