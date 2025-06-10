class StockItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final int alertThreshold;
  final String category; // 'DRINK' ou 'FOOD'

  bool get isLowStock => quantity <= alertThreshold;

  const StockItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.alertThreshold,
    required this.category,
  });

  StockItem copyWith({
    String? id,
    String? name,
    int? quantity,
    double? price,
    int? alertThreshold,
    String? category,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'alertThreshold': alertThreshold,
      'category': category,
    };
  }

  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id'],
      name: map['name'],
      quantity: map['quantity'],
      price: map['price'],
      alertThreshold: map['alertThreshold'],
      category: map['category'],
    );
  }
}
