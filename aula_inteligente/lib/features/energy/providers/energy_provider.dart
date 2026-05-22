import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/services/api_client.dart';
import '../models/energy_model.dart';

class EnergyProvider extends ChangeNotifier {
  final ApiClient _api;
  List<EnergyReading> _history = [];
  double _currentPowerKw = 1.24;
  Timer? _timer;
  final Random _rng = Random();
  bool _useMock = true;

  List<EnergyReading> get history => List.unmodifiable(_history);
  double get currentPowerKw => _currentPowerKw;
  double get todayConsumptionKwh {
    if (_history.isEmpty) return 8.7;
    return _history.fold(0.0, (sum, r) => sum + r.kwh);
  }
  double get monthConsumptionKwh => todayConsumptionKwh * 30;

  EnergyProvider(this._api) {
    _generateMockHistory();
    _fetchData();
    _timer = Timer.periodic(AppConfig.sensorPollInterval, (_) => _fetchData());
  }

  void _generateMockHistory() {
    final now = DateTime.now();
    _history = List.generate(24, (i) {
      final hour = now.subtract(Duration(hours: 23 - i));
      final base = 0.8 + (i % 8) * 0.15;
      return EnergyReading(
        time: hour,
        kwh: double.parse((base + (i % 3) * 0.2).toStringAsFixed(2)),
      );
    });
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
          _useMock = false;
          notifyListeners();
          return;
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
