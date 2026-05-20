class EnergyReading {
  final DateTime time;
  final double kwh;

  const EnergyReading({required this.time, required this.kwh});
}

class EnergySummary {
  final double currentPowerKw;
  final double todayKwh;
  final double monthKwh;
  final List<EnergyReading> history;

  const EnergySummary({
    required this.currentPowerKw,
    required this.todayKwh,
    required this.monthKwh,
    required this.history,
  });
}
