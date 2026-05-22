import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/services/api_client.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient _api;
  bool _lightsOn = true;
  int _occupancy = 14;
  final String classroomName;
  Timer? _timer;

  DashboardProvider(this._api, {this.classroomName = 'Aula 201 — Edificio B'}) {
    _fetchStatus();
    _timer = Timer.periodic(AppConfig.sensorPollInterval, (_) => _fetchStatus());
  }

  bool get lightsOn => _lightsOn;
  int get occupancy => _occupancy;

  Future<void> _fetchStatus() async {
    try {
      final data = await _api.get(
        '/classrooms/${AppConfig.classroomId}',
      );
      final classroom = data['classroom'] as Map<String, dynamic>?;
      if (classroom != null) {
        _lightsOn = classroom['lights_on'] as bool? ?? true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching classroom status: $e');
    }
  }

  Future<void> toggleLights() async {
    _lightsOn = !_lightsOn;
    notifyListeners();

    try {
      await _api.patch(
        '/classrooms/${AppConfig.classroomId}',
        body: {'lights_on': _lightsOn},
      );
    } catch (e) {
      debugPrint('Error toggling lights: $e');
      _lightsOn = !_lightsOn;
      notifyListeners();
    }
  }

  void setOccupancy(int value) {
    _occupancy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
