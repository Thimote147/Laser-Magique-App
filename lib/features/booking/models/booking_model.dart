import '../../../shared/models/formula_model.dart';
import '../../../shared/models/payment_model.dart' as payment_model;
import '../../../shared/utils/price_utils.dart';

class Booking {
  final String id;
  final String firstName;
  final String? lastName;
  // Always stored in UTC
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

  double get formulaPrice =>
      calculateTotalPrice(formula.price, numberOfGames, numberOfPersons);
  double get totalPaid =>
      payments.fold(0, (sum, payment) => sum + payment.amount);
  final double? _totalPrice;
  double get totalPrice => _totalPrice ?? (formulaPrice + consumptionsTotal);
  double get remainingBalance => totalPrice - totalPaid;

  // Always return UTC time
  DateTime get dateTimeUTC => dateTime;

  // Convert UTC to local for display
  DateTime get dateTimeLocal => dateTime.toLocal();

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
    this.paymentMethod = payment_model.PaymentMethod.transfer,
    this.payments = const [],
    this.consumptionsTotal = 0.0,
    double? totalPrice,
  }) : _totalPrice = totalPrice;
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
    double? totalPrice,
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
      totalPrice: totalPrice ?? _totalPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'date_time': dateTimeUTC.toIso8601String(), // Stockage en UTC
      'numberOfPersons': numberOfPersons,
      'numberOfGames': numberOfGames,
      'email': email,
      'phone': phone,
      'formula': formula.toMap(),
      'isCancelled': isCancelled,
      'deposit': deposit,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'payments': payments.map((x) => x.toMap()).toList(),
      'consumptionsTotal': consumptionsTotal,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> formulaMap = map['formula'] ?? {};

    // Si la formule est vide mais que nous avons des champs formula_id, etc.
    if (formulaMap.isEmpty && map['formula_id'] != null) {
      formulaMap = {
        'id': map['formula_id'],
        'activity': {
          'id': map['activity_id'] ?? '',
          'name': map['activity_name'] ?? 'Activité inconnue',
          'description': map['activity_description'] ?? '',
        },
        'name': map['formula_name'] ?? 'Formule inconnue',
        'description': map['formula_description'] ?? '',
        'price':
            map['formula_base_price']?.toDouble() ??
            map['price']?.toDouble() ??
            0.0,
        'min_persons': map['min_persons'] ?? 1,
        'max_persons': map['max_persons'],
        'duration_minutes': map['duration_minutes'] ?? 15,
        'min_games': map['min_games'] ?? 1,
        'max_games': map['max_games'],
      };
    }

    // Ensure we store as UTC
    var dateTime = DateTime.parse(map['date_time']).toUtc();

    return Booking(
      id: map['id'],
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'],
      dateTime: dateTime,
      numberOfPersons: map['number_of_persons']?.toInt() ?? 1,
      numberOfGames: map['number_of_games']?.toInt() ?? 1,
      email: map['email'],
      phone: map['phone'],
      formula: Formula.fromMap(formulaMap),
      isCancelled: map['is_cancelled'] ?? false,
      deposit: (map['deposit'] ?? 0.0).toDouble(),
      paymentMethod: payment_model.PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == map['payment_method'],
        orElse: () => payment_model.PaymentMethod.transfer,
      ),
      payments:
          (map['payments'] as List<dynamic>?)
              ?.where((x) => x != null)
              .map(
                (x) => payment_model.Payment.fromMap(x as Map<String, dynamic>),
              )
              .toList() ??
          [],
      consumptionsTotal: (map['consumptions_total'] ?? 0.0).toDouble(),
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

/// Represents a booking in the system.
/// 
/// All datetime values are stored internally in UTC timezone.
/// Use [dateTimeLocal] for display purposes and [dateTimeUTC] for storage.
/// 
/// Example:
/// ```dart
/// // Creating a new booking (converts local to UTC automatically)
/// final booking = Booking(
///   dateTime: DateTime.now().toUtc(),  // Always use UTC for storage
///   ...
/// );
/// 
/// // Displaying booking time (converts UTC to local automatically)
/// print(booking.dateTimeLocal);  // Shows in user's timezone
/// ```
