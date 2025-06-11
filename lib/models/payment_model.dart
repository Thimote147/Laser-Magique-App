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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'amount': amount,
      'method': method.toString().split('.').last,
      'type': type.toString().split('.').last,
      'date': date.toIso8601String(),
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'];
    final methodStr = json['method'] ?? json['payment_method'];
    final typeStr = json['type'] ?? json['payment_type'];
    final dateStr = json['date'] ?? json['payment_date'];

    return Payment(
      id: json['id'] ?? '',
      bookingId: json['booking_id'] ?? '',
      amount: (amount is num ? amount : 0.0).toDouble(),
      method:
          methodStr != null
              ? PaymentMethod.values.firstWhere(
                (e) =>
                    e.toString().split('.').last.toLowerCase() ==
                    methodStr.toString().toLowerCase(),
                orElse: () => PaymentMethod.transfer,
              )
              : PaymentMethod.transfer,
      type:
          typeStr != null
              ? PaymentType.values.firstWhere(
                (e) =>
                    e.toString().split('.').last.toLowerCase() ==
                    typeStr.toString().toLowerCase(),
                orElse: () => PaymentType.deposit,
              )
              : PaymentType.deposit,
      date: dateStr != null ? DateTime.parse(dateStr) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment.fromJson(map);
  }
}
