const functions = require('firebase-functions');
const { db, Timestamp } = require('../services/firebase');
const { SENSOR_THRESHOLDS } = require('../config');

exports.triggerAlertOnReading = functions.firestore
  .document('sensor_readings/{readingId}')
  .onCreate(async (snap) => {
    const data = snap.data();
    const classroomId = data.classroom_id;

    const alerts = [];

    if (data.smoke_detected === true) {
      alerts.push({
        classroom_id: classroomId,
        type: 'smoke',
        title: 'Humo detectado',
        message: `Se detectó humo en el aula ${classroomId}`,
        severity: 'critical',
        resolved: false,
        timestamp: Timestamp.now(),
        resolved_at: null,
        resolved_by: null,
      });
    }

    if (data.flame_detected === true) {
      alerts.push({
        classroom_id: classroomId,
        type: 'flame',
        title: 'Llama detectada',
        message: `Se detectó una llama en el aula ${classroomId}`,
        severity: 'critical',
        resolved: false,
        timestamp: Timestamp.now(),
        resolved_at: null,
        resolved_by: null,
      });
    }

    if (data.temperature !== null && data.temperature !== undefined) {
      if (data.temperature > SENSOR_THRESHOLDS.TEMPERATURE_HIGH) {
        const severity = data.temperature > SENSOR_THRESHOLDS.TEMPERATURE_CRITICAL
          ? 'critical'
          : 'warning';
        alerts.push({
          classroom_id: classroomId,
          type: 'high_temp',
          title: 'Temperatura alta',
          message: `Temperatura de ${data.temperature}°C en el aula ${classroomId}`,
          severity,
          resolved: false,
          timestamp: Timestamp.now(),
          resolved_at: null,
          resolved_by: null,
        });
      }
    }

    if (data.humidity !== null && data.humidity !== undefined) {
      if (data.humidity > SENSOR_THRESHOLDS.HUMIDITY_HIGH) {
        alerts.push({
          classroom_id: classroomId,
          type: 'high_humidity',
          title: 'Humedad alta',
          message: `Humedad de ${data.humidity}% en el aula ${classroomId}`,
          severity: 'warning',
          resolved: false,
          timestamp: Timestamp.now(),
          resolved_at: null,
          resolved_by: null,
        });
      }
    }

    if (alerts.length > 0) {
      const batch = db.batch();
      alerts.forEach((alert) => {
        const alertRef = db.collection('alerts').doc();
        batch.set(alertRef, alert);
      });
      await batch.commit();
      console.log(`Created ${alerts.length} alert(s) for classroom ${classroomId}`);
    }
  });
