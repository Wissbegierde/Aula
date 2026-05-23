class SensorData {
  final double temperature;
  final double humidity;
  final double airQualityIndex;
  final bool smokeDetected;
  final double? powerConsumptionWatts;
  final DateTime timestamp;

  const SensorData({
    required this.temperature,
    required this.humidity,
    required this.airQualityIndex,
    required this.smokeDetected,
    this.powerConsumptionWatts,
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

  String get airQualityStatus {
    if (airQualityIndex < 50) return 'Excelente';
    if (airQualityIndex <= 100) return 'Bueno';
    if (airQualityIndex <= 150) return 'Moderado';
    if (airQualityIndex <= 200) return 'Malo';
    return 'Peligroso';
  }

  bool get hasAlert => smokeDetected || airQualityIndex > 200;

  factory SensorData.fromApi(Map<String, dynamic> map) {
    return SensorData(
      temperature: (map['temperature'] ?? 0.0).toDouble(),
      humidity: (map['humidity'] ?? 0.0).toDouble(),
      airQualityIndex: (map['air_quality_index'] ?? 0).toInt(),
      smokeDetected: map['smoke_detected'] ?? false,
      powerConsumptionWatts: (map['power_consumption_watts'] ?? 0).toDouble(),
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'temperature': temperature,
        'humidity': humidity,
        'airQualityIndex': airQualityIndex,
        'smokeDetected': smokeDetected,
        'powerConsumptionWatts': powerConsumptionWatts,
        'timestamp': timestamp.toIso8601String(),
      };
}

class SensorReading {
  final DateTime time;
  final double value;

  const SensorReading({required this.time, required this.value});
}
