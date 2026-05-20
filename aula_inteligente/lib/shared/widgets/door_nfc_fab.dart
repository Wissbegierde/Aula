import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/nfc_access_service.dart';
import '../../features/access/models/nfc_access_status.dart';
import '../../features/access/providers/access_provider.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Botón flotante para acercar el teléfono al lector NFC de la puerta.
class DoorNfcFab extends StatefulWidget {
  const DoorNfcFab({super.key});

  @override
  State<DoorNfcFab> createState() => _DoorNfcFabState();
}

class _DoorNfcFabState extends State<DoorNfcFab> {
  bool _isScanning = false;

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
        onPressed: _isScanning ? null : _startDoorScan,
        backgroundColor: AppColors.primary,
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
            : const Icon(Icons.nfc_rounded),
        label: Text(_isScanning ? 'Leyendo…' : 'Puerta NFC'),
      ),
    );
  }
}
