class StockItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final int alertThreshold;

  StockItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.alertThreshold,
  });

  StockItem copyWith({
    String? id,
    String? name,
    int? quantity,
    double? price,
    int? alertThreshold,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      alertThreshold: alertThreshold ?? this.alertThreshold,
    );
  }
}
