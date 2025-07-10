import 'package:flutter/foundation.dart';

class Consumption {
  final String id;
  final String bookingId;
  final String stockItemId;
  final int quantity;
  final DateTime timestamp;
  final double unitPrice;
  final bool isIncluded;
  const Consumption({
    required this.id,
    required this.bookingId,
    required this.stockItemId,
    required this.quantity,
    required this.timestamp,
    required this.unitPrice, // For Social Deal, this stores the total price
    this.isIncluded = false,
  });

  // Calculate total price as a getter
  double get totalPrice {
    if (isIncluded) return 0.0;
    // For Social Deal, unit_price stores the total price, not the unit price
    return unitPrice;
  }

  // Calculate the real unit price for display purposes
  double get displayUnitPrice {
    if (quantity == 0) return 0.0;
    return totalPrice / quantity;
  }

  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'booking_id': bookingId,
      'stock_item_id': stockItemId,
      'quantity': quantity,
      'timestamp': timestamp.toIso8601String(),
      'unit_price': unitPrice,
      'is_included': isIncluded,
    };
    
    // Note: total_price is calculated dynamically via the totalPrice getter
    // We don't serialize it to avoid database schema complications
    
    return map;
  }

  factory Consumption.fromMap(Map<String, dynamic> map) {
    // Vérifier que les champs obligatoires sont présents
    if (map['id'] == null ||
        (map['booking_id'] == null && map['bookingId'] == null) ||
        (map['stock_item_id'] == null && map['stockItemId'] == null)) {
      throw FormatException(
        'Missing required fields in Consumption.fromMap: ${map.toString()}',
      );
    }

    // Gestion des champs timestamp
    DateTime timestamp;
    try {
      if (map['timestamp'] is String) {
        timestamp = DateTime.parse(map['timestamp']);
      } else if (map['timestamp'] is DateTime) {
        timestamp = map['timestamp'];
      } else {
        timestamp = DateTime.now(); // Fallback pour les nouvelles consommations
      }
    } catch (e) {
      timestamp = DateTime.now();
    }

    // Gestion du prix unitaire
    double unitPrice = 0.0;
    final rawPrice = map['unit_price'] ?? map['unitPrice'];
    if (rawPrice != null) {
      if (rawPrice is int) {
        unitPrice = rawPrice.toDouble();
      } else if (rawPrice is double) {
        unitPrice = rawPrice;
      } else if (rawPrice is String) {
        unitPrice = double.tryParse(rawPrice) ?? 0.0;
      }
    }

    // Note: total_price is calculated dynamically via the totalPrice getter
    // We don't deserialize it from the database

    final isIncluded = map['is_included'] ?? false;
    
    return Consumption(
      id: map['id'].toString(),
      bookingId: (map['booking_id'] ?? map['bookingId']).toString(),
      stockItemId: (map['stock_item_id'] ?? map['stockItemId']).toString(),
      quantity: (map['quantity'] ?? 0) as int,
      timestamp: timestamp,
      unitPrice: unitPrice,
      isIncluded: isIncluded,
      // totalPrice is calculated dynamically
    );
  }

  Consumption copyWith({
    String? id,
    String? bookingId,
    String? stockItemId,
    int? quantity,
    DateTime? timestamp,
    double? unitPrice,
    bool? isIncluded,
  }) {
    return Consumption(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      stockItemId: stockItemId ?? this.stockItemId,
      quantity: quantity ?? this.quantity,
      timestamp: timestamp ?? this.timestamp,
      unitPrice: unitPrice ?? this.unitPrice,
      isIncluded: isIncluded ?? this.isIncluded,
      // totalPrice is calculated dynamically
    );
  }
}
