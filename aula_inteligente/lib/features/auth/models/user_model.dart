enum UserRole { admin, teacher, janitor }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String rfidTag;
  final bool isActive;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.rfidTag,
    required this.isActive,
    required this.createdAt,
  });

  String get roleLabel {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.teacher:
        return 'Docente';
      case UserRole.janitor:
        return 'Conserje';
    }
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.teacher,
      ),
      rfidTag: map['rfidTag'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'rfidTag': rfidTag,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };
}
