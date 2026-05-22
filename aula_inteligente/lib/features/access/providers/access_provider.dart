import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/services/api_client.dart';
import '../models/access_log_model.dart';
import '../models/nfc_access_status.dart';

class AccessProvider extends ChangeNotifier {
  final ApiClient _api;
  List<AccessLogModel> _logs = [];
  bool _isDoorOpen = false;
  Timer? _timer;

  List<AccessLogModel> get logs => List.unmodifiable(_logs);
  bool get isDoorOpen => _isDoorOpen;

  AccessProvider(this._api) {
    _fetchLogs();
    _timer = Timer.periodic(AppConfig.accessPollInterval, (_) => _fetchLogs());
  }

  Future<void> _fetchLogs() async {
    try {
      final data = await _api.get(
        '/access/logs',
        queryParams: {
          'classroom_id': AppConfig.classroomId,
          'limit': '50',
        },
      );
      final logsList = data['logs'] as List<dynamic>?;
      if (logsList != null) {
        _logs = logsList
            .map((l) => AccessLogModel.fromApi(l as Map<String, dynamic>))
            .toList();
        _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('Error fetching access logs: $e');
    }
    _generateMockLogs();
  }

  void _generateMockLogs() {
    if (_logs.isNotEmpty) return;
    final names = ['María García', 'Carlos Mendoza', 'Roberto López', 'Ana Torres', 'Luis Pérez'];
    final roles = ['teacher', 'admin', 'janitor', 'teacher', 'teacher'];
    final rfids = ['E5F6A7B8', 'A1B2C3D4', 'I9J0K1L2', 'M3N4O5P6', 'Q7R8S9T0'];
    final rng = Random();
    final now = DateTime.now();

    for (int i = 0; i < 20; i++) {
      final idx = rng.nextInt(names.length);
      final minutesAgo = rng.nextInt(480);
      final action = i % 7 == 0
          ? AccessAction.denied
          : (i % 2 == 0 ? AccessAction.entry : AccessAction.exit);

      _logs.add(AccessLogModel(
        id: 'log-${i.toString().padLeft(3, '0')}',
        userId: 'user-$idx',
        userName: names[idx],
        userRole: roles[idx],
        rfidTag: action == AccessAction.denied ? 'UNKNOWN' : rfids[idx],
        timestamp: now.subtract(Duration(minutes: minutesAgo)),
        action: action,
        granted: action != AccessAction.denied,
      ));
    }
    _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<bool> openDoor(String cardUid) async {
    try {
      final data = await _api.post('/access/open', body: {
        'classroom_id': AppConfig.classroomId,
        'card_uid': cardUid,
      });
      final success = data['success'] as bool? ?? false;
      if (success) {
        _isDoorOpen = true;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error opening door: $e');
      return false;
    }
  }

  Future<bool> closeDoor(String cardUid) async {
    try {
      final data = await _api.post('/access/close', body: {
        'classroom_id': AppConfig.classroomId,
        'card_uid': cardUid,
      });
      final success = data['success'] as bool? ?? false;
      if (success) {
        _isDoorOpen = false;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error closing door: $e');
      return false;
    }
  }

  void registerNfcOutcome(NfcAccessOutcome outcome) {
    if (outcome.status == NfcAccessStatus.badRead) return;

    final granted = outcome.status == NfcAccessStatus.granted;

    _logs.insert(
      0,
      AccessLogModel(
        id: 'log-nfc-${DateTime.now().millisecondsSinceEpoch}',
        userId: outcome.userId ?? 'unknown',
        userName: outcome.userName ?? 'Desconocido',
        userRole: outcome.userRole ?? 'unknown',
        rfidTag: outcome.tagId ?? 'UNKNOWN',
        timestamp: DateTime.now(),
        action: granted ? AccessAction.entry : AccessAction.denied,
        granted: granted,
      ),
    );

    if (granted) _isDoorOpen = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
