import 'package:uuid/uuid.dart';

enum PaymentMethod { cash, card, transfer }

enum PaymentType { deposit, balance }

class Payment {
  final String id;
  final String bookingId;
  final double amount;
  final PaymentMethod method;
  final PaymentType type;
  final DateTime date;

  Payment({
    String? id,
    required this.bookingId,
    required this.amount,
    required this.method,
    required this.type,
    required this.date,
  }) : id = id ?? const Uuid().v4();

  Payment copyWith({
    String? id,
    String? bookingId,
    double? amount,
    PaymentMethod? method,
    PaymentType? type,
    DateTime? date,
  }) {
    return Payment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      type: type ?? this.type,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'amount': amount,
      'method': method.toString(),
      'type': type.toString(),
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      bookingId: map['bookingId'],
      amount: map['amount'],
      method: PaymentMethod.values.firstWhere(
        (e) => e.toString() == map['method'],
      ),
      type: PaymentType.values.firstWhere((e) => e.toString() == map['type']),
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
    );
  }
}
