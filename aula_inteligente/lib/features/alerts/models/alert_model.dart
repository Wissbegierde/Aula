enum AlertSeverity { info, warning, critical }
enum AlertType { smoke, airQuality, temperature, humidity, access }

class AlertModel {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isResolved;

  const AlertModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isResolved,
  });

  String get typeIcon {
    switch (type) {
      case AlertType.smoke:
        return '💨';
      case AlertType.airQuality:
        return '🌫️';
      case AlertType.temperature:
        return '🌡️';
      case AlertType.humidity:
        return '💧';
      case AlertType.access:
        return '🔒';
    }
  }

  String get typeLabel {
    switch (type) {
      case AlertType.smoke:
        return 'Humo';
      case AlertType.airQuality:
        return 'Calidad del aire';
      case AlertType.temperature:
        return 'Temperatura';
      case AlertType.humidity:
        return 'Humedad';
      case AlertType.access:
        return 'Acceso';
    }
  }

  factory AlertModel.fromApi(Map<String, dynamic> map) {
    return AlertModel(
      id: map['id'] ?? '',
      type: _parseType(map['type'] as String? ?? ''),
      severity: _parseSeverity(map['severity'] as String? ?? 'info'),
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      isResolved: map['resolved'] ?? false,
    );
  }

  static AlertType _parseType(String type) {
    switch (type) {
      case 'smoke':
        return AlertType.smoke;
      case 'air_quality':
        return AlertType.airQuality;
      case 'high_temp':
        return AlertType.temperature;
      case 'high_humidity':
        return AlertType.humidity;
      case 'access':
        return AlertType.access;
      default:
        return AlertType.smoke;
    }
  }

  static AlertSeverity _parseSeverity(String severity) {
    switch (severity) {
      case 'critical':
        return AlertSeverity.critical;
      case 'warning':
        return AlertSeverity.warning;
      default:
        return AlertSeverity.info;
    }
  }
}
