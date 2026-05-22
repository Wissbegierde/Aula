import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/services/api_client.dart';
import '../models/alert_model.dart';

class AlertsProvider extends ChangeNotifier {
  final ApiClient _api;
  List<AlertModel> _alerts = [];
  int _unreadCount = 0;
  Timer? _timer;

  List<AlertModel> get alerts => List.unmodifiable(_alerts);
  int get unreadCount => _unreadCount;
  List<AlertModel> get activeAlerts => _alerts.where((a) => !a.isResolved).toList();

  AlertsProvider(this._api) {
    _fetchAlerts();
    _timer = Timer.periodic(AppConfig.alertsPollInterval, (_) => _fetchAlerts());
  }

  Future<void> _fetchAlerts() async {
    try {
      final data = await _api.get(
        '/alerts',
        queryParams: {'classroom_id': AppConfig.classroomId},
      );
      final alertsList = data['alerts'] as List<dynamic>?;
      if (alertsList != null) {
        _alerts = alertsList
            .map((a) => AlertModel.fromApi(a as Map<String, dynamic>))
            .toList();
        _unreadCount = _alerts.where((a) => !a.isResolved).length;
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('Error fetching alerts: $e');
    }
    _generateMockAlerts();
  }

  void _generateMockAlerts() {
    if (_alerts.isNotEmpty) return;
    final now = DateTime.now();
    _alerts = [
      AlertModel(
        id: 'alert-001',
        type: AlertType.airQuality,
        severity: AlertSeverity.warning,
        title: 'Calidad del aire baja',
        message: 'Índice de calidad del aire elevado. Se recomienda ventilar el aula.',
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
        message: 'Tarjeta RFID no autorizada detectada.',
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
    _unreadCount = _alerts.where((a) => !a.isResolved).length;
    notifyListeners();
  }

  Future<void> resolveAlert(String alertId) async {
    try {
      await _api.patch('/alerts/$alertId/resolve');
    } catch (e) {
      debugPrint('Error resolving alert: $e');
    }
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx != -1) {
      final old = _alerts[idx];
      _alerts[idx] = AlertModel(
        id: old.id,
        type: old.type,
        severity: old.severity,
        title: old.title,
        message: old.message,
        timestamp: old.timestamp,
        isResolved: true,
      );
      _unreadCount = _alerts.where((a) => !a.isResolved).length;
      notifyListeners();
    }
  }

  void markAllRead() {
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
