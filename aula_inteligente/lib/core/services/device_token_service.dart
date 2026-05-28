import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceTokenService {
  DeviceTokenService._();
  static final DeviceTokenService instance = DeviceTokenService._();

  static const _tokenKey = 'hce_device_token';
  static const _registeredKey = 'hce_device_registered';
  static const _deviceNameKey = 'hce_device_name';

  // Genera un UUID v4 estable la primera vez; lo reutiliza siempre.
  Future<String> getOrCreateToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      token = const Uuid().v4();
      await prefs.setString(_tokenKey, token);
    }
    return token;
  }

  Future<bool> get isRegistered async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_registeredKey) ?? false;
  }

  Future<void> markAsRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_registeredKey, true);
  }

  Future<void> markAsUnregistered() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_registeredKey, false);
  }

  Future<String> getDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_deviceNameKey);
    if (cached != null && cached.isNotEmpty) return cached;

    String name;
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        name = '${android.brand} ${android.model}';
      } else if (Platform.isIOS) {
        final ios = await info.iosInfo;
        name = ios.utsname.machine;
      } else {
        name = 'Dispositivo desconocido';
      }
    } catch (_) {
      name = 'Dispositivo desconocido';
    }

    await prefs.setString(_deviceNameKey, name);
    return name;
  }
}
