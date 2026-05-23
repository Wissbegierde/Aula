import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = 'https://us-central1-aula-inteligente-30639.cloudfunctions.net/api';
  static String get apiKey => dotenv.env['SENSOR_API_KEY'] ?? '';
  static const String classroomId = 'aula-201-edificio-b';

  static const Duration sensorPollInterval = Duration(seconds: 30);
  static const Duration accessPollInterval = Duration(seconds: 60);
  static const Duration alertsPollInterval = Duration(seconds: 60);
}
