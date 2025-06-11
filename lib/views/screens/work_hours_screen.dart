import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/employee_profile_view_model.dart';
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

  @override
  Widget build(BuildContext context) {
    return Consumer<EmployeeProfileViewModel>(
      builder: (context, profileVM, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Heures de travail'),
            actions: [
              // Bouton Admin visible uniquement pour les administrateurs
              if (profileVM.role == UserRole.admin)
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings),
                  tooltip: 'Relevé des heures par employé',
                  onPressed: () {
                    _showEmployeeWorkHoursReport(context);
                  },
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              // Simuler un rafraîchissement (dans une vraie app, vous chargeriez les données)
              await Future.delayed(const Duration(milliseconds: 300));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(context, profileVM),
                  const SizedBox(height: 18),
                  _buildWorkHistory(context, profileVM),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              _showAddWorkDayDialog(context, profileVM);
            },
            icon: const Icon(Icons.add),
            label: const Text('Jour de travail'),
            tooltip: 'Ajouter un jour de travail',
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
    final currentMonthEarnings = profileVM.getCurrentMonthEarnings();
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Calculer les heures du mois en cours
    final currentMonthHours = profileVM.workDays
        .where(
          (day) =>
              day.date.month == currentMonth && day.date.year == currentYear,
        )
        .fold(0.0, (sum, day) => sum + day.hours);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildInfoCard(
                context,
                title: 'Taux horaire',
                value: '${profileVM.hourlyRate.toStringAsFixed(2)}€/h',
                icon: Icons.euro,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: _buildInfoCard(
                context,
                title: 'Heures ce mois',
                value: _formatHoursToHourMinutes(currentMonthHours),
                icon: Icons.access_time,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          context,
          title: 'Gagné ce mois',
          value: '${currentMonthEarnings.toStringAsFixed(2)}€',
          icon: Icons.account_balance_wallet,
          color: Colors.green.shade700,
          fullWidth: true,
        ),
      ],
    );
  }

  // Carte d'information avec icône
  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool fullWidth = false,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child:
            fullWidth
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: color, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: color, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  // Historique des jours de travail
  Widget _buildWorkHistory(
    BuildContext context,
    EmployeeProfileViewModel profileVM,
  ) {
    final workDays = profileVM.workDays;
    final colorScheme = Theme.of(context).colorScheme;

    if (workDays.isEmpty) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 42,
                  color: Colors.grey,
                ),
                SizedBox(height: 12),
                Text(
                  'Aucun jour de travail enregistré',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 6),
                Text(
                  'Appuyez sur le bouton + pour ajouter',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Organiser les jours de travail par mois
    final Map<String, List<WorkDay>> workDaysByMonth = {};

    for (var workDay in workDays) {
      final dateKey = '${workDay.date.month}-${workDay.date.year}';
      if (!workDaysByMonth.containsKey(dateKey)) {
        workDaysByMonth[dateKey] = [];
      }
      workDaysByMonth[dateKey]!.add(workDay);
    }

    // Trier les clés par date (plus récent en premier)
    final sortedKeys =
        workDaysByMonth.keys.toList()..sort((a, b) {
          final aParts = a.split('-');
          final bParts = b.split('-');
          final aYear = int.parse(aParts[1]);
          final bYear = int.parse(bParts[1]);
          final aMonth = int.parse(aParts[0]);
          final bMonth = int.parse(bParts[0]);

          if (aYear != bYear) {
            return bYear.compareTo(aYear); // Plus récent en premier
          }
          return bMonth.compareTo(aMonth); // Plus récent en premier
        });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 10.0),
          child: Text(
            'Historique des jours travaillés',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...sortedKeys.map((monthKey) {
          final monthDays = workDaysByMonth[monthKey]!;
          final parts = monthKey.split('-');
          final month = int.parse(parts[0]);
          final year = int.parse(parts[1]);

          // Calculer les totaux du mois
          final monthHours = monthDays.fold(0.0, (sum, day) => sum + day.hours);
          final monthAmount = monthDays.fold(
            0.0,
            (sum, day) =>
                sum +
                (day.totalAmount ?? day.calculateAmount(profileVM.hourlyRate)),
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 14.0),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Minimiser la hauteur
              children: [
                // En-tête du mois
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6.0,
                    horizontal: 12.0,
                  ),
                  color: colorScheme.primary.withOpacity(0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_getMonthName(month)} $year',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${_formatHoursToHourMinutes(monthHours)} • ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${monthAmount.toStringAsFixed(2)}€',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Liste des jours du mois
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 0,
                  ), // Supprimer l'espacement excessif
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero, // Supprimer le padding par défaut
                    itemCount: monthDays.length,
                    separatorBuilder:
                        (context, index) => Divider(
                          height: 2,
                          thickness: 0.5,
                          color: Colors.grey.withOpacity(0.2),
                        ),
                    itemBuilder: (context, index) {
                      final workDay = monthDays[index];
                      return _buildWorkDayItem(context, workDay, profileVM);
                    },
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // Obtenir le nom du mois en français
  String _getMonthName(int month) {
    const monthNames = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return monthNames[month - 1];
  }

  // Élément de la liste des jours de travail
  Widget _buildWorkDayItem(
    BuildContext context,
    WorkDay workDay,
    EmployeeProfileViewModel profileVM,
  ) {
    final dateFormat = DateFormat('EEEE dd MMMM', 'fr_FR');
    final timeFormat = DateFormat('HH:mm');
    final colorScheme = Theme.of(context).colorScheme;

    // Calculer la durée et le montant
    final hours = workDay.hours;
    final amount =
        workDay.totalAmount ?? workDay.calculateAmount(profileVM.hourlyRate);

    // Formater le jour de la semaine (première lettre en majuscule)
    String formattedDate = dateFormat.format(workDay.date);
    formattedDate =
        formattedDate.substring(0, 1).toUpperCase() +
        formattedDate.substring(1);

    return Dismissible(
      key: Key(workDay.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirmer la suppression'),
              content: const Text(
                'Voulez-vous vraiment supprimer ce jour de travail ?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Supprimer'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        profileVM.removeWorkDay(workDay.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jour de travail supprimé'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 2.0,
        ),
        minVerticalPadding: 6.0,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                formattedDate,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              '${amount.toStringAsFixed(2)}€',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                fontSize: 15,
              ),
            ),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, size: 13, color: Colors.grey.shade600),
                const SizedBox(width: 3),
                Text(
                  '${timeFormat.format(workDay.startTime)} - ${timeFormat.format(workDay.endTime)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
            Text(
              _formatHoursToHourMinutes(hours),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialogue pour ajouter un jour de travail
  void _showAddWorkDayDialog(
    BuildContext context,
    EmployeeProfileViewModel profileVM,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final colorScheme = Theme.of(context).colorScheme;

    DateTime selectedDate = today;
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              // Calculer la durée entre l'heure de début et de fin
              final startDateTime = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                startTime.hour,
                startTime.minute,
              );

              final endDateTime = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                endTime.hour,
                endTime.minute,
              );

              // Si l'heure de fin est avant l'heure de début, on suppose que c'est le lendemain
              final adjustedEndDateTime =
                  endDateTime.isBefore(startDateTime)
                      ? endDateTime.add(const Duration(days: 1))
                      : endDateTime;

              final difference = adjustedEndDateTime.difference(startDateTime);
              final hours = difference.inMinutes / 60.0;
              final amount = hours * profileVM.hourlyRate;

              final dateFormatter = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');
              String formattedDate = dateFormatter.format(selectedDate);
              formattedDate =
                  formattedDate.substring(0, 1).toUpperCase() +
                  formattedDate.substring(1);

              return AlertDialog(
                title: const Text('Ajouter un jour de travail'),
                contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: colorScheme.primary,
                                      onPrimary: colorScheme.onPrimary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: colorScheme.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Date',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
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

                      const Divider(height: 1),

                      // Heure de début
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: startTime,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: colorScheme.primary,
                                      onPrimary: colorScheme.onPrimary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedTime != null) {
                              setState(() {
                                startTime = pickedTime;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: colorScheme.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Heure de début',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        startTime.format(context),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
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

                      const Divider(height: 1),

                      // Heure de fin
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: endTime,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: colorScheme.primary,
                                      onPrimary: colorScheme.onPrimary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedTime != null) {
                              setState(() {
                                endTime = pickedTime;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: colorScheme.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Heure de fin',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        endTime.format(context),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
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

                      const SizedBox(height: 16),

                      // Résumé
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Durée totale:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _formatHoursToHourMinutes(hours),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Montant:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${amount.toStringAsFixed(2)}€',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final startDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        startTime.hour,
                        startTime.minute,
                      );

                      final endDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        endTime.hour,
                        endTime.minute,
                      );

                      // Si l'heure de fin est avant l'heure de début, on suppose que c'est le lendemain
                      final adjustedEndDateTime =
                          endDateTime.isBefore(startDateTime)
                              ? endDateTime.add(const Duration(days: 1))
                              : endDateTime;

                      // Calculer les heures et le montant
                      final difference = adjustedEndDateTime.difference(
                        startDateTime,
                      );
                      final hours = difference.inMinutes / 60.0;
                      final amount = hours * profileVM.hourlyRate;

                      // Créer et ajouter le jour de travail
                      final newWorkDay = WorkDay(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        date: selectedDate,
                        startTime: startDateTime,
                        endTime: adjustedEndDateTime,
                        hoursWorked: hours,
                        totalAmount: amount,
                      );

                      profileVM.addWorkDay(newWorkDay);
                      Navigator.of(context).pop();

                      // Afficher un message de confirmation
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Jour de travail ajouté avec succès'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text('Enregistrer'),
                  ),
                ],
              );
            },
          ),
    );
  }

  // Affiche le rapport des heures de travail pour tous les employés (mode administrateur)
  void _showEmployeeWorkHoursReport(BuildContext context) {
    // Au lieu d'afficher un dialogue, nous naviguons vers la nouvelle page dédiée
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EmployeeWorkHoursReportScreen(),
      ),
    );
  }
}
