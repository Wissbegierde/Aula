import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/sensor_card.dart';
import '../models/sensor_data_model.dart';
import '../providers/environment_provider.dart';

class EnvironmentScreen extends StatefulWidget {
  const EnvironmentScreen({super.key});

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen> {
  int _chartTab = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EnvironmentProvider>();
    final current = provider.current;

    final histories = [
      provider.temperatureHistory,
      provider.humidityHistory,
      provider.airQualityHistory,
    ];
    final colors = [AppColors.tempColor, AppColors.humidColor, AppColors.co2Color];
    final labels = ['Temperatura (°C)', 'Humedad (%)', 'Calidad del Aire (AQI)'];
    final segmentLabels = ['Temp', 'Hum', 'AQ'];

    return Scaffold(
      appBar: AppBar(title: const Text('Monitoreo Ambiental')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SensorCard(
            title: 'Temperatura',
            value: current.temperature.toStringAsFixed(1),
            unit: '°C',
            icon: Icons.thermostat_rounded,
            accentColor: AppColors.tempColor,
            statusLabel: current.temperatureStatus,
            statusColor: AppColors.tempColor,
          ).animate().fadeIn(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SensorCard(
                  title: 'Humedad',
                  value: current.humidity.toStringAsFixed(0),
                  unit: '%',
                  icon: Icons.water_drop_rounded,
                  accentColor: AppColors.humidColor,
                  statusLabel: current.humidityStatus,
                  statusColor: AppColors.humidColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SensorCard(
                  title: 'Calidad del Aire',
                  value: current.airQualityIndex.toString(),
                  unit: 'AQI',
                  icon: Icons.air_rounded,
                  accentColor: AppColors.co2Color,
                  statusLabel: current.airQualityStatus,
                  statusColor: AppColors.co2Color,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms),
          if (current.smokeDetected) ...[
            const SizedBox(height: 12),
            _SafetyBanner(current: current),
          ],
          const SizedBox(height: 20),
          Text('Histórico (24 h)', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 0, label: Text(segmentLabels[0])),
              ButtonSegment(value: 1, label: Text(segmentLabels[1])),
              ButtonSegment(value: 2, label: Text(segmentLabels[2])),
            ],
            selected: {_chartTab},
            onSelectionChanged: (s) => setState(() => _chartTab = s.first),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: _SensorChart(
              readings: histories[_chartTab],
              color: colors[_chartTab],
              label: labels[_chartTab],
            ),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 12),
          Text(
            'Actualizado: ${DateFormat('HH:mm:ss').format(current.timestamp)}',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SafetyBanner extends StatelessWidget {
  final dynamic current;

  const _SafetyBanner({required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.dangerGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Humo detectado. Verifique el área.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorChart extends StatelessWidget {
  final List<SensorReading> readings;
  final Color color;
  final String label;

  const _SensorChart({
    required this.readings,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(child: Text('Sin datos'));
    }

    final spots = readings.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.cardBorder, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 6,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= readings.length) return const SizedBox.shrink();
                return Text(
                  DateFormat('HH').format(readings[i].time),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withAlpha(38),
            ),
          ),
        ],
      ),
    );
  }
}
