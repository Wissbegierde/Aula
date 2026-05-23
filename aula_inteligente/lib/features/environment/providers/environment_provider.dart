import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/services/api_client.dart';
import '../models/sensor_data_model.dart';

class EnvironmentProvider extends ChangeNotifier {
  final ApiClient _api;
  SensorData _current = SensorData(
    temperature: 22.4,
    humidity: 55.0,
    airQualityIndex: 42,
    smokeDetected: false,
    timestamp: DateTime.now(),
  );

  final List<SensorReading> _temperatureHistory = [];
  final List<SensorReading> _humidityHistory = [];
  final List<SensorReading> _airQualityHistory = [];

  Timer? _timer;
  final Random _rng = Random();
  bool _useMock = true;

  EnvironmentProvider(this._api) {
    _generateHistory();
    _fetchLatest();
    _startPolling();
  }

  SensorData get current => _current;
  List<SensorReading> get temperatureHistory => _temperatureHistory;
  List<SensorReading> get humidityHistory => _humidityHistory;
  List<SensorReading> get airQualityHistory => _airQualityHistory;

  void _generateHistory() {
    final now = DateTime.now();
    for (int i = 23; i >= 0; i--) {
      final t = now.subtract(Duration(hours: i));
      _temperatureHistory.add(SensorReading(time: t, value: 19 + _rng.nextDouble() * 8));
      _humidityHistory.add(SensorReading(time: t, value: 45 + _rng.nextDouble() * 25));
      _airQualityHistory.add(SensorReading(time: t, value: 20 + _rng.nextDouble() * 80));
    }
  }

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
        _useMock = false;
        _updateHistoryFromApi();
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('Error fetching sensor data: $e');
    }
    _updateReadingsMock();
  }

  void _updateHistoryFromApi() {
    final now = DateTime.now();
    _temperatureHistory.add(SensorReading(time: now, value: _current.temperature));
    _humidityHistory.add(SensorReading(time: now, value: _current.humidity));
    _airQualityHistory.add(SensorReading(time: now, value: _current.airQualityIndex.toDouble()));
    if (_temperatureHistory.length > 24) _temperatureHistory.removeAt(0);
    if (_humidityHistory.length > 24) _humidityHistory.removeAt(0);
    if (_airQualityHistory.length > 24) _airQualityHistory.removeAt(0);
  }

  void _updateReadingsMock() {
    if (!_useMock) return;
    final now = DateTime.now();
    double newTemp = (_current.temperature + (_rng.nextDouble() - 0.5) * 0.6).clamp(15.0, 40.0);
    double newHumid = (_current.humidity + (_rng.nextDouble() - 0.5) * 1.5).clamp(20.0, 95.0);
    double newAirQuality = (_current.airQualityIndex + (_rng.nextDouble() - 0.5) * 10).clamp(0, 300).toDouble();

    _current = SensorData(
      temperature: double.parse(newTemp.toStringAsFixed(1)),
      humidity: double.parse(newHumid.toStringAsFixed(1)),
      airQualityIndex: newAirQuality,
      smokeDetected: _current.smokeDetected,
      timestamp: now,
    );

    if (_temperatureHistory.length >= 24) _temperatureHistory.removeAt(0);
    if (_humidityHistory.length >= 24) _humidityHistory.removeAt(0);
    if (_airQualityHistory.length >= 24) _airQualityHistory.removeAt(0);

    _temperatureHistory.add(SensorReading(time: now, value: newTemp));
    _humidityHistory.add(SensorReading(time: now, value: newHumid));
    _airQualityHistory.add(SensorReading(time: now, value: newAirQuality));

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
