import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/services/api_client.dart';
import '../models/sensor_data_model.dart';

class EnvironmentProvider extends ChangeNotifier {
  final ApiClient _api;
  SensorData? _current;
  bool _hasData = false;
  String? _lastError;

  final List<SensorReading> _temperatureHistory = [];
  final List<SensorReading> _humidityHistory = [];
  final List<SensorReading> _airQualityHistory = [];

  Timer? _timer;

  EnvironmentProvider(this._api) {
    _fetchLatest();
    _startPolling();
  }

  SensorData? get current => _current;
  bool get hasData => _hasData;
  String? get lastError => _lastError;
  List<SensorReading> get temperatureHistory => _temperatureHistory;
  List<SensorReading> get humidityHistory => _humidityHistory;
  List<SensorReading> get airQualityHistory => _airQualityHistory;

  void _startPolling() {
    _timer = Timer.periodic(AppConfig.sensorPollInterval, (_) => _fetchLatest());
  }

  Future<void> _fetchLatest() async {
    try {
      final data = await _api.get(
        '/sensors/latest',
        queryParams: {'classroom_id': AppConfig.classroomId},
      );
      final reading = data['reading'];
      if (reading != null) {
        _current = SensorData.fromApi(reading as Map<String, dynamic>);
        _hasData = true;
        _lastError = null;
        _updateHistory();
        notifyListeners();
        return;
      }
      _lastError = 'reading is null';
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Error fetching sensor data: $e');
    }
  }

  void _updateHistory() {
    if (_current == null) return;
    final now = DateTime.now();
    _temperatureHistory.add(SensorReading(time: now, value: _current!.temperature));
    _humidityHistory.add(SensorReading(time: now, value: _current!.humidity));
    _airQualityHistory.add(SensorReading(time: now, value: _current!.airQualityIndex.toDouble()));
    if (_temperatureHistory.length > 24) _temperatureHistory.removeAt(0);
    if (_humidityHistory.length > 24) _humidityHistory.removeAt(0);
    if (_airQualityHistory.length > 24) _airQualityHistory.removeAt(0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
