class SensorData {
  final double temperature;
  final double humidity;
  final double co2;
  final bool smokeDetected;
  final bool flameDetected;
  final DateTime timestamp;

  const SensorData({
    required this.temperature,
    required this.humidity,
    required this.co2,
    required this.smokeDetected,
    required this.flameDetected,
    required this.timestamp,
  });

  String get temperatureStatus {
    if (temperature < 18) return 'Frío';
    if (temperature <= 26) return 'Óptimo';
    if (temperature <= 30) return 'Cálido';
    return 'Caliente';
  }

  String get humidityStatus {
    if (humidity < 30) return 'Seco';
    if (humidity <= 60) return 'Óptimo';
    return 'Húmedo';
  }

  String get co2Status {
    if (co2 < 400) return 'Excelente';
    if (co2 <= 800) return 'Bueno';
    if (co2 <= 1200) return 'Moderado';
    return 'Alto';
  }

  bool get hasAlert => smokeDetected || flameDetected || co2 > 1500;

  factory SensorData.fromMap(Map<String, dynamic> map) {
    return SensorData(
      temperature: (map['temperature'] ?? 0.0).toDouble(),
      humidity: (map['humidity'] ?? 0.0).toDouble(),
      co2: (map['co2'] ?? 0.0).toDouble(),
      smokeDetected: map['smokeDetected'] ?? false,
      flameDetected: map['flameDetected'] ?? false,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'temperature': temperature,
        'humidity': humidity,
        'co2': co2,
        'smokeDetected': smokeDetected,
        'flameDetected': flameDetected,
        'timestamp': timestamp.toIso8601String(),
      };
}

class SensorReading {
  final DateTime time;
  final double value;

  const SensorReading({required this.time, required this.value});
}
