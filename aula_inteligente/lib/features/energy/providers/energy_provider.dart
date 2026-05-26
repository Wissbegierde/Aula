import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/services/api_client.dart';
import '../models/energy_model.dart';

class EnergyProvider extends ChangeNotifier {
  final ApiClient _api;
  List<EnergyReading> _history = [];
  double _currentPowerKw = 0;
  Timer? _timer;
  bool _hasData = false;

  List<EnergyReading> get history => List.unmodifiable(_history);
  double get currentPowerKw => _currentPowerKw;
  bool get hasData => _hasData;
  double get todayConsumptionKwh => _history.fold(0.0, (sum, r) => sum + r.kwh);
  double get monthConsumptionKwh => todayConsumptionKwh * 30;

  EnergyProvider(this._api) {
    _fetchData();
    _timer = Timer.periodic(AppConfig.sensorPollInterval, (_) => _fetchData());
  }

  Future<void> _fetchData() async {
    try {
      final data = await _api.get(
        '/sensors/history',
        queryParams: {
          'classroom_id': AppConfig.classroomId,
          'limit': '24',
        },
      );
      final readings = data['readings'] as List<dynamic>?;
      if (readings != null && readings.isNotEmpty) {
        final powerReadings = readings
            .map((r) => r as Map<String, dynamic>)
            .where((r) => r['power_consumption_watts'] != null)
            .toList();
        if (powerReadings.isNotEmpty) {
          _history = powerReadings.map((r) {
            return EnergyReading(
              time: DateTime.tryParse(r['timestamp'] ?? '') ?? DateTime.now(),
              kwh: ((r['power_consumption_watts'] as num).toDouble() / 1000.0),
            );
          }).toList();
          _currentPowerKw = _history.last.kwh;
          _hasData = true;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching energy data: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
