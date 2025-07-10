class StockItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final int alertThreshold;
  final String category; // 'DRINK' ou 'FOOD'
  final bool isActive; // Indique si l'article est actif/visible dans le stock
  final bool includedInSocialDeal; // Indique si l'article est inclus dans les formules Social Deal

  bool get isLowStock => quantity <= alertThreshold;

  const StockItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.alertThreshold,
    required this.category,
    this.isActive = true,
    this.includedInSocialDeal = false,
  });

  StockItem copyWith({
    String? id,
    String? name,
    int? quantity,
    double? price,
    int? alertThreshold,
    String? category,
    bool? isActive,
    bool? includedInSocialDeal,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      includedInSocialDeal: includedInSocialDeal ?? this.includedInSocialDeal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'alert_threshold': alertThreshold,
      'category': category,
      'is_active': isActive,
      'included_in_social_deal': includedInSocialDeal,
    };
  }

  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id'],
      name: map['name'],
      quantity: (map['quantity'] ?? 0).toInt(),
      price: (map['price'] ?? 0.0).toDouble(),
      alertThreshold: (map['alert_threshold'] ?? 0).toInt(),
      category: map['category'],
      isActive: map['is_active'] ?? true,
      includedInSocialDeal: map['included_in_social_deal'] ?? false,
    );
  }
}
