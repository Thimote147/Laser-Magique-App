import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/work_day_model.dart';

// Types de périodes disponibles
enum PeriodType { week, month, quarter, year, custom }

class EmployeeDetailedHoursScreen extends StatefulWidget {
  final Map<String, dynamic> employee;

  const EmployeeDetailedHoursScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailedHoursScreen> createState() =>
      _EmployeeDetailedHoursScreenState();
}

class _EmployeeDetailedHoursScreenState
    extends State<EmployeeDetailedHoursScreen> {
  DateTime _selectedMonth = DateTime.now();
  final DateFormat _monthFormat = DateFormat('MMMM yyyy', 'fr_FR');

  // Variables pour la gestion des périodes
  PeriodType _currentPeriodType = PeriodType.month;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Données fictives pour démonstration
  // Dans une vraie application, ces données seraient chargées depuis une API ou une base de données
  final Map<String, List<WorkDay>> _dummyWorkDays = {
    '1': [
      // Jean Dupont
      WorkDay(
        date: DateTime(2025, DateTime.now().month, 1),
        startTime: DateTime(2025, DateTime.now().month, 1, 8, 30),
        endTime: DateTime(2025, DateTime.now().month, 1, 17, 0),
        id: 'wd1_1',
      ),
      WorkDay(
        date: DateTime(2025, DateTime.now().month, 2),
        startTime: DateTime(2025, DateTime.now().month, 2, 9, 0),
        endTime: DateTime(2025, DateTime.now().month, 2, 18, 0),
        id: 'wd1_2',
      ),
      WorkDay(
        date: DateTime(2025, DateTime.now().month, 3),
        startTime: DateTime(2025, DateTime.now().month, 3, 8, 0),
        endTime: DateTime(2025, DateTime.now().month, 3, 16, 30),
        id: 'wd1_3',
      ),
      WorkDay(
        date: DateTime(2025, DateTime.now().month, 5),
        startTime: DateTime(2025, DateTime.now().month, 5, 8, 30),
        endTime: DateTime(2025, DateTime.now().month, 5, 15, 45),
        id: 'wd1_4',
      ),
      WorkDay(
        date: DateTime(2025, DateTime.now().month, 8),
        startTime: DateTime(2025, DateTime.now().month, 8, 9, 15),
        endTime: DateTime(2025, DateTime.now().month, 8, 17, 30),
        id: 'wd1_5',
      ),
      WorkDay(
        date: DateTime(2025, DateTime.now().month, 10),
        startTime: DateTime(2025, DateTime.now().month, 10, 8, 0),
        endTime: DateTime(2025, DateTime.now().month, 10, 16, 0),
        id: 'wd1_6',
      ),
    ],
    '2': [
      // Marie Martin
      WorkDay(
        date: DateTime(2025, DateTime.now().month, 1),
        startTime: DateTime(2025, DateTime.now().month, 1, 10, 0),
        endTime: DateTime(2025, DateTime.now().month, 1, 18, 30),
        id: 'wd2_1',
      ),
      WorkDay(
        date: DateTime(2025, DateTime.now().month, 2),
        startTime: DateTime(2025, DateTime.now().month, 2, 9, 30),
        endTime: DateTime(2025, DateTime.now().month, 2, 17, 0),
        id: 'wd2_2',
      ),
      WorkDay(
        date: DateTime(2025, DateTime.now().month, 4),
        startTime: DateTime(2025, DateTime.now().month, 4, 8, 0),
        endTime: DateTime(2025, DateTime.now().month, 4, 16, 0),
        id: 'wd2_3',
      ),
      WorkDay(
        date: DateTime(2025, DateTime.now().month, 6),
        startTime: DateTime(2025, DateTime.now().month, 6, 9, 0),
        endTime: DateTime(2025, DateTime.now().month, 6, 18, 0),
        id: 'wd2_4',
      ),
      WorkDay(
        date: DateTime(2025, DateTime.now().month, 9),
        startTime: DateTime(2025, DateTime.now().month, 9, 10, 15),
        endTime: DateTime(2025, DateTime.now().month, 9, 19, 0),
        id: 'wd2_5',
      ),
    ],
    '3': [
      // Pierre Dubois
      WorkDay(
        date: DateTime(2025, DateTime.now().month, 1),
        startTime: DateTime(2025, DateTime.now().month, 1, 8, 0),
        endTime: DateTime(2025, DateTime.now().month, 1, 18, 0),
        id: 'wd3_1',
      ),
      WorkDay(
        date: DateTime(2025, DateTime.now().month, 3),
        startTime: DateTime(2025, DateTime.now().month, 3, 9, 0),
        endTime: DateTime(2025, DateTime.now().month, 3, 17, 30),
        id: 'wd3_2',
      ),
      WorkDay(
        date: DateTime(2025, DateTime.now().month, 5),
        startTime: DateTime(2025, DateTime.now().month, 5, 8, 30),
        endTime: DateTime(2025, DateTime.now().month, 5, 16, 45),
        id: 'wd3_3',
      ),
      WorkDay(
        date: DateTime(2025, DateTime.now().month, 7),
        startTime: DateTime(2025, DateTime.now().month, 7, 8, 0),
        endTime: DateTime(2025, DateTime.now().month, 7, 17, 0),
        id: 'wd3_4',
      ),
      WorkDay(
        date: DateTime(2025, DateTime.now().month, 8),
        startTime: DateTime(2025, DateTime.now().month, 8, 9, 30),
        endTime: DateTime(2025, DateTime.now().month, 8, 18, 30),
        id: 'wd3_5',
      ),
      WorkDay(
        date: DateTime(2025, DateTime.now().month, 10),
        startTime: DateTime(2025, DateTime.now().month, 10, 8, 30),
        endTime: DateTime(2025, DateTime.now().month, 10, 16, 30),
        id: 'wd3_6',
      ),
      WorkDay(
        date: DateTime(2025, DateTime.now().month, 11),
        startTime: DateTime(2025, DateTime.now().month, 11, 9, 0),
        endTime: DateTime(2025, DateTime.now().month, 11, 18, 0),
        id: 'wd3_7',
      ),
    ],
  };

  List<WorkDay> get _employeeWorkDays {
    final String employeeId = widget.employee['id'] as String;
    return _dummyWorkDays[employeeId] ?? [];
  }

  // Convertir DateTime en format lisible (9h30)
  String _formatTimeOfDay(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Formater une date au format "Lundi 12 Janvier 2023"
  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    String formattedDate = formatter.format(date);
    // Capitaliser la première lettre
    return '${formattedDate[0].toUpperCase()}${formattedDate.substring(1)}';
  }

  // Convertir les heures décimales en format heures et minutes (8h30)
  String _formatHoursToHourMinutes(double hours) {
    int fullHours = hours.floor();
    int minutes = ((hours - fullHours) * 60).round();

    if (minutes == 0) {
      return '${fullHours}h00';
    } else {
      return minutes < 10 ? '${fullHours}h0$minutes' : '${fullHours}h$minutes';
    }
  }

  // Obtenir les dates de début et fin en fonction du type de période
  DateTimeRange _getDateRange() {
    final now = DateTime.now();

    switch (_currentPeriodType) {
      case PeriodType.week:
        // Trouver le premier jour de la semaine (lundi)
        final firstDayOfWeek = _selectedMonth.subtract(
          Duration(days: _selectedMonth.weekday - 1),
        );
        return DateTimeRange(
          start: firstDayOfWeek,
          end: firstDayOfWeek.add(const Duration(days: 6)),
        );

      case PeriodType.month:
        final firstDayOfMonth = DateTime(
          _selectedMonth.year,
          _selectedMonth.month,
          1,
        );
        final lastDayOfMonth = DateTime(
          _selectedMonth.year,
          _selectedMonth.month + 1,
          0,
        ); // Le jour 0 du mois suivant est le dernier jour du mois courant
        return DateTimeRange(start: firstDayOfMonth, end: lastDayOfMonth);

      case PeriodType.quarter:
        final currentQuarter = ((_selectedMonth.month - 1) ~/ 3) + 1;
        final firstMonthOfQuarter = ((currentQuarter - 1) * 3) + 1;
        final firstDayOfQuarter = DateTime(
          _selectedMonth.year,
          firstMonthOfQuarter,
          1,
        );
        final lastDayOfQuarter = DateTime(
          _selectedMonth.year,
          firstMonthOfQuarter + 3,
          0,
        );
        return DateTimeRange(start: firstDayOfQuarter, end: lastDayOfQuarter);

      case PeriodType.year:
        final firstDayOfYear = DateTime(_selectedMonth.year, 1, 1);
        final lastDayOfYear = DateTime(_selectedMonth.year, 12, 31);
        return DateTimeRange(start: firstDayOfYear, end: lastDayOfYear);

      case PeriodType.custom:
        if (_customStartDate != null && _customEndDate != null) {
          return DateTimeRange(start: _customStartDate!, end: _customEndDate!);
        } else {
          // Fallback au mois actuel si pas de dates personnalisées
          final firstDayOfMonth = DateTime(now.year, now.month, 1);
          final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
          return DateTimeRange(start: firstDayOfMonth, end: lastDayOfMonth);
        }
    }
  }

  // Filtrer les jours de travail en fonction de la période sélectionnée
  List<WorkDay> _getFilteredWorkDays() {
    final dateRange = _getDateRange();

    return _employeeWorkDays.where((day) {
      return day.date.isAfter(
            dateRange.start.subtract(const Duration(days: 1)),
          ) &&
          day.date.isBefore(dateRange.end.add(const Duration(days: 1)));
    }).toList();
  }

  // Formater l'affichage de la période actuelle
  String _formatCurrentPeriod() {
    final dateRange = _getDateRange();

    switch (_currentPeriodType) {
      case PeriodType.week:
        final startDate = DateFormat('d MMM', 'fr_FR').format(dateRange.start);
        final endDate = DateFormat('d MMM yyyy', 'fr_FR').format(dateRange.end);
        return 'Semaine du $startDate au $endDate';

      case PeriodType.month:
        return _monthFormat.format(_selectedMonth);

      case PeriodType.quarter:
        final currentQuarter = ((_selectedMonth.month - 1) ~/ 3) + 1;
        return 'T$currentQuarter ${_selectedMonth.year}';

      case PeriodType.year:
        return '${_selectedMonth.year}';

      case PeriodType.custom:
        if (_customStartDate != null && _customEndDate != null) {
          final startDate = DateFormat(
            'd MMM yyyy',
            'fr_FR',
          ).format(_customStartDate!);
          final endDate = DateFormat(
            'd MMM yyyy',
            'fr_FR',
          ).format(_customEndDate!);
          return 'Du $startDate au $endDate';
        } else {
          return 'Période personnalisée';
        }
    }
  }

  // Naviguer à la période précédente
  void _previousPeriod() {
    setState(() {
      switch (_currentPeriodType) {
        case PeriodType.week:
          _selectedMonth = _selectedMonth.subtract(const Duration(days: 7));
          break;
        case PeriodType.month:
          _selectedMonth = DateTime(
            _selectedMonth.year,
            _selectedMonth.month - 1,
            1,
          );
          break;
        case PeriodType.quarter:
          _selectedMonth = DateTime(
            _selectedMonth.year,
            _selectedMonth.month - 3,
            1,
          );
          break;
        case PeriodType.year:
          _selectedMonth = DateTime(
            _selectedMonth.year - 1,
            _selectedMonth.month,
            1,
          );
          break;
        case PeriodType.custom:
          // Pas de navigation pour une période personnalisée
          break;
      }
    });
  }

  // Naviguer à la période suivante
  void _nextPeriod() {
    setState(() {
      switch (_currentPeriodType) {
        case PeriodType.week:
          _selectedMonth = _selectedMonth.add(const Duration(days: 7));
          break;
        case PeriodType.month:
          _selectedMonth = DateTime(
            _selectedMonth.year,
            _selectedMonth.month + 1,
            1,
          );
          break;
        case PeriodType.quarter:
          _selectedMonth = DateTime(
            _selectedMonth.year,
            _selectedMonth.month + 3,
            1,
          );
          break;
        case PeriodType.year:
          _selectedMonth = DateTime(
            _selectedMonth.year + 1,
            _selectedMonth.month,
            1,
          );
          break;
        case PeriodType.custom:
          // Pas de navigation pour une période personnalisée
          break;
      }
    });
  }

  // Afficher le sélecteur de période
  void _showPeriodSelector() {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'Sélectionner une période',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Options pour les différents types de périodes
                    RadioListTile<PeriodType>(
                      title: const Text('Semaine'),
                      value: PeriodType.week,
                      groupValue: _currentPeriodType,
                      onChanged: (value) {
                        setState(() => _currentPeriodType = value!);
                        this.setState(() {});
                        Navigator.pop(context);
                      },
                      activeColor: colorScheme.primary,
                    ),
                    RadioListTile<PeriodType>(
                      title: const Text('Mois'),
                      value: PeriodType.month,
                      groupValue: _currentPeriodType,
                      onChanged: (value) {
                        setState(() => _currentPeriodType = value!);
                        this.setState(() {});
                        Navigator.pop(context);
                      },
                      activeColor: colorScheme.primary,
                    ),
                    RadioListTile<PeriodType>(
                      title: const Text('Trimestre'),
                      value: PeriodType.quarter,
                      groupValue: _currentPeriodType,
                      onChanged: (value) {
                        setState(() => _currentPeriodType = value!);
                        this.setState(() {});
                        Navigator.pop(context);
                      },
                      activeColor: colorScheme.primary,
                    ),
                    RadioListTile<PeriodType>(
                      title: const Text('Année'),
                      value: PeriodType.year,
                      groupValue: _currentPeriodType,
                      onChanged: (value) {
                        setState(() => _currentPeriodType = value!);
                        this.setState(() {});
                        Navigator.pop(context);
                      },
                      activeColor: colorScheme.primary,
                    ),
                    RadioListTile<PeriodType>(
                      title: const Text('Période personnalisée'),
                      value: PeriodType.custom,
                      groupValue: _currentPeriodType,
                      onChanged: (value) {
                        setState(() => _currentPeriodType = value!);
                        Navigator.pop(context);
                        _showCustomPeriodDialog();
                      },
                      activeColor: colorScheme.primary,
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  // Afficher le dialogue pour sélectionner une période personnalisée
  void _showCustomPeriodDialog() async {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    // Valeurs par défaut si pas encore définies
    DateTime startDate = _customStartDate ?? DateTime(now.year, now.month, 1);
    DateTime endDate = _customEndDate ?? DateTime(now.year, now.month + 1, 0);

    final DateTimeRange? result = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      saveText: 'Valider',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: colorScheme.primary,
              onPrimary: colorScheme.onPrimary,
              surface: colorScheme.surface,
              onSurface: colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        _customStartDate = result.start;
        _customEndDate = result.end;
        _currentPeriodType = PeriodType.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hourlyRate = widget.employee['hourlyRate'] as double;

    // Filtrer les jours de travail pour la période sélectionnée
    final filteredWorkDays = _getFilteredWorkDays();

    // Calculer le total des heures travaillées pour la période
    double totalHours = 0;
    for (var day in filteredWorkDays) {
      totalHours += day.hours;
    }

    // Calculer le montant total à payer
    final totalAmount = totalHours * hourlyRate;

    return Scaffold(
      appBar: AppBar(
        title: Text('Heures de ${widget.employee['name']}'),
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sélecteur de période
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha((255 * 0.3).round()),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _previousPeriod,
                      tooltip: 'Période précédente',
                    ),
                    GestureDetector(
                      onTap: _showPeriodSelector,
                      child: Row(
                        children: [
                          Text(
                            _formatCurrentPeriod(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _nextPeriod,
                      tooltip: 'Période suivante',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Résumé du mois
          Card(
            margin: const EdgeInsets.all(16.0),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total des heures',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        _formatHoursToHourMinutes(totalHours),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color:
                              colorScheme
                                  .tertiary, // Utilise la couleur tertiaire (indigo)
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Montant',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${totalAmount.toStringAsFixed(2)}€',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Liste des jours travaillés
          Expanded(
            child:
                filteredWorkDays.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune heure enregistrée pour cette période',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: filteredWorkDays.length,
                      itemBuilder: (context, index) {
                        final workDay = filteredWorkDays[index];
                        final hoursWorked = workDay.hours;
                        final dailyAmount = hoursWorked * hourlyRate;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(workDay.date),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${dailyAmount.toStringAsFixed(2)}€',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onPrimary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_formatTimeOfDay(workDay.startTime)} - ${_formatTimeOfDay(workDay.endTime)}',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _formatHoursToHourMinutes(hoursWorked),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                        color: colorScheme.tertiary,
                                      ),
                                    ),
                                  ],
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
    );
  }
}
