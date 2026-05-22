/**
 * Seed script for Aula Inteligente Firebase Firestore.
 *
 * Populates initial data:
 *   - 3 users (admin, teacher, janitor) with NFC card UIDs
 *   - 1 default classroom
 *
 * Usage:
 *   node scripts/seed.js
 *
 * Requires firebase-admin credentials:
 *   - Set GOOGLE_APPLICATION_CREDENTIALS env var, OR
 *   - Run from a Firebase Cloud Functions environment
 */

const admin = require('firebase-admin');

const serviceAccount = process.env.GOOGLE_APPLICATION_CREDENTIALS
  ? require(process.env.GOOGLE_APPLICATION_CREDENTIALS)
  : null;

if (serviceAccount) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'aula-inteligente-30639',
  });
} else {
  admin.initializeApp({
    projectId: 'aula-inteligente-30639',
  });
}

const db = admin.firestore();

const USERS = [
  {
    id: 'admin-001',
    name: 'Carlos Mendoza',
    email: 'admin@escuela.edu',
    role: 'admin',
    card_uid: 'a1b2c3d4',
    active: true,
  },
  {
    id: 'teacher-001',
    name: 'María García',
    email: 'docente@escuela.edu',
    role: 'docente',
    card_uid: 'e5f6a7b8',
    active: true,
  },
  {
    id: 'janitor-001',
    name: 'Roberto López',
    email: 'conserje@escuela.edu',
    role: 'conserje',
    card_uid: '32af4e06',
    active: true,
  },
];

const CLASSROOMS = [
  {
    id: 'aula-201-edificio-b',
    name: 'Aula 201 — Edificio B',
    location: 'Edificio B, Piso 2',
    current_status: 'closed',
    lights_on: false,
  },
];

async function seed() {
  console.log('Seeding Firestore...\n');

  // Seed users
  for (const user of USERS) {
    const ref = db.collection('users').doc(user.id);
    const existing = await ref.get();
    if (existing.exists) {
      console.log(`  SKIP user ${user.id} (already exists)`);
      continue;
    }
    await ref.set({
      ...user,
      created_at: admin.firestore.Timestamp.now(),
    });
    console.log(`  CREATED user ${user.id} (${user.name}, ${user.role})`);
  }

  // Seed classrooms
  for (const classroom of CLASSROOMS) {
    const ref = db.collection('classrooms').doc(classroom.id);
    const existing = await ref.get();
    if (existing.exists) {
      console.log(`  SKIP classroom ${classroom.id} (already exists)`);
      continue;
    }
    await ref.set(classroom);
    console.log(`  CREATED classroom ${classroom.id} (${classroom.name})`);
  }

  console.log('\nDone!');
  process.exit(0);
}

seed().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
