import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/manager_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'widgets/loading_view.dart';
import 'screens/login_screen.dart';
import 'screens/manager/manager_dashboard_screen.dart';
import 'screens/owner/forgot_password_screen.dart';
import 'screens/owner/owner_dashboard_screen.dart';
import 'localization/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();
  final authService = AuthService();
  await authService.init();
  runApp(AquaTrackApp(apiService: apiService, authService: authService));
}

class AquaTrackApp extends StatefulWidget {
  const AquaTrackApp({super.key, required this.apiService, required this.authService});

  final ApiService apiService;
  final AuthService authService;

  @override
  State<AquaTrackApp> createState() => _AquaTrackAppState();
}

class _AquaTrackAppState extends State<AquaTrackApp> {
  late final ThemeProvider _themeProvider;
  late final LanguageProvider _languageProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider = ThemeProvider();
    _languageProvider = LanguageProvider();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: widget.apiService),
        Provider<AuthService>.value(value: widget.authService),
        ChangeNotifierProvider<ThemeProvider>.value(value: _themeProvider),
        ChangeNotifierProvider<LanguageProvider>.value(value: _languageProvider),
        ChangeNotifierProvider<ManagerProvider>(
          create: (_) => ManagerProvider(widget.apiService),
        ),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, _) {
          AppTheme.updateBrightness(themeProvider.isDark ? Brightness.dark : Brightness.light);
          return MaterialApp(
          title: 'AquaaTrack',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeProvider.mode,
          locale: Locale(languageProvider.locale),
          supportedLocales: const [Locale('en'), Locale('ta'), Locale('hi')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            AppLocalizationsDelegate(),
          ],
          home: const HomeGate(),
          routes: {
            LoginScreen.routeName: (_) => const LoginScreen(),
            ManagerDashboardScreen.routeName: (_) => const ManagerDashboardScreen(),
            ForgotPasswordScreen.routeName: (_) => const ForgotPasswordScreen(),
          },
        );
      },
      ),
    );
  }
}

class HomeGate extends StatefulWidget {
  const HomeGate({super.key});

  @override
  State<HomeGate> createState() => _HomeGateState();
}

class _HomeGateState extends State<HomeGate> {
  bool _isLoading = true;
  bool _hasManagerSession = false;
  bool _hasOwnerSession = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final managerId = await StorageService.loadManagerId();
    if (!mounted) return;
    if (managerId != null) {
      try {
        final provider = context.read<ManagerProvider>();
        await provider.fetchManager(managerId);
        if (provider.manager?.frozen == true || provider.manager?.locked == true) {
          await StorageService.clearManagerId();
          _hasManagerSession = false;
        } else {
          _hasManagerSession = true;
        }
      } catch (_) {
        await StorageService.clearManagerId();
      }
    }
    if (!_hasManagerSession && await StorageService.loadKeepOwnerSignedIn()) {
      final auth = context.read<AuthService>();
      final valid = await auth.verifySession();
      if (valid) {
        _hasOwnerSession = true;
      } else {
        await StorageService.clearOwnerSession();
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingView(message: 'Loading AquaaTrack...'));
    }
    if (_hasManagerSession) {
      return const ManagerDashboardScreen();
    }
    if (_hasOwnerSession) {
      return const OwnerDashboardScreen();
    }
    return const LoginScreen();
  }
}
