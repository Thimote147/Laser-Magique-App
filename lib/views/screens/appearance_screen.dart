import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/settings_view_model.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apparence')),
      body: Consumer<SettingsViewModel>(
        builder: (context, settingsVM, _) {
          return ListView(
            children: [
              const SizedBox(height: 16),

              // Section Thème
              _buildSectionTitle(context, 'Thème'),

              // Mode Clair
              _buildThemeOption(
                context,
                title: 'Clair',
                description: 'Interface claire',
                icon: Icons.light_mode,
                isSelected: settingsVM.themeMode == AppThemeMode.light,
                onTap: () {
                  settingsVM.setThemeMode(AppThemeMode.light);
                },
              ),

              // Mode Sombre
              _buildThemeOption(
                context,
                title: 'Sombre',
                description: 'Interface sombre',
                icon: Icons.dark_mode,
                isSelected: settingsVM.themeMode == AppThemeMode.dark,
                onTap: () {
                  settingsVM.setThemeMode(AppThemeMode.dark);
                },
              ),

              // Mode Système
              _buildThemeOption(
                context,
                title: 'Système',
                description: 'Adapté aux paramètres de votre appareil',
                icon: Icons.smartphone,
                isSelected: settingsVM.themeMode == AppThemeMode.system,
                onTap: () {
                  settingsVM.setThemeMode(AppThemeMode.system);
                },
              ),

              const SizedBox(height: 24),

              // Explication du mode système
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Le mode système adapte automatiquement l\'apparence de l\'application selon les réglages de votre appareil.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? colorScheme.primary : null),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? colorScheme.primary : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
