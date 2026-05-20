import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/gradient_card.dart';
import '../../../shared/widgets/sensor_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../access/models/access_log_model.dart';
import '../../access/providers/access_provider.dart';
import '../../alerts/providers/alerts_provider.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../environment/providers/environment_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final env = context.watch<EnvironmentProvider>().current;
    final access = context.watch<AccessProvider>();
    final alerts = context.watch<AlertsProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final activeAlerts = alerts.activeAlerts.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hola, ${user?.name.split(' ').first ?? 'Usuario'}'),
            Text(
              dashboard.classroomName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => Future.delayed(const Duration(milliseconds: 600)),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GradientCard(
              gradient: activeAlerts > 0
                  ? AppColors.dangerGradient
                  : AppColors.successGradient,
              child: Row(
                children: [
                  Icon(
                    activeAlerts > 0
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeAlerts > 0
                              ? '$activeAlerts alerta(s) activa(s)'
                              : 'Aula en estado normal',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          access.isDoorOpen ? 'Puerta abierta' : 'Puerta cerrada',
                          style: TextStyle(
                            color: Colors.white.withAlpha(204),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (activeAlerts > 0)
                    StatusBadge.danger('$activeAlerts', icon: Icons.notifications),
                ],
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 16),
            if (user?.role == UserRole.janitor || user?.role == UserRole.admin) ...[
              _LightsControl(
                lightsOn: dashboard.lightsOn,
                onToggle: dashboard.toggleLights,
              ),
              const SizedBox(height: 16),
            ],
            Text('Sensores en vivo', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SensorCard(
                    title: 'Temperatura',
                    value: env.temperature.toStringAsFixed(1),
                    unit: '°C',
                    icon: Icons.thermostat_rounded,
                    accentColor: AppColors.tempColor,
                    statusLabel: env.temperatureStatus,
                    statusColor: AppColors.tempColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SensorCard(
                    title: 'Humedad',
                    value: env.humidity.toStringAsFixed(0),
                    unit: '%',
                    icon: Icons.water_drop_rounded,
                    accentColor: AppColors.humidColor,
                    statusLabel: env.humidityStatus,
                    statusColor: AppColors.humidColor,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 12),
            SensorCard(
              title: 'CO₂',
              value: env.co2.toStringAsFixed(0),
              unit: 'ppm',
              icon: Icons.air_rounded,
              accentColor: AppColors.co2Color,
              statusLabel: env.co2Status,
              statusColor: AppColors.co2Color,
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 20),
            Text('Acceso reciente', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (access.logs.isNotEmpty)
              _AccessTile(log: access.logs.first)
            else
              const Text('Sin registros recientes'),
            const SizedBox(height: 20),
            Text('Accesos rápidos', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (user?.role != UserRole.janitor)
                  _QuickNavChip(
                    icon: Icons.eco_rounded,
                    label: 'Ambiente',
                    onTap: () => context.go('/home/environment'),
                  ),
                _QuickNavChip(
                  icon: Icons.badge_rounded,
                  label: 'Accesos',
                  onTap: () => context.go('/home/access'),
                ),
                if (user?.role != UserRole.teacher)
                  _QuickNavChip(
                    icon: Icons.bolt_rounded,
                    label: 'Energía',
                    onTap: () => context.go('/home/energy'),
                  ),
                _QuickNavChip(
                  icon: Icons.notifications_rounded,
                  label: 'Alertas',
                  onTap: () => context.go('/home/alerts'),
                  badge: activeAlerts > 0 ? '$activeAlerts' : null,
                ),
              ],
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _LightsControl extends StatelessWidget {
  final bool lightsOn;
  final VoidCallback onToggle;

  const _LightsControl({required this.lightsOn, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      onTap: onToggle,
      child: Row(
        children: [
          Icon(
            lightsOn ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
            color: lightsOn ? AppColors.warning : AppColors.textMuted,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Iluminación', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  lightsOn ? 'Luces encendidas' : 'Luces apagadas',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: lightsOn,
            onChanged: (_) => onToggle(),
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _AccessTile extends StatelessWidget {
  final AccessLogModel log;

  const _AccessTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(log.timestamp);
    return GradientCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: log.granted
                ? AppColors.success.withAlpha(51)
                : AppColors.danger.withAlpha(51),
            child: Icon(
              log.granted ? Icons.check : Icons.block,
              color: log.granted ? AppColors.success : AppColors.danger,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.userName, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '${log.action.label} · $time',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          StatusBadge(
            label: log.granted ? 'OK' : 'Denegado',
            color: log.granted ? AppColors.success : AppColors.danger,
          ),
        ],
      ),
    );
  }
}

class _QuickNavChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  const _QuickNavChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            if (badge != null) ...[
              const SizedBox(width: 8),
              StatusBadge.danger(badge!),
            ],
          ],
        ),
      ),
    );
  }
}
