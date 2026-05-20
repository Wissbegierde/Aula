class AccessLogModel {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String rfidTag;
  final DateTime timestamp;
  final AccessAction action;
  final bool granted;

  const AccessLogModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.rfidTag,
    required this.timestamp,
    required this.action,
    required this.granted,
  });

  factory AccessLogModel.fromMap(Map<String, dynamic> map) {
    return AccessLogModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userRole: map['userRole'] ?? '',
      rfidTag: map['rfidTag'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      action: AccessAction.values.firstWhere(
        (a) => a.name == map['action'],
        orElse: () => AccessAction.entry,
      ),
      granted: map['granted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'userRole': userRole,
        'rfidTag': rfidTag,
        'timestamp': timestamp.toIso8601String(),
        'action': action.name,
        'granted': granted,
      };
}

enum AccessAction { entry, exit, denied }

extension AccessActionLabel on AccessAction {
  String get label {
    switch (this) {
      case AccessAction.entry:
        return 'Entrada';
      case AccessAction.exit:
        return 'Salida';
      case AccessAction.denied:
        return 'Denegado';
    }
  }
}
