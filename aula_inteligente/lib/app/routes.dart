import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/access/screens/access_log_screen.dart';
import '../features/alerts/screens/alerts_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/energy/screens/energy_screen.dart';
import '../features/environment/screens/environment_screen.dart';
import '../shared/widgets/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuth = authProvider.isAuthenticated;
      final path = state.matchedLocation;
      final isSplash = path == '/';
      final isLogin = path == '/login';

      if (isSplash) return null;
      if (!isAuth && !isLogin) return '/login';
      if (isAuth && isLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/environment',
                builder: (_, __) => const EnvironmentScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/access',
                builder: (_, __) => const AccessLogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/energy',
                builder: (_, __) => const EnergyScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/alerts',
                builder: (_, __) => const AlertsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
