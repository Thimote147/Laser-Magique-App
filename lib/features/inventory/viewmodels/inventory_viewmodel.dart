import 'package:flutter/foundation.dart';
import '../models/stock_item.dart';

class InventoryViewModel extends ChangeNotifier {
  final List<StockItem> _items = [];
  List<StockItem> get items => _items;

  void incrementQuantity(StockItem item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item.copyWith(quantity: item.quantity + 1);
      notifyListeners();
    }
  }

  void decrementQuantity(StockItem item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1 && item.quantity > 0) {
      _items[index] = item.copyWith(quantity: item.quantity - 1);
      notifyListeners();
    }
  }

  void updateItem({
    required String id,
    String? name,
    int? quantity,
    double? price,
    int? alertThreshold,
  }) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        name: name,
        quantity: quantity,
        price: price,
        alertThreshold: alertThreshold,
      );
      notifyListeners();
    }
  }

  void deleteItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
