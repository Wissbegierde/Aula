import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/device_token_service.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isRegistering = false;

  Color _roleColor(UserRole role) {
    return switch (role) {
      UserRole.admin => AppColors.adminColor,
      UserRole.teacher => AppColors.teacherColor,
      UserRole.janitor => AppColors.janitorColor,
    };
  }

  Future<void> _registerDevice(AuthProvider auth) async {
    setState(() => _isRegistering = true);

    final token = await DeviceTokenService.instance.getOrCreateToken();
    final name = await DeviceTokenService.instance.getDeviceName();

    final ok = await auth.registerDevice(deviceToken: token, deviceName: name);

    if (ok) {
      await DeviceTokenService.instance.markAsRegistered();
    }

    if (!mounted) return;
    setState(() => _isRegistering = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '✅ Celular registrado como llave NFC'
              : '❌ Error al registrar el dispositivo',
        ),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _removeDevice(AuthProvider auth, String token) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar dispositivo?'),
        content: const Text(
          'Este celular ya no podrá usarse como llave NFC.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await auth.removeDevice(token);
    await DeviceTokenService.instance.markAsUnregistered();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dispositivo eliminado'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No hay sesión activa')),
      );
    }

    final roleColor = _roleColor(user.role);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Mi perfil'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Avatar y datos del usuario ──────────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(height: 14),
                Text(
                  user.name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor.withAlpha(100)),
                  ),
                  child: Text(
                    user.roleLabel,
                    style: TextStyle(
                        color: roleColor, fontWeight: FontWeight.w600),
                  ),
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Tarjeta NFC física ───────────────────────────────────────────
          _InfoCard(
            icon: Icons.credit_card_rounded,
            title: 'Tarjeta NFC física',
            subtitle: user.rfidTag.isNotEmpty
                ? 'UID: ${user.rfidTag}'
                : 'Sin tarjeta asociada',
            color: AppColors.primary,
          ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1),

          const SizedBox(height: 16),

          // ── Sección de dispositivos ──────────────────────────────────────
          Text(
            'Celulares como llave',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 4),
          Text(
            'Registra este celular para abrirlo de la puerta usando NFC.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ).animate().fadeIn(delay: 320.ms),
          const SizedBox(height: 12),

          // Lista de dispositivos registrados
          if (user.registeredDevices.isEmpty)
            _EmptyDevicesCard()
          else
            ...user.registeredDevices.map(
              (device) => _DeviceTile(
                device: device,
                onRemove: () => _removeDevice(auth, device.deviceToken),
              ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.1),
            ),

          const SizedBox(height: 16),

          // Botón registrar
          FutureBuilder<String>(
            future: DeviceTokenService.instance.getOrCreateToken(),
            builder: (context, snap) {
              final currentToken = snap.data ?? '';
              final alreadyRegistered = user.registeredDevices
                  .any((d) => d.deviceToken == currentToken);

              if (alreadyRegistered) {
                return _RegisteredBadge();
              }

              return FilledButton.icon(
                onPressed: _isRegistering
                    ? null
                    : () => _registerDevice(auth),
                icon: _isRegistering
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.phone_android_rounded),
                label: Text(
                  _isRegistering
                      ? 'Registrando…'
                      : 'Registrar este celular como llave',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
            },
          ),

          const SizedBox(height: 32),

          // ── Cerrar sesión ────────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () => auth.logout(),
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            label: const Text('Cerrar sesión',
                style: TextStyle(color: AppColors.danger)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.danger),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ).animate().fadeIn(delay: 450.ms),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDevicesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.cardBorder, style: BorderStyle.solid),
      ),
      child: const Column(
        children: [
          Icon(Icons.phone_android_rounded,
              size: 36, color: AppColors.textMuted),
          SizedBox(height: 8),
          Text(
            'Ningún celular registrado',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms);
  }
}

class _RegisteredBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withAlpha(80)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.success),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Este celular ya está registrado como llave',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}

class _DeviceTile extends StatelessWidget {
  final RegisteredDevice device;
  final VoidCallback onRemove;

  const _DeviceTile({required this.device, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final date =
        '${device.registeredAt.day}/${device.registeredAt.month}/${device.registeredAt.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_android_rounded,
              color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.deviceName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Registrado el $date',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.danger),
            onPressed: onRemove,
            tooltip: 'Eliminar dispositivo',
          ),
        ],
      ),
    );
  }
}
