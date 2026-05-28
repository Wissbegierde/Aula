import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/device_token_service.dart';
import '../../core/services/hce_key_service.dart';
import '../../core/services/nfc_access_service.dart';
import '../../features/access/models/nfc_access_status.dart';
import '../../features/access/providers/access_provider.dart';
import '../../features/auth/providers/auth_provider.dart';

class DoorNfcFab extends StatefulWidget {
  const DoorNfcFab({super.key});

  @override
  State<DoorNfcFab> createState() => _DoorNfcFabState();
}

class _DoorNfcFabState extends State<DoorNfcFab> {
  bool _isScanning = false;
  bool _isKeyMode = false;
  Timer? _keyModeTimer;

  @override
  void dispose() {
    _keyModeTimer?.cancel();
    HceKeyService.instance.deactivate();
    super.dispose();
  }

  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Acceso a la puerta',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.credit_card_rounded, color: AppColors.primary),
                title: const Text('Leer tarjeta NFC'),
                subtitle: const Text('Acerca una tarjeta NFC al teléfono'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: AppColors.surfaceElevated,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _startDoorScan();
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(
                  _isKeyMode ? Icons.phonelink_lock_rounded : Icons.phone_android_rounded,
                  color: AppColors.primary,
                ),
                title: Text(_isKeyMode ? 'Desactivar modo llave' : 'Usar teléfono como llave'),
                subtitle: Text(
                  _isKeyMode
                      ? 'Toca el teléfono en el lector de la puerta'
                      : 'El teléfono funciona como una tarjeta NFC',
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: _isKeyMode
                    ? AppColors.primary.withAlpha(30)
                    : AppColors.surfaceElevated,
                onTap: () {
                  Navigator.of(ctx).pop();
                  if (_isKeyMode) {
                    _deactivateKeyMode();
                  } else {
                    _activateKeyMode();
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startDoorScan() async {
    if (_isScanning) return;

    setState(() => _isScanning = true);
    _showScanSheet();

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    final outcome = await NfcAccessService.instance.scanDoorAccess(
      currentUserRfid: user?.rfidTag,
      currentUserName: user?.name,
    );

    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pop();
    setState(() => _isScanning = false);

    context.read<AccessProvider>().registerNfcOutcome(outcome);
    _showResultDialog(outcome);
  }

  Future<void> _activateKeyMode() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    // 1. Verificar que el usuario tiene un rfidTag asociado
    final rfid = user?.rfidTag;
    if (rfid == null || rfid.isEmpty) {
      _showResultDialog(NfcAccessOutcome(
        status: NfcAccessStatus.denied,
        title: 'Sin acceso NFC',
        message: 'Tu cuenta no tiene un UID NFC asociado. Contacta al administrador.',
      ));
      return;
    }

    // 2. Verificar que este celular está registrado
    final isRegistered = await DeviceTokenService.instance.isRegistered;
    if (!isRegistered) {
      if (!mounted) return;
      _showDeviceNotRegisteredDialog();
      return;
    }

    // 3. Verificar soporte HCE
    final supported = await HceKeyService.instance.isHceSupported;
    if (!supported) {
      _showResultDialog(NfcAccessOutcome(
        status: NfcAccessStatus.badRead,
        title: 'No disponible',
        message: 'El modo llave NFC solo está disponible en Android.',
      ));
      return;
    }

    // 4. Activar con el deviceToken (no con el rfidTag)
    try {
      await HceKeyService.instance.activateWithDeviceToken();
    } catch (e) {
      _showResultDialog(NfcAccessOutcome(
        status: NfcAccessStatus.badRead,
        title: 'Error',
        message: 'No se pudo activar el modo llave: $e',
      ));
      return;
    }

    if (!mounted) return;
    setState(() => _isKeyMode = true);

    _keyModeTimer?.cancel();
    _keyModeTimer = Timer(HceKeyService.activationTimeout, () {
      if (!mounted) return;
      _deactivateKeyMode();
      _showResultDialog(NfcAccessOutcome(
        status: NfcAccessStatus.badRead,
        title: 'Tiempo agotado',
        message: 'Modo llave desactivado por inactividad.',
      ));
    });

    _showKeyModeActiveSheet();
  }

  void _showDeviceNotRegisteredDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.warning.withAlpha(128)),
        ),
        icon: const Icon(Icons.phone_android_rounded,
            color: AppColors.warning, size: 48),
        title: const Text(
          'Celular no registrado',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Para usar tu teléfono como llave NFC, primero regístralo en tu perfil.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) context.push('/profile');
            },
            icon: const Icon(Icons.person_rounded),
            label: const Text('Ir a perfil'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deactivateKeyMode() async {
    _keyModeTimer?.cancel();
    await HceKeyService.instance.deactivate();
    if (!mounted) return;
    setState(() => _isKeyMode = false);
  }

  void _showScanSheet() {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.nfc_rounded, size: 72, color: AppColors.primary)
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1200.ms, color: AppColors.primary.withAlpha(128))
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.05, 1.05),
                  duration: 900.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 20),
            Text(
              'Leyendo NFC…',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Acerca la parte trasera del teléfono al sensor NFC de la puerta.',
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            const LinearProgressIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.cardBorder,
            ),
          ],
        ),
      ),
    );
  }

  void _showKeyModeActiveSheet() {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phonelink_lock_rounded, size: 72, color: AppColors.success)
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1200.ms, color: AppColors.success.withAlpha(128))
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.05, 1.05),
                  duration: 900.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 20),
            Text(
              'Modo llave activo',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(color: AppColors.success),
            ),
            const SizedBox(height: 8),
            Text(
              'Acerca el teléfono al lector NFC de la puerta para abrir.',
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            const LinearProgressIndicator(
              color: AppColors.success,
              backgroundColor: AppColors.cardBorder,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                _deactivateKeyMode();
              },
              icon: const Icon(Icons.close_rounded),
              label: const Text('Desactivar modo llave'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResultDialog(NfcAccessOutcome outcome) {
    final (icon, color) = switch (outcome.status) {
      NfcAccessStatus.granted => (Icons.check_circle_rounded, AppColors.success),
      NfcAccessStatus.denied => (Icons.cancel_rounded, AppColors.danger),
      NfcAccessStatus.badRead => (Icons.nfc_rounded, AppColors.warning),
    };

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withAlpha(128)),
        ),
        icon: Icon(icon, color: color, size: 48),
        title: Text(
          outcome.title,
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
        content: Text(
          outcome.message,
          textAlign: TextAlign.center,
          style: Theme.of(ctx).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FloatingActionButton.extended(
        onPressed: (_isScanning || _isKeyMode) ? null : _showOptionsSheet,
        backgroundColor: _isKeyMode ? AppColors.success : AppColors.primary,
        foregroundColor: AppColors.background,
        icon: _isScanning
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.background,
                ),
              )
            : Icon(_isKeyMode ? Icons.phonelink_lock_rounded : Icons.nfc_rounded),
        label: Text(
          _isScanning ? 'Leyendo…' : _isKeyMode ? 'Llave activa' : 'Puerta NFC',
        ),
      ),
    );
  }
}
