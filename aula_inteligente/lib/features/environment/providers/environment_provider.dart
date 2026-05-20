import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/sensor_data_model.dart';

class EnvironmentProvider extends ChangeNotifier {
  SensorData _current = SensorData(
    temperature: 22.4,
    humidity: 55.0,
    co2: 620.0,
    smokeDetected: false,
    flameDetected: false,
    timestamp: DateTime.now(),
  );

  final List<SensorReading> _temperatureHistory = [];
  final List<SensorReading> _humidityHistory = [];
  final List<SensorReading> _co2History = [];

  Timer? _timer;
  final Random _rng = Random();

  SensorData get current => _current;
  List<SensorReading> get temperatureHistory => _temperatureHistory;
  List<SensorReading> get humidityHistory => _humidityHistory;
  List<SensorReading> get co2History => _co2History;

  EnvironmentProvider() {
    _generateHistory();
    _startPolling();
  }

  void _generateHistory() {
    final now = DateTime.now();
    for (int i = 23; i >= 0; i--) {
      final t = now.subtract(Duration(hours: i));
      _temperatureHistory.add(SensorReading(time: t, value: 19 + _rng.nextDouble() * 8));
      _humidityHistory.add(SensorReading(time: t, value: 45 + _rng.nextDouble() * 25));
      _co2History.add(SensorReading(time: t, value: 400 + _rng.nextDouble() * 700));
    }
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _updateReadings());
  }

  void _updateReadings() {
    final now = DateTime.now();
    double newTemp = (_current.temperature + (_rng.nextDouble() - 0.5) * 0.6).clamp(15.0, 40.0);
    double newHumid = (_current.humidity + (_rng.nextDouble() - 0.5) * 1.5).clamp(20.0, 95.0);
    double newCo2 = (_current.co2 + (_rng.nextDouble() - 0.5) * 30).clamp(350.0, 2000.0);

    _current = SensorData(
      temperature: double.parse(newTemp.toStringAsFixed(1)),
      humidity: double.parse(newHumid.toStringAsFixed(1)),
      co2: double.parse(newCo2.toStringAsFixed(0)),
      smokeDetected: _current.smokeDetected,
      flameDetected: _current.flameDetected,
      timestamp: now,
    );

    if (_temperatureHistory.length >= 24) _temperatureHistory.removeAt(0);
    if (_humidityHistory.length >= 24) _humidityHistory.removeAt(0);
    if (_co2History.length >= 24) _co2History.removeAt(0);

    _temperatureHistory.add(SensorReading(time: now, value: newTemp));
    _humidityHistory.add(SensorReading(time: now, value: newHumid));
    _co2History.add(SensorReading(time: now, value: newCo2));

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
