// filepath: /Users/thimotefetu/Sites/Laser-Magique-App/lib/viewmodels/stock_view_model.dart
import 'package:flutter/foundation.dart';
import '../models/stock_item_model.dart';
import '../models/consumption_model.dart';
import '../repositories/stock_repository.dart';

class StockViewModel extends ChangeNotifier {
  final StockRepository _repository = StockRepository();
  List<StockItem> _items = [];
  List<Consumption> _consumptions = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;

  StockViewModel() {
    _initializeData();
    _setupSubscriptions();
  }

  // Getters
  List<StockItem> get items => List.unmodifiable(_items);
  List<Consumption> get consumptions => List.unmodifiable(_consumptions);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize data
  Future<void> _initializeData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _items = await _repository.getAllStockItems();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading stock items: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Setup real-time subscriptions
  void _setupSubscriptions() {
    _repository.streamStockItems().listen(
      (items) {
        _items = items;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Subscription error: $e';
        notifyListeners();
      },
    );
  }

  // Filtered getters
  List<StockItem> get filteredItems =>
      _searchQuery.isEmpty
          ? _items
          : _items
              .where(
                (item) => item.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();

  List<StockItem> get drinks =>
      filteredItems.where((item) => item.category == 'DRINK').toList();

  List<StockItem> get food =>
      filteredItems.where((item) => item.category == 'FOOD').toList();

  List<StockItem> get others =>
      filteredItems.where((item) => item.category == 'OTHER').toList();

  List<StockItem> get lowStockItems =>
      filteredItems.where((item) => item.isLowStock).toList();

  // Get the total consumption cost for a booking
  double getConsumptionsTotalForBooking(String bookingId) {
    return _consumptions
        .where((c) => c.bookingId == bookingId)
        .fold(0.0, (sum, c) => sum + c.totalPrice);
  }

  // Search functionality
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Stock management
  Future<void> adjustQuantity(String itemId, int adjustment) async {
    try {
      // Trouver l'article dans la liste locale
      final item = _items.firstWhere(
        (item) => item.id == itemId,
        orElse: () => throw Exception('Article non trouvé'),
      );

      // Vérifier que la nouvelle quantité ne sera pas négative
      final newQuantity = item.quantity + adjustment;
      if (newQuantity < 0) {
        throw Exception('La quantité ne peut pas être négative');
      }

      // Mettre à jour l'article dans la base de données
      final updatedItem = await _repository.updateStockItem(
        item.copyWith(quantity: newQuantity),
      );

      // Mettre à jour l'article dans la liste locale
      final index = _items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        _items[index] = updatedItem;
        notifyListeners();
      }
    } catch (e) {
      _error =
          e.toString().contains('Exception:')
              ? e.toString().replaceAll('Exception:', '').trim()
              : 'Erreur lors de l\'ajustement de la quantité: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateConsumptionQuantity(
    String consumptionId,
    int newQuantity,
  ) async {
    try {
      final consumption = _consumptions.firstWhere(
        (c) => c.id == consumptionId,
      );
      final stockItem = _items.firstWhere(
        (i) => i.id == consumption.stockItemId,
      );

      // Calculate the quantity difference
      final quantityDiff = newQuantity - consumption.quantity;

      // Check if we have enough stock
      if (stockItem.quantity - quantityDiff < 0) {
        throw Exception('Not enough stock available');
      }

      // Update the stock item quantity
      await _repository.updateStockItem(
        stockItem.copyWith(quantity: stockItem.quantity - quantityDiff),
      );

      // Update the consumption
      await _repository.updateConsumption(
        consumption.copyWith(quantity: newQuantity),
      );
    } catch (e) {
      _error = 'Error updating consumption quantity: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Consumption management
  Future<List<Consumption>> getConsumptionsForBooking(String bookingId) async {
    try {
      final consumptions = await _repository.getConsumptionsForBooking(
        bookingId,
      );
      _consumptions = consumptions;
      notifyListeners();
      return consumptions;
    } catch (e) {
      _error = 'Error loading consumptions: $e';
      notifyListeners();
      return [];
    }
  }

  Future<bool> addConsumption({
    required String bookingId,
    required String stockItemId,
    required int quantity,
  }) async {
    try {
      final item = _items.firstWhere((item) => item.id == stockItemId);
      if (item.quantity < quantity) {
        _error = 'Not enough stock available';
        notifyListeners();
        return false;
      }

      final success = await _repository.addConsumption(
        bookingId: bookingId,
        stockItemId: stockItemId,
        quantity: quantity,
      );

      if (success) {
        await getConsumptionsForBooking(bookingId);
      } else {
        _error = 'Failed to add consumption';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = 'Error adding consumption: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cancelConsumption(String consumptionId) async {
    try {
      final consumption = _consumptions.firstWhere(
        (c) => c.id == consumptionId,
      );
      final stockItem = _items.firstWhere(
        (i) => i.id == consumption.stockItemId,
      );

      // Return the quantity to stock
      await adjustQuantity(stockItem.id, consumption.quantity);

      // Delete the consumption
      await _repository.deleteConsumption(consumptionId);

      // Update local state
      _consumptions.removeWhere((c) => c.id == consumptionId);
      notifyListeners();
    } catch (e) {
      _error = 'Error canceling consumption: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Stock Items
  Future<void> addItem({
    required String name,
    required int quantity,
    required double price,
    required int alertThreshold,
    required String category,
  }) async {
    try {
      final item = await _repository.createStockItem(
        name: name,
        quantity: quantity,
        price: price,
        alertThreshold: alertThreshold,
        category: category,
      );
      _items.add(item);
      notifyListeners();
    } catch (e) {
      _error = 'Error adding item: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateItem(StockItem item) async {
    try {
      final updatedItem = await _repository.updateStockItem(item);
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index] = updatedItem;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error updating item: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await _repository.deleteStockItem(itemId);
      _items.removeWhere((item) => item.id == itemId);
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de la suppression : ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
