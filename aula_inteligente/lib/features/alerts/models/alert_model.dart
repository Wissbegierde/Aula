enum AlertSeverity { info, warning, critical }
enum AlertType { smoke, flame, co2, temperature, humidity, access }

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
      case AlertType.flame:
        return '🔥';
      case AlertType.co2:
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
      case AlertType.flame:
        return 'Flama';
      case AlertType.co2:
        return 'CO₂';
      case AlertType.temperature:
        return 'Temperatura';
      case AlertType.humidity:
        return 'Humedad';
      case AlertType.access:
        return 'Acceso';
    }
  }
}
