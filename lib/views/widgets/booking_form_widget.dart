import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../models/formula_model.dart';
import '../../viewmodels/booking_view_model.dart';
import '../../viewmodels/activity_formula_view_model.dart';

class BookingFormWidget extends StatefulWidget {
  final Booking? booking;

  const BookingFormWidget({super.key, this.booking});

  @override
  State<BookingFormWidget> createState() => _BookingFormWidgetState();
}

class _BookingFormWidgetState extends State<BookingFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  late int numberOfPersons;
  late int numberOfGames;
  Formula? selectedFormula;

  @override
  void initState() {
    super.initState();
    // Initialiser avec les valeurs de la réservation existante ou des valeurs par défaut
    if (widget.booking != null) {
      firstNameController.text = widget.booking!.firstName;
      lastNameController.text = widget.booking!.lastName ?? '';
      emailController.text = widget.booking!.email ?? '';
      phoneController.text = widget.booking!.phone ?? '';
      selectedDate = widget.booking!.dateTime;
      selectedTime = TimeOfDay(
        hour: widget.booking!.dateTime.hour,
        minute: widget.booking!.dateTime.minute,
      );
      numberOfPersons = widget.booking!.numberOfPersons;
      numberOfGames = widget.booking!.numberOfGames;
      selectedFormula = widget.booking!.formula;
    } else {
      selectedDate = DateTime.now();
      selectedTime = TimeOfDay.now();
      numberOfPersons = 1;
      numberOfGames = 1;
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
    final activityFormulaViewModel = context.watch<ActivityFormulaViewModel>();

    if (selectedFormula == null &&
        activityFormulaViewModel.formulas.isNotEmpty) {
      selectedFormula = activityFormulaViewModel.formulas.first;
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: firstNameController,
              decoration: const InputDecoration(
                labelText: 'Prénom *',
                hintText: 'Entrez le prénom',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le prénom est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: lastNameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                hintText: 'Entrez le nom',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Entrez l\'email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                hintText: 'Entrez le numéro de téléphone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Date'),
              subtitle: Text(DateFormat.yMMMMd('fr_FR').format(selectedDate)),
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
                  setState(() => selectedDate = pickedDate);
                }
              },
            ),
            const SizedBox(height: 8),
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
                  setState(() => selectedTime = pickedTime);
                }
              },
            ),
            const SizedBox(height: 16),
            if (activityFormulaViewModel.formulas.isNotEmpty)
              DropdownButtonFormField<Formula>(
                value: selectedFormula,
                decoration: const InputDecoration(
                  labelText: 'Formule',
                  border: OutlineInputBorder(),
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
                  child: DropdownButtonFormField<int>(
                    value: numberOfPersons,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de personnes',
                      border: OutlineInputBorder(),
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
                        setState(() => numberOfPersons = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: numberOfGames,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de parties',
                      border: OutlineInputBorder(),
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
                        setState(() => numberOfGames = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitForm,
              child: Text(
                widget.booking == null
                    ? 'Créer la réservation'
                    : 'Enregistrer les modifications',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<BookingViewModel>();
    final dateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (widget.booking == null) {
      // Création d'une nouvelle réservation
      viewModel.addBooking(
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
    } else {
      // Modification d'une réservation existante
      viewModel.updateBooking(
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
    }

    Navigator.pop(context);
  }
}
