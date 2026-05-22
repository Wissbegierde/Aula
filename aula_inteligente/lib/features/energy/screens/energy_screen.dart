import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/gradient_card.dart';
import '../models/energy_model.dart';
import '../providers/energy_provider.dart';

class EnergyScreen extends StatelessWidget {
  const EnergyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EnergyProvider>();
    final history = provider.history;
    final currentKw = provider.currentPowerKw;
    final todayKwh = provider.todayConsumptionKwh;
    final monthKwh = provider.monthConsumptionKwh;
    final usagePercent = (todayKwh / 15).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Consumo Energético')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GradientCard(
            gradient: AppColors.energyGradient,
            child: Row(
              children: [
                CircularPercentIndicator(
                  radius: 48,
                  lineWidth: 8,
                  percent: usagePercent,
                  center: Text(
                    '${(usagePercent * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  progressColor: AppColors.energyColor,
                  backgroundColor: Colors.white.withAlpha(51),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Consumo de hoy',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '${todayKwh.toStringAsFixed(1)} kWh',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Potencia actual: ${currentKw.toStringAsFixed(2)} kW',
                        style: TextStyle(color: Colors.white.withAlpha(179)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.bolt_rounded,
                  label: 'Potencia',
                  value: '${currentKw.toStringAsFixed(2)} kW',
                  color: AppColors.energyColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.calendar_month_rounded,
                  label: 'Este mes',
                  value: '${monthKwh.toStringAsFixed(0)} kWh',
                  color: AppColors.primary,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 20),
          Text('Histórico (24 h)', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: _EnergyChart(history: history),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 16),
          GradientCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dispositivos', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _DeviceRow(name: 'Iluminación LED', power: '0.45 kW', pct: 0.36),
                _DeviceRow(name: 'Proyector', power: '0.32 kW', pct: 0.26),
                _DeviceRow(name: 'Aire acondicionado', power: '0.38 kW', pct: 0.31),
                _DeviceRow(name: 'Otros', power: '0.09 kW', pct: 0.07),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _EnergyChart extends StatelessWidget {
  final List<EnergyReading> history;

  const _EnergyChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.kwh);
    }).toList();

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.cardBorder, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(1),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
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
                if (i < 0 || i >= history.length) return const SizedBox.shrink();
                return Text(
                  DateFormat('HH').format(history[i].time),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: spots.map((spot) {
          return BarChartGroupData(
            x: spot.x.toInt(),
            barRods: [
              BarChartRodData(
                toY: spot.y,
                color: AppColors.energyColor,
                width: 8,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.energyColor.withAlpha(128),
                    AppColors.energyColor,
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  final String name;
  final String power;
  final double pct;

  const _DeviceRow({
    required this.name,
    required this.power,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: Theme.of(context).textTheme.bodyMedium),
              Text(power, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.cardBorder,
            color: AppColors.energyColor,
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}
