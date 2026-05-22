import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

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
    },
  ];

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

    _currentUser = UserModel.fromMap(match.first);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  static List<UserModel> get authorizedUsers =>
      _mockUsers.map((u) => UserModel.fromMap(u)).toList();

  static UserModel? findUserByRfidTag(String tagId) {
    final normalized = tagId.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
    for (final user in authorizedUsers) {
      final userTag =
          user.rfidTag.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
      if (userTag == normalized) return user;
    }
    return null;
  }
}
