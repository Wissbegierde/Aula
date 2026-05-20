import 'package:flutter_test/flutter_test.dart';
import 'package:aula_inteligente/features/auth/models/user_model.dart';

void main() {
  test('UserModel expone etiqueta de rol en español', () {
    final user = UserModel(
      id: '1',
      name: 'Test',
      email: 'test@test.com',
      role: UserRole.admin,
      rfidTag: 'ABC',
      isActive: true,
      createdAt: DateTime(2024, 1, 1),
    );
    expect(user.roleLabel, 'Administrador');
  });
}
