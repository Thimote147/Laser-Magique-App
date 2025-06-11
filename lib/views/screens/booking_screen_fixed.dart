// filepath: /Users/thimotefetu/Sites/Laser-Magique-App/lib/views/screens/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/booking_view_model.dart';
import '../../viewmodels/activity_formula_view_model.dart';
import '../../models/formula_model.dart';
import '../widgets/booking_calendar_widget.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialisez les réservations de test au chargement de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<BookingViewModel>(context, listen: false);

      // Charger uniquement les réservations de démonstration si nécessaire
      if (viewModel.bookings.isEmpty) {
        viewModel.loadDummyBookings();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Réservations')),
      body: const BookingCalendarWidget(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBookingDialog(context),
        tooltip: 'Ajouter une réservation',
        child: const Icon(Icons.add),
      ),
    );
  }

  List<DropdownMenuItem<int>> _generateGamesDropdownItems(Formula? formula) {
    int minGames = 1;
    int maxGames = 5; // Par défaut, maximum 5 parties

    if (formula != null) {
      // Appliquer les restrictions de la formule
      if (formula.minGameCount != null) {
        minGames = formula.minGameCount!;
      }

      if (formula.maxGameCount != null) {
        maxGames = formula.maxGameCount!;
      }

      // Si le nombre de parties est fixe, n'afficher que cette valeur
      if (formula.fixedGameCount == true && formula.defaultGameCount != null) {
        minGames = formula.defaultGameCount!;
        maxGames = formula.defaultGameCount!;
      }
    }

    return List.generate(maxGames - minGames + 1, (index) => index + minGames)
        .map(
          (value) => DropdownMenuItem<int>(
            value: value,
            child: Text(value.toString()),
          ),
        )
        .toList();
  }

  List<DropdownMenuItem<int>> _generatePersonsDropdownItems(Formula? formula) {
    int minPersons = 1;
    int maxPersons = 20; // Par défaut, maximum 20 personnes

    if (formula != null) {
      // Appliquer les restrictions de la formule
      if (formula.minParticipants != null) {
        minPersons = formula.minParticipants!;
      }

      if (formula.maxParticipants != null) {
        maxPersons = formula.maxParticipants!;
      }
    }

    return List.generate(
          maxPersons - minPersons + 1,
          (index) => index + minPersons,
        )
        .map(
          (value) => DropdownMenuItem<int>(
            value: value,
            child: Text(value.toString()),
          ),
        )
        .toList();
  }

  void _showAddBookingDialog(BuildContext context) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    // Pour la sélection de formule
    final activityFormulaViewModel = Provider.of<ActivityFormulaViewModel>(
      context,
      listen: false,
    );
    Formula? selectedFormula =
        activityFormulaViewModel.formulas.isNotEmpty
            ? activityFormulaViewModel.formulas.first
            : null;

    // Initialiser le nombre de personnes et de parties selon les restrictions de la formule par défaut
    int numberOfPersons = selectedFormula?.minParticipants ?? 1;
    int numberOfGames = selectedFormula?.defaultGameCount ?? 1;

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
                            hintText: 'Entrez le prénom',
                          ),
                        ),
                        TextField(
                          controller: lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom',
                            hintText: 'Entrez le nom',
                          ),
                        ),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Entrez l\'email',
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        TextField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Téléphone',
                            hintText: 'Entrez le numéro de téléphone',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        ListTile(
                          title: const Text('Date'),
                          subtitle: Text(
                            DateFormat.yMMMMd('fr_FR').format(selectedDate),
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              locale: const Locale('fr', 'FR'),
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
                                            // Utiliser un simple Text au lieu d'une structure complexe
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${formula.activity.name} - ${formula.name}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '${formula.price.toStringAsFixed(2)}€',
                                                  style: TextStyle(
                                                    color: Colors.blue.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedFormula = value;

                                      // Mettre à jour le nombre de parties en fonction de la formule
                                      if (value.fixedGameCount == true &&
                                          value.defaultGameCount != null) {
                                        // Si le nombre de parties est fixe, utiliser le defaultGameCount
                                        numberOfGames = value.defaultGameCount!;
                                      } else if (value.defaultGameCount !=
                                          null) {
                                        // Sinon utiliser le nombre par défaut
                                        numberOfGames = value.defaultGameCount!;
                                      }

                                      // Ajuster le nombre de personnes si nécessaire
                                      if (value.minParticipants != null &&
                                          numberOfPersons <
                                              value.minParticipants!) {
                                        numberOfPersons =
                                            value.minParticipants!;
                                      }
                                    });
                                  }
                                },
                              ),

                              // Afficher les informations sur les limites de la formule sélectionnée
                              if (selectedFormula != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Formule: ${selectedFormula!.name}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (selectedFormula?.description != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            selectedFormula!.description!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Participants: ${selectedFormula?.minParticipants ?? "1"} à ${selectedFormula?.maxParticipants ?? "∞"}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'Parties: ${selectedFormula?.fixedGameCount == true ? "Fixé à " : ""}${selectedFormula?.minGameCount ?? "1"} à ${selectedFormula?.maxGameCount ?? "∞"}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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
                                    items: _generatePersonsDropdownItems(
                                      selectedFormula,
                                    ),
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
                                    items: _generateGamesDropdownItems(
                                      selectedFormula,
                                    ),
                                    onChanged:
                                        selectedFormula?.fixedGameCount == true
                                            ? null // Désactiver si le nombre de parties est fixe
                                            : (value) {
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
