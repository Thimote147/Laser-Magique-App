import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../main.dart'; // Pour accéder à supabase et au themeService

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  String? _userEmail;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    // Initialisation de l'état du mode sombre
    _darkModeEnabled = themeService.darkMode;
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final user = supabase.auth.currentUser;
      if (user != null) {
        setState(() {
          _userEmail = user.email;
        });
      }
    } catch (e) {
      // Handle error
      print('Error loading user info: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Utiliser les couleurs appropriées pour le mode actuel (clair ou sombre)
    final textColor = themeService.getTextColor();
    final backgroundColor = themeService.getBackgroundColor();
    final cardColor = themeService.getCardColor();
    final separatorColor = themeService.getSeparatorColor();

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      navigationBar: CupertinoNavigationBar(
        padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
        middle: null,
        backgroundColor: backgroundColor,
        border: null,
        heroTag: 'settingsScreenNavBar',
        transitionBetweenRoutes: false,
        leading: Text(
          'Paramètres',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: textColor,
            fontFamily: '.SF Pro Display',
          ),
        ),
      ),
      child: SafeArea(
        child:
            _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildUserInfoSection(
                            cardColor,
                            textColor,
                            separatorColor,
                          ),
                          const SizedBox(height: 24),
                          _buildGeneralSettingsSection(
                            cardColor,
                            textColor,
                            separatorColor,
                          ),
                          const SizedBox(height: 24),
                          _buildAppearanceSection(
                            cardColor,
                            textColor,
                            separatorColor,
                          ),
                          const SizedBox(height: 24),
                          _buildAboutSection(
                            cardColor,
                            textColor,
                            separatorColor,
                          ),
                          const SizedBox(height: 24),
                          _buildSignOutButton(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: CupertinoTheme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(
    Color cardColor,
    Color textColor,
    Color separatorColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: separatorColor,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: CupertinoTheme.of(context).primaryColor,
            child: const Icon(
              CupertinoIcons.person_fill,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Administrateur Laser Magique',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userEmail ?? 'Non connecté',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeService.getSecondaryTextColor(),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    // Navigate to profile edit screen
                  },
                  child: Text(
                    'Modifier le profil',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoTheme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSettingsSection(
    Color cardColor,
    Color textColor,
    Color separatorColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Paramètres généraux'),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: separatorColor,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: CupertinoIcons.bell_fill,
                title: 'Notifications',
                textColor: textColor,
                trailing: CupertinoSwitch(
                  value: _notificationsEnabled,
                  activeTrackColor: CupertinoTheme.of(context).primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
              ),
              Divider(height: 1, indent: 65, color: separatorColor),
              _buildSettingsItem(
                icon: CupertinoIcons.time,
                title: 'Heures de travail',
                textColor: textColor,
                onTap: () {
                  // Navigate to working hours screen
                },
              ),
              Divider(height: 1, indent: 65, color: separatorColor),
              _buildSettingsItem(
                icon: CupertinoIcons.money_dollar_circle_fill,
                title: 'Services et tarifs',
                textColor: textColor,
                onTap: () {
                  // Navigate to services & pricing screen
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(
    Color cardColor,
    Color textColor,
    Color separatorColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Apparence'),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: separatorColor,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: CupertinoIcons.moon_fill,
                title: 'Mode sombre',
                textColor: textColor,
                trailing: CupertinoSwitch(
                  value: _darkModeEnabled,
                  activeTrackColor: CupertinoTheme.of(context).primaryColor,
                  onChanged: (value) async {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                    // Appliquer le changement de thème
                    await themeService.setDarkMode(value);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(
    Color cardColor,
    Color textColor,
    Color separatorColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('À propos'),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: separatorColor,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: CupertinoIcons.info_circle_fill,
                title: 'Infos sur l\'application',
                textColor: textColor,
                onTap: () {
                  _showAppInfoDialog();
                },
              ),
              Divider(height: 1, indent: 65, color: separatorColor),
              _buildSettingsItem(
                icon: CupertinoIcons.doc_text,
                title: 'Conditions d\'utilisation',
                textColor: textColor,
                onTap: () {
                  // Navigate to terms screen
                },
              ),
              Divider(height: 1, indent: 65, color: separatorColor),
              _buildSettingsItem(
                icon: CupertinoIcons.lock_fill,
                title: 'Politique de confidentialité',
                textColor: textColor,
                onTap: () {
                  // Navigate to privacy policy screen
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required Color textColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: CupertinoTheme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            trailing ??
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 18,
                  color: themeService.getSecondaryTextColor(),
                ),
          ],
        ),
      ),
    );
  }

  void _showAppInfoDialog() {
    final textColor = themeService.getTextColor();
    final secondaryTextColor = themeService.getSecondaryTextColor();

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text('Laser Magique', style: TextStyle(color: textColor)),
            content: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(color: secondaryTextColor, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  'L\'application Laser Magique aide les salons de beauté à gérer efficacement les rendez-vous, les clients et les services.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textColor),
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  Widget _buildSignOutButton() {
    // Les boutons de déconnexion devraient rester rouges en mode sombre
    final backgroundColor =
        themeService.darkMode
            ? const Color(0xFF3B1213) // Rouge foncé en mode sombre
            : Colors.red.shade50;
    final borderColor =
        themeService.darkMode ? Colors.red.shade900 : Colors.red.shade300;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _signOut,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor),
        ),
        child: const Text(
          'Déconnexion',
          style: TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();

    if (!context.mounted) return;

    // Navigate to login or reset app state
    // This would depend on how your authentication flow is set up
  }
}
