import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'employee_detailed_hours_screen.dart';

class EmployeeWorkHoursReportScreen extends StatefulWidget {
  const EmployeeWorkHoursReportScreen({super.key});

  @override
  State<EmployeeWorkHoursReportScreen> createState() =>
      _EmployeeWorkHoursReportScreenState();
}

class _EmployeeWorkHoursReportScreenState
    extends State<EmployeeWorkHoursReportScreen> {
  // Date sélectionnée (par défaut, date actuelle)
  DateTime _selectedDate = DateTime.now();
  final DateFormat _monthFormat = DateFormat('MMMM yyyy', 'fr_FR');

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

  // Naviguer au mois précédent
  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    });
  }

  // Naviguer au mois suivant
  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    });
  }

  // Aller au mois courant
  void _goToCurrentMonth() {
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  // Génère des données fictives pour le mois sélectionné
  List<Map<String, dynamic>> _getEmployeeDataForMonth(DateTime month) {
    // Simuler un changement dans les heures travaillées en fonction du mois
    // Dans une vraie application, ces données seraient chargées depuis une API ou une base de données
    final monthMultiplier =
        0.8 + (month.month % 3) * 0.1; // Variation selon le mois

    return [
      {
        'id': '1',
        'name': 'Jean Dupont',
        'role': 'Membre',
        'hourlyRate': 12.50,
        'currentMonthHours': 42.5 * monthMultiplier,
        'currentMonthAmount': 531.25 * monthMultiplier,
        'totalHours': 142.0 + (month.month * 10),
        'totalAmount': 1775.0 + (month.month * 125),
      },
      {
        'id': '2',
        'name': 'Marie Martin',
        'role': 'Membre',
        'hourlyRate': 13.20,
        'currentMonthHours': 38.0 * monthMultiplier,
        'currentMonthAmount': 501.60 * monthMultiplier,
        'totalHours': 128.5 + (month.month * 8),
        'totalAmount': 1696.20 + (month.month * 105.60),
      },
      {
        'id': '3',
        'name': 'Pierre Dubois',
        'role': 'Administrateur',
        'hourlyRate': 15.00,
        'currentMonthHours': 45.0 * monthMultiplier,
        'currentMonthAmount': 675.0 * monthMultiplier,
        'totalHours': 165.0 + (month.month * 12),
        'totalAmount': 2475.0 + (month.month * 180),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Obtenir les données des employés pour le mois sélectionné
    final employees = _getEmployeeDataForMonth(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relevé des heures par employé'),
        elevation: 0, // Material 3 style
      ),
      backgroundColor:
          Theme.of(
            context,
          ).colorScheme.surface, // Fond cohérent avec le reste de l'app
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête avec le mois sélectionné
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 24.0,
            ),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withAlpha((255 * 0.3).round()),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Text(
                _monthFormat.format(_selectedDate),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final employee = employees[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      // Naviguer vers la page détaillée des heures de cet employé
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) => EmployeeDetailedHoursScreen(
                                employee: employee,
                              ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Nom de l'employé
                              Text(
                                employee['name'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              // Montant du mois
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${(employee['currentMonthAmount'] as double).toStringAsFixed(2)}€',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Rôle et taux horaire
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.tertiary.withAlpha((255 * 0.2).round()),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  employee['role'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        Theme.of(context).colorScheme.tertiary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(employee['hourlyRate'] as double).toStringAsFixed(2)}€/h',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Heures travaillées ce mois
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Heures travaillées ce mois:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                _formatHoursToHourMinutes(
                                  employee['currentMonthHours'] as double,
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.05).round()),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Bouton mois précédent
                _NavigationButton(
                  icon: Icons.chevron_left,
                  onPressed: _previousMonth,
                  tooltip: 'Mois précédent',
                  colorScheme: Theme.of(context).colorScheme,
                ),
                // Bouton pour revenir au mois courant
                TextButton(
                  onPressed: _goToCurrentMonth,
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.tertiary.withAlpha((255 * 0.15).round()),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Mois actuel',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.tertiary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Bouton mois suivant
                _NavigationButton(
                  icon: Icons.chevron_right,
                  onPressed: _nextMonth,
                  tooltip: 'Mois suivant',
                  colorScheme: Theme.of(context).colorScheme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget personnalisé pour les boutons de navigation
class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final ColorScheme colorScheme;

  const _NavigationButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, size: 28, color: colorScheme.primary),
          ),
        ),
      ),
    );
  }
}
