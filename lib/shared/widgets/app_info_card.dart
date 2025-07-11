import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/app_update_service.dart';
import 'app_update_dialog.dart';

class AppInfoCard extends StatelessWidget {
  const AppInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Informations de l\'application',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(),
            ListenableBuilder(
              listenable: AppUpdateService(),
              builder: (context, child) {
                final updateService = AppUpdateService();
                final packageInfo = updateService.currentPackageInfo;
                
                return Column(
                  children: [
                    if (packageInfo != null) ...[
                      _InfoRow(
                        label: 'Version actuelle',
                        value: '${packageInfo.version} (${packageInfo.buildNumber})',
                      ),
                      _InfoRow(
                        label: 'Nom de l\'application',
                        value: packageInfo.appName,
                      ),
                      _InfoRow(
                        label: 'Package',
                        value: packageInfo.packageName,
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Update status section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: updateService.hasUpdate
                            ? Colors.orange.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: updateService.hasUpdate
                              ? Colors.orange.shade200
                              : Colors.green.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            updateService.hasUpdate
                                ? Icons.system_update
                                : Icons.check_circle_outline,
                            color: updateService.hasUpdate
                                ? Colors.orange.shade600
                                : Colors.green.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  updateService.hasUpdate
                                      ? 'Mise à jour disponible'
                                      : 'Application à jour',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: updateService.hasUpdate
                                        ? Colors.orange.shade800
                                        : Colors.green.shade800,
                                  ),
                                ),
                                if (updateService.hasUpdate && updateService.latestVersion != null)
                                  Text(
                                    'Version ${updateService.latestVersion!.version} disponible',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (updateService.hasUpdate && updateService.latestVersion != null)
                            ElevatedButton(
                              onPressed: () {
                                AppUpdateDialog.show(context, updateService.latestVersion!);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade600,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(80, 32),
                              ),
                              child: const Text('Voir'),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Manual check button and last check info
                    Row(
                      children: [
                        Expanded(
                          child: FutureBuilder<DateTime?>(
                            future: updateService.getLastCheckTime(),
                            builder: (context, snapshot) {
                              final lastCheck = snapshot.data;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dernière vérification',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    lastCheck != null
                                        ? DateFormat('dd/MM/yyyy à HH:mm').format(lastCheck)
                                        : 'Jamais',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: updateService.isCheckingForUpdates
                              ? null
                              : () async {
                                  await updateService.checkForUpdates();
                                },
                          icon: updateService.isCheckingForUpdates
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(
                            updateService.isCheckingForUpdates
                                ? 'Vérification...'
                                : 'Vérifier',
                          ),
                        ),
                      ],
                    ),
                    
                    if (updateService.lastCheckError != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Erreur: ${updateService.lastCheckError}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}