enum UserRole { admin, teacher, janitor }

class RegisteredDevice {
  final String deviceToken;
  final String deviceName;
  final DateTime registeredAt;

  const RegisteredDevice({
    required this.deviceToken,
    required this.deviceName,
    required this.registeredAt,
  });

  factory RegisteredDevice.fromMap(Map<String, dynamic> map) {
    return RegisteredDevice(
      deviceToken: map['deviceToken'] as String? ?? '',
      deviceName: map['deviceName'] as String? ?? 'Dispositivo',
      registeredAt: DateTime.tryParse(map['registeredAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'deviceToken': deviceToken,
        'deviceName': deviceName,
        'registeredAt': registeredAt.toIso8601String(),
      };
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String rfidTag;
  final bool isActive;
  final DateTime createdAt;
  final List<RegisteredDevice> registeredDevices;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.rfidTag,
    required this.isActive,
    required this.createdAt,
    this.registeredDevices = const [],
  });

  bool get hasRegisteredDevice => registeredDevices.isNotEmpty;

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
    final devicesRaw = map['registeredDevices'];
    final devices = devicesRaw is List
        ? devicesRaw
            .whereType<Map<String, dynamic>>()
            .map(RegisteredDevice.fromMap)
            .toList()
        : <RegisteredDevice>[];

    return UserModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.teacher,
      ),
      rfidTag: map['rfidTag'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      registeredDevices: devices,
    );
  }

  UserModel copyWith({List<RegisteredDevice>? registeredDevices}) {
    return UserModel(
      id: id,
      name: name,
      email: email,
      role: role,
      rfidTag: rfidTag,
      isActive: isActive,
      createdAt: createdAt,
      registeredDevices: registeredDevices ?? this.registeredDevices,
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
        'registeredDevices': registeredDevices.map((d) => d.toMap()).toList(),
      };
}
