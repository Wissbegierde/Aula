import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/access_log_model.dart';
import '../models/nfc_access_status.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

class AccessProvider extends ChangeNotifier {
  final List<AccessLogModel> _logs = [];
  bool _isDoorOpen = false;

  List<AccessLogModel> get logs => List.unmodifiable(_logs);
  bool get isDoorOpen => _isDoorOpen;

  AccessProvider() {
    _generateMockLogs();
  }

  void _generateMockLogs() {
    final names = ['María García', 'Carlos Mendoza', 'Roberto López', 'Ana Torres', 'Luis Pérez'];
    final roles = ['teacher', 'admin', 'janitor', 'teacher', 'teacher'];
    final rfids = ['E5F6G7H8', 'A1B2C3D4', 'I9J0K1L2', 'M3N4O5P6', 'Q7R8S9T0'];
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
  }

  void simulateAccess(String userName, AccessAction action, bool granted) {
    _logs.insert(
      0,
      AccessLogModel(
        id: 'log-${DateTime.now().millisecondsSinceEpoch}',
        userId: 'user-sim',
        userName: userName,
        userRole: 'teacher',
        rfidTag: granted ? 'E5F6G7H8' : 'UNKNOWN',
        timestamp: DateTime.now(),
        action: action,
        granted: granted,
      ),
    );
    if (granted) _isDoorOpen = action == AccessAction.entry;
    notifyListeners();
  }

  /// Registra el resultado del escaneo NFC en el historial y estado de puerta.
  void registerNfcOutcome(NfcAccessOutcome outcome) {
    if (outcome.status == NfcAccessStatus.badRead) return;

    final granted = outcome.status == NfcAccessStatus.granted;
    UserModel? user;
    if (outcome.tagId != null) {
      user = AuthProvider.findUserByRfidTag(outcome.tagId!);
    }

    _logs.insert(
      0,
      AccessLogModel(
        id: 'log-nfc-${DateTime.now().millisecondsSinceEpoch}',
        userId: user?.id ?? 'unknown',
        userName: outcome.userName ?? user?.name ?? 'Desconocido',
        userRole: user?.role.name ?? 'unknown',
        rfidTag: outcome.tagId ?? 'UNKNOWN',
        timestamp: DateTime.now(),
        action: granted ? AccessAction.entry : AccessAction.denied,
        granted: granted,
      ),
    );

    if (granted) _isDoorOpen = true;
    notifyListeners();
  }
}
