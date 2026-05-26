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
  bool _hasData = false;

  List<AlertModel> get alerts => List.unmodifiable(_alerts);
  int get unreadCount => _unreadCount;
  bool get hasData => _hasData;
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
        _hasData = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching alerts: $e');
    }
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
