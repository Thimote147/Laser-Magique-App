import 'stock_item_model.dart';

class Consumption {
  final String id;
  final String bookingId;
  final String stockItemId;
  final int quantity;
  final DateTime timestamp;
  final double unitPrice; // Prix unitaire au moment de la consommation

  const Consumption({
    required this.id,
    required this.bookingId,
    required this.stockItemId,
    required this.quantity,
    required this.timestamp,
    required this.unitPrice,
  });

  double get totalPrice => quantity * unitPrice;

  Consumption copyWith({
    String? id,
    String? bookingId,
    String? stockItemId,
    int? quantity,
    DateTime? timestamp,
    double? unitPrice,
  }) {
    return Consumption(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      stockItemId: stockItemId ?? this.stockItemId,
      quantity: quantity ?? this.quantity,
      timestamp: timestamp ?? this.timestamp,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'stockItemId': stockItemId,
      'quantity': quantity,
      'timestamp': timestamp.toIso8601String(),
      'unitPrice': unitPrice,
    };
  }

  factory Consumption.fromMap(Map<String, dynamic> map) {
    return Consumption(
      id: map['id'],
      bookingId: map['bookingId'],
      stockItemId: map['stockItemId'],
      quantity: map['quantity'],
      timestamp: DateTime.parse(map['timestamp']),
      unitPrice: map['unitPrice'],
    );
  }
}
