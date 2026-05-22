import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_config.dart';
import '../core/constants/app_theme.dart';
import '../core/services/api_client.dart';
import '../core/services/nfc_access_service.dart';
import '../features/access/providers/access_provider.dart';
import '../features/alerts/providers/alerts_provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/dashboard/providers/dashboard_provider.dart';
import '../features/energy/providers/energy_provider.dart';
import '../features/environment/providers/environment_provider.dart';
import 'routes.dart';

class AulaInteligenteApp extends StatefulWidget {
  const AulaInteligenteApp({super.key});

  @override
  State<AulaInteligenteApp> createState() => _AulaInteligenteAppState();
}

class _AulaInteligenteAppState extends State<AulaInteligenteApp> {
  late final AuthProvider _authProvider;
  late final ApiClient _apiClient;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _apiClient = ApiClient(
      baseUrl: AppConfig.apiBaseUrl,
      apiKey: AppConfig.apiKey,
    );
    NfcAccessService.instance.setApiClient(_apiClient);
    _router = createRouter(_authProvider);
  }

  @override
  void dispose() {
    _authProvider.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => DashboardProvider(_apiClient)),
        ChangeNotifierProvider(create: (_) => EnvironmentProvider(_apiClient)),
        ChangeNotifierProvider(create: (_) => AccessProvider(_apiClient)),
        ChangeNotifierProvider(create: (_) => AlertsProvider(_apiClient)),
        ChangeNotifierProvider(create: (_) => EnergyProvider(_apiClient)),
      ],
      child: MaterialApp.router(
        title: 'Aula Inteligente',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: _router,
      ),
    );
  }
}
