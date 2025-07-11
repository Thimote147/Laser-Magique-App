import 'package:flutter/material.dart';
import '../services/app_update_service.dart';
import 'custom_dialog.dart';

class AppUpdateDialog extends StatelessWidget {
  final AppVersion updateVersion;

  const AppUpdateDialog({
    super.key,
    required this.updateVersion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CustomDialog(
      title: 'Mise à jour disponible',
      titleIcon: Icon(
        Icons.system_update,
        color: theme.colorScheme.primary,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.new_releases,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Version ${updateVersion.version}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nouveautés :',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            updateVersion.description,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    updateVersion.isRequired
                        ? 'Cette mise à jour est obligatoire pour continuer à utiliser l\'application.'
                        : 'Cette mise à jour est recommandée pour bénéficier des dernières améliorations.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (!updateVersion.isRequired)
          TextButton(
            onPressed: () {
              AppUpdateService().dismissUpdate(updateVersion.version);
              Navigator.of(context).pop();
            },
            child: const Text('Plus tard'),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Fermer'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            AppUpdateService().openUpdateLink();
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.download),
          label: const Text('Mettre à jour'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  /// Show the update dialog
  static Future<void> show(BuildContext context, AppVersion updateVersion) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: !updateVersion.isRequired,
      builder: (context) => AppUpdateDialog(updateVersion: updateVersion),
    );
  }
}

class UpdateAvailableButton extends StatelessWidget {
  const UpdateAvailableButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppUpdateService(),
      builder: (context, child) {
        final updateService = AppUpdateService();
        
        if (!updateService.hasUpdate || updateService.latestVersion == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(8),
          child: ElevatedButton.icon(
            onPressed: () {
              AppUpdateDialog.show(context, updateService.latestVersion!);
            },
            icon: const Icon(Icons.system_update),
            label: const Text('Mise à jour disponible'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AppUpdateChecker extends StatefulWidget {
  final Widget child;

  const AppUpdateChecker({
    super.key,
    required this.child,
  });

  @override
  State<AppUpdateChecker> createState() => _AppUpdateCheckerState();
}

class _AppUpdateCheckerState extends State<AppUpdateChecker> {
  @override
  void initState() {
    super.initState();
    _initializeUpdateService();
  }

  void _initializeUpdateService() async {
    await AppUpdateService().initialize();
    
    // Listen for new updates
    AppUpdateService().addListener(_onUpdateAvailable);
  }

  void _onUpdateAvailable() {
    final updateService = AppUpdateService();
    if (updateService.hasUpdate && 
        updateService.latestVersion != null && 
        mounted) {
      
      // Show update dialog automatically for required updates
      if (updateService.latestVersion!.isRequired) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppUpdateDialog.show(context, updateService.latestVersion!);
        });
      }
    }
  }

  @override
  void dispose() {
    AppUpdateService().removeListener(_onUpdateAvailable);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}