const functions = require('firebase-functions');
const { db, Timestamp } = require('../services/firebase');
const { INACTIVITY_TIMEOUT_HOURS } = require('../config');

exports.autoCloseOnInactivity = functions.pubsub
  .schedule('every 30 minutes')
  .onRun(async () => {
    const now = Timestamp.now();
    const cutoff = new Date(now.toDate().getTime() - INACTIVITY_TIMEOUT_HOURS * 60 * 60 * 1000);
    const cutoffTimestamp = Timestamp.fromDate(cutoff);

    try {
      const openClassroomsSnapshot = await db
        .collection('classrooms')
        .where('current_status', '==', 'open')
        .get();

      if (openClassroomsSnapshot.empty) {
        console.log('No open classrooms to check');
        return null;
      }

      const batch = db.batch();

      for (const classroomDoc of openClassroomsSnapshot.docs) {
        const classroomId = classroomDoc.id;

        const lastActivitySnapshot = await db
          .collection('access_logs')
          .where('classroom_id', '==', classroomId)
          .orderBy('timestamp', 'desc')
          .limit(1)
          .get();

        if (!lastActivitySnapshot.empty) {
          const lastLog = lastActivitySnapshot.docs[0].data();
          const lastActivityTime = lastLog.timestamp.toDate();

          if (lastActivityTime < cutoff) {
            console.log(
              `Auto-closing classroom ${classroomId} - no activity since ${lastActivityTime.toISOString()}`
            );

            batch.update(classroomDoc.ref, {
              current_status: 'closed',
              lights_on: false,
            });

            await db.collection('access_logs').add({
              classroom_id: classroomId,
              user_id: 'system',
              user_name: 'Sistema',
              role: 'admin',
              action: 'close',
              granted: true,
              timestamp: Timestamp.now(),
            });
          }
        }
      }

      await batch.commit();
      console.log('Auto-close check completed');
    } catch (error) {
      console.error('Error in auto-close function:', error);
    }

    return null;
  });
