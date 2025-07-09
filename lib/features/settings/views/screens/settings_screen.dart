import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../profile/viewmodels/employee_profile_view_model.dart';
import '../../viewmodels/settings_view_model.dart';
import 'appearance_screen.dart';
import '../../../../shared/activity_formula_screen.dart';
import '../../../auth/services/auth_service.dart';
import '../../../auth/views/screens/auth_view.dart';
import '../../../equipment/views/screens/equipment_management_screen.dart';
import '../widgets/settings_profile_preview.dart';
import '../../../../shared/widgets/custom_dialog.dart';
import '../widgets/settings_section_header.dart';
import '../widgets/settings_item.dart';
import '../widgets/settings_toggle_item.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileVM = Provider.of<EmployeeProfileViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              final navigator = Navigator.of(context);
              await Provider.of<AuthService>(context, listen: false).signOut();
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthView()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 8),
          // Prévisualisation du profil
          const SettingsProfilePreview(),

          const SizedBox(height: 24),
          // Section Application
          const SettingsSectionHeader(
            title: 'Application',
            icon: Icons.settings_rounded,
          ),

          // Notifications
          Consumer<SettingsViewModel>(
            builder: (context, settingsVM, child) => SettingsToggleItem(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Activer ou désactiver les notifications',
              value: settingsVM.notificationsEnabled,
              onChanged: (value) {
                settingsVM.toggleNotifications(value);
                showDialog(
                  context: context,
                  builder: (context) => CustomSuccessDialog(
                    title: 'Notifications',
                    content: value
                        ? 'Notifications activées'
                        : 'Notifications désactivées',
                    autoClose: true,
                    autoCloseDuration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),

          // Apparence
          Consumer<SettingsViewModel>(
            builder: (context, settingsVM, child) => SettingsItem(
              icon: Icons.color_lens,
              title: 'Apparence',
              subtitle: _getThemeModeSubtitle(settingsVM.themeMode),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AppearanceScreen(),
                  ),
                );
              },
            ),
          ),

          // Formules et activités (visible uniquement pour admin)
          if (profileVM.role == UserRole.admin)
            SettingsItem(
              icon: Icons.sports_esports,
              title: 'Formules et activités',
              subtitle: 'Gérer les activités et leurs formules',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ActivityFormulaScreen(),
                  ),
                );
              },
            ),

          // Gestion du matériel
          SettingsItem(
            icon: Icons.build,
            title: 'Gestion du matériel',
            subtitle: 'Voir et gérer l\'état du matériel',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EquipmentManagementScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Section Support
          const SettingsSectionHeader(
            title: 'Support',
            icon: Icons.help_outline_rounded,
          ),

          // Aide
          SettingsItem(
            icon: Icons.help,
            title: 'Aide',
            subtitle: 'Consulter l\'aide et les guides',
            onTap: () {
              // Implémentation future
              showDialog(
                context: context,
                builder: (context) => CustomDialog(
                  title: 'Information',
                  titleIcon: Icon(Icons.info, color: Colors.blue),
                  content: Text('Fonctionnalité à venir'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),

          // À propos
          SettingsItem(
            icon: Icons.info,
            title: 'À propos',
            subtitle: 'Informations sur l\'application',
            onTap: () {
              // Implémentation future
              showDialog(
                context: context,
                builder: (context) => CustomDialog(
                  title: 'Information',
                  titleIcon: Icon(Icons.info, color: Colors.blue),
                  content: Text('Fonctionnalité à venir'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getThemeModeSubtitle(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Mode clair';
      case AppThemeMode.dark:
        return 'Mode sombre';
      case AppThemeMode.system:
        return 'Adapté au système';
    }
  }
}
