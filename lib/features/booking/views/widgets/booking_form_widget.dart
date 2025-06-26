import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../../../shared/models/formula_model.dart';
import '../../models/customer_model.dart';
import '../../../../shared/models/payment_model.dart';
import '../../../../shared/utils/price_utils.dart';

import '../../../../shared/viewmodels/activity_formula_view_model.dart';
import '../../viewmodels/booking_edit_viewmodel.dart';
import '../../viewmodels/customer_view_model.dart';
import 'customer_selection_widget.dart';

class BookingFormWidget extends StatefulWidget {
  final Booking? booking;
  final VoidCallback? onSubmit;

  const BookingFormWidget({super.key, this.booking, this.onSubmit});

  @override
  State<BookingFormWidget> createState() => _BookingFormWidgetState();
}

class _BookingFormWidgetState extends State<BookingFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  late int numberOfPersons;
  late int numberOfGames;
  Customer? selectedCustomer;
  bool _isCreatingCustomer = false;
  double _deposit = 0.0;
  PaymentMethod _depositPaymentMethod = PaymentMethod.transfer;

  final _depositController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    if (widget.booking != null) {
      // Vérifier que tous les champs requis sont présents
      if (widget.booking!.lastName == null ||
          widget.booking!.email == null ||
          widget.booking!.phone == null) {
        throw StateError('Les informations du client sont incomplètes');
      }

      selectedCustomer = Customer(
        firstName: widget.booking!.firstName,
        lastName: widget.booking!.lastName!,
        email: widget.booking!.email!,
        phone: widget.booking!.phone!,
      );
      selectedDate = widget.booking!.dateTime;
      selectedTime = TimeOfDay(
        hour: widget.booking!.dateTime.hour,
        minute: widget.booking!.dateTime.minute,
      );
      numberOfPersons = widget.booking!.numberOfPersons;
      numberOfGames = widget.booking!.numberOfGames;

      // Mise à jour des valeurs monétaires
      _deposit = widget.booking!.deposit;
      _depositController.text = _deposit.toString();
      _depositPaymentMethod = widget.booking!.paymentMethod;

      // Synchronisation initiale avec le ViewModel
      final bookingEditViewModel = context.read<BookingEditViewModel>();
      bookingEditViewModel.setFormula(widget.booking!.formula);
    } else {
      selectedDate = DateTime.now();
      selectedTime = TimeOfDay.now();
      numberOfPersons = 1;
      numberOfGames = 1;
    }

    // Planifier l'initialisation de la formule après la construction
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activityFormulaViewModel = context.read<ActivityFormulaViewModel>();
      final bookingEditViewModel = context.read<BookingEditViewModel>();

      // Initialise la formule si nécessaire
      if (bookingEditViewModel.selectedFormula == null &&
          activityFormulaViewModel.formulas.isNotEmpty) {
        final firstFormula = activityFormulaViewModel.formulas.first;
        _adjustValuesToFormula(firstFormula);
      }
    });
  }

  @override
  void dispose() {
    _depositController.dispose();
    super.dispose();
  }

  Future<void> _showAdaptiveDatePicker(BuildContext context) async {
    final bookingEditViewModel = context.read<BookingEditViewModel>();

    if (Platform.isIOS) {
      await showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 216,
            padding: const EdgeInsets.only(top: 6.0),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: SafeArea(
              top: false,
              child: CupertinoDatePicker(
                initialDateTime: selectedDate,
                minimumDate: DateTime.now(),
                maximumDate: DateTime.now().add(const Duration(days: 365)),
                mode: CupertinoDatePickerMode.date,
                onDateTimeChanged: (DateTime newDate) {
                  setState(() => selectedDate = newDate);
                  bookingEditViewModel.setDate(newDate);
                },
              ),
            ),
          );
        },
      );
    } else {
      final pickedDate = await showDatePicker(
        context: context,
        locale: const Locale('fr', 'FR'),
        initialDate: selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (pickedDate != null) {
        setState(() => selectedDate = pickedDate);
        bookingEditViewModel.setDate(pickedDate);
      }
    }
  }

  Future<void> _showAdaptiveTimePicker(BuildContext context) async {
    final bookingEditViewModel = context.read<BookingEditViewModel>();

    if (Platform.isIOS) {
      await showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 216,
            padding: const EdgeInsets.only(top: 6.0),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: SafeArea(
              top: false,
              child: CupertinoDatePicker(
                initialDateTime: DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                ),
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                onDateTimeChanged: (DateTime newDateTime) {
                  final newTime = TimeOfDay(
                    hour: newDateTime.hour,
                    minute: newDateTime.minute,
                  );
                  setState(() => selectedTime = newTime);
                  bookingEditViewModel.setTime(newTime);
                },
              ),
            ),
          );
        },
      );
    } else {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: selectedTime,
      );
      if (pickedTime != null) {
        setState(() => selectedTime = pickedTime);
        bookingEditViewModel.setTime(pickedTime);
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final bookingEditViewModel = context.read<BookingEditViewModel>();

      // Validate formula
      if (bookingEditViewModel.selectedFormula == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une formule'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate participants
      final minPersons =
          bookingEditViewModel.selectedFormula!.minParticipants ?? 1;
      final maxPersons = bookingEditViewModel.selectedFormula!.maxParticipants;

      if (numberOfPersons < minPersons) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Minimum $minPersons personne(s) requis'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (maxPersons != null && numberOfPersons > maxPersons) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximum $maxPersons personne(s) autorisé'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Update state in view model
      bookingEditViewModel
        ..setNumberOfPersons(numberOfPersons)
        ..setNumberOfGames(numberOfGames)
        ..setDepositAmount(_deposit)
        ..setPaymentMethod(_depositPaymentMethod)
        ..save();

      if (widget.onSubmit != null) {
        widget.onSubmit!();
      }
    }
  }

  void _adjustValuesToFormula(Formula formula, {bool silentMode = false}) {
    // Ajuster le nombre de personnes si nécessaire
    if (numberOfPersons < formula.minParticipants) {
      setState(() => numberOfPersons = formula.minParticipants);
    } else if (formula.maxParticipants != null &&
        numberOfPersons > formula.maxParticipants!) {
      setState(() => numberOfPersons = formula.maxParticipants!);
    }

    // Ajuster le nombre de parties si nécessaire
    if (numberOfGames < formula.minGames) {
      setState(() => numberOfGames = formula.minGames);
    } else if (formula.maxGames != null && numberOfGames > formula.maxGames!) {
      setState(() => numberOfGames = formula.maxGames!);
    }

    // Mettre à jour le ViewModel avec les nouvelles valeurs
    final bookingEditViewModel = context.read<BookingEditViewModel>();
    bookingEditViewModel
      ..setFormula(formula)
      ..setNumberOfPersons(numberOfPersons)
      ..setNumberOfGames(numberOfGames);
  }

  Widget _buildFormulaSelector(
    ActivityFormulaViewModel activityFormulaViewModel,
    BookingEditViewModel bookingEditViewModel,
  ) {
    if (activityFormulaViewModel.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Chargement des formules...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final formulas = activityFormulaViewModel.formulas;
    if (formulas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Aucune formule disponible',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Formula>(
              value: bookingEditViewModel.selectedFormula,
              isExpanded: true,
              isDense: true,
              icon: const Icon(Icons.expand_more_rounded, size: 20),
              hint: Text(
                'Sélectionnez une formule',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              items:
                  formulas
                      .map(
                        (formula) => DropdownMenuItem(
                          value: formula,
                          child: Text(
                            '${formula.activity.name} - ${formula.name}',
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (Formula? value) {
                if (value != null) {
                  _adjustValuesToFormula(value);
                }
              },
            ),
          ),
        ),
        if (bookingEditViewModel.selectedFormula != null) ...[
          const SizedBox(width: 12),
          Text(
            '${bookingEditViewModel.selectedFormula!.price.toStringAsFixed(2)}€',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingEditViewModel = context.watch<BookingEditViewModel>();
    final activityFormulaViewModel = context.watch<ActivityFormulaViewModel>();

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    _isCreatingCustomer
                        ? Icons.person_add_rounded
                        : Icons.person_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isCreatingCustomer
                        ? 'Nouveau client'
                        : 'Informations client',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
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
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (selectedCustomer != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${selectedCustomer!.firstName} ${selectedCustomer!.lastName ?? ''}'
                                      .trim(),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (selectedCustomer!.email != null ||
                                    selectedCustomer!.phone != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Wrap(
                                      spacing: 12,
                                      runSpacing: 4,
                                      children: [
                                        if (selectedCustomer!.email != null)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.email_rounded,
                                                size: 14,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                selectedCustomer!.email!,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.copyWith(
                                                  color:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (selectedCustomer!.phone != null)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.phone_rounded,
                                                size: 14,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                selectedCustomer!.phone!,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.copyWith(
                                                  color:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
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
                          IconButton.outlined(
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            tooltip: 'Modifier le client',
                            onPressed: () {
                              setState(() {
                                selectedCustomer = null;
                              });
                              bookingEditViewModel.setCustomer(null);
                            },
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(6),
                              foregroundColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child:
                        selectedCustomer == null
                            ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: CustomerSelectionWidget(
                                initialCustomer: selectedCustomer,
                                onCustomerSelected: (customer) {
                                  setState(() {
                                    selectedCustomer = customer;
                                  });
                                  bookingEditViewModel.setCustomer(customer);
                                },
                              ),
                            )
                            : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Date et heure',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
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
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showAdaptiveDatePicker(context),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceVariant.withOpacity(0.3),
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
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat.yMMMMd(
                                    'fr_FR',
                                  ).format(selectedDate),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _showAdaptiveTimePicker(context),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Heure',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedTime.format(context),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
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
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.sports_esports_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Détails de l\'activité',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
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
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Formule',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          _buildFormulaSelector(
                            activityFormulaViewModel,
                            bookingEditViewModel,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Nombre de personnes et parties
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Personnes',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton.filled(
                                      icon: const Icon(Icons.remove, size: 16),
                                      style: IconButton.styleFrom(
                                        minimumSize: const Size(36, 36),
                                        padding: EdgeInsets.zero,
                                        backgroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                        foregroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                      ),
                                      onPressed:
                                          numberOfPersons >
                                                  (bookingEditViewModel
                                                          .selectedFormula
                                                          ?.minParticipants ??
                                                      1)
                                              ? () {
                                                setState(
                                                  () => numberOfPersons--,
                                                );
                                                bookingEditViewModel
                                                    .setNumberOfPersons(
                                                      numberOfPersons,
                                                    );
                                              }
                                              : null,
                                    ),
                                    Expanded(
                                      child: Text(
                                        numberOfPersons.toString(),
                                        textAlign: TextAlign.center,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                      ),
                                    ),
                                    IconButton.filled(
                                      icon: const Icon(Icons.add, size: 16),
                                      style: IconButton.styleFrom(
                                        minimumSize: const Size(36, 36),
                                        padding: EdgeInsets.zero,
                                        backgroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                        foregroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                      ),
                                      onPressed:
                                          bookingEditViewModel
                                                          .selectedFormula
                                                          ?.maxParticipants ==
                                                      null ||
                                                  numberOfPersons <
                                                      bookingEditViewModel
                                                          .selectedFormula!
                                                          .maxParticipants!
                                              ? () {
                                                setState(
                                                  () => numberOfPersons++,
                                                );
                                                bookingEditViewModel
                                                    .setNumberOfPersons(
                                                      numberOfPersons,
                                                    );
                                              }
                                              : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Parties',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton.filled(
                                      icon: const Icon(Icons.remove, size: 16),
                                      style: IconButton.styleFrom(
                                        minimumSize: const Size(36, 36),
                                        padding: EdgeInsets.zero,
                                        backgroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                        foregroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                      ),
                                      onPressed:
                                          numberOfGames >
                                                  (bookingEditViewModel
                                                          .selectedFormula
                                                          ?.minGames ??
                                                      1)
                                              ? () {
                                                setState(() => numberOfGames--);
                                                bookingEditViewModel
                                                    .setNumberOfGames(
                                                      numberOfGames,
                                                    );
                                              }
                                              : null,
                                    ),
                                    Expanded(
                                      child: Text(
                                        numberOfGames.toString(),
                                        textAlign: TextAlign.center,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                      ),
                                    ),
                                    IconButton.filled(
                                      icon: const Icon(Icons.add, size: 16),
                                      style: IconButton.styleFrom(
                                        minimumSize: const Size(36, 36),
                                        padding: EdgeInsets.zero,
                                        backgroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                        foregroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                      ),
                                      onPressed:
                                          bookingEditViewModel
                                                          .selectedFormula
                                                          ?.maxGames ==
                                                      null ||
                                                  numberOfGames <
                                                      bookingEditViewModel
                                                          .selectedFormula!
                                                          .maxGames!
                                              ? () {
                                                setState(() => numberOfGames++);
                                                bookingEditViewModel
                                                    .setNumberOfGames(
                                                      numberOfGames,
                                                    );
                                              }
                                              : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (bookingEditViewModel.selectedFormula != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '${calculateTotalPrice(bookingEditViewModel.selectedFormula?.price ?? 0, numberOfGames, numberOfPersons).toStringAsFixed(2)}€',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.payments_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Acompte',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
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
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Montant de l'acompte
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 12,
                              right: 12,
                              top: 8,
                            ),
                            child: Text(
                              'Montant',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: _depositController,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.fromLTRB(
                                12,
                                4,
                                12,
                                8,
                              ),
                              prefixText: '€ ',
                              prefixStyle: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (value) {
                              final depositValue =
                                  double.tryParse(value) ?? 0.0;
                              setState(() => _deposit = depositValue);
                              bookingEditViewModel.setDepositAmount(
                                depositValue,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Moyen de paiement
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'Paiement',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _PaymentMethodButton(
                                label: 'Virement',
                                icon: Icons.account_balance_rounded,
                                isSelected:
                                    _depositPaymentMethod ==
                                    PaymentMethod.transfer,
                                onPressed: () {
                                  setState(
                                    () =>
                                        _depositPaymentMethod =
                                            PaymentMethod.transfer,
                                  );
                                  bookingEditViewModel.setPaymentMethod(
                                    PaymentMethod.transfer,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _PaymentMethodButton(
                                label: 'Carte',
                                icon: Icons.credit_card_rounded,
                                isSelected:
                                    _depositPaymentMethod == PaymentMethod.card,
                                onPressed: () {
                                  setState(
                                    () =>
                                        _depositPaymentMethod =
                                            PaymentMethod.card,
                                  );
                                  bookingEditViewModel.setPaymentMethod(
                                    PaymentMethod.card,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _PaymentMethodButton(
                                label: 'Espèces',
                                icon: Icons.euro_rounded,
                                isSelected:
                                    _depositPaymentMethod == PaymentMethod.cash,
                                onPressed: () {
                                  setState(
                                    () =>
                                        _depositPaymentMethod =
                                            PaymentMethod.cash,
                                  );
                                  bookingEditViewModel.setPaymentMethod(
                                    PaymentMethod.cash,
                                  );
                                },
                              ),
                            ),
                          ],
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
    );
  }
}

class _PaymentMethodButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onPressed;

  const _PaymentMethodButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color:
                    isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade700,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
