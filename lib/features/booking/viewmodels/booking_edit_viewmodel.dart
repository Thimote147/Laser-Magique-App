import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../../../shared/models/formula_model.dart';
import '../../../shared/models/payment_model.dart';
import '../models/customer_model.dart';
import '../../../shared/utils/price_utils.dart';

/// Manages the state and logic for editing or creating a booking.
///
/// Timezone handling:
/// - All UI interactions use local time zone
/// - Times are converted to UTC when saving to database
/// - When editing an existing booking, UTC times are converted to local for display
///
/// The booking form workflow:
/// 1. User selects date/time in their local timezone
/// 2. ViewModel stores selection as local DateTime
/// 3. On save, local time is converted to UTC for storage
/// 4. When loading a booking for edit, UTC time is converted back to local
///
/// Example:
/// ```dart
/// viewModel.setDate(localDate);  // User's local date
/// viewModel.setTime(localTime);  // User's local time
/// viewModel.save();  // Automatically converts to UTC for storage
/// ```

class BookingEditViewModel extends ChangeNotifier {
  final Booking? booking;
  final Function(Booking) onSave;

  Customer? _selectedCustomer;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  int _numberOfPersons = 1;
  int _numberOfGames = 1;
  Formula? _selectedFormula;
  double _depositAmount = 0.0;
  PaymentMethod _paymentMethod = PaymentMethod.transfer;

  // Getters
  Customer? get selectedCustomer => _selectedCustomer;
  DateTime get selectedDate => _selectedDate;
  TimeOfDay get selectedTime => _selectedTime;
  DateTime get selectedDateTime => DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _selectedTime.hour,
    _selectedTime.minute,
  );
  DateTime get selectedDateTimeUTC => selectedDateTime.toUtc();
  int get numberOfPersons => _numberOfPersons;
  int get numberOfGames => _numberOfGames;
  Formula? get selectedFormula => _selectedFormula;
  double get depositAmount => _depositAmount;
  PaymentMethod get paymentMethod => _paymentMethod;
  double get totalPrice =>
      _selectedFormula != null
          ? calculateTotalPrice(
            _selectedFormula!.price,
            _numberOfGames,
            _numberOfPersons,
          )
          : 0.0;

  BookingEditViewModel({required this.booking, required this.onSave}) {
    _initializeState();
  }

  void _initializeState() {
    if (booking != null) {
      // Vérifier que les champs requis sont présents
      if (booking!.lastName == null ||
          booking!.email == null ||
          booking!.phone == null) {
        throw StateError('Les informations du client sont incomplètes');
      }

      _selectedCustomer = Customer(
        firstName: booking!.firstName,
        lastName: booking!.lastName!,
        email: booking!.email!,
        phone: booking!.phone!,
      );
      // Convert UTC to local time
      final localDateTime = booking!.dateTimeLocal;
      _selectedDate = localDateTime;
      _selectedTime = TimeOfDay(
        hour: localDateTime.hour,
        minute: localDateTime.minute,
      );
      _numberOfPersons = booking!.numberOfPersons;
      _numberOfGames = booking!.numberOfGames;
      _selectedFormula = booking!.formula;
      _depositAmount = booking!.deposit;
      _paymentMethod = booking!.paymentMethod;
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
  }

  void setCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setDate(DateTime date) {
    // Always store and work with local time
    _selectedDate = DateTime(
      date.year,
      date.month,
      date.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    notifyListeners();
  }

  void setTime(TimeOfDay time) {
    // Always store and work with local time
    _selectedTime = time;
    _selectedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      time.hour,
      time.minute,
    );
    notifyListeners();
  }

  void setFormula(Formula formula) {
    _selectedFormula = formula;
    if (formula != null) {
      _numberOfGames = formula.minGames;
    }
    notifyListeners();
  }

  void setNumberOfPersons(int value) {
    _numberOfPersons = value;
    notifyListeners();
  }

  void setNumberOfGames(int value) {
    _numberOfGames = value;
    notifyListeners();
  }

  double _calculateTotal() {
    if (_selectedFormula == null) return 0;
    return calculateTotalPrice(
      _selectedFormula!.price,
      _numberOfGames,
      _numberOfPersons,
    );
  }

  void setDepositAmount(double value) {
    _depositAmount = value;
    notifyListeners();
  }

  void setPaymentMethod(PaymentMethod method) {
    _paymentMethod = method;
    notifyListeners();
  }

  String? validate() {
    if (_selectedCustomer == null) {
      return 'Veuillez sélectionner ou créer un client';
    }

    if (_selectedFormula == null) {
      return 'Veuillez sélectionner une formule';
    }

    if (_numberOfPersons < _selectedFormula!.minParticipants) {
      return 'Le nombre de participants doit être d\'au moins ${_selectedFormula!.minParticipants} pour cette formule';
    }

    if (_depositAmount > 0) {
      final total = calculateTotalPrice(
        _selectedFormula!.price,
        _numberOfGames,
        _numberOfPersons,
      );
      if (_depositAmount > totalPrice) {
        return 'L\'acompte ne peut pas dépasser le montant total';
      }
    }

    return null;
  }

  void save() {
    if (_selectedCustomer == null || _selectedFormula == null) {
      return;
    }

    // Convert to UTC for storage
    final dateTime = selectedDateTimeUTC;

    // Calculer le montant total selon la nouvelle formule
    final totalPrice = calculateTotalPrice(
      _selectedFormula!.price,
      _numberOfGames,
      _numberOfPersons,
    );

    final updatedBooking = (booking ??
            Booking(
              id: '',
              firstName: '',
              dateTime: DateTime.now().toUtc(),
              numberOfPersons: 1,
              numberOfGames: 1,
              formula: _selectedFormula!,
            ))
        .copyWith(
          firstName: _selectedCustomer!.firstName,
          lastName: _selectedCustomer!.lastName,
          dateTime: dateTime,
          numberOfPersons: _numberOfPersons,
          numberOfGames: _numberOfGames,
          email: _selectedCustomer!.email,
          phone: _selectedCustomer!.phone,
          formula: _selectedFormula!,
          deposit: _depositAmount,
          totalPrice: totalPrice,
          paymentMethod: _paymentMethod,
        );

    onSave(updatedBooking);
  }
}
