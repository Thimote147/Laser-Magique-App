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
  }) : id = id ?? '';

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
    // Pour l'insertion en base de données, on n'inclut pas l'ID
    // car il sera généré automatiquement par Supabase
    final map = {
      'booking_id': bookingId,
      'amount': amount,
      'payment_method': method.toString().split('.').last,
      'payment_type': type.toString().split('.').last,
      'payment_date': date.toIso8601String(),
    };

    // On n'ajoute l'ID que s'il est non vide (cas des mises à jour)
    if (id.isNotEmpty) {
      map['id'] = id;
    }

    return map;
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'];

    // Check for both column naming styles
    final methodStr = json['payment_method'] ?? json['method'];
    final typeStr = json['payment_type'] ?? json['type'];
    final dateStr = json['payment_date'] ?? json['date'];

    print('Payment.fromJson full json: $json');
    print('Payment.fromJson raw method: $methodStr');

    // Default payment method
    PaymentMethod method = PaymentMethod.transfer;

    // Try to parse the payment method with more detailed logging
    if (methodStr != null) {
      try {
        final methodStrLower = methodStr.toString().toLowerCase();
        print('Attempting to match payment method: $methodStrLower');

        // Print all enum values for debugging
        for (var e in PaymentMethod.values) {
          final enumStrLower = e.toString().split('.').last.toLowerCase();
          print(
            '  Available enum: $enumStrLower - matches: ${enumStrLower == methodStrLower}',
          );
        }

        method = PaymentMethod.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == methodStrLower,
          orElse: () => PaymentMethod.transfer,
        );
        print('Selected payment method: $method');
      } catch (e) {
        print('Error parsing payment method: $e');
        method = PaymentMethod.transfer;
      }
    }

    final payment = Payment(
      id: json['id'] ?? '',
      bookingId: json['booking_id'] ?? '',
      amount: (amount is num ? amount : 0.0).toDouble(),
      method: method,
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

    print('Payment.fromJson parsed method: ${payment.method}');
    return payment;
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment.fromJson(map);
  }
}
