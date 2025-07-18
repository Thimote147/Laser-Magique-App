import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:developer' as developer;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../viewmodels/employee_work_hours_viewmodel.dart';
import '../../models/work_day_model.dart';
import '../../../../shared/services/pdf_header_service.dart';
import '../../../../shared/widgets/custom_dialog.dart';

class EmployeeWorkHoursReportScreen extends StatefulWidget {
  const EmployeeWorkHoursReportScreen({super.key});

  @override
  State<EmployeeWorkHoursReportScreen> createState() =>
      _EmployeeWorkHoursReportScreenState();
}

class _EmployeeWorkHoursReportScreenState
    extends State<EmployeeWorkHoursReportScreen>
    with SingleTickerProviderStateMixin {
  // Contrôleurs et animation
  late TextEditingController _searchController;
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  // ViewModel pour gérer les données et la logique
  final EmployeeWorkHoursViewModel _viewModel = EmployeeWorkHoursViewModel();

  // Date Format
  final DateFormat _monthFormat = DateFormat('MMMM yyyy', 'fr_FR');

  // État local pour la recherche et les filtres
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    developer.log('initState called');

    initializeDateFormatting('fr_FR');
    _searchController = TextEditingController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Ajouter un listener pour les changements dans le ViewModel
    _viewModel.addListener(_onViewModelChanged);

    // Charger les données initiales avec un léger délai pour permettre à l'UI de se rendre
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Un petit délai pour permettre au premier rendu de s'afficher
      Future.delayed(const Duration(milliseconds: 100), () async {
        developer.log('Loading initial data...');
        try {
          await _viewModel.loadEmployeeData();
          developer.log(
            'Initial data loaded: ${_viewModel.employees.length} employees',
          );
          if (mounted) {
            setState(() {});
          }
        } catch (e) {
          developer.log('Error loading initial data: $e');
        }
      });
    });
  }

  // Callback pour les changements dans le ViewModel
  void _onViewModelChanged() {
    developer.log(
      'ViewModel changed: isLoading=${_viewModel.isLoading}, employees=${_viewModel.employees.length}',
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  // Obtenir les initiales d'un nom
  String _getInitials(String name) {
    if (name.isEmpty) return '';
    List<String> words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : '';
    }
    return words
        .take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();
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

  // Construire le résumé total des heures
  Widget _buildTotalSummary(List<Map<String, dynamic>> employees) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    double totalHours = 0;
    double totalAmount = 0;
    int totalDays = 0;

    // Calculer les totaux seulement si nous avons des employés
    for (var employee in employees) {
      totalHours += employee['currentMonthHours'] as double;
      totalAmount += employee['currentMonthAmount'] as double;
      totalDays += employee['daysWorked'] as int;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total ${_monthFormat.format(_viewModel.selectedDate)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimaryContainer.withAlpha(
                        (255 * 0.2).round(),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _viewModel.isLoading
                          ? 'Chargement...'
                          : '${employees.length} employé${employees.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTotalItem(
                    icon: Icons.access_time_rounded,
                    title:
                        _viewModel.isLoading
                            ? '---'
                            : _formatHoursToHourMinutes(totalHours),
                    subtitle: 'heures',
                    color: colorScheme.onSurface,
                  ),
                  _buildTotalItem(
                    icon: Icons.euro_rounded,
                    title:
                        _viewModel.isLoading
                            ? '---'
                            : '${totalAmount.toStringAsFixed(2)}€',
                    subtitle: 'payés',
                    color: colorScheme.onSurface,
                  ),
                  _buildTotalItem(
                    icon: Icons.calendar_month_rounded,
                    title: _viewModel.isLoading ? '---' : '$totalDays',
                    subtitle: 'jours',
                    color: colorScheme.onSurface,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Item pour l'affichage du résumé
  Widget _buildTotalItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: color.withAlpha((255 * 0.8).round()),
          ),
        ),
      ],
    );
  }

  // Construire une carte d'employé
  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.primaryContainer.withValues(
                      alpha: 0.5,
                    ),
                    child: Text(
                      _getInitials(employee['name'] as String),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Informations principales
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee['name'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiary.withAlpha(
                                  (255 * 0.2).round(),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                employee['role'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.tertiary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(employee['hourlyRate'] as double).toStringAsFixed(2)}€/h',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Montant total
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(employee['currentMonthAmount'] as double).toStringAsFixed(2)}€',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Statistiques et bouton
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildEmployeeStat(
                    icon: Icons.access_time_rounded,
                    value: _formatHoursToHourMinutes(
                      employee['currentMonthHours'] as double,
                    ),
                    label: 'Heures',
                    color: colorScheme.primary,
                  ),
                  _buildEmployeeStat(
                    icon: Icons.calendar_today_rounded,
                    value: '${employee['daysWorked']}',
                    label: 'Jours',
                    color: colorScheme.tertiary,
                  ),

                  // Bouton "Voir détails" intégré dans les statistiques
                  ElevatedButton.icon(
                    onPressed: () {
                      _showEmployeeLogSheet(employee);
                    },
                    icon: const Icon(Icons.visibility_rounded, size: 16),
                    label: const Text('Voir détails'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Statistique d'employé
  Widget _buildEmployeeStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // Afficher les logs des heures de l'employé
  void _showEmployeeLogSheet(Map<String, dynamic> employee) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Charger les logs réels pour l'employé sélectionné et le mois actuel
    List<Map<String, dynamic>> logs = [];

    // État de chargement
    bool isLoading = true;
    String? errorMessage;

    // Fonction pour charger les logs de l'employé
    Future<void> loadEmployeeLogs() async {
      try {
        // Initialiser les logs
        logs = [];

        // Vérifier si les workDays sont déjà disponibles dans l'objet employee
        if (employee.containsKey('workDays') &&
            employee['workDays'] is List<WorkDay>) {
          final workDays = employee['workDays'] as List<WorkDay>;
          developer.log(
            'Utilisation des workDays existants: ${workDays.length}',
          );

          // Convertir les WorkDay en logs pour l'affichage
          for (var workDay in workDays) {
            // Formater la date (JJ/MM/YYYY)
            final String formattedDate =
                '${workDay.date.day.toString().padLeft(2, '0')}/${workDay.date.month.toString().padLeft(2, '0')}/${workDay.date.year}';

            // Formater l'heure de début (HH:MM)
            final String formattedStartTime =
                '${workDay.startTime.hour.toString().padLeft(2, '0')}:${workDay.startTime.minute.toString().padLeft(2, '0')}';

            // Formater l'heure de fin (HH:MM)
            final String formattedEndTime =
                '${workDay.endTime.hour.toString().padLeft(2, '0')}:${workDay.endTime.minute.toString().padLeft(2, '0')}';

            // Calculer le montant journalier (heures * taux horaire)
            final double hourlyRate = employee['hourlyRate'] as double;
            final double dailyAmount = workDay.hours * hourlyRate;

            logs.add({
              'id': workDay.id,
              'date': formattedDate,
              'startTime': formattedStartTime,
              'endTime': formattedEndTime,
              'hours': workDay.hours,
              'amount': dailyAmount,
            });
          }
        } else {
          // Récupérer les jours de travail depuis la base de données via le ViewModel si non disponibles
          developer.log(
            'Récupération des workDays depuis la DB pour: ${employee['id']}',
          );
          try {
            final workDays = await _viewModel.getEmployeeWorkDays(
              employee['id'],
            );
            developer.log('Nombre de workDays récupérés: ${workDays.length}');

            // Convertir les WorkDay en logs pour l'affichage
            for (var workDay in workDays) {
              developer.log(
                'Traitement du workDay: ${workDay.date} (${workDay.hours}h)',
              );

              // Formater la date (JJ/MM/YYYY)
              final String formattedDate =
                  '${workDay.date.day.toString().padLeft(2, '0')}/${workDay.date.month.toString().padLeft(2, '0')}/${workDay.date.year}';

              // Formater l'heure de début (HH:MM)
              final String formattedStartTime =
                  '${workDay.startTime.hour.toString().padLeft(2, '0')}:${workDay.startTime.minute.toString().padLeft(2, '0')}';

              // Formater l'heure de fin (HH:MM)
              final String formattedEndTime =
                  '${workDay.endTime.hour.toString().padLeft(2, '0')}:${workDay.endTime.minute.toString().padLeft(2, '0')}';

              // Calculer le montant journalier (heures * taux horaire)
              final double hourlyRate = employee['hourlyRate'] as double;
              final double dailyAmount = workDay.hours * hourlyRate;

              logs.add({
                'id': workDay.id,
                'date': formattedDate,
                'startTime': formattedStartTime,
                'endTime': formattedEndTime,
                'hours': workDay.hours,
                'amount': dailyAmount,
              });
            }
          } catch (e) {
            developer.log('Erreur lors de la récupération des workDays: $e');
            rethrow;
          }
        }

        // Si aucun log n'est trouvé, laissez la liste vide (logs = [])
        isLoading = false;
        errorMessage = null;
      } catch (e) {
        developer.log('Erreur lors du chargement des logs: $e');
        isLoading = false;
        errorMessage =
            'Impossible de charger les logs de l\'employé. Veuillez réessayer.';
      }
    }

    // Charger les logs immédiatement
    loadEmployeeLogs();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => DraggableScrollableSheet(
                  initialChildSize: 0.7,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  expand: false,
                  builder:
                      (context, scrollController) => Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.2,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Handle bar
                            Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.outline.withValues(
                                  alpha: 0.4,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // En-tête
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundImage:
                                              employee['avatarUrl'] != null
                                                  ? NetworkImage(
                                                    employee['avatarUrl']
                                                        as String,
                                                  )
                                                  : null,
                                          child:
                                              employee['avatarUrl'] == null
                                                  ? Text(
                                                    (employee['name'] as String)
                                                        .split(' ')
                                                        .map(
                                                          (word) =>
                                                              word.isNotEmpty
                                                                  ? word[0]
                                                                  : '',
                                                        )
                                                        .take(2)
                                                        .join()
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  )
                                                  : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Écouter les changements du ViewModel pour toutes les infos de l'employé
                                              AnimatedBuilder(
                                                animation: _viewModel,
                                                builder: (context, child) {
                                                  // Trouver l'employé mis à jour dans la liste
                                                  final updatedEmployee = _viewModel.employees
                                                      .firstWhere(
                                                        (emp) => emp['id'] == employee['id'],
                                                        orElse: () => employee,
                                                      );
                                                  return Row(
                                                    children: [
                                                      Text(
                                                        '${updatedEmployee['name']} - ',
                                                        style: theme
                                                            .textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight.w600,
                                                            ),
                                                      ),
                                                      Text(
                                                        '${(updatedEmployee['hourlyRate'] ?? 0.0).toStringAsFixed(2)}€/h',
                                                        style: TextStyle(
                                                          color:
                                                              colorScheme
                                                                  .onSurfaceVariant,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                              Text(
                                                'Détails des heures de ${_monthFormat.format(_viewModel.selectedDate)}',
                                                style: TextStyle(
                                                  color:
                                                      colorScheme
                                                          .onSurfaceVariant,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed:
                                              () => Navigator.pop(context),
                                        ),
                                      ],
                                    ),

                                    Divider(
                                      color: colorScheme.outlineVariant,
                                      height: 24,
                                    ),

                                    // Actions pour l'employé
                                    Column(
                                      children: [
                                        // Première ligne avec deux boutons
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () async {
                                                  _showModifyHourlyRateDialog(
                                                    employee,
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.euro,
                                                  size: 16,
                                                ),
                                                label: const Text(
                                                  'Taux horaire',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(
                                                    color:
                                                        colorScheme
                                                            .outlineVariant,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 8,
                                                      ),
                                                  minimumSize: const Size(
                                                    0,
                                                    36,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () async {
                                                  _showBlockEmployeeDialog(
                                                    employee,
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.block,
                                                  size: 16,
                                                ),
                                                label: const Text(
                                                  'Bloquer',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(
                                                    color: colorScheme.error,
                                                  ),
                                                  foregroundColor:
                                                      colorScheme.error,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 8,
                                                      ),
                                                  minimumSize: const Size(
                                                    0,
                                                    36,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Deuxième ligne avec le bouton PDF
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () async {
                                                  // Générer un PDF avec les logs
                                                  if (logs.isNotEmpty) {
                                                    final RenderBox box =
                                                        context.findRenderObject()
                                                            as RenderBox;
                                                    final Offset position = box
                                                        .localToGlobal(
                                                          Offset.zero,
                                                        );
                                                    _generateEmployeeLogsPdf(
                                                      employee,
                                                      logs,
                                                      Rect.fromLTWH(
                                                        position.dx,
                                                        position.dy,
                                                        box.size.width,
                                                        box.size.height,
                                                      ),
                                                    );
                                                  } else {
                                                    await showDialog(
                                                      context: context,
                                                      builder:
                                                          (
                                                            context,
                                                          ) => CustomErrorDialog(
                                                            title:
                                                                'Exportation impossible',
                                                            content:
                                                                'Aucune donnée à exporter',
                                                          ),
                                                    );
                                                  }
                                                },
                                                icon: const Icon(
                                                  Icons.picture_as_pdf,
                                                  size: 16,
                                                ),
                                                label: const Text(
                                                  'Exporter PDF',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(
                                                    color:
                                                        colorScheme
                                                            .outlineVariant,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 8,
                                                      ),
                                                  minimumSize: const Size(
                                                    0,
                                                    36,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Liste des logs
                                    Expanded(
                                      child:
                                          isLoading
                                              ? Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    CircularProgressIndicator(),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Chargement des heures travaillées...',
                                                      style: TextStyle(
                                                        color:
                                                            colorScheme
                                                                .onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                              : errorMessage != null
                                              ? Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.error_outline,
                                                      size: 64,
                                                      color: colorScheme.error,
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      errorMessage!,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color:
                                                            colorScheme
                                                                .onSurfaceVariant,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          isLoading = true;
                                                        });
                                                        loadEmployeeLogs();
                                                      },
                                                      child: const Text(
                                                        'Réessayer',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                              : logs.isEmpty
                                              ? Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.event_busy_rounded,
                                                      size: 64,
                                                      color: colorScheme
                                                          .onSurfaceVariant
                                                          .withAlpha(
                                                            (255 * 0.5).round(),
                                                          ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Aucun log trouvé pour ${_monthFormat.format(_viewModel.selectedDate)}',
                                                      style: theme
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            color:
                                                                colorScheme
                                                                    .onSurfaceVariant,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                              : ListView.separated(
                                                controller: scrollController,
                                                itemCount: logs.length,
                                                separatorBuilder:
                                                    (context, index) =>
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                itemBuilder: (context, index) {
                                                  final log = logs[index];
                                                  return Card(
                                                    margin:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 8,
                                                          horizontal: 0,
                                                        ),
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      side: BorderSide(
                                                        color: theme
                                                            .colorScheme
                                                            .outlineVariant
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            16,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          // Date dans un container légèrement arrondi
                                                          Container(
                                                            width: 90,
                                                            height: 50,
                                                            decoration: BoxDecoration(
                                                              color: theme
                                                                  .colorScheme
                                                                  .primary
                                                                  .withValues(
                                                                    alpha: 0.1,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                              border: Border.all(
                                                                color: theme
                                                                    .colorScheme
                                                                    .primary
                                                                    .withValues(
                                                                      alpha:
                                                                          0.2,
                                                                    ),
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Center(
                                                              child: Text(
                                                                log['date'],
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: theme
                                                                    .textTheme
                                                                    .labelLarge
                                                                    ?.copyWith(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color:
                                                                          theme
                                                                              .colorScheme
                                                                              .primary,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 16,
                                                          ),

                                                          // Heures et durée
                                                          Expanded(
                                                            child: Row(
                                                              children: [
                                                                // Icône et heures
                                                                Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .access_time_rounded,
                                                                      size: 18,
                                                                      color:
                                                                          theme
                                                                              .colorScheme
                                                                              .primary,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    Text(
                                                                      '${log['startTime']} - ${log['endTime']}',
                                                                      style: theme
                                                                          .textTheme
                                                                          .bodyMedium
                                                                          ?.copyWith(
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                            color:
                                                                                theme.colorScheme.onSurface,
                                                                          ),
                                                                    ),
                                                                  ],
                                                                ),

                                                                const Spacer(),

                                                                // Badge pour la durée
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            10,
                                                                        vertical:
                                                                            3,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color: theme
                                                                        .colorScheme
                                                                        .primary
                                                                        .withValues(
                                                                          alpha:
                                                                              0.15,
                                                                        ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          12,
                                                                        ),
                                                                    border: Border.all(
                                                                      color: theme
                                                                          .colorScheme
                                                                          .primary
                                                                          .withValues(
                                                                            alpha:
                                                                                0.3,
                                                                          ),
                                                                      width: 1,
                                                                    ),
                                                                  ),
                                                                  child: Text(
                                                                    _formatHoursToHourMinutes(
                                                                      log['hours'],
                                                                    ),
                                                                    style: theme
                                                                        .textTheme
                                                                        .titleSmall
                                                                        ?.copyWith(
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                          color:
                                                                              theme.colorScheme.primary,
                                                                        ),
                                                                  ),
                                                                ),

                                                                // Badge pour le montant journalier
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            10,
                                                                        vertical:
                                                                            3,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color: colorScheme
                                                                        .tertiaryContainer
                                                                        .withValues(
                                                                          alpha:
                                                                              0.3,
                                                                        ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          12,
                                                                        ),
                                                                    border: Border.all(
                                                                      color: colorScheme
                                                                          .tertiary
                                                                          .withValues(
                                                                            alpha:
                                                                                0.3,
                                                                          ),
                                                                      width: 1,
                                                                    ),
                                                                  ),
                                                                  child: Text(
                                                                    '${log['amount'].toStringAsFixed(2)}€',
                                                                    style: theme
                                                                        .textTheme
                                                                        .labelLarge
                                                                        ?.copyWith(
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                          color:
                                                                              colorScheme.tertiary,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                ),
          ),
    );
  }

  // Générer et sauvegarder un PDF avec les logs de l'employé
  Future<void> _generateEmployeeLogsPdf(
    Map<String, dynamic> employee,
    List<Map<String, dynamic>> logs,
    Rect sharePositionOrigin,
  ) async {
    // Afficher un indicateur de progression
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withAlpha((255 * 0.2).round()),
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: Theme.of(context).brightness == Brightness.dark ? 1 : 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Utilisation d'un effet de pulsation pour l'indicateur
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer
                          .withAlpha((255 * 0.3).round()),
                      shape: BoxShape.circle,
                    ),
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                      strokeWidth: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Génération du PDF en cours...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Veuillez patienter pendant la préparation de votre document',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final pdf = pw.Document();

      // Format de date pour le PDF
      final monthYear = DateFormat(
        'MMMM yyyy',
        'fr_FR',
      ).format(_viewModel.selectedDate);
      final fileName =
          'releve_${employee['name'].toString().toLowerCase().replaceAll(' ', '_')}_${monthYear.toLowerCase().replaceAll(' ', '_')}.pdf';

      // Créer les styles avec Google Fonts pour une meilleure cohérence
      final font = await PdfGoogleFonts.openSansRegular();
      final fontBold = await PdfGoogleFonts.openSansBold();

      final headerStyle = pw.TextStyle(font: fontBold, fontSize: 12);
      final cellStyle = pw.TextStyle(font: font, fontSize: 10);
      final totalStyle = pw.TextStyle(font: fontBold, fontSize: 12);

      // Calculer les totaux
      double totalHours = 0;
      double totalAmount = 0;
      for (var log in logs) {
        totalHours += log['hours'] as double;
        totalAmount += log['amount'] as double;
      }

      // Générer le header standard
      final standardHeader = await PdfHeaderService.buildStandardHeader(
        title: 'Relevé des heures',
        subtitle:
            'Employé: ${employee['name']} • Période: $monthYear • Taux horaire: ${employee['hourlyRate'].toStringAsFixed(2)}€/h',
        font: font,
        fontBold: fontBold,
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => standardHeader,
          footer:
              (context) => pw.Column(
                children: [
                  PdfHeaderService.buildStandardFooter(font: font),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Page ${context.pageNumber} sur ${context.pagesCount}',
                    style: cellStyle.copyWith(
                      fontSize: 8,
                      color: PdfColors.grey,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
          build:
              (context) => [
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Date', style: headerStyle),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Horaires', style: headerStyle),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Heures', style: headerStyle),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Montant', style: headerStyle),
                        ),
                      ],
                    ),
                    ...logs.map(
                      (log) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              log['date'] as String,
                              style: cellStyle,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              '${log['startTime']} - ${log['endTime']}',
                              style: cellStyle,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              _formatHoursToHourMinutes(log['hours'] as double),
                              style: cellStyle,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              '${log['amount'].toStringAsFixed(2)}€',
                              style: cellStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('TOTAL', style: totalStyle),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            '${logs.length} jours',
                            style: totalStyle,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            _formatHoursToHourMinutes(totalHours),
                            style: totalStyle,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            '${totalAmount.toStringAsFixed(2)}€',
                            style: totalStyle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
        ),
      );

      // Sauvegarder temporairement le PDF pour le partage
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        // Fermer le dialogue de progression
        Navigator.of(context, rootNavigator: true).pop();

        // Montrer un dialogue de succès avant le partage
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withAlpha((255 * 0.2).round()),
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation:
                  Theme.of(context).brightness == Brightness.dark ? 1 : 2,
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              title: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer
                          .withAlpha((255 * 0.5).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Exportation réussie',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Le PDF a été généré avec succès.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withAlpha((255 * 0.4).round()),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withAlpha((255 * 0.2).round()),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 22,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nom du fichier',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withAlpha((255 * 0.7).round()),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                fileName,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Que souhaitez-vous faire?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.share_rounded, size: 18),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondaryContainer,
                        foregroundColor:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Partager le PDF
                        Share.shareXFiles(
                          [XFile(file.path)],
                          subject: 'Relevé des heures',
                          text:
                              'Relevé des heures de ${employee['name']} - $monthYear',
                          sharePositionOrigin: sharePositionOrigin,
                        );
                      },
                      label: const Text('Partager'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save_alt_rounded, size: 18),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();

                        // Afficher un indicateur de chargement
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.outline
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                backgroundColor:
                                    Theme.of(context).colorScheme.surface,
                                elevation:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? 1
                                        : 2,
                                content: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        "Enregistrement en cours...",
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }

                        try {
                          // On a déjà le fichier ici, donc on utilise directement le message de succès

                          // Fermer le dialogue de chargement après un court délai
                          await Future.delayed(Duration(milliseconds: 500));
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }

                          if (context.mounted) {
                            // Afficher un message de confirmation avec un bouton pour prévisualiser
                            await showDialog(
                              context: context,
                              builder:
                                  (context) => CustomDialog(
                                    title: 'PDF enregistré',
                                    titleIcon: Icon(
                                      Icons.check_circle,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.tertiary,
                                    ),
                                    content: Text(
                                      'PDF enregistré avec succès dans ${file.path}',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(context).pop(),
                                        child: const Text('Fermer'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Printing.layoutPdf(
                                            onLayout:
                                                (PdfPageFormat format) async =>
                                                    await file.readAsBytes(),
                                            name: fileName,
                                          );
                                        },
                                        child: const Text('Aperçu'),
                                      ),
                                    ],
                                  ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.of(
                              context,
                            ).pop(); // Fermer le dialogue de chargement
                            await showDialog(
                              context: context,
                              builder:
                                  (context) => CustomErrorDialog(
                                    title: 'Erreur d\'enregistrement',
                                    content:
                                        'Erreur lors de l\'enregistrement: $e',
                                  ),
                            );
                          }
                        }
                      },
                      label: const Text('Enregistrer'),
                    ),
                  ],
                ),
              ],
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            );
          },
        );
      }
    } catch (e) {
      developer.log('Erreur lors de la génération du PDF: $e');

      if (context.mounted) {
        // Fermer le dialogue de progression en cas d'erreur
        Navigator.of(context, rootNavigator: true).pop();

        // Afficher un dialogue d'erreur plus détaillé
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.error.withAlpha((255 * 0.2).round()),
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation:
                  Theme.of(context).brightness == Brightness.dark ? 1 : 2,
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              title: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer
                          .withAlpha((255 * 0.5).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Échec de l\'exportation',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Une erreur est survenue lors de la génération du PDF.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer
                          .withAlpha((255 * 0.3).round()),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withAlpha((255 * 0.4).round()),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Détails de l\'erreur',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          e.toString(),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                            fontFamily: 'monospace',
                            height: 1.5,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      label: const Text('Fermer'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Réessayer l'export
                        _generateEmployeeLogsPdf(
                          employee,
                          logs,
                          sharePositionOrigin,
                        );
                      },
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ],
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            );
          },
        );
      }
    }
  }

  // Afficher le dialogue pour modifier le taux horaire
  void _showModifyHourlyRateDialog(Map<String, dynamic> employee) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final TextEditingController hourlyRateController = TextEditingController(
      text: employee['hourlyRate'].toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          backgroundColor: colorScheme.surface,
          title: Row(
            children: [
              Icon(Icons.monetization_on, color: colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Modifier le taux horaire',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Employé: ${employee['name']}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: hourlyRateController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Nouveau taux horaire (€/h)',
                  prefixIcon: const Icon(Icons.euro),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newRate = double.tryParse(hourlyRateController.text);
                if (newRate != null && newRate > 0) {
                  Navigator.of(context).pop();

                  // Capturer le navigator avant l'opération async
                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  // Afficher un indicateur de chargement
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) => Dialog(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(width: 16),
                                Text('Mise à jour du taux horaire...'),
                              ],
                            ),
                          ),
                        ),
                  );

                  try {
                    // Mettre à jour le taux horaire via le ViewModel
                    await _viewModel.updateEmployeeHourlyRate(
                      employee['id'],
                      newRate,
                    );

                    // Fermer le loading
                    navigator.pop();

                    // Afficher un message de succès via SnackBar
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Taux horaire de ${employee['name']} modifié à ${newRate.toStringAsFixed(2)}€/h',
                        ),
                        backgroundColor: colorScheme.tertiary,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  } catch (e) {
                    // Fermer le loading
                    navigator.pop();

                    // Afficher un message d'erreur via SnackBar
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de la mise à jour: $e'),
                        backgroundColor: colorScheme.error,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                } else {
                  // Afficher un message d'erreur
                  if (mounted) {
                    await showDialog(
                      context: context,
                      builder:
                          (context) => CustomErrorDialog(
                            title: 'Valeur invalide',
                            content:
                                'Veuillez entrer un taux horaire valide supérieur à 0',
                          ),
                    );
                  }
                }
              },
              child: const Text('Modifier'),
            ),
          ],
        );
      },
    );
  }

  // Afficher le dialogue pour bloquer un employé
  void _showBlockEmployeeDialog(Map<String, dynamic> employee) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.error.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          backgroundColor: colorScheme.surface,
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: colorScheme.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bloquer l\'employé',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Êtes-vous sûr de vouloir bloquer ${employee['name']} ?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cette action empêchera l\'employé de se connecter à l\'application.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // Capturer les références avant l'opération async
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                // Afficher un indicateur de chargement
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (context) => Dialog(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(width: 16),
                              Text('Blocage de l\'employé...'),
                            ],
                          ),
                        ),
                      ),
                );

                try {
                  // Bloquer l'employé via le ViewModel
                  await _viewModel.toggleEmployeeBlockStatus(
                    employee['id'],
                    true, // true = bloquer
                  );

                  // Fermer le loading et le modal des logs
                  navigator.pop(); // Fermer le loading
                  navigator.pop(); // Fermer le modal des logs

                  // Afficher un message de succès via SnackBar
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        '${employee['name']} a été bloqué avec succès',
                      ),
                      backgroundColor: colorScheme.error,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  // Fermer le loading
                  navigator.pop();

                  // Afficher un message d'erreur via SnackBar
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors du blocage: $e'),
                      backgroundColor: colorScheme.error,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Bloquer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Obtenir les données filtrées et triées du ViewModel
    final employees = _viewModel.employees;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // App Bar avec recherche et date
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 140,
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title:
                _isSearching
                    ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un employé...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.withAlpha(
                            (255 * 0.7).round(),
                          ),
                        ),
                      ),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                      onChanged: (query) {
                        setState(() {
                          _viewModel.setSearchQuery(query);
                        });
                      },
                    )
                    : Text(
                      'Heures des employés',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
            actions: [
              _isSearching
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                        _viewModel.setSearchQuery('');
                      });
                    },
                  )
                  : IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        _isSearching = true;
                      });
                    },
                  ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.only(bottom: 16, top: 80),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () async {
                          final currentDate = _viewModel.selectedDate;
                          final newDate = DateTime(
                            currentDate.year,
                            currentDate.month - 1,
                            1,
                          );
                          await _viewModel.setSelectedDate(newDate);
                          setState(() {});
                        },
                      ),
                      GestureDetector(
                        onTap: () async {
                          // Afficher un sélecteur de date
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _viewModel.selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            locale: const Locale('fr', 'FR'),
                          );
                          if (picked != null &&
                              picked != _viewModel.selectedDate) {
                            await _viewModel.setSelectedDate(picked);
                            setState(() {});
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _monthFormat.format(_viewModel.selectedDate),
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () async {
                          final currentDate = _viewModel.selectedDate;
                          final newDate = DateTime(
                            currentDate.year,
                            currentDate.month + 1,
                            1,
                          );
                          await _viewModel.setSelectedDate(newDate);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Résumé total - toujours affiché, même pendant le chargement
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Si en chargement ou pas d'employés, afficher un résumé vide ou avec les données disponibles
                _viewModel.isLoading
                    ? _buildTotalSummary(
                      [],
                    ) // Carte avec des valeurs à zéro pendant le chargement
                    : _buildTotalSummary(employees),
              ],
            ),
          ),

          // Indicateur de chargement
          _viewModel.isLoading
              ? const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Chargement des données...',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              : const SliverToBoxAdapter(child: SizedBox.shrink()),

          // Message d'erreur
          !_viewModel.isLoading && _viewModel.errorMessage != null
              ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _viewModel.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _viewModel.loadEmployeeData(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              )
              : const SliverToBoxAdapter(child: SizedBox.shrink()),

          // Liste des employés
          !_viewModel.isLoading && _viewModel.errorMessage == null
              ? SliverPadding(
                padding: const EdgeInsets.only(bottom: 80),
                sliver:
                    employees.isEmpty
                        ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_search_rounded,
                                  size: 64,
                                  color: colorScheme.onSurfaceVariant.withAlpha(
                                    (255 * 0.5).round(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun employé trouvé',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        : SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final employee = employees[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: _buildEmployeeCard(employee),
                            );
                          }, childCount: employees.length),
                        ),
              )
              : const SliverToBoxAdapter(child: SizedBox.shrink()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _viewModel.setSelectedDate(DateTime.now());
          setState(() {});
        },
        icon: const Icon(Icons.today_rounded),
        label: const Text(
          'Mois actuel',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
