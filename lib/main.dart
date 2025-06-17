import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'views/screens/main_screen.dart';
import 'viewmodels/booking_view_model.dart';
import 'viewmodels/activity_formula_view_model.dart';
import 'viewmodels/stock_view_model.dart';
import 'viewmodels/employee_profile_view_model.dart';
import 'viewmodels/settings_view_model.dart';
import 'viewmodels/customer_view_model.dart';

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

  // Initialize French date formats
  await initializeDateFormatting('fr_FR', null);

  runApp(const LaserMagiqueApp());
}

class LaserMagiqueApp extends StatelessWidget {
  const LaserMagiqueApp({super.key});

  // Convertit notre enum AppThemeMode en ThemeMode
  ThemeMode _getFlutterThemeMode(AppThemeMode themeMode) {
    switch (themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ActivityFormulaViewModel()),
        ChangeNotifierProvider(create: (_) => StockViewModel()),
        ChangeNotifierProvider(create: (_) => EmployeeProfileViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => CustomerViewModel()),
        ChangeNotifierProxyProvider2<
          ActivityFormulaViewModel,
          StockViewModel,
          BookingViewModel
        >(
          create:
              (context) => BookingViewModel(
                Provider.of<ActivityFormulaViewModel>(context, listen: false),
                Provider.of<StockViewModel>(context, listen: false),
              ),
          update: (
            context,
            activityFormulaViewModel,
            stockViewModel,
            previous,
          ) {
            // Keep previous instance if available to preserve state
            if (previous != null) {
              // Manually update dependencies
              previous.updateDependencies(
                activityFormulaViewModel,
                stockViewModel,
              );
              return previous;
            }
            // Create new instance only if needed
            return BookingViewModel(activityFormulaViewModel, stockViewModel);
          },
          lazy:
              false, // Eagerly create the ViewModel to ensure data is loaded immediately
        ),
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, settingsViewModel, _) {
          return MaterialApp(
            title: 'Laser Magique',
            locale: const Locale('fr', 'FR'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('fr', 'FR')],
            debugShowCheckedModeBanner: false,
            themeMode: _getFlutterThemeMode(settingsViewModel.themeMode),
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo,
                primary: Colors.indigo,
                secondary:
                    Colors
                        .blue
                        .shade300, // Remplace amber par un bleu plus clair
                tertiary:
                    Colors
                        .indigo
                        .shade300, // Utilise une nuance plus claire de la couleur primaire
                brightness: Brightness.light,
              ),
              useMaterial3: true, // Utiliser Material 3 pour un design moderne
              appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
              cardTheme: CardTheme(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo,
                primary:
                    Colors
                        .indigo
                        .shade200, // Légèrement plus clair pour un meilleur contraste
                secondary: Colors.blue.shade200,
                tertiary: Colors.indigo.shade200,
                brightness: Brightness.dark,
                surface: const Color(0xFF1E1E1E),
                background: const Color(0xFF121212),
                onBackground: Colors.white, // Meilleur contraste pour le texte
                onSurface: Colors.white.withOpacity(
                  0.9,
                ), // Meilleur contraste pour le texte
                onPrimary:
                    Colors.black, // Texte foncé sur couleur principale claire
              ),
              useMaterial3: true,
              appBarTheme: AppBarTheme(
                centerTitle: false,
                elevation: 0,
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: Colors.white,
              ),
              cardTheme: CardTheme(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: const Color(0xFF2A2A2A),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: Colors.indigo.shade300,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
