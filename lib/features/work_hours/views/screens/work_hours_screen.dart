import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../../../profile/viewmodels/employee_profile_view_model.dart';
import '../../models/work_day_model.dart';
import 'employee_work_hours_report_screen.dart';

class WorkHoursScreen extends StatefulWidget {
  const WorkHoursScreen({Key? key}) : super(key: key);

  @override
  State<WorkHoursScreen> createState() => _WorkHoursScreenState();
}

class _WorkHoursScreenState extends State<WorkHoursScreen> {
  @override
  void initState() {
    super.initState();
    // Initialiser les données de localisation française
    initializeDateFormatting('fr_FR');
  }

  // Convertir les heures décimales en format heures et minutes (08:01)
  String _formatHoursToHourMinutes(double hours) {
    int fullHours = hours.floor();
    int minutes = ((hours - fullHours) * 60).round();
    return '${fullHours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  // Convertir une durée en format heures:minutes
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}h${minutes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmployeeProfileViewModel>(
      builder: (context, profileVM, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return Scaffold(
          backgroundColor: colorScheme.background,
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
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildSummaryCards(context, profileVM),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: _buildWorkHistory(context, profileVM),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
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

  // Cartes résumé avec statistiques
  Widget _buildSummaryCards(
    BuildContext context,
    EmployeeProfileViewModel profileVM,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Heures ce mois',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.timer_rounded,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatDuration(
                            Duration(
                              minutes:
                                  (profileVM.totalHoursThisMonth * 60).round(),
                            ),
                          ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 48,
                child: VerticalDivider(
                  width: 32,
                  color: colorScheme.outline.withOpacity(0.2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gains du mois',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.payments_rounded,
                            size: 20,
                            color: colorScheme.tertiary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${profileVM.totalEarningsThisMonth.toStringAsFixed(2)}€',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  // Historique des jours de travail
  Widget _buildWorkHistory(
    BuildContext context,
    EmployeeProfileViewModel profileVM,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historique',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: profileVM.workDays.length,
            separatorBuilder:
                (context, index) => Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                ),
            itemBuilder: (context, index) {
              final workDay = profileVM.workDays[index];
              return _WorkDayListItem(
                workDay: workDay,
                onTap:
                    () => _showEditWorkDayDialog(context, profileVM, workDay),
              );
            },
          ),
        ),
      ],
    );
  }

  // Obtenir le nom du mois en français
  // Removed unused _getMonthName method

  // Dialogue pour ajouter un jour de travail
  void _showAddWorkDayDialog(
    BuildContext context,
    EmployeeProfileViewModel profileVM,
  ) {
    final now = DateTime.now();
    final workDay = WorkDay(
      id: '', // L'ID sera généré par Supabase
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
                  title: 'Nouveau jour',
                  workDay: workDay,
                  onSave: (updatedWorkDay) async {
                    await profileVM.addWorkDay(updatedWorkDay);
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

  // Dialogue pour modifier un jour de travail
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

  // Affiche le rapport des heures de travail pour tous les employés (mode administrateur)
  void _showEmployeeWorkHoursReport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.8,
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
                child: const EmployeeWorkHoursReportScreen(),
              );
            },
          ),
    );
  }
}

class WorkDayEditSheet extends StatefulWidget {
  final String title;
  final WorkDay workDay;
  final Function(WorkDay) onSave;
  final VoidCallback? onDelete;

  const WorkDayEditSheet({
    Key? key,
    required this.title,
    required this.workDay,
    required this.onSave,
    this.onDelete,
  }) : super(key: key);

  @override
  State<WorkDayEditSheet> createState() => _WorkDayEditSheetState();
}

class _WorkDayEditSheetState extends State<WorkDayEditSheet> {
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Barre de glissement
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.onSurfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 24),

        // En-tête avec titre et bouton supprimer
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                widget.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
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
                                  foregroundColor:
                                      Theme.of(context).colorScheme.error,
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
        const SizedBox(height: 32),

        // Résumé des heures et du montant
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.timer_rounded,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatHoursToHourMinutes(_hours),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.payments_rounded,
                              size: 20,
                              color: colorScheme.tertiary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _amount != null
                                ? '${_amount!.toStringAsFixed(2)}€'
                                : '-',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Sélecteurs de date et heure
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Sélecteur de date
              ListTile(
                title: const Text('Date'),
                subtitle: Text(
                  DateFormat.yMMMMEEEEd('fr_FR').format(_date),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                leading: Icon(
                  Icons.calendar_today_rounded,
                  color: colorScheme.primary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),

              // Sélecteurs d'heure
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Début'),
                      subtitle: Text(
                        _startTime.format(context),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      leading: Icon(
                        Icons.access_time_rounded,
                        color: colorScheme.primary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                      onTap: () => _selectStartTime(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ListTile(
                      title: const Text('Fin'),
                      subtitle: Text(
                        _endTime.format(context),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      leading: Icon(
                        Icons.access_time_filled_rounded,
                        color: colorScheme.primary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                      onTap: () => _selectEndTime(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Bouton Enregistrer
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Enregistrer',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

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
}

// Removed unused _WorkDayEditSheet class

class _WorkDayListItem extends StatelessWidget {
  final WorkDay workDay;
  final VoidCallback onTap;

  const _WorkDayListItem({Key? key, required this.workDay, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final formattedDate = DateFormat.yMMMd('fr_FR').format(workDay.date);
    final hours = workDay.hours;
    final formattedHours =
        '${hours.floor().toString().padLeft(2, '0')}:${((hours - hours.floor()) * 60).round().toString().padLeft(2, '0')}';
    final formattedAmount =
        workDay.totalAmount != null
            ? '${workDay.totalAmount!.toStringAsFixed(2)}€'
            : '-';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  workDay.date.day.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$formattedHours • $formattedAmount',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
