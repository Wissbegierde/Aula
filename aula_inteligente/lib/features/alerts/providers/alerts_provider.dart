import 'package:flutter/foundation.dart';
import '../models/alert_model.dart';

class AlertsProvider extends ChangeNotifier {
  final List<AlertModel> _alerts = [];
  int _unreadCount = 0;

  List<AlertModel> get alerts => List.unmodifiable(_alerts);
  int get unreadCount => _unreadCount;
  List<AlertModel> get activeAlerts => _alerts.where((a) => !a.isResolved).toList();

  AlertsProvider() {
    _generateMockAlerts();
  }

  void _generateMockAlerts() {
    final now = DateTime.now();
    final mockAlerts = [
      AlertModel(
        id: 'alert-001',
        type: AlertType.co2,
        severity: AlertSeverity.warning,
        title: 'CO₂ elevado',
        message: 'Nivel de CO₂ superó 1200 ppm. Se recomienda ventilar el aula.',
        timestamp: now.subtract(const Duration(minutes: 15)),
        isResolved: false,
      ),
      AlertModel(
        id: 'alert-002',
        type: AlertType.temperature,
        severity: AlertSeverity.info,
        title: 'Temperatura alta',
        message: 'La temperatura alcanzó 29°C. Considere activar ventilación.',
        timestamp: now.subtract(const Duration(hours: 1)),
        isResolved: true,
      ),
      AlertModel(
        id: 'alert-003',
        type: AlertType.access,
        severity: AlertSeverity.warning,
        title: 'Acceso denegado',
        message: 'Tarjeta RFID no autorizada detectada a las ${now.subtract(const Duration(hours: 2)).hour}:00.',
        timestamp: now.subtract(const Duration(hours: 2)),
        isResolved: true,
      ),
      AlertModel(
        id: 'alert-004',
        type: AlertType.smoke,
        severity: AlertSeverity.critical,
        title: '¡Humo detectado!',
        message: 'Sensor MQ2 detectó presencia de humo. Verifique el aula inmediatamente.',
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        isResolved: true,
      ),
      AlertModel(
        id: 'alert-005',
        type: AlertType.humidity,
        severity: AlertSeverity.info,
        title: 'Humedad baja',
        message: 'Humedad relativa por debajo del 30%. Ambiente muy seco.',
        timestamp: now.subtract(const Duration(days: 2)),
        isResolved: true,
      ),
    ];

    _alerts.addAll(mockAlerts);
    _unreadCount = _alerts.where((a) => !a.isResolved).length;
  }

  void addAlert(AlertModel alert) {
    _alerts.insert(0, alert);
    _unreadCount++;
    notifyListeners();
  }

  void markAllRead() {
    _unreadCount = 0;
    notifyListeners();
  }
}
