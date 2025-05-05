import 'package:uuid/uuid.dart';

class FoodItem {
  final String id;
  final String name;
  final double price;
  int quantity;

  FoodItem({
    String? id,
    required this.name,
    required this.price,
    required this.quantity,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {'food_id': id, 'name': name, 'price': price, 'quantity': quantity};
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['food_id'],
      name: json['name'],
      price:
          (json['price'] is int)
              ? (json['price'] as int).toDouble()
              : json['price'],
      quantity: json['quantity'] ?? 0,
    );
  }

  // Create a copy of this food item with updated fields
  FoodItem copyWith({String? name, double? price, int? quantity}) {
    return FoodItem(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }
}
