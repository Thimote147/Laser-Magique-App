import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/booking_view_model.dart';
import '../../viewmodels/activity_formula_view_model.dart';
import '../../viewmodels/stock_view_model.dart';
import 'booking_edit_screen.dart';
import '../../models/formula_model.dart';
import '../widgets/booking_calendar_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Charger les réservations de test au chargement de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookingViewModel = Provider.of<BookingViewModel>(
        context,
        listen: false,
      );
      final activityFormulaViewModel = Provider.of<ActivityFormulaViewModel>(
        context,
        listen: false,
      );
      final stockViewModel = Provider.of<StockViewModel>(
        context,
        listen: false,
      );

      // Vérifier si les activités/formules sont déjà chargées, sinon les charger
      if (activityFormulaViewModel.formulas.isEmpty) {
        activityFormulaViewModel.loadDummyData();
      }

      // Vérifier si les données de stock sont déjà chargées, sinon les charger
      if (stockViewModel.items.isEmpty) {
        stockViewModel.loadDummyData();
      }

      if (bookingViewModel.bookings.isEmpty) {
        bookingViewModel.loadDummyBookings();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Laser Magique')),
      body: const BookingCalendarWidget(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const BookingEditScreen()),
          );
        },
        tooltip: 'Ajouter une réservation',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddBookingDialog(BuildContext context) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    int numberOfPersons = 1;
    int numberOfGames = 1;

    // Pour la sélection de formule
    final activityFormulaViewModel = Provider.of<ActivityFormulaViewModel>(
      context,
      listen: false,
    );
    Formula? selectedFormula =
        activityFormulaViewModel.formulas.isNotEmpty
            ? activityFormulaViewModel.formulas.first
            : null;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Nouvelle réservation'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'Prénom *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Téléphone',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('Date'),
                          subtitle: Text(
                            DateFormat(
                              'dd MMMM yyyy',
                              'fr_FR',
                            ).format(selectedDate),
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                        ),
                        ListTile(
                          title: const Text('Heure'),
                          subtitle: Text(selectedTime.format(context)),
                          trailing: const Icon(Icons.access_time),
                          onTap: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (pickedTime != null) {
                              setState(() {
                                selectedTime = pickedTime;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        // Sélection de formule
                        if (activityFormulaViewModel.formulas.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Formule'),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<Formula>(
                                value: selectedFormula,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                                items:
                                    activityFormulaViewModel.formulas
                                        .map(
                                          (
                                            formula,
                                          ) => DropdownMenuItem<Formula>(
                                            value: formula,
                                            child: Text(
                                              '${formula.activity.name} - ${formula.name}',
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedFormula = value;
                                      // Mettre à jour le nombre de parties par défaut si spécifié dans la formule
                                      if (value.defaultGameCount != null) {
                                        numberOfGames = value.defaultGameCount!;
                                      }
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Nombre de personnes'),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<int>(
                                    value: numberOfPersons,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                    ),
                                    items:
                                        List.generate(20, (index) => index + 1)
                                            .map(
                                              (value) => DropdownMenuItem<int>(
                                                value: value,
                                                child: Text(value.toString()),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          numberOfPersons = value;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Nombre de parties'),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<int>(
                                    value: numberOfGames,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                    ),
                                    items:
                                        List.generate(5, (index) => index + 1)
                                            .map(
                                              (value) => DropdownMenuItem<int>(
                                                value: value,
                                                child: Text(value.toString()),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          numberOfGames = value;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () {
                        if (firstNameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Le prénom est obligatoire'),
                            ),
                          );
                          return;
                        }

                        if (selectedFormula == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Veuillez choisir une formule'),
                            ),
                          );
                          return;
                        }

                        final bookingViewModel = Provider.of<BookingViewModel>(
                          context,
                          listen: false,
                        );

                        final dateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        bookingViewModel.addBooking(
                          firstName: firstNameController.text,
                          lastName:
                              lastNameController.text.isEmpty
                                  ? null
                                  : lastNameController.text,
                          dateTime: dateTime,
                          numberOfPersons: numberOfPersons,
                          numberOfGames: numberOfGames,
                          email:
                              emailController.text.isEmpty
                                  ? null
                                  : emailController.text,
                          phone:
                              phoneController.text.isEmpty
                                  ? null
                                  : phoneController.text,
                          formula: selectedFormula!,
                        );

                        Navigator.of(context).pop();
                      },
                      child: const Text('Enregistrer'),
                    ),
                  ],
                ),
          ),
    );
  }
}
