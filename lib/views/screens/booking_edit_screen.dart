import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../models/formula_model.dart';
import '../../viewmodels/activity_formula_view_model.dart';
import '../../viewmodels/booking_view_model.dart';

class BookingEditScreen extends StatefulWidget {
  final Booking? booking;

  const BookingEditScreen({super.key, this.booking});

  @override
  State<BookingEditScreen> createState() => _BookingEditScreenState();
}

class _BookingEditScreenState extends State<BookingEditScreen> {
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  late int numberOfPersons;
  late int numberOfGames;
  Formula? selectedFormula;

  @override
  void initState() {
    super.initState();
    final booking = widget.booking;

    // Initialiser les contrôleurs avec les valeurs existantes ou vides
    firstNameController = TextEditingController(text: booking?.firstName ?? '');
    lastNameController = TextEditingController(text: booking?.lastName ?? '');
    emailController = TextEditingController(text: booking?.email ?? '');
    phoneController = TextEditingController(text: booking?.phone ?? '');

    // Initialiser la date et l'heure
    if (booking != null) {
      selectedDate = booking.dateTime;
      selectedTime = TimeOfDay(
        hour: booking.dateTime.hour,
        minute: booking.dateTime.minute,
      );
      numberOfPersons = booking.numberOfPersons;
      numberOfGames = booking.numberOfGames;
      selectedFormula = booking.formula;
    } else {
      selectedDate = DateTime.now();
      selectedTime = TimeOfDay.now();
      numberOfPersons = 1;
      numberOfGames = 1;
    }

    // Si c'est une nouvelle réservation, on va chercher la première formule disponible
    if (selectedFormula == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final formulas =
            Provider.of<ActivityFormulaViewModel>(
              context,
              listen: false,
            ).formulas;
        if (formulas.isNotEmpty) {
          setState(() {
            selectedFormula = formulas.first;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activityFormulaViewModel = Provider.of<ActivityFormulaViewModel>(
      context,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.booking != null
              ? 'Modifier la réservation'
              : 'Nouvelle réservation',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.booking?.isCancelled ?? false)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red.shade400),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Réservation annulée',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom *',
                        hintText: 'Entrez le prénom',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        hintText: 'Entrez le nom',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Entrez l\'email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        hintText: 'Entrez le numéro de téléphone',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
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
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                  ),
                  const Divider(height: 1),
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Formule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (activityFormulaViewModel.formulas.isNotEmpty)
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
                                  (formula) => DropdownMenuItem<Formula>(
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
                              if (value.defaultGameCount != null) {
                                numberOfGames = value.defaultGameCount!;
                              }
                            });
                          }
                        },
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nombre de personnes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                              const Text(
                                'Nombre de parties',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _saveBooking,
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveBooking() {
    if (firstNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le prénom est obligatoire')),
      );
      return;
    }

    if (selectedFormula == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une formule')),
      );
      return;
    }

    final dateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    final bookingViewModel = Provider.of<BookingViewModel>(
      context,
      listen: false,
    );

    if (widget.booking != null) {
      // Mise à jour d'une réservation existante
      bookingViewModel.updateBooking(
        widget.booking!.copyWith(
          firstName: firstNameController.text,
          lastName:
              lastNameController.text.isEmpty ? null : lastNameController.text,
          dateTime: dateTime,
          numberOfPersons: numberOfPersons,
          numberOfGames: numberOfGames,
          email: emailController.text.isEmpty ? null : emailController.text,
          phone: phoneController.text.isEmpty ? null : phoneController.text,
          formula: selectedFormula!,
        ),
      );
    } else {
      // Création d'une nouvelle réservation
      bookingViewModel.addBooking(
        firstName: firstNameController.text,
        lastName:
            lastNameController.text.isEmpty ? null : lastNameController.text,
        dateTime: dateTime,
        numberOfPersons: numberOfPersons,
        numberOfGames: numberOfGames,
        email: emailController.text.isEmpty ? null : emailController.text,
        phone: phoneController.text.isEmpty ? null : phoneController.text,
        formula: selectedFormula!,
      );
    }

    Navigator.of(context).pop();
  }
}
