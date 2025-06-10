import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'views/screens/main_screen.dart';
import 'viewmodels/booking_view_model.dart';
import 'viewmodels/activity_formula_view_model.dart';
import 'viewmodels/stock_view_model.dart';

void main() {
  // Initialiser les formats de date en français
  initializeDateFormatting('fr_FR', null).then((_) {
    runApp(const LaserMagiqueApp());
  });
}

class LaserMagiqueApp extends StatelessWidget {
  const LaserMagiqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ActivityFormulaViewModel()),
        ChangeNotifierProxyProvider<ActivityFormulaViewModel, BookingViewModel>(
          create:
              (context) => BookingViewModel(
                Provider.of<ActivityFormulaViewModel>(context, listen: false),
              ),
          update:
              (context, activityFormulaViewModel, previous) =>
                  previous ?? BookingViewModel(activityFormulaViewModel),
        ),
        ChangeNotifierProvider(create: (_) => StockViewModel()),
      ],
      child: MaterialApp(
        title: 'Laser Magique',
        locale: const Locale('fr', 'FR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr', 'FR')],
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            primary: Colors.indigo,
            secondary: Colors.amber,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        home: const MainScreen(),
      ),
    );
  }
}
