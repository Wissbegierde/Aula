import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'door_nfc_fab.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  bool _canAccessEnergy(UserRole? role) =>
      role == UserRole.admin || role == UserRole.janitor;

  bool _canAccessEnvironment(UserRole? role) =>
      role == UserRole.admin || role == UserRole.teacher;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final role = user?.role;

    final destinations = <_NavItem>[
      const _NavItem(icon: Icons.dashboard_rounded, label: 'Inicio', index: 0),
      if (_canAccessEnvironment(role))
        const _NavItem(icon: Icons.eco_rounded, label: 'Ambiente', index: 1),
      const _NavItem(icon: Icons.badge_rounded, label: 'Accesos', index: 2),
      if (_canAccessEnergy(role))
        const _NavItem(icon: Icons.bolt_rounded, label: 'Energía', index: 3),
      const _NavItem(icon: Icons.notifications_rounded, label: 'Alertas', index: 4),
    ];

    final currentIndex = navigationShell.currentIndex;
    final visibleIndex = destinations.indexWhere((d) => d.index == currentIndex);

    return Scaffold(
      body: navigationShell,
      floatingActionButton: const DoorNfcFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withAlpha(51),
        selectedIndex: visibleIndex < 0 ? 0 : visibleIndex,
        onDestinationSelected: (i) {
          navigationShell.goBranch(destinations[i].index);
        },
        destinations: destinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(d.icon),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}
