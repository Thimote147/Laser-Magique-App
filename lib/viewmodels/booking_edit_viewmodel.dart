import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/formula_model.dart';
import '../models/payment_model.dart';
import '../models/customer_model.dart';

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
  int get numberOfPersons => _numberOfPersons;
  int get numberOfGames => _numberOfGames;
  Formula? get selectedFormula => _selectedFormula;
  double get depositAmount => _depositAmount;
  PaymentMethod get paymentMethod => _paymentMethod;

  BookingEditViewModel({required this.booking, required this.onSave}) {
    _initializeState();
  }

  void _initializeState() {
    if (booking != null) {
      _selectedCustomer = Customer(
        firstName: booking!.firstName,
        lastName: booking!.lastName,
        email: booking!.email,
        phone: booking!.phone,
      );
      _selectedDate = booking!.dateTime;
      _selectedTime = TimeOfDay(
        hour: booking!.dateTime.hour,
        minute: booking!.dateTime.minute,
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
    _selectedDate = date;
    notifyListeners();
  }

  void setTime(TimeOfDay time) {
    _selectedTime = time;
    notifyListeners();
  }

  void setFormula(Formula? formula) {
    _selectedFormula = formula;
    if (formula?.defaultGameCount != null) {
      _numberOfGames = formula!.defaultGameCount!;
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

    if (_selectedFormula!.minParticipants != null &&
        _numberOfPersons < _selectedFormula!.minParticipants!) {
      return 'Le nombre de participants doit être d\'au moins ${_selectedFormula!.minParticipants} pour cette formule';
    }

    if (_depositAmount > 0) {
      final totalPrice =
          _selectedFormula!.price * _numberOfPersons * _numberOfGames;
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

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final updatedBooking = (booking ??
            Booking(
              id: '',
              firstName: '',
              dateTime: DateTime.now(),
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
          paymentMethod: _paymentMethod,
        );

    onSave(updatedBooking);
  }
}
