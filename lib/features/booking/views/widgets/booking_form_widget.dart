import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../../../shared/models/formula_model.dart';
import '../../models/customer_model.dart';
import '../../../../shared/models/payment_model.dart';

import '../../../../shared/viewmodels/activity_formula_view_model.dart';
import '../../viewmodels/booking_edit_viewmodel.dart';
import 'customer_selection_widget.dart';

class BookingFormWidget extends StatefulWidget {
  final Booking? booking;
  final VoidCallback? onSubmit;
  final DateTime? initialDate;

  const BookingFormWidget({super.key, this.booking, this.onSubmit, this.initialDate});

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
  final bool _isCreatingCustomer = false;
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

      // Synchronisation immédiate avec le ViewModel et vérification des limites
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final bookingEditViewModel = context.read<BookingEditViewModel>();
        _lastCheckedFormula =
            widget
                .booking!
                .formula; // Mémoriser la formule pour éviter la boucle
        bookingEditViewModel.setFormula(widget.booking!.formula);

        // S'assurer que les limites sont correctement appliquées
        _checkAndAdjustLimits(widget.booking!.formula);
      });
    } else {
      // Pour une nouvelle réservation, vérifier si la date initiale est passée
      DateTime initialDate = widget.initialDate ?? DateTime.now();
      
      // Si la date initiale est passée, utiliser aujourd'hui
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final initialDay = DateTime(initialDate.year, initialDate.month, initialDate.day);
      
      if (initialDay.isBefore(today)) {
        initialDate = DateTime.now();
      }
      
      selectedDate = initialDate;
      selectedTime = TimeOfDay.now();
      numberOfPersons = 1;
      numberOfGames = 1;
    }

    // Planifier l'initialisation de la formule après la construction (uniquement pour les nouvelles réservations)
    if (widget.booking == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final activityFormulaViewModel =
            context.read<ActivityFormulaViewModel>();
        final bookingEditViewModel = context.read<BookingEditViewModel>();

        // Initialise la formule si nécessaire pour une nouvelle réservation
        if (bookingEditViewModel.selectedFormula == null &&
            activityFormulaViewModel.formulas.isNotEmpty) {
          final firstFormula = activityFormulaViewModel.formulas.first;
          _adjustValuesToFormula(firstFormula);
        }
      });
    }
  }

  @override
  void dispose() {
    _depositController.dispose();
    super.dispose();
  }

  // Variable pour suivre la dernière formule vérifiée et éviter les boucles infinies
  Formula? _lastCheckedFormula;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bookingEditViewModel = context.read<BookingEditViewModel>();

    // Ne vérifier les limites que si la formule a changé depuis la dernière vérification
    if (bookingEditViewModel.selectedFormula != null &&
        (_lastCheckedFormula == null ||
            _lastCheckedFormula!.id !=
                bookingEditViewModel.selectedFormula!.id)) {
      // Utiliser addPostFrameCallback pour exécuter le code après le build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _lastCheckedFormula = bookingEditViewModel.selectedFormula;
          _checkAndAdjustLimits(bookingEditViewModel.selectedFormula!);
        }
      });
    }
  }

  // Vérifier et ajuster les limites en fonction de la formule sélectionnée
  void _checkAndAdjustLimits(Formula formula) {
    bool needsUpdate = false;

    // Vérifier si le nombre de personnes est hors limites
    if (numberOfPersons < formula.minParticipants) {
      numberOfPersons = formula.minParticipants;
      needsUpdate = true;
    } else if (formula.maxParticipants != null &&
        numberOfPersons > formula.maxParticipants!) {
      numberOfPersons = formula.maxParticipants!;
      needsUpdate = true;
    }

    // Vérifier si le nombre de parties est hors limites
    if (numberOfGames < formula.minGames) {
      numberOfGames = formula.minGames;
      needsUpdate = true;
    } else if (formula.maxGames != null && numberOfGames > formula.maxGames!) {
      numberOfGames = formula.maxGames!;
      needsUpdate = true;
    }

    // N'appeler setState que si quelque chose a changé
    if (needsUpdate) {
      setState(() {});

      final bookingEditViewModel = context.read<BookingEditViewModel>();
      // Mettre à jour le ViewModel
      bookingEditViewModel
        ..setNumberOfPersons(numberOfPersons)
        ..setNumberOfGames(numberOfGames);
    }
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

  void _adjustValuesToFormula(Formula formula) {
    bool needsUpdate = false;

    // Ajuster le nombre de personnes si nécessaire
    if (numberOfPersons < formula.minParticipants) {
      numberOfPersons = formula.minParticipants;
      needsUpdate = true;
    } else if (formula.maxParticipants != null &&
        numberOfPersons > formula.maxParticipants!) {
      numberOfPersons = formula.maxParticipants!;
      needsUpdate = true;
    }

    // Ajuster le nombre de parties si nécessaire
    if (numberOfGames < formula.minGames) {
      numberOfGames = formula.minGames;
      needsUpdate = true;
    } else if (formula.maxGames != null && numberOfGames > formula.maxGames!) {
      numberOfGames = formula.maxGames!;
      needsUpdate = true;
    }

    // N'appeler setState que si quelque chose a changé
    if (needsUpdate) {
      setState(() {
        // Les valeurs ont déjà été mises à jour ci-dessus
      });
    }

    // Mettre à jour le ViewModel avec les nouvelles valeurs et mémoriser la formule pour éviter les boucles
    final bookingEditViewModel = context.read<BookingEditViewModel>();

    // Mémoriser la formule pour éviter le déclenchement infini de didChangeDependencies
    _lastCheckedFormula = formula;

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
              value:
                  bookingEditViewModel.selectedFormula != null
                      ? formulas.firstWhere(
                        (f) => f.id == bookingEditViewModel.selectedFormula!.id,
                        orElse: () => bookingEditViewModel.selectedFormula!,
                      )
                      : null,
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
                  // Toujours ajuster les valeurs lors du changement de formule
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
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withAlpha((255 * 0.2).round()),
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
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withAlpha((255 * 0.5).round()),
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
                                  '${selectedCustomer!.firstName} ${selectedCustomer!.lastName}'
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
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    children: [
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
                                            selectedCustomer!.email,
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
                                            selectedCustomer!.phone,
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
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withAlpha((255 * 0.2).round()),
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
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withAlpha((255 * 0.3).round()),
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
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withAlpha((255 * 0.3).round()),
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
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withAlpha((255 * 0.2).round()),
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
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withAlpha((255 * 0.3).round()),
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withAlpha((255 * 0.3).round()),
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
                                          bookingEditViewModel.numberOfPersons >
                                                  (bookingEditViewModel
                                                          .selectedFormula
                                                          ?.minParticipants ??
                                                      1)
                                              ? () {
                                                final newValue =
                                                    bookingEditViewModel
                                                        .numberOfPersons -
                                                    1;
                                                setState(
                                                  () =>
                                                      numberOfPersons =
                                                          newValue,
                                                );
                                                bookingEditViewModel
                                                    .setNumberOfPersons(
                                                      newValue,
                                                    );
                                              }
                                              : null,
                                    ),
                                    Expanded(
                                      child: Text(
                                        bookingEditViewModel.numberOfPersons
                                            .toString(),
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
                                                  bookingEditViewModel
                                                          .numberOfPersons <
                                                      bookingEditViewModel
                                                          .selectedFormula!
                                                          .maxParticipants!
                                              ? () {
                                                final newValue =
                                                    bookingEditViewModel
                                                        .numberOfPersons +
                                                    1;
                                                setState(
                                                  () =>
                                                      numberOfPersons =
                                                          newValue,
                                                );
                                                bookingEditViewModel
                                                    .setNumberOfPersons(
                                                      newValue,
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withAlpha((255 * 0.3).round()),
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
                                          bookingEditViewModel.numberOfGames >
                                                  (bookingEditViewModel
                                                          .selectedFormula
                                                          ?.minGames ??
                                                      1)
                                              ? () {
                                                final newValue =
                                                    bookingEditViewModel
                                                        .numberOfGames -
                                                    1;
                                                setState(
                                                  () =>
                                                      numberOfGames = newValue,
                                                );
                                                bookingEditViewModel
                                                    .setNumberOfGames(newValue);
                                              }
                                              : null,
                                    ),
                                    Expanded(
                                      child: Text(
                                        bookingEditViewModel.numberOfGames
                                            .toString(),
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
                                                  bookingEditViewModel
                                                          .numberOfGames <
                                                      bookingEditViewModel
                                                          .selectedFormula!
                                                          .maxGames!
                                              ? () {
                                                final newValue =
                                                    bookingEditViewModel
                                                        .numberOfGames +
                                                    1;
                                                setState(
                                                  () =>
                                                      numberOfGames = newValue,
                                                );
                                                bookingEditViewModel
                                                    .setNumberOfGames(newValue);
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
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withAlpha((255 * 0.3).round()),
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
                              '${bookingEditViewModel.totalPrice.toStringAsFixed(2)}€',
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
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withAlpha((255 * 0.2).round()),
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
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withAlpha((255 * 0.3).round()),
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
                              suffixText: '€ ',
                              suffixStyle: Theme.of(context)
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
                ? Theme.of(
                  context,
                ).colorScheme.primary.withAlpha((255 * 0.1).round())
                : Theme.of(context).colorScheme.surfaceContainerHighest
                    .withAlpha((255 * 0.3).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                    context,
                  ).colorScheme.outline.withAlpha((255 * 0.3).round()),
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
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
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
