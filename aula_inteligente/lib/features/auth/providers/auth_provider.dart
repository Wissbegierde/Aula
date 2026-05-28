import 'package:flutter/foundation.dart';
import '../../../core/services/api_client.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  ApiClient? _api;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  void setApiClient(ApiClient api) {
    _api = api;
  }

  // ---------------------------------------------------------------------------
  // Mock users — en producción esto vendría del backend
  // ---------------------------------------------------------------------------
  static final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': 'admin-001',
      'name': 'Carlos Mendoza',
      'email': 'admin@escuela.edu',
      'password': 'admin123',
      'role': 'admin',
      'rfidTag': 'A1B2C3D4',
      'isActive': true,
      'createdAt': '2024-01-15T08:00:00',
      'registeredDevices': <Map<String, dynamic>>[],
    },
    {
      'id': 'teacher-001',
      'name': 'María García',
      'email': 'docente@escuela.edu',
      'password': 'docente123',
      'role': 'teacher',
      'rfidTag': 'E5F6A7B8',
      'isActive': true,
      'createdAt': '2024-02-10T09:00:00',
      'registeredDevices': <Map<String, dynamic>>[],
    },
    {
      'id': 'janitor-001',
      'name': 'Roberto López',
      'email': 'conserje@escuela.edu',
      'password': 'conserje123',
      'role': 'janitor',
      'rfidTag': '32AF4E06',
      'isActive': true,
      'createdAt': '2024-03-05T07:00:00',
      'registeredDevices': <Map<String, dynamic>>[],
    },
  ];

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    final match = _mockUsers.where(
      (u) => u['email'] == email.trim() && u['password'] == password,
    );

    if (match.isEmpty) {
      _error = 'Correo o contraseña incorrectos';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final mockData = match.first;
    UserModel user = UserModel.fromMap(mockData);

    if (_api != null) {
      try {
        final response = await _api!.get('/users/${user.id}');
        final backendUser = response['user'] as Map<String, dynamic>?;
        if (backendUser != null) {
          final registeredList = backendUser['registered_devices'] as List<dynamic>? ?? [];
          final devices = registeredList.map((d) {
            final map = d as Map<String, dynamic>;
            return RegisteredDevice(
              deviceToken: map['deviceToken'] ?? '',
              deviceName: map['deviceName'] ?? '',
              registeredAt: DateTime.tryParse(map['registeredAt'] ?? '') ?? DateTime.now(),
            );
          }).toList();

          user = user.copyWith(registeredDevices: devices);
        }
      } catch (e) {
        debugPrint('Error syncing user from backend: $e');
      }
    }

    _currentUser = user;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Device registration
  // ---------------------------------------------------------------------------

  /// Registra el celular actual como llave NFC para el usuario autenticado.
  Future<bool> registerDevice({
    required String deviceToken,
    required String deviceName,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    // Verifica que el token no esté ya registrado en esta cuenta
    final alreadyRegistered = _currentUser!.registeredDevices
        .any((d) => d.deviceToken.toLowerCase() == deviceToken.toLowerCase());

    if (!alreadyRegistered) {
      final newDevice = RegisteredDevice(
        deviceToken: deviceToken,
        deviceName: deviceName,
        registeredAt: DateTime.now(),
      );
      final updatedDevices = [..._currentUser!.registeredDevices, newDevice];
      _currentUser = _currentUser!.copyWith(registeredDevices: updatedDevices);

      // Actualiza en el mock
      final idx = _mockUsers.indexWhere((u) => u['id'] == _currentUser!.id);
      if (idx >= 0) {
        _mockUsers[idx]['registeredDevices'] = updatedDevices.map((d) => d.toMap()).toList();
      }

      // Enviar al backend si ApiClient está configurado
      if (_api != null) {
        try {
          final tokens = updatedDevices.map((d) => d.deviceToken.toLowerCase()).toList();
          final devicesJson = updatedDevices.map((d) => {
            'deviceToken': d.deviceToken,
            'deviceName': d.deviceName,
            'registeredAt': d.registeredAt.toUtc().toIso8601String(),
          }).toList();

          await _api!.patch('/users/${_currentUser!.id}', body: {
            'device_tokens': tokens,
            'registered_devices': devicesJson,
          });
        } catch (e) {
          debugPrint('Error updating backend with registered device: $e');
        }
      }
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Elimina un dispositivo registrado por su token.
  Future<void> removeDevice(String deviceToken) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    final updatedDevices = _currentUser!.registeredDevices
        .where((d) => d.deviceToken.toLowerCase() != deviceToken.toLowerCase())
        .toList();

    _currentUser = _currentUser!.copyWith(registeredDevices: updatedDevices);

    final idx = _mockUsers.indexWhere((u) => u['id'] == _currentUser!.id);
    if (idx >= 0) {
      _mockUsers[idx]['registeredDevices'] = updatedDevices.map((d) => d.toMap()).toList();
    }

    if (_api != null) {
      try {
        final tokens = updatedDevices.map((d) => d.deviceToken.toLowerCase()).toList();
        final devicesJson = updatedDevices.map((d) => {
          'deviceToken': d.deviceToken,
          'deviceName': d.deviceName,
          'registeredAt': d.registeredAt.toUtc().toIso8601String(),
        }).toList();

        await _api!.patch('/users/${_currentUser!.id}', body: {
          'device_tokens': tokens,
          'registered_devices': devicesJson,
        });
      } catch (e) {
        debugPrint('Error removing device from backend: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Verifica si un deviceToken está autorizado (usado por el ESP32 vía backend).
  static UserModel? findUserByDeviceToken(String token) {
    for (final u in _mockUsers) {
      final devices = u['registeredDevices'] as List;
      if (devices.any((d) => d['deviceToken'] == token)) {
        return UserModel.fromMap(u);
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // NFC tag (tarjetas físicas)
  // ---------------------------------------------------------------------------
  static List<UserModel> get authorizedUsers =>
      _mockUsers.map((u) => UserModel.fromMap(u)).toList();

  static UserModel? findUserByRfidTag(String tagId) {
    final normalized =
        tagId.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
    for (final user in authorizedUsers) {
      final userTag =
          user.rfidTag.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
      if (userTag == normalized) return user;
    }
    return null;
  }
}
