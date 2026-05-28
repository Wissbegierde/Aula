import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'device_token_service.dart';

class HceKeyService {
  HceKeyService._();
  static final HceKeyService instance = HceKeyService._();

  static const _channel = MethodChannel('com.example.aula_inteligente/hce');

  static const Duration activationTimeout = Duration(seconds: 45);

  bool _isActive = false;

  bool get isActive => _isActive;

  Future<bool> get isHceSupported async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      await _channel.invokeMethod('getHceUid');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Activa el modo llave usando el deviceToken del dispositivo como identificador.
  /// El ESP32 recibirá este token vía APDU y lo validará contra el backend.
  Future<void> activateWithDeviceToken() async {
    final token = await DeviceTokenService.instance.getOrCreateToken();
    try {
      await _channel.invokeMethod('setHceUid', {'uid': token});
      _isActive = true;
    } catch (e) {
      _isActive = false;
      throw Exception('Failed to activate HCE key mode: $e');
    }
  }

  /// Activa el modo llave con un UID personalizado (uso legacy / tarjetas físicas).
  Future<void> activate({required String uid}) async {
    try {
      await _channel.invokeMethod('setHceUid', {'uid': uid});
      _isActive = true;
    } catch (e) {
      _isActive = false;
      throw Exception('Failed to activate HCE key mode: $e');
    }
  }

  Future<void> deactivate() async {
    try {
      await _channel.invokeMethod('setHceUid', {'uid': ''});
    } catch (_) {}
    _isActive = false;
  }
}
