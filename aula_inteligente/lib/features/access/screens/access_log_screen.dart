import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/access_log_model.dart';
import '../providers/access_provider.dart';

class AccessLogScreen extends StatelessWidget {
  const AccessLogScreen({super.key});

  Color _actionColor(AccessAction action) {
    switch (action) {
      case AccessAction.entry:
        return AppColors.success;
      case AccessAction.exit:
        return AppColors.info;
      case AccessAction.denied:
        return AppColors.danger;
    }
  }

  IconData _actionIcon(AccessAction action) {
    switch (action) {
      case AccessAction.entry:
        return Icons.login_rounded;
      case AccessAction.exit:
        return Icons.logout_rounded;
      case AccessAction.denied:
        return Icons.block_rounded;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'teacher':
        return 'Docente';
      case 'janitor':
        return 'Conserje';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccessProvider>();
    final logs = provider.logs;
    final hasData = provider.hasData;
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Acceso'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: StatusBadge(
                label: provider.isDoorOpen ? 'Puerta abierta' : 'Puerta cerrada',
                color: provider.isDoorOpen ? AppColors.success : AppColors.textMuted,
                icon: provider.isDoorOpen
                    ? Icons.door_front_door_outlined
                    : Icons.door_front_door,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _StatBox(
                  label: 'Entradas hoy',
                  value: logs
                      .where((l) =>
                          l.action == AccessAction.entry &&
                          l.timestamp.day == DateTime.now().day)
                      .length
                      .toString(),
                  color: AppColors.success,
                ),
                const SizedBox(width: 12),
                _StatBox(
                  label: 'Denegados',
                  value: logs
                      .where((l) => l.action == AccessAction.denied)
                      .length
                      .toString(),
                  color: AppColors.danger,
                ),
              ],
            ),
          ),
          Expanded(
            child: hasData && logs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 8),
                        Text('Sin registros de acceso',
                            style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final log = logs[index];
                final color = _actionColor(log.action);
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withAlpha(38),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_actionIcon(log.action), color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.userName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${_roleLabel(log.userRole)} · RFID ${log.rfidTag}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              dateFmt.format(log.timestamp),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(label: log.action.label, color: color),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 30 * index));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
