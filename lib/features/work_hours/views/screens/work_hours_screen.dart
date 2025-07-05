import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import '../../../profile/viewmodels/employee_profile_view_model.dart';
import '../../models/work_day_model.dart';
import 'employee_work_hours_report_screen.dart';

// Extension pour rendre la première lettre d'une chaîne majuscule (pour les dates)
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class WorkHoursScreen extends StatefulWidget {
  const WorkHoursScreen({super.key});

  @override
  State<WorkHoursScreen> createState() => _WorkHoursScreenState();
}

class _WorkHoursScreenState extends State<WorkHoursScreen> {
  bool _showingFullHistory =
      false; // Ajout d'une variable d'état pour l'historique

  @override
  void initState() {
    super.initState();
    // Initialiser les données de localisation française
    initializeDateFormatting('fr_FR');
  }

  // --- Helper methods must be declared before build ---

  Widget _buildWorkHistory(
    BuildContext context,
    EmployeeProfileViewModel profileVM,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Fonction pour vérifier si un jour est récent (moins de 3 jours)
    bool isRecentDay(DateTime date) {
      final now = DateTime.now();
      final difference = now.difference(date).inDays;
      return difference <= 2;
    }

    // Trier tous les workDays par date (plus récent en premier)
    final allWorkDays = List<WorkDay>.from(profileVM.workDays);
    allWorkDays.sort((a, b) => b.date.compareTo(a.date));

    // Filtrer pour n'afficher que le mois courant par défaut
    final now = DateTime.now();
    final currentMonthWorkDays =
        allWorkDays
            .where(
              (wd) => wd.date.year == now.year && wd.date.month == now.month,
            )
            .toList();

    // Si on affiche tout l'historique, on regroupe par mois
    if (_showingFullHistory) {
      // Grouper les jours par mois/année
      final workDaysByMonth = <String, List<WorkDay>>{};

      for (final workDay in allWorkDays) {
        final monthKey = '${workDay.date.year}-${workDay.date.month}';
        if (!workDaysByMonth.containsKey(monthKey)) {
          workDaysByMonth[monthKey] = [];
        }
        workDaysByMonth[monthKey]!.add(workDay);
      }

      // Trier les clés de mois par date décroissante
      final sortedMonthKeys =
          workDaysByMonth.keys.toList()..sort((a, b) {
            final partsA = a.split('-').map(int.parse).toList();
            final partsB = b.split('-').map(int.parse).toList();
            if (partsA[0] != partsB[0]) {
              // Comparer les années
              return partsB[0].compareTo(partsA[0]); // Ordre décroissant
            }
            return partsB[1].compareTo(
              partsA[1],
            ); // Comparer les mois en ordre décroissant
          });

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historique détaillé',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Mettre à jour l'état et reconstruire le widget
                  setState(() {
                    _showingFullHistory = !_showingFullHistory;
                  });
                },
                icon: Icon(
                  _showingFullHistory
                      ? Icons.calendar_month_rounded
                      : Icons.calendar_view_month_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                label: Text(
                  _showingFullHistory ? 'Mois courant' : 'Tout voir',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Message si aucune journée
          if (allWorkDays.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 48,
                      color: colorScheme.onSurfaceVariant.withAlpha(
                        (255 * 0.5).round(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune journée de travail enregistrée',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withAlpha(
                          (255 * 0.7).round(),
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Afficher les mois groupés
          if (allWorkDays.isNotEmpty)
            ...sortedMonthKeys.map((monthKey) {
              final parts = monthKey.split('-').map(int.parse).toList();
              final year = parts[0];
              final month = parts[1];

              // Formater le mois et l'année
              final monthDate = DateTime(year, month);
              final monthName =
                  DateFormat.MMMM('fr_FR').format(monthDate).capitalize();
              final isCurrentMonth = year == now.year && month == now.month;

              // Calculer le total des heures et montant pour ce mois
              final monthWorkDays = workDaysByMonth[monthKey]!;
              final totalHours = monthWorkDays.fold<double>(
                0,
                (sum, wd) => sum + (wd.hoursWorked ?? 0),
              );
              final totalAmount = monthWorkDays.fold<double>(
                0,
                (sum, wd) => sum + (wd.totalAmount ?? 0),
              );

              // Formater les heures
              String formatHoursToHourMinutes(double hours) {
                int fullHours = hours.floor();
                int minutes = ((hours - fullHours) * 60).round();
                return '${fullHours.toString().padLeft(2, '0')}h${minutes.toString().padLeft(2, '0')}';
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 16, bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête du mois avec badge et total
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    isCurrentMonth
                                        ? colorScheme.primary.withAlpha(
                                          (255 * 0.15).round(),
                                        )
                                        : colorScheme.surfaceContainerHighest.withAlpha(
                                          (255 * 0.5).round(),
                                        ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.calendar_month_rounded,
                                size: 20,
                                color:
                                    isCurrentMonth
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '$monthName $year',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color:
                                                isCurrentMonth
                                                    ? colorScheme.primary
                                                    : colorScheme.onSurface,
                                          ),
                                    ),
                                    if (isCurrentMonth)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withAlpha(
                                            (255 * 0.15).round(),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Text(
                                          'En cours',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.primary,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${formatHoursToHourMinutes(totalHours)} · ${totalAmount.toStringAsFixed(2)} €',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Ligne de séparation stylisée
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 4,
                                decoration: BoxDecoration(
                                  color:
                                      isCurrentMonth
                                          ? colorScheme.primary.withAlpha(
                                            (255 * 0.3).round(),
                                          )
                                          : colorScheme.surfaceContainerHighest
                                              .withAlpha((255 * 0.3).round()),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  margin: const EdgeInsets.only(left: 8),
                                  color: colorScheme.outlineVariant.withAlpha(
                                    (255 * 0.3).round(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Liste des jours pour ce mois
                  ...monthWorkDays
                      .take(
                        5,
                      ) // Limiter à 5 jours par mois pour ne pas surcharger
                      .map(
                        (workDay) => _buildWorkDayItem(
                          context,
                          workDay,
                          profileVM,
                          isRecentDay(workDay.date),
                        ),
                      ),

                  // Bouton "Voir plus" si plus de 5 jours dans ce mois
                  if (monthWorkDays.length > 5)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: TextButton.icon(
                          onPressed: () {
                            // Action pour voir plus de jours de ce mois
                          },
                          icon: const Icon(Icons.expand_more_rounded, size: 16),
                          label: Text(
                            '${monthWorkDays.length - 5} de plus',
                            style: theme.textTheme.bodySmall,
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Séparateur entre les mois
                  if (sortedMonthKeys.last != monthKey)
                    Divider(
                      height: 32,
                      color: colorScheme.outlineVariant.withAlpha(
                        77,
                      ), // ~0.3 opacity
                    ),
                ],
              );
            }),
        ],
      );
    }
    // Sinon, afficher uniquement le mois courant
    else {
      // Liste à afficher (uniquement le mois courant)
      final displayedWorkDays = currentMonthWorkDays;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historique détaillé',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Mettre à jour l'état et reconstruire le widget
                  setState(() {
                    _showingFullHistory = !_showingFullHistory;
                  });
                },
                icon: Icon(
                  _showingFullHistory
                      ? Icons.calendar_month_rounded
                      : Icons.calendar_view_month_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                label: Text(
                  _showingFullHistory ? 'Mois courant' : 'Tout voir',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Message si aucune journée pour le mois en cours
          if (displayedWorkDays.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 48,
                      color: colorScheme.onSurfaceVariant.withAlpha((255 * 0.5).round()),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune journée ce mois-ci',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withAlpha((255 * 0.7).round()),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Liste des jours (limités aux 10 plus récents pour ne pas surcharger l'UI)
          ...displayedWorkDays
              .take(10)
              .map(
                (workDay) => _buildWorkDayItem(
                  context,
                  workDay,
                  profileVM,
                  isRecentDay(workDay.date),
                ),
              ),

          // Bouton "Voir plus" si plus de 10 jours
          if (displayedWorkDays.length > 10)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton.icon(
                  onPressed: () {
                    // Action pour voir plus de jours
                    // TODO: Implémenter la pagination ou un écran dédié
                  },
                  icon: const Icon(Icons.expand_more_rounded),
                  label: const Text('Voir plus'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }
  }

  // Item pour un jour de travail dans l'historique
  Widget _buildWorkDayItem(
    BuildContext context,
    WorkDay workDay,
    EmployeeProfileViewModel profileVM,
    bool isRecent,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Formater la date avec le jour de la semaine
    final formattedDate =
        "${DateFormat.EEEE('fr_FR').format(workDay.date).capitalize()} ${DateFormat.d('fr_FR').format(workDay.date)} ${DateFormat.MMMM('fr_FR').format(workDay.date).toLowerCase()}";

    // Heures de début et de fin
    final formattedStartTime = DateFormat.Hm().format(workDay.startTime);
    final formattedEndTime = DateFormat.Hm().format(workDay.endTime);

    // Heures travaillées
    final hours = workDay.hoursWorked ?? 0;
    // Formater les heures correctement avec les minutes
    int fullHours = hours.floor();
    int minutes = ((hours - fullHours) * 60).round();
    final formattedHours = '${fullHours}h${minutes.toString().padLeft(2, '0')}';

    // Montant
    final formattedAmount =
        workDay.totalAmount != null
            ? '${workDay.totalAmount!.toStringAsFixed(2)} €'
            : '-';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color:
          isRecent
              ? colorScheme.primaryContainer.withAlpha(38) // ~0.15 opacity
              : colorScheme.surfaceContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showEditWorkDayDialog(context, profileVM, workDay),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icône de calendrier
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          isRecent
                              ? colorScheme.primary.withAlpha((255 * 0.15).round())
                              : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.event_rounded,
                      color:
                          isRecent
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Date et détails
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight:
                                isRecent ? FontWeight.w600 : FontWeight.w500,
                            color:
                                isRecent
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$formattedStartTime - $formattedEndTime',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Heures et montant
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isRecent
                                  ? colorScheme.primary.withAlpha((255 * 0.15).round())
                                  : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          formattedHours,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                isRecent
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedAmount,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Tags ou notes supplémentaires
              if (isRecent)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha((255 * 0.1).round()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Récent',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Modifier',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddWorkDayDialog(
    BuildContext context,
    EmployeeProfileViewModel profileVM,
  ) {
    final now = DateTime.now();
    final workDay = WorkDay(
      id: '',
      date: now,
      startTime: DateTime(now.year, now.month, now.day, 9),
      endTime: DateTime(now.year, now.month, now.day, 17),
      hoursWorked: 8.0,
      totalAmount: 8.0 * profileVM.hourlyRate,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 300),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize:
                0.2, // Réduit pour permettre une fermeture plus intuitive
            snap: true,
            snapSizes: const [0.2, 0.7, 0.9],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26), // ~0.1 opacity
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: WorkDayEditSheet(
                  title: 'Nouveau jour',
                  workDay: workDay,
                  scrollController: scrollController,
                  onSave: (updatedWorkDay) async {
                    // Animation de succès avant de fermer
                    await _showSuccessAndClose(context, () async {
                      await profileVM.addWorkDay(updatedWorkDay);
                    });
                  },
                ),
              );
            },
          ),
    );
  }

  void _showEditWorkDayDialog(
    BuildContext context,
    EmployeeProfileViewModel profileVM,
    WorkDay workDay,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: WorkDayEditSheet(
                  title: 'Modifier le jour',
                  workDay: workDay,
                  onSave: (updatedWorkDay) async {
                    await profileVM.updateWorkDay(updatedWorkDay);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  onDelete: () async {
                    await profileVM.deleteWorkDay(workDay.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              );
            },
          ),
    );
  }

  void _showEmployeeWorkHoursReport(BuildContext context) {
    // Navigation vers la page dédiée de suivi des heures des employés
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EmployeeWorkHoursReportScreen(),
      ),
    );
  }

  // Méthode pour afficher une animation de succès avant de fermer le modal
  Future<void> _showSuccessAndClose(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      // Exécuter l'action (comme sauvegarder)
      await action();

      if (!context.mounted) return;

      // Afficher une animation de succès
      final scaffold = ScaffoldMessenger.of(context);
      final theme = Theme.of(context);
      scaffold.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: theme.colorScheme.onPrimary,
              ),
              const SizedBox(width: 12),
              const Text('Enregistré avec succès !'),
            ],
          ),
          backgroundColor: theme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // Fermer le modal avec une animation
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!context.mounted) return;

      // Afficher une erreur si quelque chose ne va pas
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmployeeProfileViewModel>(
      builder: (context, profileVM, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: Text(
              'Heures de travail',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            actions: [
              if (profileVM.role == UserRole.admin)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton.filledTonal(
                    icon: const Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 20,
                    ),
                    tooltip: 'Relevé des heures par employé',
                    onPressed: () => _showEmployeeWorkHoursReport(context),
                  ),
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 300));
              // Ici, vous pourriez ajouter une vraie actualisation des données
            },
            child:
                profileVM.workDays.isEmpty
                    ? _buildEmptyState(context, profileVM)
                    : _buildMainContent(context, profileVM),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddWorkDayDialog(context, profileVM),
            elevation: 0,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Nouveau jour',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    EmployeeProfileViewModel profileVM,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(
                  38,
                ), // ~0.15 opacity
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.hourglass_empty_rounded,
                size: 72,
                color: colorScheme.primary.withAlpha(204), // ~0.8 opacity
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Pas encore de journées de travail',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Ajoutez votre première journée de travail pour commencer à suivre vos heures et vos revenus.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () => _showAddWorkDayDialog(context, profileVM),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter une journée'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    EmployeeProfileViewModel profileVM,
  ) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Header avec le résumé du mois courant
              _buildMonthSummaryHeader(context, profileVM),
              const SizedBox(height: 24),
              // Résumé graphique des heures
              _buildHoursGraph(context, profileVM),
              const SizedBox(height: 24),
              // Cards avec stats
              _buildStatsCards(context, profileVM),
              const SizedBox(height: 24),
              // Historique
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildWorkHistory(context, profileVM),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  // Afficher un résumé du mois courant avec un design moderne
  Widget _buildMonthSummaryHeader(
    BuildContext context,
    EmployeeProfileViewModel profileVM,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculer les totaux pour le mois courant
    final now = DateTime.now();
    final String currentMonthDisplay =
        "${DateFormat.MMMM('fr_FR').format(now).capitalize()} ${now.year}";
    final currentMonthWorkDays =
        profileVM.workDays
            .where(
              (wd) => wd.date.year == now.year && wd.date.month == now.month,
            )
            .toList();

    final totalHours = currentMonthWorkDays.fold<double>(
      0,
      (sum, wd) => sum + (wd.hoursWorked ?? 0),
    );
    final totalAmount = currentMonthWorkDays.fold<double>(
      0,
      (sum, wd) => sum + (wd.totalAmount ?? 0),
    );

    // Formatage des heures en HHhMM
    String formatHoursToHourMinutes(double hours) {
      int fullHours = hours.floor();
      int minutes = ((hours - fullHours) * 60).round();
      return '${fullHours.toString().padLeft(2, '0')}h${minutes.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withAlpha(
                    51,
                  ), // ~0.2 opacity
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mois en cours',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    currentMonthDisplay,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Le bouton rapport a été supprimé car jugé inutile
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withAlpha(179), // ~0.7 opacity
                  colorScheme.primary,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withAlpha(26), // ~0.1 opacity
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((255 * 0.2).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.timer_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Total du mois',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51), // ~0.2 opacity
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        formatHoursToHourMinutes(totalHours),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Montant gagné',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withAlpha((255 * 0.8).round()),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${totalAmount.toStringAsFixed(2)} €',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((255 * 0.2).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Taux: ${profileVM.hourlyRate.toStringAsFixed(2)} €/h',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Créer un graphique pour visualiser les heures travaillées
  Widget _buildHoursGraph(
    BuildContext context,
    EmployeeProfileViewModel profileVM,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Obtenir les 7 derniers jours
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));

    // Créer une liste de tous les jours dans la plage
    List<DateTime> dateRange = [];
    for (int i = 0; i <= 6; i++) {
      dateRange.add(sevenDaysAgo.add(Duration(days: i)));
    }

    // Trouver les jours qui ont des entrées
    Map<String, double> dailyHours = {};
    for (final date in dateRange) {
      final key = DateFormat('yyyy-MM-dd').format(date);
      final dayEntries =
          profileVM.workDays
              .where(
                (wd) =>
                    wd.date.year == date.year &&
                    wd.date.month == date.month &&
                    wd.date.day == date.day,
              )
              .toList();

      if (dayEntries.isNotEmpty) {
        dailyHours[key] = dayEntries.fold<double>(
          0,
          (sum, wd) => sum + (wd.hoursWorked ?? 0),
        );
      } else {
        dailyHours[key] = 0;
      }
    }

    // Trouver la valeur maximale pour normalisation
    double maxHours = dailyHours.values.fold<double>(
      0,
      (max, hours) => hours > max ? hours : max,
    );
    maxHours =
        maxHours == 0 ? 8 : maxHours; // Valeur par défaut si aucune donnée

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Text(
                  'Derniers 7 jours',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Hebdomadaire',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children:
                  dateRange.map((date) {
                    final key = DateFormat('yyyy-MM-dd').format(date);
                    final hours = dailyHours[key] ?? 0;
                    final barHeight =
                        hours /
                        maxHours *
                        120; // Proportionnel à la hauteur max
                    final isToday =
                        date.year == now.year &&
                        date.month == now.month &&
                        date.day == now.day;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (hours > 0)
                              Text(
                                '${hours.toStringAsFixed(1)}h',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      isToday
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                  fontWeight:
                                      isToday
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                  fontSize: 10,
                                ),
                              ),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: barHeight > 0 ? barHeight : 4,
                              decoration: BoxDecoration(
                                color:
                                    isToday
                                        ? colorScheme.primary
                                        : hours > 0
                                        ? colorScheme.primary.withAlpha((255 * 0.6).round())
                                        : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat(
                                'E',
                                'fr_FR',
                              ).format(date).substring(0, 1).toUpperCase(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    isToday
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                fontWeight:
                                    isToday
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            ),
                            Text(
                              date.day.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    isToday
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                fontWeight:
                                    isToday
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Cartes statistiques
  Widget _buildStatsCards(
    BuildContext context,
    EmployeeProfileViewModel profileVM,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculer des statistiques intéressantes
    final now = DateTime.now();
    final thisMonth = DateFormat('yyyy-MM').format(now);
    final lastMonth = DateFormat(
      'yyyy-MM',
    ).format(DateTime(now.year, now.month - 1, 1));

    // Heures ce mois-ci
    final thisMonthHours = profileVM.workDays
        .where((wd) => DateFormat('yyyy-MM').format(wd.date) == thisMonth)
        .fold<double>(0, (sum, wd) => sum + (wd.hoursWorked ?? 0));

    // Heures le mois dernier
    final lastMonthHours = profileVM.workDays
        .where((wd) => DateFormat('yyyy-MM').format(wd.date) == lastMonth)
        .fold<double>(0, (sum, wd) => sum + (wd.hoursWorked ?? 0));

    // Jours travaillés ce mois-ci
    final daysWorkedThisMonth =
        profileVM.workDays
            .where((wd) => DateFormat('yyyy-MM').format(wd.date) == thisMonth)
            .length;

    // Moyenne d'heures par jour
    final avgHoursPerDay =
        daysWorkedThisMonth > 0 ? thisMonthHours / daysWorkedThisMonth : 0;

    // Tendance par rapport au mois précédent
    final percentChange =
        lastMonthHours > 0
            ? ((thisMonthHours - lastMonthHours) / lastMonthHours) * 100
            : 0;

    // Formatage des heures
    String formatHoursToHourMinutes(double hours) {
      int fullHours = hours.floor();
      int minutes = ((hours - fullHours) * 60).round();
      return '${fullHours.toString().padLeft(2, '0')}h${minutes.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Statistiques',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.calendar_month_rounded,
                  title: 'Jours travaillés',
                  value: '$daysWorkedThisMonth jours',
                  subtitle: 'ce mois-ci',
                  iconColor: colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.schedule_rounded,
                  title: 'Moyenne',
                  value: formatHoursToHourMinutes(avgHoursPerDay.toDouble()),
                  subtitle: 'par jour',
                  iconColor: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.insights_rounded,
                  title: 'Tendance',
                  value:
                      lastMonthHours > 0
                          ? '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}%'
                          : 'N/A',
                  subtitle: 'vs mois dernier',
                  iconColor: percentChange >= 0 ? Colors.green : Colors.orange,
                  valueColor: percentChange >= 0 ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.access_time_filled_rounded,
                  title: 'Total heures',
                  value: formatHoursToHourMinutes(
                    profileVM.workDays.fold<double>(
                      0,
                      (sum, wd) => sum + (wd.hoursWorked ?? 0),
                    ),
                  ),
                  subtitle: 'tous temps',
                  iconColor: colorScheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card pour afficher une statistique
  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color iconColor,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(128), // ~0.5 opacity
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(26), // ~0.1 opacity
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor ?? colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkDayEditSheet extends StatefulWidget {
  final String title;
  final WorkDay workDay;
  final Function(WorkDay) onSave;
  final VoidCallback? onDelete;
  final ScrollController? scrollController;

  const WorkDayEditSheet({
    super.key,
    required this.title,
    required this.workDay,
    required this.onSave,
    this.onDelete,
    this.scrollController,
  });

  @override
  State<WorkDayEditSheet> createState() => _WorkDayEditSheetState();
}

class _WorkDayEditSheetState extends State<WorkDayEditSheet> {
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
      _calculateValues();
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
      });
      _calculateValues();
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
      _calculateValues();
    }
  }

  void _save() {
    // Créer les DateTime pour le début et la fin
    final startTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _endTime.hour,
      _endTime.minute,
    );

    // Valider que l'heure de fin n'est pas avant l'heure de début
    DateTime adjustedEndTime = endTime;
    if (endTime.isBefore(startTime)) {
      adjustedEndTime = endTime.add(const Duration(days: 1));
    }

    // Créer le nouveau WorkDay
    final updatedWorkDay = WorkDay(
      id: widget.workDay.id,
      date: _date,
      startTime: startTime,
      endTime: adjustedEndTime,
      hoursWorked: _hours,
      totalAmount: _amount,
    );

    // Appeler la fonction onSave
    widget.onSave(updatedWorkDay);
  }

  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  // Nouvelles propriétés pour le calcul en temps réel
  double _hours = 0;
  double? _amount;

  // Convertir les heures décimales en format heures:minutes
  String _formatHoursToHourMinutes(double hours) {
    int fullHours = hours.floor();
    int minutes = ((hours - fullHours) * 60).round();
    return '${fullHours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _date = widget.workDay.date;
    _startTime = TimeOfDay.fromDateTime(widget.workDay.startTime);
    _endTime = TimeOfDay.fromDateTime(widget.workDay.endTime);
    _calculateValues();
  }

  // Calculer les heures et le montant
  void _calculateValues() {
    final startTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _endTime.hour,
      _endTime.minute,
    );

    // Si l'heure de fin est avant l'heure de début, on suppose que c'est le lendemain
    DateTime adjustedEndTime = endTime;
    if (endTime.isBefore(startTime)) {
      adjustedEndTime = endTime.add(const Duration(days: 1));
    }
    _hours = adjustedEndTime.difference(startTime).inMinutes / 60.0;
    final profileVM = Provider.of<EmployeeProfileViewModel>(
      context,
      listen: false,
    );
    _amount = _hours * profileVM.hourlyRate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withAlpha(
                    (255 * 0.4).round(),
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Header with title and delete button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (widget.onDelete != null)
                    IconButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Supprimer ce jour ?'),
                                content: const Text(
                                  'Cette action est irréversible. Voulez-vous vraiment supprimer cette entrée ?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(false),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: colorScheme.error,
                                    ),
                                    child: const Text('Supprimer'),
                                  ),
                                ],
                              ),
                        );
                        if (confirmed == true) {
                          widget.onDelete!();
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: colorScheme.error,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Section Résumé (Booking details style)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.summarize_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Aperçu',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withAlpha(
                    (255 * 0.2).round(),
                  ),
                  width: 1,
                ),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(
                      (255 * 0.3).round(),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer_rounded,
                              size: 24,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Heures travaillées',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatHoursToHourMinutes(_hours),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 48,
                        child: VerticalDivider(
                          width: 32,
                          color: colorScheme.outlineVariant.withAlpha(
                            (255 * 0.2).round(),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.payments_rounded,
                              size: 24,
                              color: colorScheme.tertiary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Montant',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _amount != null
                                        ? '${_amount!.toStringAsFixed(2)}€'
                                        : '-',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Date & Time Section Header
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Date et heure',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withAlpha(
                    (255 * 0.2).round(),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Date picker
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _selectDate(context),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withAlpha(
                            (255 * 0.3).round(),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat.yMMMMEEEEd('fr_FR').format(_date),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Time pickers
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _selectStartTime(context),
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withAlpha((255 * 0.3).round()),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 20,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Début',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _startTime.format(context),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _selectEndTime(context),
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withAlpha((255 * 0.3).round()),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_filled_rounded,
                                    size: 20,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Fin',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _endTime.format(context),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Save button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Enregistrer'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// --- End of _WorkDayEditSheetState ---
