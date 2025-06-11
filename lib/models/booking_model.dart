import 'package:uuid/uuid.dart';
import 'formula_model.dart';
import 'payment_model.dart' as payment_model;

class Booking {
  final String id;
  final String firstName;
  final String? lastName;
  final DateTime dateTime;
  final int numberOfPersons;
  final int numberOfGames;
  final String? email;
  final String? phone;
  final Formula formula;
  final bool isCancelled;
  final double deposit;
  final payment_model.PaymentMethod paymentMethod;
  final List<payment_model.Payment> payments;
  final double consumptionsTotal;

  double get formulaPrice => numberOfPersons * numberOfGames * formula.price;
  double get totalPaid =>
      payments.fold(0, (sum, payment) => sum + payment.amount);
  double get totalPrice => formulaPrice + consumptionsTotal;
  double get remainingBalance => totalPrice - totalPaid;

  Booking({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.dateTime,
    required this.numberOfPersons,
    required this.numberOfGames,
    this.email,
    this.phone,
    required this.formula,
    this.isCancelled = false,
    this.deposit = 0.0,
    this.paymentMethod = payment_model.PaymentMethod.card,
    this.payments = const [],
    this.consumptionsTotal = 0.0,
  });

  Booking copyWith({
    String? id,
    String? firstName,
    String? lastName,
    DateTime? dateTime,
    int? numberOfPersons,
    int? numberOfGames,
    String? email,
    String? phone,
    Formula? formula,
    bool? isCancelled,
    double? deposit,
    payment_model.PaymentMethod? paymentMethod,
    List<payment_model.Payment>? payments,
    double? consumptionsTotal,
  }) {
    return Booking(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateTime: dateTime ?? this.dateTime,
      numberOfPersons: numberOfPersons ?? this.numberOfPersons,
      numberOfGames: numberOfGames ?? this.numberOfGames,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      formula: formula ?? this.formula,
      isCancelled: isCancelled ?? this.isCancelled,
      deposit: deposit ?? this.deposit,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      payments: payments ?? this.payments,
      consumptionsTotal: consumptionsTotal ?? this.consumptionsTotal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'dateTime': dateTime.millisecondsSinceEpoch,
      'numberOfPersons': numberOfPersons,
      'numberOfGames': numberOfGames,
      'email': email,
      'phone': phone,
      'formula': formula.toMap(),
      'isCancelled': isCancelled,
      'deposit': deposit,
      'paymentMethod': paymentMethod.index,
      'payments': payments.map((x) => x.toMap()).toList(),
      'consumptionsTotal': consumptionsTotal,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['dateTime']),
      numberOfPersons: map['numberOfPersons'] ?? 1,
      numberOfGames: map['numberOfGames'] ?? 1,
      email: map['email'],
      phone: map['phone'],
      formula: Formula.fromMap(map['formula']),
      isCancelled: map['isCancelled'] ?? false,
      deposit: map['deposit'] ?? 0.0,
      paymentMethod:
          payment_model.PaymentMethod.values[map['paymentMethod'] ?? 0],
      payments: List<payment_model.Payment>.from(
        map['payments']?.map((x) => payment_model.Payment.fromMap(x)) ?? [],
      ),
      consumptionsTotal: map['consumptionsTotal']?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return 'Booking(id: $id, firstName: $firstName, lastName: $lastName, dateTime: $dateTime, numberOfPersons: $numberOfPersons, numberOfGames: $numberOfGames, email: $email, phone: $phone, formula: $formula, isCancelled: $isCancelled, deposit: $deposit, paymentMethod: $paymentMethod, payments: $payments, consumptionsTotal: $consumptionsTotal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Booking &&
        other.id == id &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.dateTime == dateTime &&
        other.numberOfPersons == numberOfPersons &&
        other.numberOfGames == numberOfGames &&
        other.email == email &&
        other.phone == phone &&
        other.formula == formula &&
        other.isCancelled == isCancelled &&
        other.deposit == deposit &&
        other.paymentMethod == paymentMethod &&
        other.consumptionsTotal == consumptionsTotal;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        firstName.hashCode ^
        lastName.hashCode ^
        dateTime.hashCode ^
        numberOfPersons.hashCode ^
        numberOfGames.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        formula.hashCode ^
        isCancelled.hashCode ^
        deposit.hashCode ^
        paymentMethod.hashCode ^
        consumptionsTotal.hashCode;
  }
}
