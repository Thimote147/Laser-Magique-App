import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  bool _darkMode = false;
  bool get darkMode => _darkMode;

  // Clé utilisée pour stocker la préférence de thème
  static const String _darkModeKey = 'dark_mode';

  // Singleton pour accéder au service de thème depuis n'importe où
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  // Initialisation du service de thème
  Future<void> initialize() async {
    await loadPreferences();
  }

  // Chargement des préférences enregistrées
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool(_darkModeKey) ?? false;
    notifyListeners();
  }

  // Mise à jour du mode sombre et enregistrement de la préférence
  Future<void> setDarkMode(bool value) async {
    if (_darkMode == value) return;

    _darkMode = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  // Obtenir le thème CupertinoThemeData en fonction du mode
  CupertinoThemeData getTheme() {
    if (_darkMode) {
      return const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFF0A84FF), // Bleu iOS foncé plus vif
        barBackgroundColor: Color(0xFF1C1C1E), // Fond de barre sombre iOS
        scaffoldBackgroundColor: Color(0xFF1C1C1E), // Fond d'écran sombre iOS
        textTheme: CupertinoTextThemeData(
          navTitleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.white,
            fontFamily: '.SF Pro Text',
            inherit: false,
          ),
          navLargeTitleTextStyle: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.white,
            fontFamily: '.SF Pro Display',
            inherit: false,
          ),
          textStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 16,
            color: CupertinoColors.white,
            inherit: false,
          ),
          actionTextStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 16,
            color: Color(0xFF0A84FF), // Bleu iOS foncé
            inherit: false,
          ),
          tabLabelTextStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 10,
            color: CupertinoColors.systemGrey,
            inherit: false,
          ),
          pickerTextStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 16,
            color: CupertinoColors.white,
            inherit: false,
          ),
          dateTimePickerTextStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 21,
            color: CupertinoColors.white,
            inherit: false,
          ),
        ),
      );
    } else {
      return const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF007AFF),
        barBackgroundColor: CupertinoColors.systemGroupedBackground,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
        textTheme: CupertinoTextThemeData(
          navTitleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.black,
            fontFamily: '.SF Pro Text',
            inherit: false,
          ),
          navLargeTitleTextStyle: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.black,
            fontFamily: '.SF Pro Display',
            inherit: false,
          ),
          textStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 16,
            color: CupertinoColors.black,
            inherit: false,
          ),
          actionTextStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 16,
            color: Color(0xFF007AFF),
            inherit: false,
          ),
          tabLabelTextStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 10,
            color: CupertinoColors.inactiveGray,
            inherit: false,
          ),
          pickerTextStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 16,
            color: CupertinoColors.black,
            inherit: false,
          ),
          dateTimePickerTextStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 21,
            color: CupertinoColors.black,
            inherit: false,
          ),
        ),
      );
    }
  }

  // Obtenir la couleur de texte appropriée selon le mode
  Color getTextColor() {
    return _darkMode ? CupertinoColors.white : CupertinoColors.black;
  }

  // Obtenir la couleur de fond de carte appropriée selon le mode
  Color getCardColor() {
    return _darkMode ? const Color(0xFF2C2C2E) : CupertinoColors.white;
  }

  // Obtenir la couleur de fond du scaffold appropriée selon le mode
  Color getBackgroundColor() {
    return _darkMode
        ? const Color(0xFF1C1C1E) // iOS dark background - darker black
        : const Color(0xFFF2F2F7); // iOS light background - slightly off-white
  }

  // Obtenir une couleur de fond secondaire (pour les écrans imbriqués) selon le mode
  Color getSecondaryBackgroundColor() {
    return _darkMode
        ? const Color(
          0xFF2C2C2E,
        ) // iOS dark secondary background - slightly lighter than main background
        : CupertinoColors.white; // White for light mode
  }

  // Obtenir la couleur des séparateurs appropriée selon le mode
  Color getSeparatorColor() {
    return _darkMode ? const Color(0xFF38383A) : CupertinoColors.systemGrey5;
  }

  // Obtenir la couleur secondaire de texte appropriée selon le mode
  Color getSecondaryTextColor() {
    return _darkMode ? CupertinoColors.systemGrey : CupertinoColors.systemGrey;
  }
}
