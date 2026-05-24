import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
