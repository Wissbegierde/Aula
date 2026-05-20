import '../../features/energy/models/energy_model.dart';

/// Datos simulados centralizados (listos para reemplazar por Firebase).
class MockDataService {
  MockDataService._();
  static final MockDataService instance = MockDataService._();

  static const String classroomName = 'Aula 201 — Edificio B';

  List<EnergyReading> getEnergyHistory() {
    final now = DateTime.now();
    return List.generate(24, (i) {
      final hour = now.subtract(Duration(hours: 23 - i));
      final base = 0.8 + (i % 8) * 0.15;
      return EnergyReading(
        time: hour,
        kwh: double.parse((base + (i % 3) * 0.2).toStringAsFixed(2)),
      );
    });
  }

  double get currentPowerKw => 1.24;
  double get todayConsumptionKwh => 8.7;
  double get monthConsumptionKwh => 186.4;
}
