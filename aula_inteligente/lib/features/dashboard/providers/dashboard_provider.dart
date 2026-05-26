import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/services/api_client.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient _api;
  int _occupancy = 0;
  bool? _lightsOn;
  String? _status;
  final String classroomName;
  Timer? _timer;

  DashboardProvider(this._api, {this.classroomName = 'Aula 201 — Edificio B'}) {
    _fetchStatus();
    _timer = Timer.periodic(AppConfig.sensorPollInterval, (_) => _fetchStatus());
  }

  int get occupancy => _occupancy;
  bool? get lightsOn => _lightsOn;
  String? get status => _status;

  Future<void> _fetchStatus() async {
    try {
      final data = await _api.get(
        '/classrooms/${AppConfig.classroomId}',
      );
      final classroom = data['classroom'] as Map<String, dynamic>?;
      if (classroom != null) {
        _status = classroom['current_status'] as String?;
        _lightsOn = classroom['lights_on'] as bool?;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching classroom status: $e');
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
