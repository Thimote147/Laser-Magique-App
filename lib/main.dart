import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/core.dart';
import 'app/app.dart';
import 'features/auth/auth.dart';
import 'features/booking/booking.dart';
import 'features/equipment/equipment.dart';
import 'features/settings/settings.dart';
import 'features/inventory/inventory.dart';
import 'features/profile/profile.dart';
import 'shared/shared.dart';
import 'shared/widgets/custom_dialog.dart';
import 'shared/user_provider.dart';
import 'shared/services/realtime_notification_service.dart';
import 'shared/services/firebase_notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('🚀 Starting Laser Magique App...');

    // Load environment variables
    debugPrint('⚙️ Loading config...');
    final config = AppConfig();
    await config.load();

    if (!config.isValid) {
      debugPrint('❌ Invalid Supabase configuration');
      throw Exception('Invalid Supabase configuration. Please check your .env file.');
    }

    // Initialize Firebase
    debugPrint('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');

    // Initialize Supabase
    debugPrint('🗄️ Initializing Supabase...');
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
    debugPrint('✅ Supabase initialized');

    // Initialize French date formats
    debugPrint('🌍 Initializing date formats...');
    await initializeDateFormatting('fr_FR', null);
    debugPrint('✅ Date formats initialized');

    debugPrint('🚀 Starting app...');
    runApp(const LaserMagiqueApp());

  } catch (e, stackTrace) {
    debugPrint('💥 Error in main: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // Show error app
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Erreur d\'initialisation'),
              const SizedBox(height: 8),
              Text('$e', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    ));
  }
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
          create: (context) => BookingViewModel(context.read<ActivityFormulaViewModel>()),
          update: (_, activityFormulaVM, previousBookingVM) =>
              previousBookingVM ?? BookingViewModel(activityFormulaVM),
        ),
        ChangeNotifierProxyProvider<BookingViewModel, StockViewModel>(
          create: (context) => StockViewModel(context.read<BookingViewModel>()),
          update: (_, bookingVM, previousStockVM) =>
              previousStockVM ?? StockViewModel(bookingVM),
        ),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => CustomerViewModel()),
        ChangeNotifierProvider(create: (_) => EquipmentViewModel()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => RealtimeNotificationService()),
        Provider(create: (_) => FirebaseNotificationService()),
      ],
      child: Builder(
        builder: (context) {
          // Initialiser les données au démarrage de l'app
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            final authService = Provider.of<AuthService>(context, listen: false);
            final firebaseNotificationService = Provider.of<FirebaseNotificationService>(context, listen: false);
            final realtimeNotificationService = Provider.of<RealtimeNotificationService>(context, listen: false);
            
            // Initialize Firebase notifications
            firebaseNotificationService.initialize().catchError((error) {
              debugPrint('❌ Failed to initialize Firebase notifications: $error');
            });
            
            // Initialize realtime notifications
            realtimeNotificationService.initialize().catchError((error) {
              debugPrint('❌ Failed to initialize realtime notifications: $error');
            });
            
            authService.currentUserWithSettings.then((user) {
              userProvider.user = user;
            }).catchError((error) {
              // En cas d'erreur, l'utilisateur reste null
            });

            // Préchargement du stock
            final stockViewModel = Provider.of<StockViewModel>(context, listen: false);
            stockViewModel.forceInitialize().catchError((error) {
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) => CustomErrorDialog(
                    title: 'Erreur de chargement',
                    content: 'Erreur lors du chargement des données de stock: $error',
                  ),
                );
              }
            });
          });

          return Consumer<SettingsViewModel>(
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
                navigatorKey: navigatorKey,
                title: 'Laser Magique',
                theme: ThemeData(
                  useMaterial3: true,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF1E88E5),
                    brightness: Brightness.light,
                  ),
                  appBarTheme: const AppBarTheme(
                    centerTitle: true,
                    elevation: 0,
                  ),
                  cardTheme: CardTheme(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF1E88E5),
                    brightness: Brightness.dark,
                  ),
                  appBarTheme: const AppBarTheme(
                    centerTitle: true,
                    elevation: 0,
                  ),
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

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
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

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          final authService = Provider.of<AuthService>(context, listen: false);

          if (session != null) {
            authService.currentUserWithSettings.then((user) {
              userProvider.user = user;
            }).catchError((error) {
              userProvider.user = null;
            });
          } else {
            userProvider.user = null;
          }
        });

        if (session != null) {
          return const MainScreen();
        } else {
          return const AuthView();
        }
      },
    );
  }
}