import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/employee_profile_view_model.dart';
import '../../viewmodels/settings_view_model.dart';
import 'profile_screen.dart';
import 'work_hours_screen.dart';
import 'appearance_screen.dart';
import 'activity_formula_screen.dart';
import '../../services/auth_service.dart';
import '../auth/auth_view.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileVM = Provider.of<EmployeeProfileViewModel>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).signOut();
              Navigator.of(context).pushAndRemoveUntil(
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
          _buildProfilePreview(context, profileVM),

          const SizedBox(height: 24),
          // Section Application
          _buildSectionHeader(context, 'Application', Icons.settings_rounded),

          // Notifications
          Consumer<SettingsViewModel>(
            builder:
                (context, settingsVM, child) => _buildToggleSettingsItem(
                  context,
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Activer ou désactiver les notifications',
                  value: settingsVM.notificationsEnabled,
                  onChanged: (value) {
                    settingsVM.toggleNotifications(value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Notifications activées'
                              : 'Notifications désactivées',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
          ),

          // Apparence
          Consumer<SettingsViewModel>(
            builder:
                (context, settingsVM, child) => _buildSettingsItem(
                  context,
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

          // Formules et activités
          _buildSettingsItem(
            context,
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

          const SizedBox(height: 24),

          // Section Support
          _buildSectionHeader(context, 'Support', Icons.help_outline_rounded),

          // Aide
          _buildSettingsItem(
            context,
            icon: Icons.help,
            title: 'Aide',
            subtitle: 'Consulter l\'aide et les guides',
            onTap: () {
              // Implémentation future
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),

          // À propos
          _buildSettingsItem(
            context,
            icon: Icons.info,
            title: 'À propos',
            subtitle: 'Informations sur l\'application',
            onTap: () {
              // Implémentation future
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper pour obtenir le sous-titre du mode de thème
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

  Widget _buildProfilePreview(
    BuildContext context,
    EmployeeProfileViewModel profileVM,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isDark ? 1 : 2,
      shadowColor: colorScheme.shadow.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Partie supérieure - Nom et rôle (cliquer redirige vers profil)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withOpacity(0.1),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          profileVM.initials,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profileVM.fullName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (profileVM.role == UserRole.admin
                                      ? colorScheme.error
                                      : colorScheme.primary)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (profileVM.role == UserRole.admin
                                        ? colorScheme.error
                                        : colorScheme.primary)
                                    .withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              profileVM.roleString,
                              style: TextStyle(
                                color:
                                    profileVM.role == UserRole.admin
                                        ? colorScheme.error
                                        : colorScheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withOpacity(0.2),
          ),
          // Partie inférieure - Statistiques (cliquer redirige vers heures de travail)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const WorkHoursScreen(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildProfileStat(
                            context,
                            label: 'Taux horaire',
                            value:
                                '${profileVM.hourlyRate.toStringAsFixed(2)}€',
                            icon: Icons.euro_rounded,
                          ),
                          VerticalDivider(
                            thickness: 1,
                            width: 1,
                            indent: 8,
                            endIndent: 8,
                            color: colorScheme.outlineVariant.withOpacity(0.2),
                          ),
                          _buildProfileStat(
                            context,
                            label: 'Heures travaillées',
                            value: _formatHoursToHourMinutes(
                              _calculateTotalHours(profileVM),
                            ),
                            icon: Icons.access_time_rounded,
                          ),
                          VerticalDivider(
                            thickness: 1,
                            width: 1,
                            indent: 8,
                            endIndent: 8,
                            color: colorScheme.outlineVariant.withOpacity(0.2),
                          ),
                          _buildProfileStat(
                            context,
                            label: 'Revenus du mois',
                            value:
                                '${profileVM.getCurrentMonthEarnings().toStringAsFixed(2)}€',
                            icon: Icons.payments_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16, // Légèrement réduit
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  double _calculateTotalHours(EmployeeProfileViewModel profileVM) {
    return profileVM.workDays.fold(0, (sum, day) => sum + day.hours);
  }

  // Convertir les heures décimales en format heures et minutes (Xh30)
  String _formatHoursToHourMinutes(double hours) {
    int fullHours = hours.floor();
    int minutes = ((hours - fullHours) * 60).round();

    if (minutes == 0) {
      return '${fullHours}h00';
    } else {
      return minutes < 10 ? '${fullHours}h0$minutes' : '${fullHours}h$minutes';
    }
  }

  Widget _buildToggleSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
