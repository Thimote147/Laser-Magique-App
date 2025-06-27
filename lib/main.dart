import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/core.dart';
import 'app/app.dart';
import 'features/auth/auth.dart';
import 'features/booking/booking.dart';
import 'features/equipment/equipment.dart';
import 'features/settings/settings.dart';
import 'features/inventory/inventory.dart';
import 'features/profile/profile.dart';
import 'shared/shared.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  final config = AppConfig();
  await config.load();

  if (!config.isValid) {
    throw Exception(
      'Invalid Supabase configuration. Please check your .env file.',
    );
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
  );

  // Test Supabase connection
  // Removed debug print statements

  // Initialize French date formats
  await initializeDateFormatting('fr_FR', null);

  runApp(const LaserMagiqueApp());
}

class LaserMagiqueApp extends StatelessWidget {
  const LaserMagiqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => EmployeeProfileViewModel()),
        ChangeNotifierProvider(create: (_) => ActivityFormulaViewModel()),
        ChangeNotifierProxyProvider<ActivityFormulaViewModel, BookingViewModel>(
          create:
              (context) =>
                  BookingViewModel(context.read<ActivityFormulaViewModel>()),
          update:
              (_, activityFormulaVM, previousBookingVM) =>
                  previousBookingVM ?? BookingViewModel(activityFormulaVM),
        ),
        ChangeNotifierProxyProvider<BookingViewModel, StockViewModel>(
          create: (context) => StockViewModel(context.read<BookingViewModel>()),
          update:
              (_, bookingVM, previousStockVM) =>
                  previousStockVM ?? StockViewModel(bookingVM),
        ),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => CustomerViewModel()),
        ChangeNotifierProvider(create: (_) => EquipmentViewModel()),
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, settingsVM, child) {
          ThemeMode themeMode;
          switch (settingsVM.themeMode) {
            case AppThemeMode.light:
              themeMode = ThemeMode.light;
              break;
            case AppThemeMode.dark:
              themeMode = ThemeMode.dark;
              break;
            case AppThemeMode.system:
              themeMode = ThemeMode.system;
              break;
          }

          return MaterialApp(
            title: 'Laser Magique',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E88E5), // Bleu Material 600
                brightness: Brightness.light,
              ),
              appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
              cardTheme: CardTheme(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E88E5), // Bleu Material 600
                brightness: Brightness.dark,
              ),
              appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
              cardTheme: CardTheme(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            themeMode: themeMode,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('fr', 'FR')],
            locale: const Locale('fr', 'FR'),
            home: const _SessionGate(),
          );
        },
      ),
    );
  }
}

class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        // Removed debug print statements

        // Always show loading on first connection
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Vérification de la session...'),
                ],
              ),
            ),
          );
        }

        if (session != null) {
          return const MainScreen();
        } else {
          return const AuthView();
        }
      },
    );
  }
}
