import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
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
    final currentA = provider.currentA;

    return Scaffold(
      appBar: AppBar(title: const Text('Corriente Eléctrica')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GradientCard(
            gradient: AppColors.energyGradient,
            child: Row(
              children: [
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Corriente actual',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '${currentA.toStringAsFixed(3)} A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 20),
          Text('Histórico (24 h)', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: _EnergyChart(history: history),
          ).animate().fadeIn(delay: 150.ms),
          if (!provider.hasData)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Sin datos de corriente',
                  style: TextStyle(color: AppColors.textMuted)),
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
    if (history.isEmpty) {
      return const Center(child: Text('Sin datos'));
    }
    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.currentA);
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
                  DateFormat('HH').format(history[i].time.toLocal()),
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

