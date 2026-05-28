import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/services/api_client.dart';
import '../models/energy_model.dart';

class EnergyProvider extends ChangeNotifier {
  final ApiClient _api;
  List<EnergyReading> _history = [];
  double _currentA = 0;
  Timer? _timer;
  bool _hasData = false;

  List<EnergyReading> get history => List.unmodifiable(_history);
  double get currentA => _currentA;
  bool get hasData => _hasData;

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
        final currentReadings = readings
            .map((r) => r as Map<String, dynamic>)
            .where((r) => r['current_a'] != null)
            .toList();
        if (currentReadings.isNotEmpty) {
          _history = currentReadings.map((r) {
            return EnergyReading(
              time: DateTime.tryParse(r['timestamp'] ?? '') ?? DateTime.now(),
              currentA: (r['current_a'] as num).toDouble(),
            );
          }).toList();
          _currentA = _history.last.currentA;
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
