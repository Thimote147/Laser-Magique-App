import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/formula_model.dart';
import '../models/payment_model.dart';

class BookingEditViewModel extends ChangeNotifier {
  final Booking? booking;
  final Function(Booking) onSave;

  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  int _numberOfPersons = 1;
  int _numberOfGames = 1;
  Formula? _selectedFormula;
  double _depositAmount = 0.0;
  PaymentMethod _paymentMethod = PaymentMethod.card;

  String get firstName => _firstName;
  String get lastName => _lastName;
  String get email => _email;
  String get phone => _phone;
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
      _firstName = booking!.firstName;
      _lastName = booking!.lastName ?? '';
      _email = booking!.email ?? '';
      _phone = booking!.phone ?? '';
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

  void setFirstName(String value) {
    _firstName = value;
    notifyListeners();
  }

  void setLastName(String value) {
    _lastName = value;
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }

  void setPhone(String value) {
    _phone = value;
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
      notifyListeners();
    }
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
    if (_firstName.isEmpty) {
      return 'Le prénom est obligatoire';
    }

    if (_selectedFormula == null) {
      return 'Veuillez sélectionner une formule';
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
          firstName: _firstName,
          lastName: _lastName.isEmpty ? null : _lastName,
          dateTime: dateTime,
          numberOfPersons: _numberOfPersons,
          numberOfGames: _numberOfGames,
          email: _email.isEmpty ? null : _email,
          phone: _phone.isEmpty ? null : _phone,
          formula: _selectedFormula!,
          deposit: _depositAmount,
          paymentMethod: _paymentMethod,
        );

    onSave(updatedBooking);
  }
}
