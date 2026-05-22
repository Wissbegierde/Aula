import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../../features/access/models/nfc_access_status.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../constants/app_config.dart';
import 'api_client.dart';

class NfcAccessService {
  NfcAccessService._();
  static final NfcAccessService instance = NfcAccessService._();

  static const Duration scanTimeout = Duration(seconds: 12);

  ApiClient? _api;

  void setApiClient(ApiClient api) {
    _api = api;
  }

  Future<bool> get isNfcAvailable async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }
    try {
      return await NfcManager.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<NfcAccessOutcome> scanDoorAccess({
    required String? currentUserRfid,
    required String? currentUserName,
  }) async {
    final available = await isNfcAvailable;

    if (!available) {
      return _simulateScan(currentUserRfid, currentUserName);
    }

    final completer = Completer<NfcAccessOutcome>();
    Timer? timeoutTimer;
    var completed = false;

    void complete(NfcAccessOutcome outcome) {
      if (completed) return;
      completed = true;
      timeoutTimer?.cancel();
      NfcManager.instance.stopSession().catchError((_) {});
      if (!completer.isCompleted) completer.complete(outcome);
    }

    timeoutTimer = Timer(scanTimeout, () {
      complete(
        const NfcAccessOutcome(
          status: NfcAccessStatus.badRead,
          title: 'Mala lectura',
          message:
              'No se detectó el sensor de la puerta. Acerca el teléfono al lector NFC e intenta de nuevo.',
        ),
      );
    });

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          final tagId = _extractTagId(tag);
          final outcome = await _evaluateTagWithBackend(tagId);
          complete(outcome);
        },
      );
    } catch (e) {
      complete(
        NfcAccessOutcome(
          status: NfcAccessStatus.badRead,
          title: 'Mala lectura',
          message: 'Error al iniciar NFC: $e',
        ),
      );
      return completer.future;
    }

    return completer.future;
  }

  Future<NfcAccessOutcome> _evaluateTagWithBackend(String? rawTagId) async {
    final tagId = _normalizeTagId(rawTagId);

    if (tagId == null || tagId.isEmpty) {
      return const NfcAccessOutcome(
        status: NfcAccessStatus.badRead,
        title: 'Mala lectura',
        message: 'No se pudo leer el identificador NFC.',
      );
    }

    if (_api != null) {
      try {
        final data = await _api!.post('/auth/validate-nfc', body: {
          'card_uid': tagId,
        });
        final authorized = data['authorized'] as bool? ?? false;
        if (authorized) {
          return NfcAccessOutcome(
            status: NfcAccessStatus.granted,
            title: 'Acceso permitido',
            message: 'Bienvenido/a, ${data['name'] ?? 'Usuario'}. Puerta desbloqueada.',
            tagId: tagId,
            userName: data['name'] as String?,
            userId: data['user_id'] as String?,
            userRole: data['role'] as String?,
          );
        } else {
          return NfcAccessOutcome(
            status: NfcAccessStatus.denied,
            title: 'Acceso denegado',
            message: data['message'] as String? ?? 'Tarjeta no autorizada.',
            tagId: tagId,
          );
        }
      } catch (e) {
        debugPrint('Error validating NFC via backend: $e');
      }
    }

    final user = AuthProvider.findUserByRfidTag(tagId);
    if (user == null) {
      return NfcAccessOutcome(
        status: NfcAccessStatus.denied,
        title: 'Acceso denegado',
        message: 'Tarjeta o dispositivo no autorizado para esta puerta.',
        tagId: tagId,
      );
    }

    if (!user.isActive) {
      return NfcAccessOutcome(
        status: NfcAccessStatus.denied,
        title: 'Acceso denegado',
        message: 'El usuario ${user.name} no tiene acceso activo.',
        tagId: tagId,
        userName: user.name,
      );
    }

    return NfcAccessOutcome(
      status: NfcAccessStatus.granted,
      title: 'Acceso permitido',
      message: 'Bienvenido/a, ${user.name}. Puerta desbloqueada.',
      tagId: tagId,
      userName: user.name,
      userId: user.id,
      userRole: user.role.name,
    );
  }

  Future<NfcAccessOutcome> _simulateScan(
    String? currentUserRfid,
    String? currentUserName,
  ) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (currentUserRfid == null || currentUserRfid.isEmpty) {
      return const NfcAccessOutcome(
        status: NfcAccessStatus.badRead,
        title: 'Mala lectura',
        message: 'Inicia sesión para simular el acceso NFC.',
      );
    }

    return _evaluateTagWithBackend(currentUserRfid);
  }

  String? _extractTagId(NfcTag tag) {
    final data = tag.data;
    for (final key in ['nfca', 'nfcb', 'nfcf', 'nfcv']) {
      final tech = data[key];
      if (tech is Map && tech['identifier'] != null) {
        return _bytesToHex(List<int>.from(tech['identifier'] as List));
      }
    }
    return null;
  }

  String? _normalizeTagId(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
    if (cleaned.isEmpty) return null;

    if (cleaned.length > 8) {
      final suffix = cleaned.substring(cleaned.length - 8);
      if (AuthProvider.findUserByRfidTag(suffix) != null) return suffix;
    }
    return cleaned;
  }

  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
  }
}
